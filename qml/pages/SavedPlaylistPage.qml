// SavedPlaylistPage.qml
import QtQuick 2.0
import Sailfish.Silica 1.0
import "widgets"

Page {
    id: page
    allowedOrientations: Orientation.All

    property string playlistId
    property string playlistTitle
    property string type // or alias ?

    TrackList {
        id: trackList
        anchors {
            fill: parent
            bottomMargin: getBottomOffset()
        }
        height: parent.height - getBottomOffset()
        title: playlistTitle
        type: "playlist"
        playlistId: page.playlistId  // Wenn die TrackList einen playlistId Parameter hat

        function getBottomOffset()
        {
            if (minPlayerPanel.open) return ( 0.6 * minPlayerPanel.height )
            return 0
        }
    }
}
