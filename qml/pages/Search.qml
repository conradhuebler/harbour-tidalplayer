import QtQuick 2.0
import Sailfish.Silica 1.0
import QtMultimedia 5.6
import Sailfish.Media 1.0
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
        anchors {
            fill: parent
            bottomMargin: minPlayerPanel.margin
        }
        clip: true //miniPlayerPanel.expanded
        contentHeight: parent.height - miniPlayerPanel.height
        anchors.bottom: miniPlayerPanel.top

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
                label: qsTr("Please wait for login ...")
                enabled: tidalApi.loginTrue

                EnterKey.enabled: text.length > 0
                EnterKey.iconSource: "image://theme/icon-m-search"
                EnterKey.onClicked: {
                    listModel.clear()
                    tidalApi.genericSearch(text)
                    focus = false
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
        }

        // Suchergebnisse
        SilicaListView {
            anchors {
                top: header.bottom
                topMargin: Theme.paddingLarge
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                margins: Theme.horizontalPageMargin
            }
            clip: true
            height: parent.height - miniPlayerPanel.height
            model: ListModel { id: listModel }

            delegate: SearchResultDelegate {
                width: parent.width
                itemData: model
            }

            VerticalScrollDecorator {}
        }
    }

    // Connections
    Connections {
        target: tidalApi

        onLoginSuccess: searchField.label = qsTr("Find")

        onLoginFailed: searchField.label = qsTr("Please go to the settings and login via OAuth")

        onSearchResults: {
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
    }

    function createTrackItem(track) {
        return {
            name: track.title,
            artist: track.artist,
            album: track.album,
            trackid: track.trackid,
            albumid: track.albumid,
            artistid: track.artistid,
            type: typeTrack,
            image: track.image,
            duration: track.duration,
            albumid : track.albumid
        }
    }

    function createAlbumItem(album) {
        return {
            name: album.title,
            albumid: album.albumid,
            artistid: album.artistid,
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
            type: typeArtist,
            image: artist.image
        }
    }

    function createPlaylistItem(playlist) {
        console.log("Found playlist", playlist.title, playlist.playlistid)
        return {
            name: playlist.title,
            playlistid: playlist.playlistid,
            type: typePlaylist,
            image: playlist.image,
            duration: playlist.duration

        }
    }

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
