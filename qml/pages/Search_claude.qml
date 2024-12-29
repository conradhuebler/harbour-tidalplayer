import QtQuick 2.0
import Sailfish.Silica 1.0
import QtMultimedia 5.6
import Sailfish.Media 1.0

import "widgets"
import "stuff"

Page {
    id: searchPage

    ListModel {
        id: searchResultsModel
    }

    Connections {
        target: tidalApi

        onSearchResults: {
            searchResultsModel.clear()

            // Tracks hinzufügen
            results.tracks.forEach(function(track) {
                searchResultsModel.append({
                    type: "track",
                    data: track
                })
            })

            // Albums hinzufügen
            results.albums.forEach(function(album) {
                searchResultsModel.append({
                    type: "album",
                    data: album
                })
            })

            // Artists hinzufügen
            results.artists.forEach(function(artist) {
                searchResultsModel.append({
                    type: "artist",
                    data: artist
                })
            })
        }

        onError: {
            // Fehlerbehandlung
            notification.show(errorData.message)
        }
    }

    SearchField {
        id: searchField
        width: parent.width

        onTextChanged: {
            if (text.length >= 3) {
                tidalApi.search(text)
            }
        }
    }

    SilicaListView {
        anchors.top: searchField.bottom
        anchors.bottom: parent.bottom
        width: parent.width

        model: searchResultsModel

        delegate: ListItem {
            contentHeight: column.height

            Column {
                id: column
                width: parent.width

                Label {
                    text: {
                        switch(type) {
                            case "track": return data.title
                            case "album": return data.title
                            case "artist": return data.name
                            default: return ""
                        }
                    }
                }

                Label {
                    text: {
                        switch(type) {
                            case "track": return data.artist
                            case "album": return data.artist
                            default: return ""
                        }
                    }
                    visible: type !== "artist"
                    color: Theme.secondaryColor
                }
            }

            onClicked: {
                switch(type) {
                    case "track":
                        tidalApi.playTrack(data.id)
                        break
                    case "album":
                        pageStack.push(Qt.resolvedUrl("AlbumPage.qml"),
                            {albumId: data.id})
                        break
                    case "artist":
                        pageStack.push(Qt.resolvedUrl("ArtistPage.qml"),
                            {artistId: data.id})
                        break
                }
            }
        }
    }
}
