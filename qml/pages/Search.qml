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
        clip: miniPlayerPanel.expanded
        contentHeight: parent.height
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
                text: "Corvus Corax"
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

            model: ListModel { id: listModel }

            delegate: SearchResultDelegate {
                width: parent.width
                itemData: model
            }

            VerticalScrollDecorator {}
        }

        TrackPage {
            id: trackPage
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
        console.log(album.title, album.albumid)
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
}
