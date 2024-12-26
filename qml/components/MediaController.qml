import QtQuick 2.0
import QtMultimedia 5.6
import org.nemomobile.mpris 1.0

Item {
    id: root

    // Exposed Properties
    property alias player: mediaPlayer
    property alias mpris: mprisPlayer
    property bool isPlaying: mediaPlayer.isPlaying

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

    function setSource(url) {
        mediaPlayer.source = url
    }

    function updateMprisMetadata(track, artist, album) {
        mprisPlayer.updateTrack(track, artist, album)
    }
}
