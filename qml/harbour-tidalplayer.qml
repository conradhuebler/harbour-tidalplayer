import QtQuick 2.0
import Sailfish.Silica 1.0
import io.thp.pyotherside 1.5
import QtMultimedia 5.6
import org.nemomobile.mpris 1.0
import Nemo.Configuration 1.0

import "components"

import "pages"
import "pages/widgets"


ApplicationWindow
{
    property bool loginTrue : false
    property var locale: Qt.locale()
    property date currentDate: new Date()
    property MiniPlayer minPlayerPanel : miniPlayerPanel

    MprisPlayer{
        id: mprisPlayer
        canControl: true

        canGoNext: true
        canGoPrevious: true
        canPause: true
        canPlay: true
        canSeek: true

        serviceName: "tidalplayer"
        identity: "Tidal Music Player"

        function updateTrack(track, artist, album)
        {
                console.debug("Title changed to: " + track)
                var metadata = mprisPlayer.metadata
                metadata[Mpris.metadataToString(Mpris.Title)] = track
                metadata[Mpris.metadataToString(Mpris.Artist)] = artist

                metadata[Mpris.metadataToString(Mpris.Album)] = album

                mprisPlayer.metadata = metadata

        }

    }

    TidalApi {

        id: pythonApi
        /*
        // Neue Handler für Tracks
        onTrackAdded: {
            // Wenn ein Track aus der Suche hinzugefügt wird
            console.log("TidalApi: Track added signal", id, title)
            playlistManager.appendTrack({
                id: id,
                title: title,
                album: album,
                artist: artist,
                image: image,
                duration: duration
            })
        }*/
    }


    PlaylistManager {
        id: playlistManager
        onCurrentTrackChanged: {
            if (track) {
                pythonApi.playTrackId(track.id)
                console.log("playlistmanager call id", track)
            }
        }
    }

    MediaPlayer {
        id: mediaPlayer
        autoLoad: true
        signal currentPosition(int position)
        property bool blockAutoNext : false
        property bool isPlaying : false
        property bool videoPlaying: false
        property string errorMsg: ""

        onError: {
            if ( error === MediaPlayer.ResourceError ) errorMsg = qsTr("Error: Problem with allocating resources")
            else if ( error === MediaPlayer.ServiceMissing ) errorMsg = qsTr("Error: Media service error")
            else if ( error === MediaPlayer.FormatError ) errorMsg = qsTr("Error: Video or Audio format is not supported")
            else if ( error === MediaPlayer.AccessDenied ) errorMsg = qsTr("Error: Access denied to the video")
            else if ( error === MediaPlayer.NetworkError ) errorMsg = qsTr("Error: Network error")
            stop()
            isPlaying = false
        }

        onStopped:
        {
            console.log("playing stopped", playlistManager.canNext, blockAutoNext)
            if(!blockAutoNext)
            {
                console.log("playing next is not blocked", playlistManager.canNext, blockAutoNext)

                if(playlistManager.canNext)
                {
                    playlistManager.nextTrack()
                }
                else
                {
                    console.log("there is no next track to play", playlistManager.canNext, blockAutoNext)

                    playlistManager.playListFinished()
                    isPlaying = false
                }
            }else
            console.log("playing next was blocked", playlistManager.canNext, blockAutoNext)

            blockAutoNext = false
        }

        onPositionChanged:
        {
            mediaPlayer.currentPosition(mediaPlayer.position/mediaPlayer.duration*100)
        }

        onPlaying:
        {
            isPlaying = true
            //mprisPlayer.canPause = true
            mprisPlayer.canGoNext = playlistManager.canNext
            mprisPlayer.canGoPrevious = playlistManager.canPrev
            mprisPlayer.playbackStatus = Mpris.Playing
        }

        onPaused:
        {
            mprisPlayer.playbackStatus = Mpris.Paused
        }
    }

    initialPage: Component { FirstPage { } }
    cover: Qt.resolvedUrl("cover/CoverPage.qml")
    allowedOrientations: defaultAllowedOrientations


    MiniPlayer {
        parent: pageStack
        id: miniPlayerPanel
        z:10
    }


    AuthManager {
            id: authManager
        }



        Component.onCompleted: {
            authManager.checkAndLogin()
            mprisPlayer.setCanControl(true)
        }
    /*
    Connections {
        target: pythonApi
        onOAuthSuccess: {
            authManager.updateTokens(type, token, rtoken, date)
        }
        onLoginFailed: {
            authManager.clearTokens()
        }
    }
*/

    Connections
    {
        target: playlistManager
        onCurrentId:
        {
            pythonApi.playTrackId(id)
        }
    }

    Connections{
        target: mprisPlayer
        onPlayRequested :
        {
            console.log("play requested")
            mediaPlayer.play()
        }

        onPauseRequested :
        {
            console.log("pause requested")
            mediaPlayer.pause()
        }

        onPlayPauseRequested :
        {
            console.log("playpause requested")

            if (mediaPlayer.playbackState == 1)
            {
                mediaPlayer.pause()
            }
            else if(mediaPlayer.playbackState == 2){
                mediaPlayer.play()
            }
        }

        onNextRequested :
        {
            console.log("play next")
            mediaPlayer.blockAutoNext = true
            playlistManager.nextTrackClicked()
        }

        onPreviousRequested :
        {
            playlistManager.previousTrackClicked()
        }
    }
}
