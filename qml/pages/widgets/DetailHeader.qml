// Claude Generated — hero header for album/playlist/mix/artist pages: the
// artwork blurred across the full width, the cover itself standing on its
// reflection, title, subtitle and a primary action next to it.
// Ported from qml-tidalplayer/qml/pages/DetailHeader.qml.
import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: header

    property string heading: ""
    property string subtitle: ""
    property string meta: ""
    property url image
    property string fallbackIcon: "image://theme/icon-m-media-albums"
    property string playText: qsTr("Play")
    property bool showPlay: true
    // Collapsed headers keep the artwork but drop the reflection and shrink,
    // so a page can pull the header out of the way while scrolling.
    property bool collapsed: false
    property bool effects: applicationWindow.settings ? applicationWindow.settings.artworkEffects : true

    signal playClicked()

    readonly property real artSize: collapsed
        ? Theme.itemSizeLarge
        : Math.min(Theme.itemSizeExtraLarge * 1.6, width * 0.38)
    readonly property real margin: Theme.horizontalPageMargin

    width: parent ? parent.width : 0
    height: Math.round(artSize + (effects && !collapsed ? artSize * 0.35 : 0) + margin * 2)

    Behavior on height {
        NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
    }

    BlurBackdrop {
        anchors.fill: parent
        source: header.image
        dim: 0.45
    }

    Row {
        id: row
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            leftMargin: header.margin
            rightMargin: header.margin
            topMargin: header.margin
        }
        spacing: Theme.paddingLarge

        CoverArt {
            id: art
            width: header.artSize
            height: header.artSize
            source: header.image
            fallbackIcon: header.fallbackIcon
            elevation: header.collapsed ? 0 : Theme.paddingMedium
            reflection: header.collapsed ? 0 : 0.35
        }

        Column {
            width: parent.width - art.width - parent.spacing
            spacing: Theme.paddingSmall

            Label {
                width: parent.width
                text: header.heading
                font.pixelSize: Theme.fontSizeLarge
                font.bold: true
                color: Theme.primaryColor
                wrapMode: Text.WordWrap
                maximumLineCount: header.collapsed ? 1 : 3
                truncationMode: TruncationMode.Fade
            }

            Label {
                width: parent.width
                visible: header.subtitle !== ""
                text: header.subtitle
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.secondaryColor
                truncationMode: TruncationMode.Fade
            }

            Label {
                width: parent.width
                visible: header.meta !== "" && !header.collapsed
                text: header.meta
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor
                opacity: 0.8
                truncationMode: TruncationMode.Fade
            }

            Button {
                visible: header.showPlay && !header.collapsed
                text: header.playText
                preferredWidth: Theme.buttonWidthSmall
                onClicked: header.playClicked()
            }
        }
    }
}
