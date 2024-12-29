// PlaylistPage.qml
import QtQuick 2.0
import Sailfish.Silica 1.0
import QtMultimedia 5.6
import Sailfish.Media 1.0
import "widgets"

Item {
    id: playlistPage
    width: parent.width
    height: parent.height

    // Timer für verzögerte Ausführung
    Timer {
        id: updateTimer
        interval: 100  // 100ms Verzögerung
        repeat: false
        onTriggered: {
            console.log(playlistManager.size)
            for(var i = 0; i < playlistManager.size; ++i) {
                console.log("Requesting item", i)
                var id = playlistManager.requestPlaylistItem(i)
                console.log("here id", id)
                var track = cacheManager.getTrackInfo(id)
                if (track) {
                    console.log("Adding track:", track.title)
                    pLtrackList.addTrack(track.title, track.artist, track.album, track.track_id, track.duration)
                } else {
                    console.log("No track data for index:", i)
                }
            }
            pLtrackList.highlight_index = playlistManager.current_track
        }
    }

    SilicaFlickable {
        id: flickable
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingMedium

            TrackList {
                id: pLtrackList
                width: parent.width
                height: playlistPage.height
                allow_add: false
                start_on_tap: true
                allow_play: false
                title: ""
            }
        }
    }

    Connections {
        target: playlistManager
        onCurrentTrack: {
            pLtrackList.highlight_index = playlistManager.current_track
        }
        onPositionChanged: {
            console.log("Current position changed to:", playlistManager.current_position)
            pLtrackList.highlight_index = playlistManager.current_position
        }
        onListChanged: {
            console.log("Update playlist now", playlistManager.size)
            pLtrackList.clear()
            updateTimer.start()  // Timer starten statt Qt.callLater
        }
        onClearList: {
            pLtrackList.clear()
        }
        onTrackInformation: {
            pLtrackList.setTrack(index, id, title, artist, album, image, duration)
            console.log("Track information updated:", title)
        }
    }

    Component.onCompleted: {
        console.log("PlaylistPage loaded")
        if (playlistManager.size > 0) {
            playlistManager.generateList()
        }
    }
}
