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
        anchors {
            fill: parent
            bottomMargin: getBottomOffset()
        }
        title: "Current Playlist"
        type: "current"
        height: parent.height - getBottomOffset()

        function getBottomOffset()
        {
            console.log('in getBottomOffset in playlistpage')
            if (pLtrackList.minPlayerPanel.open) return ( 1.2 * pLtrackList.minPlayerPanel.height )
            return pLtrackList.minPlayerPanel.height * 0.4
        }

    }

    Component.onCompleted: {
        console.log("PlaylistPage loaded")
        if (playlistManager.size > 0) {
            playlistManager.generateList()
        }
    }
}
