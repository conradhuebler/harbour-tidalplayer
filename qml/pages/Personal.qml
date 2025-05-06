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

            SectionHeader {
                visible: applicationWindow.settings.dailyMixesList
                text: qsTr("Daily Mixes")
            }

            HorizontalList {
                visible: applicationWindow.settings.dailyMixesList
                id: dailyMixesList
               // getPageDailyMixes
            }

            SectionHeader {
                visible: applicationWindow.settings.radioMixesList
                text: qsTr("Radio Mixes")
            }

            HorizontalList {
                visible: applicationWindow.settings.radioMixesList
                id: radioMixesList
                //def getPageSuggestedRadioMixes(self):
            }

            SectionHeader {
                visible: applicationWindow.settings.topArtistsList
                text: qsTr("Favorite Artists")
            }

            HorizontalList {
                visible: applicationWindow.settings.topArtistsList
                id: topArtistList
                //getPageFavoriteArtists // sorted by activity
            }

        }            

/*

    def getPageListeningHistorypage(self):
        return self.session.page.get("pages/HISTORY_MIXES/view-all?")
    
    def getPageSuggestedNewAlbumspage(self):
        return self.session.page.get("pages/NEW_ALBUM_SUGGESTIONS/view-all?")
    
    def getPageMoods(self):
        return self.session.page.get("pages/moods_page") */
        

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

        onRecentTrack:
        {
            recentList.addTrack(track_info)
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

        onCustomMix: {
            //if (mix_info.type == "dailyMix") {
            if (mixType == "dailyMix") {
                dailyMixesList.addMix(mix_info)
            } else if (mixType == "radioMix") {
                radioMixesList.addMix(mix_info)
            }
        }

        onTopArtist: {
            topArtistList.addArtist(artist_info)
        }

        onLoginSuccess: {
            console.log("Loading personal content")
            tidalApi.getHomepage() // loads recent, for you
            if (applicationWindow.settings.personalPlaylistList) {
                console.log("Loading personal playlists")
                tidalApi.getPersonalPlaylists()
            }
            if (applicationWindow.settings.dailyMixesList) {
                console.log("Loading daily mixes")
                tidalApi.getDailyMixes()
            }
            if (applicationWindow.settings.radioMixesList) {
                console.log("Loading radio mixes")
                tidalApi.getRadioMixes()
            }
            if (applicationWindow.settings.topArtistsList) {
                console.log("Loading recent top artists")
                tidalApi.getTopArtists() // loads top artists
            }
            console.log("Loading favorites")
            tidalApi.getFavorits() // loads fav artists, fav albums, fav tracks
        }
    }
}
