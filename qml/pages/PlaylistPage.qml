import QtQuick 2.0
import Sailfish.Silica 1.0
import QtMultimedia 5.6
import Sailfish.Media 1.0
import "widgets"

Page {
    id: root

    allowedOrientations: Orientation.All  // Optional: Erlaubt alle Orientierungen

    TrackList {
        id: pLtrackList
        anchors.fill: parent
        title: "Current Playlist"
        type: "current"
    }

    Component.onCompleted: {
        console.log("PlaylistPage loaded")
        if (playlistManager.size > 0) {
            playlistManager.generateList()
        }
    }
}
