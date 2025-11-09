import QtQuick 2.0
import Sailfish.Silica 1.0
import "widgets"

import "personalLists"

Item {
    id: personalPage
    anchors.fill: parent

    SilicaFlickable {
        id: flick
        anchors.fill: parent
        contentHeight: mainColumn.height


        // todo: function to hide all search fields but current one
        // or one search field for all sections?
        Column {
            id: mainColumn
            width: parent.width
            spacing: Theme.paddingMedium
            property bool showFilterArtist : true

            PageHeader {
                title: "Personal Collection"
            }

            // Recently Played Section
            SectionHeader {
                text: qsTr("Recently played")
                visible: applicationWindow.settings.recentList
                //height: (filter.visible ? filter.height*2 : filter.height)
                MouseArea {
                  anchors.fill: parent
                  onClicked: filterRecentlyPlayed.visible = ! filterRecentlyPlayed.visible
                }
                // does not work as expected, it would also need to increase height of SessionHeader
                /*SearchField {
                    id: filterRecentlyPlayed
                    labelVisible: false
                    visible: false
                    anchors.margins: Theme.paddingMedium
                    anchors.top: sectionHeader.bottom
                }*/
            }
            SearchField {
                id: filterRecentlyPlayed
                labelVisible: false
                visible: false
                anchors.margins: Theme.paddingMedium
                onTextChanged: recentList.filterText = text
            }
            HorizontalList {
                id: recentList
                visible: applicationWindow.settings.recentList
            }

            // For you section
            SectionHeader {
                text: qsTr("Popular playlists")
                visible: applicationWindow.settings.yourList
                MouseArea {
                  anchors.fill: parent
                  onClicked: filterPopularPlaylists.visible = ! filterPopularPlaylists.visible
                }                
            }
            SearchField {
                id: filterPopularPlaylists
                labelVisible: false
                visible: false
                anchors.margins: Theme.paddingMedium
                onTextChanged: foryouList.filterText = text
            }
            HorizontalList {
                id: foryouList
                visible: applicationWindow.settings.yourList
            }

            // Top Artists Section
            SectionHeader {
                visible: applicationWindow.settings.topartistList
                text: qsTr("Top Artists")
                MouseArea {
                  anchors.fill: parent
                  onClicked:  {
                        filterTopArtists.visible = ! filterTopArtists.visible
                        if (filterTopArtists.visible) {
                            filterTopArtists.forceActiveFocus()
                        }
                    }
                }     
            }
            SearchField {
                id: filterTopArtists
                placeholderText: "Filter artists"
                visible: false
                anchors.margins: Theme.paddingMedium
                property int debounceInterval: 600
                Timer {
                    id: debounceTimer
                    interval: filterTopArtists.debounceInterval
                    repeat: false
                    onTriggered: {
                        console.log("Debounce timer triggered, applying filter: " + filterTopArtists.text)
                        artistList.filterText = filterTopArtists.text
                    }
                }
                onTextChanged: {
                    console.log("Debounce timer restart")
                    debounceTimer.restart()
                }
            }
            HorizontalList {
                visible: applicationWindow.settings.topartistList
                id: artistList
                //property string filterText: ""
            }

            // Top Albums Section
            SectionHeader {
                visible: applicationWindow.settings.topalbumsList
                text: qsTr("Top Albums")
                MouseArea {
                    anchors.fill: parent
                    onClicked:  {
                        filterAlbum.visible = ! filterAlbum.visible
                        if (filterAlbum.visible) {
                            filterAlbum.forceActiveFocus()
                        }
                    }
                }
            }
            SearchField {
                id: filterAlbum
                placeholderText: "Filter albums"
                visible: false
                anchors.margins: Theme.paddingMedium
                onTextChanged: albumsList.filterText = text
            }
            HorizontalList {
                visible: applicationWindow.settings.topalbumsList
                id: albumsList
            }

            // Top Titles Section
            SectionHeader {
                visible: applicationWindow.settings.toptrackList
                text: qsTr("Top Tracks")
                MouseArea {
                    anchors.fill: parent
                    onClicked: filterTracks.visible = ! filterTracks.visible
                }
            }
            SearchField {
                id: filterTracks
                placeholderText: "Filter tracks"
                visible: false
                anchors.margins: Theme.paddingMedium
                onTextChanged: tracksList.filterText = text
            }            
            HorizontalList {
                visible: applicationWindow.settings.toptrackList
                id: tracksList
            }

            // Playlists Section
            SectionHeader {
                visible: applicationWindow.settings.personalPlaylistList
                text: qsTr("Personal Playlists")
                MouseArea {
                    anchors.fill: parent
                    onClicked: filterPlaylists.visible = ! filterPlaylists.visible
                }                
            }
            SearchField {
                id: filterPlaylists
                placeholderText: "Filter playlists"
                visible: false
                anchors.margins: Theme.paddingMedium
                onTextChanged: playlistList.filterText = text
            }
            HorizontalList {
                visible: applicationWindow.settings.personalPlaylistList
                id: playlistList
            } 

            SectionHeader {
                visible: applicationWindow.settings.dailyMixesList
                text: qsTr("Custom Mixes")
            }

            HorizontalList {
                visible: applicationWindow.settings.dailyMixesList
                id: dailyMixesList
               // getPageDailyMixes
            }

            SectionHeader {
                visible: applicationWindow.settings.radioMixesList
                text: qsTr("Personal Radio Stations")
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
