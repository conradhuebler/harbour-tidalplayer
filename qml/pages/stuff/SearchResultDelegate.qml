// widgets/SearchResultDelegate.qml
import QtQuick 2.0
import Sailfish.Silica 1.0

ListItem {
    id: delegate
    property var itemData

    // type 1=track, 2=album, 3=artist, 4=playlist - all support the four
    // play actions. Type 5 (video) and unknowns do not.
    readonly property bool isPlayableType: itemData.type >= 1 && itemData.type <= 4

    contentHeight: contentRow.height + 2 * Theme.paddingMedium

    visible: {
        switch(itemData.type) {
            case 2:
                return searchAlbum.checked
            case 3:
                return searchArtists.checked
            case 1:
                return searchTracks.checked
            case 4:
                return searchPlaylists.checked
            case 5:
                return searchVideo.checked
            default:
                return false
        }
    }
    // Optional: Höhe auf 0 setzen wenn nicht sichtbar
    height: {
        if(!visible)
        return 0
    }
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
            width: parent.width - 2*thumbnail.width - parent.spacing
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

        Image {
            id: mediaType
            width: Theme.iconSizeMedium
            height: Theme.iconSizeMedium
            source: {
                switch(itemData.type) {
                case 1: return "image://theme/icon-m-media-songs"
                case 3: return "image://theme/icon-m-media-artists"
                case 2: return "image://theme/icon-m-media-albums"
                case 4: return "image://theme/icon-m-media-playlists"
                case 5: return "image://theme/icon-m-video"
                default: return ""
                }
            }

            fillMode: Image.PreserveAspectFit
        }
    }

    menu: ContextMenu {
        MenuItem {
            text: qsTr("Replace Playlist & Play")
            visible: isPlayableType
            onClicked: dispatchAction("replace", itemData)
        }
        MenuItem {
            text: qsTr("Play Now")
            visible: isPlayableType
            onClicked: dispatchAction("playnow", itemData)
        }
        MenuItem {
            text: qsTr("Play Next")
            visible: isPlayableType
            onClicked: dispatchAction("playnext", itemData)
        }
        MenuItem {
            text: qsTr("Add to Playlist")
            visible: isPlayableType
            onClicked: dispatchAction("append", itemData)
        }

        MenuItem {
            text: qsTr("Play Album")
            visible: itemData.type === 1 // typeTrack
            onClicked: playlistManager.replaceWithAlbumFromTrack(itemData.trackid)
        }

        MenuItem {
            text: qsTr("Album Info")
            visible: itemData.type === 1 || itemData.type === 2
            onClicked: pageStack.push(Qt.resolvedUrl("../AlbumPage.qml"),
                                      { "albumId": itemData.albumid })
        }

        MenuItem {
            text: qsTr("Artist Info")
            visible: itemData.type === 1 || itemData.type === 3
            onClicked: pageStack.push(Qt.resolvedUrl("../ArtistPage.qml"),
                                      { "artistId": itemData.artistid })
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

    // Map a search-result item to the (contentType, contentInfo) shape that
    // advancedPlayManager.executeAction expects.
    function dispatchAction(action, item) {
        var contentType, contentInfo
        switch (item.type) {
        case 1: contentType = "track";    contentInfo = {id: item.trackid}; break
        case 2: contentType = "album";    contentInfo = {id: item.albumid}; break
        case 3: contentType = "artist";   contentInfo = {id: item.artistid}; break
        case 4: contentType = "playlist"; contentInfo = {id: item.playlistid}; break
        default: return
        }
        advancedPlayManager.executeAction(contentType, contentInfo, action)
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
                    "albumId" :item.albumid
                })

                break
            case 3: // Artist
                pageStack.push(Qt.resolvedUrl("../ArtistPage.qml"),
                {
                    "artistId" :item.artistid
                })
                break
            case 4: // Playlist
                // all but name is undefined
                console.log("Playlist", item.playlistid, item.mixid, item.albumid, item.name)
                pageStack.push(Qt.resolvedUrl("../SavedPlaylistPage.qml"),
                {
                    "playlistId" :item.playlistid,
                    "playlistTitle" : item.name
                })
                break
        }
    }
}
