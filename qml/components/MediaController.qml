import QtQuick 2.0
import QtMultimedia 5.6
import org.nemomobile.mpris 1.0

Item {
    id: root

    // signals
    signal currentTrackChanged()
    signal currentPosition(double position)

    property string current_track_title : ""
    property string current_track_artist : ""
    property string current_track_album : ""
    property string current_track_image : ""
    property double current_track_duration : 0

   // MediaPlayer Properties (durchgereicht via alias)
    readonly property alias mediaPlayer: mediaPlayer
    property alias player: mediaPlayer
    property alias mpris: mprisPlayer
    property alias source: mediaPlayer.source
    property alias position: mediaPlayer.position
    property alias duration: mediaPlayer.duration
    property alias volume: mediaPlayer.volume
    property alias muted: mediaPlayer.muted
    //property alias playbackState: mediaPlayer.playbackState
    property alias bufferProgress: mediaPlayer.bufferProgress
    property alias seekable: mediaPlayer.seekable
    property alias autoLoad: mediaPlayer.autoLoad
    property alias error: mediaPlayer.error
    property alias status: mediaPlayer.status

    readonly property int playingState: MediaPlayer.PlayingState
    readonly property int pausedState: MediaPlayer.PausedState
    readonly property int stoppedState: MediaPlayer.StoppedState

    property int playbackState: mediaPlayer.playbackState
    property bool isPlaying: playbackState === MediaPlayer.PlayingState


    // Custom Properties
    //property alias isPlaying: mediaPlayer.isPlaying
    property alias blockAutoNext: mediaPlayer.blockAutoNext
    property alias videoPlaying: mediaPlayer.videoPlaying
    property string errorMsg: mediaPlayer.errorMsg

    // MPRIS Player
    MprisPlayer {
        id: mprisPlayer

        // Bereits vorhandene Eigenschaften
        canControl: true
        canGoNext: true
        canGoPrevious: true
        canPause: true
        canPlay: true
        canSeek: true

        serviceName: "tidalplayer"
        identity: "Tidal Music Player"

        // Zusätzliche wichtige Eigenschaften
        canQuit: true
        canSetFullscreen: false
        canRaise: true
        hasTrackList: true
        loopStatus: Mpris.None
        shuffle: false
        volume: mediaPlayer.volume
        position: mediaPlayer.position * 1000 // MPRIS verwendet Mikrosekunden

        // Aktualisierte Metadaten-Funktion
        function updateTrack(track, artist, album) {
            var metadata = {}

            // Pflichtfelder
            metadata[Mpris.metadataToString(Mpris.Title)] = track
            metadata[Mpris.metadataToString(Mpris.Artist)] = [artist] // Array von Künstlern
            metadata[Mpris.metadataToString(Mpris.Album)] = album

            // Zusätzliche wichtige Metadaten
            metadata[Mpris.metadataToString(Mpris.Length)] = current_track_duration * 1000000 // Mikrosekunden
            metadata[Mpris.metadataToString(Mpris.TrackNumber)] = playlistManager.currentIndex + 1

            if (current_track_image !== "") {
                metadata[Mpris.metadataToString(Mpris.ArtUrl)] = current_track_image
            }

            // Eindeutige ID für den Track
            metadata[Mpris.metadataToString(Mpris.TrackId)] = "/org/mpris/MediaPlayer2/track/" +
                playlistManager.currentIndex

            mprisPlayer.metadata = metadata
        }

        // Zusätzliche MPRIS-Signalhandler
        onRaiseRequested: {
            // App in den Vordergrund bringen
            window.raise()
        }

        onQuitRequested: {
            // App beenden
            Qt.quit()
        }

        onVolumeRequested: {
            // Lautstärke ändern
            mediaPlayer.volume = volume
        }

        onSeekRequested: {
            // Position ändern (offset ist in Mikrosekunden)
            var newPos = mediaPlayer.position + (offset / 1000000)
            if (newPos < 0) newPos = 0
            if (newPos > mediaPlayer.duration) newPos = mediaPlayer.duration
            mediaPlayer.seek(newPos)
        }

        onSetPositionRequested: {
            // Absolute Position setzen (position ist in Mikrosekunden)
            mediaPlayer.seek(position / 1000000)
        }
    }

    // Media Player
    MediaPlayer {
        id: mediaPlayer
        autoLoad: true

        property bool blockAutoNext: false
        property bool isPlaying: false
        property bool videoPlaying: false
        property string errorMsg: ""


        onError: {
            if (error === MediaPlayer.ResourceError) errorMsg = qsTr("Error: Problem with allocating resources")
            else if (error === MediaPlayer.ServiceMissing) errorMsg = qsTr("Error: Media service error")
            else if (error === MediaPlayer.FormatError) errorMsg = qsTr("Error: Video or Audio format is not supported")
            else if (error === MediaPlayer.AccessDenied) errorMsg = qsTr("Error: Access denied to the video")
            else if (error === MediaPlayer.NetworkError) errorMsg = qsTr("Error: Network error")
            console.log(errorMsg)
            stop()
            isPlaying = false
        }

        onStopped: {
            console.log("Playback stopped, look for next track")
            if (!blockAutoNext) {
                console.log("playing next track is not blocked by user interface")
                if (playlistManager.canNext) {
                    playlistManager.nextTrack()
                } else {
                    playlistManager.playListFinished()
                    isPlaying = false
                }
            }else{
                console.log("playing next track is blocked by user interface")
                //blockAutoNext = false
            }
        }

        onPositionChanged: {
            root.currentPosition(mediaPlayer.position/mediaPlayer.duration*100)
        }

        onPlaying: {
            isPlaying = true
            mprisPlayer.canGoNext = playlistManager.canNext
            mprisPlayer.canGoPrevious = playlistManager.canPrev
            mprisPlayer.playbackStatus = Mpris.Playing
        }

        onPaused: {
            mprisPlayer.playbackStatus = Mpris.Paused
        }

        onStatusChanged:
        {
            console.log("Playback state changed: ", playbackState)
            console.log("Next and prev ", playlistManager.canNext, playlistManager.canPrev)
            console.log(errorMsg)
        }
    }

    // MPRIS Connections
    Connections {
        target: mprisPlayer

        onPlayRequested: mediaPlayer.play()
        onPauseRequested: mediaPlayer.pause()

        onPlayPauseRequested: {
            if (mediaPlayer.playbackState == 1) {
                mediaPlayer.pause()
            } else if(mediaPlayer.playbackState == 2) {
                mediaPlayer.play()
            }
        }

        onNextRequested: {
            mediaPlayer.blockAutoNext = true
            playlistManager.nextTrackClicked()
        }

        onPreviousRequested: {
            playlistManager.previousTrackClicked()
        }
    }

    // Public Functions
    function play() {
        mediaPlayer.play()
    }

    function pause() {
        mediaPlayer.pause()
    }

    function stop() {
        mediaPlayer.stop()
    }

    function seek(position) {
        if (mediaPlayer.seekable) {
            mediaPlayer.seek(position)
        }
    }

    function setSource(url) {
        mediaPlayer.source = url
    }

    function updateMprisMetadata(track, artist, album) {
        mprisPlayer.updateTrack(track, artist, album)
    }

    function playUrl(url) {
        mediaPlayer.blockAutoNext = true
        console.log("only this function is allowed to start playback", url)
        mediaPlayer.source = url
        mediaPlayer.play()
        mediaPlayer.blockAutoNext = false
    }


    Connections {
        target: tidalApi
        onCurrentPlayback: {
            current_track_title = trackinfo.title
            current_track_artist = trackinfo.artist
            current_track_album = trackinfo.album
            current_track_image = trackinfo.image
            current_track_duration = trackinfo.duration
            updateMprisMetadata(current_track_title, current_track_artist, current_track_album)
        }
    }

}
