import QtQuick 2.0
import Sailfish.Silica 1.0
import QtMultimedia 5.6
import Sailfish.Media 1.0

import "widgets"


Page {
    id: artistPage
    property int track_id
    PageHeader {
        id: header
        title:  qsTr("Artist Info")
    }

    // The effective value will be restricted by ApplicationWindow.allowedOrientations
    allowedOrientations: Orientation.All

    // To enable PullDownMenu, place our content in a SilicaFlickable
    SilicaFlickable {

        width: parent.width
        anchors {
            left: parent.left
            leftMargin: Theme.horizontalPageMargin
            right: parent.right
            rightMargin: Theme.horizontalPageMargin
            verticalCenter: parent.verticalCenter
        }

        SilicaListView {
            id: infoCoulumn

            anchors {
                left: parent.left
                leftMargin: Theme.horizontalPageMargin
                right: parent.right
                rightMargin: Theme.horizontalPageMargin
                verticalCenter: parent.verticalCenter
            }

            Image {
                id: coverImage
                width: parent.width
                //anchors.centerIn: parent.top
                fillMode: Image.PreserveAspectFit
                anchors.margins: Theme.paddingSmall
            }

            Label
            {
                id: artistName
                truncationMode: TruncationMode.Fade
                color: Theme.highlightColor
            }
            TrackList {
                id: topTracks
                header : Column {
                    width: parent.width
                    PageHeader {
                        title:  qsTr("Popular Tracks")
                    }
                }
                start_on_top : true
                anchors {
                    fill: parent
                   horizontalCenter: parent.horizontalCenter
                }

            }

        }
            }

    Connections {
        target: pythonApi

        onArtistChanged:
        {
            artistName.text = name
            coverImage.source = img
        }
        onTrackAdded:
        {
            topTracks.addTrack(title, artist, album, id, duration)
        }

    }
}
