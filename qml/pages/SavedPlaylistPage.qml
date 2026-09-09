// SavedPlaylistPage.qml
import QtQuick 2.0
import Sailfish.Silica 1.0
import "widgets"

Page {
    id: page
    allowedOrientations: Orientation.All

    property string playlistId
    property string playlistTitle
    // Artwork for the hero header; empty falls back to a plain PageHeader.
    // - Claude Generated
    property url playlistImage: ""
    property string type // or alias ?

    SilicaFlickable {
        id: flickable
        anchors {
            fill: parent
            rightMargin: minPlayerPanel.reservedRight
        }
        contentHeight: flickable.height //trackList.height + Theme.paddingLarge + getBottomOffset()
        height: parent.height + miniPlayerPanel.height + getBottomOffset()            

        PullDownMenu {

            MenuItem {
                text: qsTr("Play All")
                onClicked: {
                    playlistManager.replaceWithPlaylist(playlistId)
                }
            }
        }

        function getBottomOffset()
        {
            // Landscape: the player sits on the right edge, not below. - Claude Generated
            if (minPlayerPanel.landscape) return 0
            if (minPlayerPanel.open) return ( 0.6 * minPlayerPanel.height )
            return minPlayerPanel.height * 0.2
        }

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
            headerImage: page.playlistImage
            headerSubtitle: qsTr("Playlist")
            headerPlayVisible: true
            onHeaderPlayClicked: playlistManager.replaceWithPlaylist(page.playlistId)

            function getBottomOffset()
            {
                if (minPlayerPanel.landscape) return 0
                if (minPlayerPanel.open) return ( 0.6 * minPlayerPanel.height )
                return 0
            }
        }
    }
}
