import QtQuick 2.0
import Sailfish.Silica 1.0
import QtMultimedia 5.6
import Sailfish.Media 1.0
import harbour.tidalplayer 1.0

import "widgets"


Page {
    id: playlistPage

    // The effective value will be restricted by ApplicationWindow.allowedOrientations
    allowedOrientations: Orientation.All

    // To enable PullDownMenu, place our content in a SilicaFlickable
    SilicaFlickable {
        width: parent.width
        anchors.fill: parent
        PullDownMenu {
            MenuItem {
                text: qsTr("Clear")
                onClicked:
                {
                    trackList.clear();
                }
            }
        }
        Column {
            width: parent.width
            id: infoCoulumn
            anchors.fill: parent

            SectionHeader
            {
                id: section
                text: "Track List"
            }

            TrackList {
                id: trackList
                anchors {
                    top : section.bottom
                    fill: infoCoulumn
                }
            }
        }
   }
    Component.onCompleted: {
        trackList.track_id_list = PlaylistManager.trackIds
        trackList.createListfromTrackIds()
    }

    Connections
    {
        target: PlaylistManager
        onCurrentTrackChanged:
        {
            trackList.highlight_index = PlaylistManager.currentTrackID
        }
    }
}
