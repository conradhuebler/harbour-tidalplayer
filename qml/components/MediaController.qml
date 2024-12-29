import QtQuick 2.0
import QtMultimedia 5.6
import org.nemomobile.mpris 1.0

Item {
    id: root

    // signals
    signal currentTrackChanged()

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
        canControl: true
        canGoNext: true
        canGoPrevious: true
        canPause: true
        canPlay: true
        canSeek: true

        serviceName: "tidalplayer"
        identity: "Tidal Music Player"

        function updateTrack(track, artist, album) {
            var metadata = mprisPlayer.metadata
            metadata[Mpris.metadataToString(Mpris.Title)] = track
            metadata[Mpris.metadataToString(Mpris.Artist)] = artist
            metadata[Mpris.metadataToString(Mpris.Album)] = album
            console.log("mpris", track)
            mprisPlayer.metadata = metadata
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

        signal currentPosition(int position)

        onError: {
            if (error === MediaPlayer.ResourceError) errorMsg = qsTr("Error: Problem with allocating resources")
            else if (error === MediaPlayer.ServiceMissing) errorMsg = qsTr("Error: Media service error")
            else if (error === MediaPlayer.FormatError) errorMsg = qsTr("Error: Video or Audio format is not supported")
            else if (error === MediaPlayer.AccessDenied) errorMsg = qsTr("Error: Access denied to the video")
            else if (error === MediaPlayer.NetworkError) errorMsg = qsTr("Error: Network error")
            stop()
            isPlaying = false
        }

        onStopped: {
            if (!blockAutoNext) {
                if (playlistManager.canNext) {
                    playlistManager.nextTrack()
                } else {
                    playlistManager.playListFinished()
                    isPlaying = false
                }
            }
            blockAutoNext = false
        }

        onPositionChanged: {
            mediaPlayer.currentPosition(mediaPlayer.position/mediaPlayer.duration*100)
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
        console.log("only this function is allowed to start playback")
        mediaPlayer.source = url
        mediaPlayer.play()
    }


    Connections {
        target: pythonApi
        onCurrentPlayback: {
            console.log("current track info media controller")
            console.log("track", trackinfo.title)
            current_track_title = trackinfo.title
            current_track_artist = trackinfo.artist
            current_track_album = trackinfo.album
            current_track_image = trackinfo.image
            current_track_duration = trackinfo.duration
            updateMprisMetadata(current_track_title, current_track_artist, current_track_album)
        }
    }

}
