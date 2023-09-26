import QtQuick 2.0
import Sailfish.Silica 1.0
import QtMultimedia 5.6
import Sailfish.Media 1.0

import "widgets"


Page {
    id: trackPage
    property int track_id
    PageHeader {
        id: header
        title:  qsTr("Track Info")
    }


    // The effective value will be restricted by ApplicationWindow.allowedOrientations
    allowedOrientations: Orientation.All

    // To enable PullDownMenu, place our content in a SilicaFlickable
    SilicaFlickable {
        anchors {
            left: parent.left
            leftMargin: Theme.horizontalPageMargin
            right: parent.right
            rightMargin: Theme.horizontalPageMargin
            verticalCenter: parent.verticalCenter
        }


        Column {
            anchors {
                left: parent.left
                leftMargin: Theme.horizontalPageMargin
                right: parent.right
                rightMargin: Theme.horizontalPageMargin
                verticalCenter: parent.verticalCenter
            }
            Image {
                id: coverImage
                width: 0.9 * parent.width
                //anchors.centerIn: parent.top
                fillMode: Image.PreserveAspectFit
                anchors.margins: Theme.paddingSmall
            }

            Label
            {
                id: trackName
                truncationMode: TruncationMode.Fade
                color: Theme.highlightColor
            }

            Label
            {
                id: artistName
                truncationMode: TruncationMode.Fade
                color: Theme.highlightColor
            }

            Label
            {
                id: albumName
                truncationMode: TruncationMode.Fade
                color: Theme.highlightColor
            }

        }
    }
    Connections {
        target: pythonApi

        onTrackChanged:
        {
            trackName.text = title
            artistName.text =artist
            albumName.text = album
            coverImage.source = image
        }

    }
}
