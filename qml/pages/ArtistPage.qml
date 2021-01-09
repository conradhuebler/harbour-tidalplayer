import QtQuick 2.0
import Sailfish.Silica 1.0
import QtMultimedia 5.6
import Sailfish.Media 1.0
import harbour.tidalplayer 1.0

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
                id: artistName
                truncationMode: TruncationMode.Fade
                color: Theme.highlightColor
            }



        }
    }
    Connections {
        target: PythonApi

        onArtistInfoChanged:
        {
            console.log(PythonApi.artistInfo)
            var trackInfo = JSON.parse(PythonApi.artistInfo)
            artistName.text = trackInfo["name"]
            coverImage.source = trackInfo["image"]
        }

    }
}
