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
    property bool isHeaderCollapsed: false
    property bool isFav: false
    property bool initialized: false

    allowedOrientations: Orientation.All

    function saveAlbumAsPlaylist(name) {
        var trackIds = []
        // Wir nutzen die Tracks aus dem Album-Cache
        if (albumData) {
            var tracks = tidalApi.getAlbumTracks(albumId)
            for(var i = 0; i < trackList.model.count; i++) {
                var track = trackList.model.get(i)
                trackIds.push(track.trackid)
            }
            playlistStorage.savePlaylist(name, trackIds, 0)
        }
    }

    SilicaFlickable {
        id: flickable
        anchors {
            fill: parent
            bottomMargin: miniPlayerPanel.margin
        }

        contentHeight: column.height + Theme.paddingLarge
        height: parent.height

        // Überwache das Scrollen des Flickable
        onContentYChanged: {
            if (contentY > Theme.paddingLarge) {
                isHeaderCollapsed = true
            } else {
                isHeaderCollapsed = false
            }
        }

        PullDownMenu {

        MenuItem {
                text: qsTr("Save as Playlist")
                onClicked: {
                    if (albumData) {
                        var dialog = pageStack.push(Qt.resolvedUrl("../dialogs/saveplaylist.qml"), {
                            "suggestedName": albumData.title
                        })
                        dialog.accepted.connect(function() {
                            if (dialog.playlistName.length > 0) {
                                saveAlbumAsPlaylist(dialog.playlistName)
                            }
                        })
                    }
                }
                enabled: albumData !== null
            }

            MenuItem {
                text: qsTr("Share")
                onClicked: {
                    if (albumData) {
                        var shareText = qsTr("Check out this album: %1 by %2").arg(albumData.title).arg(albumData.artist);
                        var shareUrl = "https://tidal.com/album/" + albumData.albumid;
                        var shareData = {
                            text: shareText,
                            url: shareUrl
                        };
                        Clipboard.text = shareText + "\n" + shareUrl;
                    }
                }
            }

            MenuItem {
                text: minPlayerPanel.open ? qsTr("Hide player") : qsTr("Show player")
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

            Item {
                id: albumInfoContainer
                width: parent.width
                height: isHeaderCollapsed ? Theme.itemSizeLarge : parent.width * 0.4
                clip: true

                Behavior on height {
                    NumberAnimation { duration: 200 }
                }

                Row {
                    width: parent.width
                    height: parent.height
                    spacing: Theme.paddingMedium
                    anchors.margins: Theme.paddingMedium

                    Image {
                        id: coverImage
                        width: parent.height
                        height: width
                        fillMode: Image.PreserveAspectFit
                        source: albumData ? albumData.image : ""

                        Rectangle {
                            color: Theme.rgba(Theme.highlightBackgroundColor, 0.1)
                            anchors.fill: parent
                            visible: coverImage.status !== Image.Ready
                        }

                        IconButton {
                            id: favButton
                            width: Theme.iconSizeMedium
                            height: Theme.iconSizeMedium
                            anchors {
                                top: coverImage.top
                                right: coverImage.right
                                margins: Theme.paddingSmall
                            }
                            icon.source: "image://theme/icon-s-favorite"
                            icon.sourceSize: Qt.size(Theme.iconSizeMedium, Theme.iconSizeMedium)
                            highlighted: isFav
                            onClicked: {
                               favManager.setAlbumFavoriteInfo(albumId,!isFav)
                            }
                            z:1 // tobe on top of the image
                        }
                    }

                    Column {
                        width: parent.width - coverImage.width - 2* parent.spacing //- Theme.paddingLarge //* 2
                        height: parent.height
                        spacing: Theme.paddingSmall
                        anchors.verticalCenter: parent.verticalCenter

                        BackgroundItem {
                            width: parent.width
                            height: artistRow.height + Theme.paddingMedium * 2

                            Rectangle {
                                anchors.fill: parent
                                color: Theme.rgba(Theme.highlightBackgroundColor, parent.pressed ? 0.3 : 0.1)
                                radius: Theme.paddingSmall
                            }

                            Row {
                                id: artistRow
                                anchors.centerIn: parent
                                spacing: Theme.paddingMedium

                                Image {
                                    id: artistIcon
                                    source: "image://theme/icon-m-media-artists"
                                    width: Theme.iconSizeSmall
                                    height: width
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Label {
                                    id: artistName
                                    text: albumData ? albumData.artist : ""
                                    truncationMode: TruncationMode.Fade
                                    color: parent.parent.pressed ? Theme.highlightColor : Theme.primaryColor
                                    font.pixelSize: Theme.fontSizeLarge
                                }
                            }

                            onClicked: {
                                if (albumData && albumData.artistid) {
                                    pageStack.push(Qt.resolvedUrl("ArtistPage.qml"),
                                                  { artistId: albumData.artistid })
                                }
                            }
                        }

                        Label {
                            width: parent.width
                            text: albumData ? Format.formatDuration(albumData.duration, Format.DurationLong) : ""
                            color: Theme.secondaryHighlightColor
                            font.pixelSize: Theme.fontSizeMedium
                        }

                        Label {
                            width: parent.width
                            text: albumData ? qsTr("Released: ") + albumData.year : ""
                            color: Theme.secondaryColor
                            font.pixelSize: Theme.fontSizeSmall
                            opacity: isHeaderCollapsed ? 0.0 : 1.0
                            visible: opacity > 0
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }

                        Label {
                            width: parent.width
                            text: albumData ? qsTr("Tracks: ") + albumData.num_tracks : ""
                            color: Theme.secondaryColor
                            font.pixelSize: Theme.fontSizeSmall
                            opacity: isHeaderCollapsed ? 0.0 : 1.0
                            visible: opacity > 0
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }
                    }
                }
            }
        Row {
            id: albumControlBar
            width: parent.width
            height: Theme.itemSizeSmall
            spacing: Theme.paddingMedium
            anchors {
                left: parent.left
                right: parent.right
                margins: Theme.paddingMedium
            }

            IconButton {
                width: Theme.iconSizeMedium
                height: Theme.iconSizeMedium
                icon.source: "image://theme/icon-m-play"
                anchors.verticalCenter: parent.verticalCenter
                onClicked: {
                    if (albumData) {
                        playlistManager.clearPlayList()
                        playlistManager.playAlbum(albumId, true) // start playing immediately
                    }
                }
            }

            IconButton {
                width: Theme.iconSizeMedium
                height: Theme.iconSizeMedium
                icon.source: "image://theme/icon-m-add"
                anchors.verticalCenter: parent.verticalCenter
                onClicked: {
                    if (albumData) {
                        playlistManager.playAlbum(albumId,false)
                    }
                }
            }

            Label {
                text: qsTr("Play Album")
                // color: Theme.highlightColor
                font.pixelSize: Theme.fontSizeSmall
                anchors.verticalCenter: parent.verticalCenter
            }

            Item {
                width: Theme.paddingLarge
                height: parent.height
            }

            Label {
                text: albumData ? qsTr("%n tracks", "", albumData.num_tracks) : ""
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeExtraSmall
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // Optional: Füge einen Separator hinzu
        Separator {
            width: parent.width
            color: Theme.primaryColor
            horizontalAlignment: Qt.AlignHCenter
        }
        TrackList {
                id: trackList
                width: parent.width
                height: albumPage.height -  y - (minPlayerPanel.open ? minPlayerPanel.height*0.6 : 0)
                type: "album"
                albumId: albumPage.albumId
            }
        }

        VerticalScrollDecorator {}
    }

    Component.onCompleted: {
        if (albumId > 0) {
            albumData = cacheManager.getAlbumInfo(albumId)
            if (albumData) {
                initialized = true
                isFav = favManager.isFavorite(albumId)
                return
            }
            console.log("Album nicht im Cache gefunden:", albumId)
            initialized = false
        }
    }

    Connections {
        target: favManager

        onUpdateFavorite: {
            if (id === albumId)
                isFav = status
        }
    }
    
    Connections {

        target: tidalApi
        onCacheAlbum: {
            if (initialized) {
                return
            }
            if (albumId === album_info.albumid) {
                albumData = cacheManager.getAlbumInfo(albumId)
                if (albumData) {
                    initialized = true
                    isFav = favManager.isFavorite(albumId)
                } else {
                    console.log("Album nicht im Cache gefunden:", albumId)
                }
            }
        }
    }
}
