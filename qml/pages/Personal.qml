import QtQuick 2.0
import Sailfish.Silica 1.0

import "personalLists"

Item {
    id: personalPage
    anchors.fill: parent
    anchors.bottomMargin: miniPlayerPanel.height

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: mainColumn.height

        Column {
            id: mainColumn
            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader {
                title: "Personal Collection"
            }

            // Recently Played Section
            SectionHeader {
                text: qsTr("Recently played")
            }

            RecentList {
                id: recentView
            }

            // Recently Played Section
            SectionHeader {
                text: qsTr("For you")
            }

            ForYouList {
                id: forYouView
            }

            // Custom Mixes
            //SectionHeader {
            //    text: qsTr("Custom Mixes")
            //}

            //CustomMixes {
            //    id: mixesView
            //}


            // Top Artists Section
            SectionHeader {
                text: qsTr("Top Artists")
            }

            SilicaListView {
                id: topArtistsView
                width: parent.width
                height: Theme.itemSizeLarge * 3
                orientation: ListView.Horizontal
                clip: true
                spacing: Theme.paddingMedium

                model: ListModel {
                    id: topArtistsModel
                }

                delegate: BackgroundItem {
                    width: Theme.itemSizeLarge * 2
                    height: topArtistsView.height

                    Column {
                        anchors {
                            fill: parent
                            margins: Theme.paddingSmall
                        }
                        spacing: Theme.paddingMedium

                        Image {
                            width: parent.width
                            height: width
                            source: model.image
                            fillMode: Image.PreserveAspectCrop

                            Rectangle {
                                color: Theme.rgba(Theme.highlightBackgroundColor, 0.1)
                                anchors.fill: parent
                                visible: parent.status !== Image.Ready
                            }
                        }

                        Label {
                            width: parent.width
                            text: model.name
                            truncationMode: TruncationMode.Fade
                            font.pixelSize: Theme.fontSizeSmall
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                        }
                    }

                    onClicked: pageStack.push(Qt.resolvedUrl("ArtistPage.qml"),
                                            { artistId: model.artistid })
                }

                // Horizontaler Scroll-Indikator für Top Artists
                Rectangle {
                    visible: topArtistsView.contentWidth > topArtistsView.width
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
                        width: Math.max(parent.width * (topArtistsView.width / topArtistsView.contentWidth), Theme.paddingLarge)
                        x: (parent.width - width) * (topArtistsView.contentX / (topArtistsView.contentWidth - topArtistsView.width))
                        visible: topArtistsView.contentWidth > topArtistsView.width
                    }
                }
            }



            // Top Albums Section
            SectionHeader {
                text: qsTr("Top Albums")
            }

            SilicaListView {
                id: topAlbumsView
                width: parent.width
                height: Theme.itemSizeLarge * 3
                orientation: ListView.Horizontal
                clip: true
                spacing: Theme.paddingMedium

                model: ListModel {
                    id: topAlbumsModel
                }

                delegate: BackgroundItem {
                    width: Theme.itemSizeLarge * 2
                    height: topAlbumsView.height

                    Column {
                        anchors {
                            fill: parent
                            margins: Theme.paddingSmall
                        }
                        spacing: Theme.paddingMedium

                        Image {
                            width: parent.width
                            height: width
                            source: model.image
                            fillMode: Image.PreserveAspectCrop

                            Rectangle {
                                color: Theme.rgba(Theme.highlightBackgroundColor, 0.1)
                                anchors.fill: parent
                                visible: parent.status !== Image.Ready
                            }
                        }

                        Label {
                            width: parent.width
                            text: model.title
                            truncationMode: TruncationMode.Fade
                            font.pixelSize: Theme.fontSizeSmall
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                        }
                    }

                    onClicked: pageStack.push(Qt.resolvedUrl("AlbumPage.qml"),
                                            { albumId: model.albumId })
                }

                // Horizontaler Scroll-Indikator für Top Artists
                Rectangle {
                    visible: topAlbumsView.contentWidth > topAlbumsView.width
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
                        width: Math.max(parent.width * (topAlbumsView.width / topAlbumsView.contentWidth), Theme.paddingLarge)
                        x: (parent.width - width) * (topAlbumsView.contentX / (topAlbumsView.contentWidth - topAlbumsView.width))
                        visible: topAlbumsView.contentWidth > topAlbumsView.width
                    }
                }
            }



            // Top Titles Section
            SectionHeader {
                text: qsTr("Top Titles")
            }

            SilicaListView {
                id: topTitleView
                width: parent.width
                height: Theme.itemSizeLarge * 3
                orientation: ListView.Horizontal
                clip: true
                spacing: Theme.paddingMedium

                model: ListModel {
                    id: topTitleModel
                }

                delegate: BackgroundItem {
                    width: Theme.itemSizeLarge * 2
                    height: topTitleView.height

                    Column {
                        anchors {
                            fill: parent
                            margins: Theme.paddingSmall
                        }
                        spacing: Theme.paddingMedium

                        Image {
                            width: parent.width
                            height: width
                            source: model.image
                            fillMode: Image.PreserveAspectCrop

                            Rectangle {
                                color: Theme.rgba(Theme.highlightBackgroundColor, 0.1)
                                anchors.fill: parent
                                visible: parent.status !== Image.Ready
                            }
                        }

                        Label {
                            width: parent.width
                            text: model.title
                            truncationMode: TruncationMode.Fade
                            font.pixelSize: Theme.fontSizeSmall
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                        }
                    }

                    onClicked: {
                        playlistManager.playTrack(model.trackid)
                    }
                }

                // Horizontaler Scroll-Indikator für Top Artists
                Rectangle {
                    visible: topTitleView.contentWidth > topTitleView.width
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
                        width: Math.max(parent.width * (topTitleView.width / topTitleView.contentWidth), Theme.paddingLarge)
                        x: (parent.width - width) * (topTitleView.contentX / (topTitleView.contentWidth - topTitleView.width))
                        visible: topTitleView.contentWidth > topTitleView.width
                    }
                }
            }



            // Playlists Section
            SectionHeader {
                text: qsTr("Personal Playlists")
            }

            SilicaListView {
                id: playlistsView
                width: parent.width
                height: Theme.itemSizeLarge * 3
                orientation: ListView.Horizontal
                clip: true
                spacing: Theme.paddingMedium

                model: ListModel {
                    id: listModel
                }

                delegate: ListItem {
                id: delegateItem  // ID hinzugefügt für Referenzierung
                width: Theme.itemSizeLarge * 2
                height: playlistsView.height
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

                        Label {
                            width: parent.width
                            text: model.num_tracks + " Tracks"
                            color: Theme.secondaryColor
                            font.pixelSize: Theme.fontSizeExtraSmall
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
                        text: qsTr("Play Playlist")
                        opacity: 1
                        onClicked: {
                            playlistManager.clearPlayList()
                            tidalApi.playPlaylist(model.id) //todo: extend tidalApi with playPlaylist
                            playlistManager.nextTrackClicked() //playPosition and nextTrack wont start song so extension, as mentioned above is needed
                        }
                    }
                }

                onClicked: {
                    pageStack.push(Qt.resolvedUrl("SavedPlaylistPage.qml"), {
                        playlistTitle: model.title,
                        playlistId: model.id,
                        type: "playlist"
                    })
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
            }
        }

        VerticalScrollDecorator {}

        PullDownMenu {
            MenuItem {
                text: minPlayerPanel.open ? qsTr("Hide player") : qsTr("Show player")
                onClicked: minPlayerPanel.open = !minPlayerPanel.open
            }
        }
    }

    Connections {
        target: tidalApi

        onPersonalPlaylistAdded: {
            listModel.append({
                "title": title,
                "id": id,
                "image": image,
                "num_tracks": num_tracks,
                "description": description,
                "duration": duration
            })
        }

        onFavArtists: {
            if (artist_info == undefined) {
                 console.error("artist_info is undefined. skip append to model")
                 return;
            }
            topArtistsModel.append({
                "name": artist_info.name,
                "image": artist_info.image,
                "artistid": artist_info.artistid
            })
        }

        onFavAlbums: {
            if (album_info == undefined) {
                 console.error("album_info is undefined. skip append to model")
                 return;
            }            
            topAlbumsModel.append({
                "title": album_info.title,
                "image": album_info.image,
                "albumId": album_info.albumid
            })
        }

        onFavTracks: {
            if (track_info == undefined) {
                 console.error("track_info is undefined. skip append to model")
                 return;
            }
            console.log("Found favourite tracks", track_info.title)
            topTitleModel.append({
                "title": track_info.title,
                "image": track_info.image,
                "trackid": track_info.trackid
            })
        }

        onLoginSuccess: {
            console.log("Loading personal content")
            tidalApi.getPersonalPlaylists()
            tidalApi.getFavorits()
        }
    }
}
