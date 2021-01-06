import QtQuick 2.0
import Sailfish.Silica 1.0
import QtMultimedia 5.6
import Sailfish.Media 1.0
import harbour.tidalplayer 1.0

import "widgets"


Page {
    property int track_id
    PageHeader {
        id: header
        title:  qsTr("Album Info")
    }
    id: albumPage

    // The effective value will be restricted by ApplicationWindow.allowedOrientations
    allowedOrientations: Orientation.All

    // To enable PullDownMenu, place our content in a SilicaFlickable
    SilicaFlickable {
        width: parent.width
        anchors.fill: parent
        PullDownMenu {
            MenuItem {
                text: qsTr("Show Playlist")
                onClicked:
                {
                    onClicked: pageStack.push(Qt.resolvedUrl("PlaylistPage.qml"))
                }
            }
            MenuItem {
                text: qsTr("Play Album")
                onClicked:
                {
                    trackList.appendtoPlaylist();
                }
            }
        }
        Image {
            id: coverImage
            anchors {
                top: header.bottom
                horizontalCenter: albumPage.isPortrait ? parent.horizontalCenter : undefined
            }

            sourceSize.width: {
                var maxImageWidth = Screen.height/2
                var leftMargin = Theme.horizontalPageMargin
                var rightMargin = albumPage.isPortrait ? Theme.horizontalPageMargin : 0
                return maxImageWidth - leftMargin - rightMargin
            }

            fillMode: Image.PreserveAspectFit
        }

        Column {
            width: parent.width
            id: infoCoulumn
            anchors {
                fill: parent

                // in landscape, anchor the top to the bottom of the header instead of the image
                top: albumPage.isPortrait ? coverImage.bottom : header.bottom
                topMargin: albumPage.isPortrait ? Theme.paddingLarge : 0

                // in landscape, anchor the column's left side to the right of the image with a
                // margin of Theme.paddingLarge between them
                left: albumPage.isPortrait ? parent.left : coverImage.right
                leftMargin: albumPage.isPortrait ? Theme.horizontalPageMargin : Theme.paddingLarge

                right: parent.right
                rightMargin: Theme.horizontalPageMargin
            }

            Label
            {
                id: artistName
                truncationMode: TruncationMode.Fade
                color: Theme.highlightColor
            }
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

        Connections {
            target: PythonApi

            onAlbumInfoChanged:
            {
                var trackInfo = JSON.parse(PythonApi.albumInfo)
                console.log(PythonApi.albumInfo)
                artistName.text =trackInfo["artist"]
                header.title = trackInfo["name"]
                coverImage.source = trackInfo["cover"]

                var tracks = PythonApi.fetchTracksfromAlbum(trackInfo["id"])
                trackList.track_list = tracks
                trackList.createListfromTracks()
            }

        }
   }
}
