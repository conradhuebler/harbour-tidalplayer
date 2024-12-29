// AlbumPage.qml
import QtQuick 2.0
import Sailfish.Silica 1.0
import QtMultimedia 5.6
import Sailfish.Media 1.0
import "widgets"

Page {
    id: albumPage
    property int albumId: -1
    property var albumData: null

    allowedOrientations: Orientation.All

    SilicaFlickable {
        id: flickable
        anchors {
            fill: parent
            bottomMargin: minPlayerPanel.margin
        }

        contentHeight: column.height

        PullDownMenu {

            MenuItem {
                text: minPlayerPanel.open ? "Hide player" : "Show player"
                onClicked: minPlayerPanel.open = !minPlayerPanel.open
            }
        }

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader {
                id: header
                title: albumData ? albumData.title : qsTr("Album Info")
            }

            Image {
                id: coverImage
                width: parent.width * 0.8
                height: width
                anchors.horizontalCenter: parent.horizontalCenter
                fillMode: Image.PreserveAspectFit
                source: albumData ? albumData.image : ""

                Rectangle {
                    color: Theme.rgba(Theme.highlightBackgroundColor, 0.1)
                    anchors.fill: parent
                    visible: coverImage.status !== Image.Ready
                }
            }

            Label {
                id: artistName
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: albumData ? albumData.artist : ""
                truncationMode: TruncationMode.Fade
                color: Theme.highlightColor
                font.pixelSize: Theme.fontSizeLarge
            }

            Label {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: albumData ? Format.formatDuration(albumData.duration, Format.DurationLong) : ""
                color: Theme.secondaryHighlightColor
                font.pixelSize: Theme.fontSizeMedium
            }

            Item {
                width: parent.width
                height: Theme.paddingLarge
            }

            TrackList {
                id: trackList
                width: parent.width
                height: albumPage.height - y - (minPlayerPanel.open ? minPlayerPanel.height : 0)
                type: "album"
                albumId: albumPage.albumId
            }
        }

        VerticalScrollDecorator {}
    }

    Component.onCompleted: {
        if (albumId > 0) {
            albumData = cacheManager.getAlbum(albumId)
            if (!albumData) {
                console.log("Album nicht im Cache gefunden:", albumId)
            }
        }
    }
}
