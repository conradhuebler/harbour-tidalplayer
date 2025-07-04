import QtQuick 2.0
import Sailfish.Silica 1.0
import "widgets"

Page {
    id: page
    allowedOrientations: Orientation.All

    property string playlistId
    property string playlistTitle
    property string type                                                                                                                                                                                                                                                                                                                                                                                                                        // or alias ?

    SilicaFlickable {
        id: flickable
        anchors {
            fill: parent
            bottomMargin: minPlayerPanel.margin
        }
        contentHeight: flickable.height //trackList.height + Theme.paddingLarge + getBottomOffset()
        height: parent.height + miniPlayerPanel.height + getBottomOffset()

        function getBottomOffset()
        {
            if (minPlayerPanel.open) return ( 0.6 * minPlayerPanel.height )
            return minPlayerPanel.height * 0.2
        }

        PullDownMenu {

            MenuItem {
                text: qsTr("Play All")
                onClicked: {
                    playlistManager.clearPlayList()
                    tidalApi.playMix(playlistId)                       
                }
            }
            MenuItem {
                text: minPlayerPanel.open ? qsTr("Hide player") : qsTr("Show player")
                onClicked: minPlayerPanel.open = !minPlayerPanel.open
            }
        }

        TrackList {
            id: trackList
            width: parent.width
            //height:  parent.height //Theme.itemSizeLarge * 14
            anchors {
                fill: parent
                bottomMargin: flickable.getBottomOffset()
            }
            title: playlistTitle
            type: "mix"
            playlistId: page.playlistId  // Wenn die TrackList einen playlistId Parameter hat

        }
    }
}
