import QtQuick 2.0
import Sailfish.Silica 1.0

SilicaListView {
    // Konstanten
    readonly property int typeTrack: 1
    readonly property int typeAlbum: 2
    readonly property int typeArtist: 3
    readonly property int typePlaylist: 4
    readonly property int typeVideo: 5
    readonly property int typeMix: 6

    id: recentlyView
                width: parent.width
                height: Theme.itemSizeLarge * 3
                orientation: ListView.Horizontal
                clip: true
                spacing: Theme.paddingMedium

                model: ListModel {
                    id: recentModel
                }

                delegate: ListItem {
                id: delegateItem  // ID hinzugefügt für Referenzierung
                width: Theme.itemSizeLarge * 2
                height: recentlyView.height
                contentHeight: height

                Column {
                    anchors {
                        fill: parent
                        margins: Theme.paddingSmall
                    }
                    spacing: Theme.paddingMedium

                    Image {
                        id: coverImage
                        width: parent.width
                        height: width
                        fillMode: Image.PreserveAspectCrop
                        source: model.image
                        smooth: true
                        asynchronous: true

                        Rectangle {
                            color: Theme.rgba(Theme.highlightBackgroundColor, 0.1)
                            anchors.fill: parent
                            visible: coverImage.status !== Image.Ready
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.paddingSmall

                        Label {
                            width: parent.width
                            text: model.title
                            color: parent.parent.pressed ? Theme.highlightColor : Theme.primaryColor
                            font.pixelSize: Theme.fontSizeSmall
                            truncationMode: TruncationMode.Fade
                            horizontalAlignment: Text.AlignHCenter
                            visible: !delegateItem.menuOpen
                        }
                    }
                }

                menu: ContextMenu {
                    width: delegateItem.width  // same with as item
                    x: (delegateItem.width - width) / 2 // center menue item
                    opacity: 1
                    backgroundColor: Theme.rgba(Theme.secondaryHighlightColor, 1.0)
                    MenuItem {
                        text: qsTr("Play")
                        opacity: 1
                        onClicked: {
                           // playlistManager.clearPlayList()
                           // tidalApi.playPlaylist(model.id) //todo: extend tidalApi with playPlaylist
                           // playlistManager.nextTrackClicked() //playPosition and nextTrack wont start song so extension, as mentioned above is needed
                        }
                    }
                }

                onClicked: {
                switch(model.type) {
                    case 1: // Track
                        pageStack.push(Qt.resolvedUrl("../AlbumPage.qml"),
                        {
                            "albumId": model.albumid
                        })

                        break
                    case 2: // Album
                        pageStack.push(Qt.resolvedUrl("../AlbumPage.qml"),
                        {
                            "albumId" :model.albumid
                        })

                        break
                    case 3: // Artist
                        pageStack.push(Qt.resolvedUrl("../ArtistPage.qml"),
                        {
                            "artistId" :model.artistid
                        })
                        break
                    case 4: // Playlist
                    console.log("Playlist", item.playlistid, item.name)
                        pageStack.push(Qt.resolvedUrl("../SavedPlaylistPage.qml"),
                        {
                            "playlistId" :model.playlistid,
                            "playlistTitle" : model.name
                        })
                        break
                    }
                }
            }

                // Horizontaler Scroll-Indikator für Playlists
                Rectangle {
                    visible: playlistsView.contentWidth > playlistsView.width
                    height: 2
                    color: Theme.highlightColor
                    opacity: 0.4
                    anchors {
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                    }

                    Rectangle {
                        height: parent.height
                        color: Theme.highlightColor
                        width: Math.max(parent.width * (playlistsView.width / playlistsView.contentWidth), Theme.paddingLarge)
                        x: (parent.width - width) * (playlistsView.contentX / (playlistsView.contentWidth - playlistsView.width))
                        visible: playlistsView.contentWidth > playlistsView.width
                    }
                }

                ViewPlaceholder {
                    enabled: listModel.count === 0
                    text: qsTr("No Playlists")
                    hintText: qsTr("Your personal playlists will appear here")
                }

    Connections {

        target: tidalApi

        onRecentAlbum:
        {
            console.log(album_info)
            if (album_info == undefined) {
                     console.error("album_info is undefined. skip append to model")
                     return;
                }
                recentModel.append({
                    "title": album_info.title,
                    "image": album_info.image,
                    "albumid": album_info.albumid,
                    "type" : typeAlbum
                })
        }

        onRecentArtist:
        {
            console.log(artist_info)
            if (artist_info == undefined) {
                     console.error("artist_info is undefined. skip append to model")
                     return;
                }
                recentModel.append({
                    "name": artist_info.name,
                    "image": artist_info.image,
                    "artistid": artist_info.artistid,
                    "type" : typeArtist
                })
        }

        onRecentMix:
        {
                recentModel.append({
                    "title": mix_info.title,
                    "image": mix_info.image,
                    "mixid": mix_info.mixid,
                    "type" : typePlaylist
                })
        }

        onRecentPlaylist:
        {

        console.log(playlist_info)
        if (playlist_info == undefined) {
                 console.error("album_info is undefined. skip append to model")
                 return;
            }
            recentModel.append({
                "title": playlist_info.title,
                "image": playlist_info.image,
                "playlistid": playlist_info.playlistid,
                "type" : typePlaylist
            })

        }

        }
}
