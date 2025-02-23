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
                visible: applicationWindow.settings.recentList
            }

            HorizontalList {
                id: recentList
                visible: applicationWindow.settings.recentList
            }

            // For you section
            SectionHeader {
                text: qsTr("For you")
                visible: applicationWindow.settings.yourList
            }

            HorizontalList {
                id: foryouList
                visible: applicationWindow.settings.yourList
            }

            // Top Artists Section
            SectionHeader {
                visible: applicationWindow.settings.topartistList
                text: qsTr("Top Artists")
            }

            HorizontalList {
                visible: applicationWindow.settings.topartistList
                id: artistList
            }

            // Top Albums Section
            SectionHeader {
                visible: applicationWindow.settings.topalbumsList
                text: qsTr("Top Albums")
            }
            HorizontalList {
                visible: applicationWindow.settings.topalbumsList
                id: albumsList
            }

            // Top Titles Section
            SectionHeader {
                visible: applicationWindow.settings.toptrackList
                text: qsTr("Top Tracks")
            }
            HorizontalList {
                visible: applicationWindow.settings.toptrackList
                id: tracksList
            }

            // Playlists Section
            SectionHeader {
                visible: applicationWindow.settings.personalPlaylistList
                text: qsTr("Personal Playlists")
            }

            HorizontalList {
                visible: applicationWindow.settings.personalPlaylistList
                id: playlistList
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


        onRecentAlbum:
        {
            recentList.addAlbum(album_info)
        }

        onRecentMix:
        {
            recentList.addMix(mix_info)
        }

        onRecentArtist:
        {
            recentList.addArtist(artist_info)
        }

        onRecentPlaylist:
        {
            recentList.addPlaylist(playlist_info)
        }

        onForyouAlbum:
        {
            foryouList.addAlbum(album_info)
        }

        onForyouArtist:
        {
            foryouList.addArtist(artist_info)
        }

        onForyouPlaylist:
        {
            foryouList.addPlaylist(playlist_info)
        }

        onForyouMix:
        {
            foryouList.addMix(mix_info)
        }

        onPersonalPlaylistAdded: {
            playlistList.addPlaylist(playlist_info)
        }

        onFavArtists: {
            artistList.addArtist(artist_info)
        }

        onFavAlbums: {
            albumsList.addAlbum(album_info)
        }

        onFavTracks: {
            tracksList.addTrack(track_info)
        }

        onLoginSuccess: {
            console.log("Loading personal content")
            tidalApi.getPersonalPlaylists()
            tidalApi.getFavorits()
        }
    }
}
