// widgets/SearchResultDelegate.qml
import QtQuick 2.0
import Sailfish.Silica 1.0

ListItem {
    id: delegate
    property var itemData

    contentHeight: contentRow.height + 2 * Theme.paddingMedium

    Row {
        id: contentRow
        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
        }
        spacing: Theme.paddingMedium

        Image {
            id: thumbnail
            width: Theme.iconSizeMedium
            height: Theme.iconSizeMedium
            source: getImageSource(itemData)
            fillMode: Image.PreserveAspectFit
        }

        Column {
            width: parent.width - thumbnail.width - parent.spacing
            spacing: Theme.paddingSmall

            Label {
                width: parent.width
                text: getMainText(itemData)
                color: delegate.highlighted ? Theme.highlightColor : Theme.primaryColor
                truncationMode: TruncationMode.Fade
            }

            Label {
                width: parent.width
                text: getSubText(itemData)
                color: delegate.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
                visible: itemData.type === 1 // typeTrack
                truncationMode: TruncationMode.Fade
            }
        }
    }

    menu: ContextMenu {
        MenuItem {
            text: qsTr("Play")
            onClicked: handlePlay(itemData)
        }

        MenuItem {
            text: qsTr("Play Album")
            visible: itemData.type === 1 // typeTrack
            onClicked: playlistManager.playAlbumFromTrack(itemData.id)
        }

        MenuItem {
            text: qsTr("Queue")
            onClicked: playlistManager.appendTrack(itemData.id)
        }

        MenuItem {
            text: qsTr("Remove")
            onClicked: delegate.remorseAction(qsTr("Deleting"), function() {
                listModel.remove(model.index)
            })
        }
    }

    onClicked: handleItemClick(itemData)

    // Hilfsfunktionen
    function getImageSource(item) {
        if (item.image && item.image !== "") return item.image

        switch(item.type) {
            case 1: return "image://theme/icon-m-media-songs"
            case 3: return "image://theme/icon-m-media-artists"
            case 2: return "image://theme/icon-m-media-albums"
            case 4: return "image://theme/icon-m-media-playlists"
            case 5: return "image://theme/icon-m-video"
            default: return ""
        }
    }

    function getMainText(item) {
        var text = item.name
        if (item.duration && item.type !== 3) { // nicht für Artists
            text += " (" + formatDuration(item.duration) + ")"
        }
        return text
    }

    function getSubText(item) {
        return item.artist ? item.artist + " (" + item.album + ")" : ""
    }

    function formatDuration(duration) {
        return duration > 3599
            ? Format.formatDuration(duration, Formatter.DurationLong)
            : Format.formatDuration(duration, Formatter.DurationShort)
    }

    function handlePlay(item) {
        switch(item.type) {
            case 1: // Track
                playlistManager.playTrack(item.id)
                break
            case 2: // Album
                playlistManager.playAlbum(item.id)
                break
            case 4: // Playlist
                tidalApi.playPlaylist(item.uid)
                break
        }
    }

    function handleItemClick(item) {
        switch(item.type) {

            case 1: // Track
                pageStack.push(Qt.resolvedUrl("../AlbumPage.qml"),
                {
                    "albumId": item.albumid
                })
                break
            case 2: // Album
                pageStack.push(Qt.resolvedUrl("../AlbumPage.qml"),
                {
                    "albumId" :item.id
                })
                break
            case 3: // Artist
                pageStack.push(Qt.resolvedUrl("../ArtistPage.qml"))
                tidalApi.getArtistInfo(item.id)
                break
        }
    }
}
