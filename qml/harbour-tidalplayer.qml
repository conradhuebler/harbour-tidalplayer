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
    }


    PlaylistManager {
        id: playlistManager
        onCurrentTrackChanged: {
            if (track) {
                pythonApi.playTrackId(track)
                console.log("playlistmanager call id", track)
            }
        }
    }

    TidalCache
    {
        id: cacheManager
    }

    MediaController
    {
        id: mediaController
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

    Connections {
        target: pythonApi
        onOAuthSuccess: {
            authManager.updateTokens(type, token, rtoken, date)
        }
        onLoginFailed: {
            authManager.clearTokens()
        }
    }


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
