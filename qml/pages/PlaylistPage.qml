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
            rightMargin: minPlayerPanel.reservedRight
        }
        title: "Current Playlist"
        type: "current"
        height: parent.height - getBottomOffset()

        function getBottomOffset()
        {
            if (applicationWindow.settings && applicationWindow.settings.debugLevel >= 1)
                console.log('in getBottomOffset in playlistpage')
            // minPlayerPanel is a property of the application window, not of
            // the TrackList this used to reach through. - Claude Generated
            if (minPlayerPanel.landscape) return 0
            if (minPlayerPanel.open) return ( 1.2 * minPlayerPanel.height )
            return minPlayerPanel.height * 0.4
        }

    }

    Component.onCompleted: {
        if (applicationWindow.settings && applicationWindow.settings.debugLevel >= 1)
            console.log("PlaylistPage loaded")
        if (playlistManager.size > 0) {
            playlistManager.generateList()
        }
    }
}
