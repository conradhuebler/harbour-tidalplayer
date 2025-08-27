import QtQuick 2.0
import Sailfish.Silica 1.0
import "widgets"
import "stuff"

Item {
    id: searchPage

    // Konstanten
    readonly property int typeTrack: 1
    readonly property int typeAlbum: 2
    readonly property int typeArtist: 3
    readonly property int typePlaylist: 4
    readonly property int typeVideo: 5

    SilicaFlickable {
        anchors.fill: parent
        clip: true //miniPlayerPanel.expanded
        contentHeight: mainColumn.height


        // Main content column
        Column {
            id: mainColumn
            width: parent.width
            spacing: Theme.paddingLarge
            
            // Header-Bereich
            Column {
                id: header
            width: searchPage.width
            spacing: Theme.paddingSmall

            // Suchfeld
            SearchField {
                id: searchField
                width: parent.width
                placeholderText: qsTr("Type and Search")
                text: ""
                label: tidalApi.loginTrue ? 
                       (tidalApi.loading ? qsTr("Searching...") : qsTr("Find")) : 
                       qsTr("Please wait for login ...")
                enabled: tidalApi.loginTrue && !tidalApi.loading

                EnterKey.enabled: text.length > 0 && !tidalApi.loading
                EnterKey.iconSource: "image://theme/icon-m-search"
                EnterKey.onClicked: {
                    if (applicationWindow.settings.debugLevel >= 1) {
                        console.log("SEARCH: Starting search for:", text)
                    }
                    listModel.clear()
                    tidalApi.genericSearch(text)
                    focus = false
                }
                
                // Claude Generated: Clear search button when results are shown
                IconButton {
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.horizontalPageMargin
                    anchors.verticalCenter: parent.verticalCenter
                    icon.source: "image://theme/icon-m-clear"
                    visible: listModel.count > 0 || searchField.text.length > 0
                    enabled: !tidalApi.loading
                    
                    onClicked: {
                        if (applicationWindow.settings.debugLevel >= 1) {
                            console.log("SEARCH: Clearing search results")
                        }
                        searchField.text = ""
                        listModel.clear()
                        searchField.focus = true
                    }
                }
            }

            // Filter-Optionen
            Row {
                spacing: Theme.paddingMedium
                anchors {
                    left: parent.left
                    right: parent.right
                    margins: Theme.horizontalPageMargin
                }

                SearchFilterSwitch {
                    id: searchAlbum
                    icon: "image://theme/icon-m-media-albums"
                    checked: true
                    onCheckedChanged: tidalApi.albums = checked
                }

                SearchFilterSwitch {
                    id: searchArtists
                    icon: "image://theme/icon-m-media-artists"
                    checked: true
                    onCheckedChanged: tidalApi.artists = checked
                }

                SearchFilterSwitch {
                    id: searchTracks
                    icon: "image://theme/icon-m-media-songs"
                    checked: true
                    onCheckedChanged: tidalApi.tracks = checked
                }

                SearchFilterSwitch {
                    id: searchPlaylists
                    icon: "image://theme/icon-m-media-playlists"
                    enabled: true
                    checked: true
                }

                 SearchFilterSwitch {
                    id: searchVideo
                    icon: "image://theme/icon-m-video"
                    enabled: false
                    checked: false
                }
            }
            
            // Claude Generated: Search status and feedback
            Column {
                width: parent.width
                spacing: Theme.paddingMedium
                visible: tidalApi.loading || (searchField.text.length > 0 && listModel.count === 0 && !tidalApi.loading)
                
                // Loading indicator
                BusyIndicator {
                    anchors.horizontalCenter: parent.horizontalCenter
                    running: tidalApi.loading
                    visible: tidalApi.loading
                    size: BusyIndicatorSize.Medium
                }
                
                // No results message
                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: tidalApi.loading ? qsTr("Searching...") : 
                          (searchField.text.length > 0 ? qsTr("No results found for \"%1\"").arg(searchField.text) : "")
                    color: Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeMedium
                    visible: !tidalApi.loading && searchField.text.length > 0 && listModel.count === 0
                    wrapMode: Text.WordWrap
                    width: parent.width - 2 * Theme.horizontalPageMargin
                }
            }
        }

            // Suchergebnisse
            SilicaListView {
                width: mainColumn.width
                leftMargin: Theme.horizontalPageMargin
                rightMargin: Theme.horizontalPageMargin
                clip: true
                height: searchPage.height - header.height - Theme.paddingLarge * 2
                contentHeight: contentItem.childrenRect.height
            
            // PERFORMANCE: Virtual scrolling optimizations for search results
            cacheBuffer: height * 3        // Search results might be longer, cache more
            model: ListModel { id: listModel }

            delegate: SearchResultDelegate {
                width: parent.width
                itemData: model
            }

                VerticalScrollDecorator {}
            }
        }
    }

    // Connections
    Connections {
        target: tidalApi

        onLoginSuccess: {
            searchField.label = qsTr("Find")
            if (applicationWindow.settings.debugLevel >= 1) {
                console.log("SEARCH: Login successful, search enabled")
            }
        }

        onLoginFailed: {
            searchField.label = qsTr("Please go to the settings and login via OAuth")
            if (applicationWindow.settings.debugLevel >= 1) {
                console.log("SEARCH: Login failed, search disabled")
            }
        }

        onSearchResults: {
            if (applicationWindow.settings.debugLevel >= 1) {
                console.log("SEARCH: Received search results")
            }
            listModel.clear()
            addSearchResultsToModel(search_results)
        }

        onFoundTrack:
        {
            listModel.append(createTrackItem(track_info))
        }

        onFoundAlbum:
        {
            listModel.append(createAlbumItem(album_info))
        }

        onFoundArtist:
        {
            listModel.append(createArtistItem(artist_info))
        }
        onFoundPlaylist:
        {
            listModel.append(createPlaylistItem(playlist_info))
        }

        onFoundVideo:
        {
            listModel.append(createVideoItem(video_info))
        }

        // PERFORMANCE: Batch signal handlers for improved search performance
        onFoundTracksBatch: {
            if (applicationWindow.settings.debugLevel >= 2) {
                console.log("SEARCH: Adding", tracks_array.length, "tracks to results")
            }
            tracks_array.forEach(function(track) {
                listModel.append(createTrackItem(track))
            })
        }
        
        onFoundAlbumsBatch: {
            if (applicationWindow.settings.debugLevel >= 2) {
                console.log("SEARCH: Adding", albums_array.length, "albums to results")
            }
            albums_array.forEach(function(album) {
                listModel.append(createAlbumItem(album))
            })
        }
        
        onFoundArtistsBatch: {
            if (applicationWindow.settings.debugLevel >= 2) {
                console.log("SEARCH: Adding", artists_array.length, "artists to results")
            }
            artists_array.forEach(function(artist) {
                listModel.append(createArtistItem(artist))
            })
        }
        
        onFoundPlaylistsBatch: {
            if (applicationWindow.settings.debugLevel >= 2) {
                console.log("SEARCH: Adding", playlists_array.length, "playlists to results")
            }
            playlists_array.forEach(function(playlist) {
                listModel.append(createPlaylistItem(playlist))
            })
        }

    }

    // Hilfsfunktionen
    function addSearchResultsToModel(results) {
        // Tracks hinzufügen
        results.tracks.forEach(function(track) {
            listModel.append(createTrackItem(track))
        })

        // Albums hinzufügen
        results.albums.forEach(function(album) {
            listModel.append(createAlbumItem(album))
        })

        // Artists hinzufügen
        results.artists.forEach(function(artist) {
            listModel.append(createArtistItem(artist))
        })
        // Playlist hinzufügen
        results.playlists.forEach(function(playlist) {
            listModel.append(createPlaylistItem(playlist))
        })
    }

    function createTrackItem(track) {
        return {
            name: track.title,
            artist: track.artist,
            album: track.album,
            trackid: track.trackid,
            albumid: track.albumid,
            artistid: track.artistid,
            playlistid: "",
            type: typeTrack,
            image: track.image,
            duration: track.duration,
            mixid : ""// track.mixid
        }
    }

    function createAlbumItem(album) {
        return {
            name: album.title,
            albumid: album.albumid,
            artistid: album.artistid,
            playlistid: "",
            trackid: "",
            type: typeAlbum,
            image: album.image,
            duration: album.duration
        }
    }

    function createArtistItem(artist) {
        return {
            name: artist.name,
            artistid: artist.artistid,
            albumid:artist.albumid,
            playlistid : "",
            trackid : "",
            type: typeArtist,
            image: artist.image
        }
    }

    function createPlaylistItem(playlist) {
        console.log("Found playlist", playlist.title, playlist.playlistid)
        return {
            name: playlist.title,
            playlistid: playlist.playlistid,
            artistid: "",
            albumid: 0,
            trackid: "",
            type: typePlaylist,
            image: playlist.image,
            duration: playlist.duration
        }
    }

    /*
    'playlistid': 'a1010338-0ebe-49f9-85e9-91e5bd4c54f7',
    'title': 'Metal Party Classics', 
    'image': 'https://resources.tidal.com/images/0db830f2/f569/45c5/984a/da9a38188fb9/320x320.jpg',
     'duration': 9335, 'num_tracks': 40, 
     'description': "Get that hard rockin' party started with these shout-a-long friendly all-time classics! (Photo: Johannes Havn / Pexels)", 
     'type': 'playlist
    */

    function createVideoItem(video) {
        console.log("Found video", video.title)
        return {
            name: video.title,
            videoid:video.videoid,
            type: typeVideo,
            image: video.image
        }
    }
}
