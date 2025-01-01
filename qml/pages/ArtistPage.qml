import QtQuick 2.0
import Sailfish.Silica 1.0
import QtMultimedia 5.6
import Sailfish.Media 1.0
import "widgets"

Page {
    id: artistPage
    property int artistId : -1
    property var artistData: null
    property bool isHeaderCollapsed: false

function processWimpLinks(text) {
    if (!text) return ""

    // Text in Teile zerlegen
    var parts = text.split("[wimpLink")
    var result = parts[0] // Start mit dem ersten Teil ohne Link

    // Durch alle weiteren Teile gehen
    for (var i = 1; i < parts.length; i++) {
        var part = parts[i]
        try {
            // Artist Link
            if (part.indexOf('artistId="') >= 0) {
                var idMatch = part.match(/artistId="(\d+)"/)
                var textMatch = part.match(/](.*?)\[/)
                if (idMatch && textMatch) {
                    result += '<a href="artist:' + idMatch[1] + '" style="color: ' + Theme.highlightColor + '">' + textMatch[1] + '</a>'
                    result += part.split("[/wimpLink]")[1] || ""
                }
            }
            // Album Link
            else if (part.indexOf('albumId="') >= 0) {
                var idMatch = part.match(/albumId="(\d+)"/)
                var textMatch = part.match(/](.*?)\[/)
                if (idMatch && textMatch) {
                    result += '<a href="album:' + idMatch[1] + '" style="color: ' + Theme.highlightColor + '">' + textMatch[1] + '</a>'
                    result += part.split("[/wimpLink]")[1] || ""
                }
            }
            else {
                // Falls kein Match, original Text behalten
                result += "[wimpLink" + part
            }
        } catch (e) {
            console.log("Fehler beim Verarbeiten eines Links:", e)
            // Bei Fehler original Text behalten
            result += "[wimpLink" + part
        }
    }
    return result
}

    allowedOrientations: Orientation.All

    SilicaFlickable {
        id: flickable
        anchors {
            fill: parent
            bottomMargin: minPlayerPanel.margin
        }
        contentHeight: mainColumn.height

        PullDownMenu {
            MenuItem {
                text: minPlayerPanel.open ? "Hide player" : "Show player"
                onClicked: minPlayerPanel.open = !minPlayerPanel.open
            }
        }

        Column {
            id: mainColumn
            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader {
                id: header
                title: qsTr("Artist Info")
            }

            // Artist Info Section
            Item {
                id: artistInfoContainer
                width: parent.width
                height: isHeaderCollapsed ? Theme.itemSizeLarge : width * 0.4
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

                        Rectangle {
                            color: Theme.rgba(Theme.highlightBackgroundColor, 0.1)
                            anchors.fill: parent
                            visible: coverImage.status !== Image.Ready
                        }
                    }

                    Column {
                        width: parent.width - coverImage.width - parent.spacing - Theme.paddingLarge * 2
                        height: parent.height
                        spacing: Theme.paddingSmall
                        anchors.verticalCenter: parent.verticalCenter

                        Label {
                            id: artistName
                            width: parent.width
                            truncationMode: TruncationMode.Fade
                            color: Theme.highlightColor
                            font.pixelSize: Theme.fontSizeLarge
                        }

                        Item {
                            width: parent.width
                            height: parent.height - artistName.height - parent.spacing
                            clip: true

                            Flickable {
                                id: bioFlickable
                                anchors.fill: parent
                                contentHeight: bioText.height
                                clip: true

                                Label {
                                    id: bioText
                                    width: parent.width
                                    wrapMode: Text.WordWrap
                                    textFormat: Text.RichText  // Wichtig für HTML-Links
                                    color: Theme.secondaryColor
                                    font.pixelSize: Theme.fontSizeSmall

                                    onLinkActivated: {
                                        var parts = link.split(":")
                                        if (parts.length === 2) {
                                            if (parts[0] === "artist") {
                                                pageStack.push(Qt.resolvedUrl("ArtistPage.qml"),
                                                             { artistId: parseInt(parts[1]) })
                                            } else if (parts[0] === "album") {
                                                pageStack.push(Qt.resolvedUrl("AlbumPage.qml"),
                                                             { albumId: parseInt(parts[1]) })
                                            }
                                        }
                                    }
                                }
                            }

                            // Scrollbar für die Biografie
                            VerticalScrollDecorator {
                                flickable: bioFlickable
                            }
                        }
                    }

                }
            }

            // Albums Section
            SectionHeader {
                text: qsTr("Albums")
            }

        // Ersetze den ScrollDecorator mit diesem angepassten horizontalen Scroll-Indikator
                   SilicaListView {
            id: albumsView
            width: parent.width
            height: Theme.itemSizeLarge * 2.5  // Höhe vergrößert
            orientation: ListView.Horizontal
            clip: true
            spacing: Theme.paddingMedium  // Abstand zwischen den Items

            model: ListModel {}

            delegate: BackgroundItem {
                width: Theme.itemSizeLarge * 2  // Breite vergrößert
                height: albumsView.height

                Column {
                    anchors {
                        fill: parent
                        margins: Theme.paddingSmall
                    }
                    spacing: Theme.paddingMedium  // Mehr Abstand zwischen Bild und Text

                    Image {
                        width: parent.width
                        height: width  // Quadratisches Cover
                        source: model.cover
                        fillMode: Image.PreserveAspectCrop
                    }

                    Label {
                        width: parent.width
                        text: model.title
                        truncationMode: TruncationMode.Fade
                        font.pixelSize: Theme.fontSizeSmall  // Größere Schrift
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap  // Text kann umbrechen
                        maximumLineCount: 2  // Maximal zwei Zeilen
                    }
                }

                onClicked: pageStack.push(Qt.resolvedUrl("AlbumPage.qml"),
                                        { albumId: model.albumId })
            }

            // Horizontaler Scroll-Indikator
            Rectangle {
                visible: albumsView.contentWidth > albumsView.width
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
                    width: Math.max(parent.width * (albumsView.width / albumsView.contentWidth), Theme.paddingLarge)
                    x: (parent.width - width) * (albumsView.contentX / (albumsView.contentWidth - albumsView.width))
                    visible: albumsView.contentWidth > albumsView.width
                }
            }
        }

            // Top Tracks Section
            SectionHeader {
                text: qsTr("Popular Tracks")
            }

            TrackList {
                id: topTracks
                width: parent.width
                height: artistPage.height - y - (minPlayerPanel.open ? minPlayerPanel.height : 0)
                type: "tracklist"
            }

            // Similiar Artists Section
            SectionHeader {
                id:similarArtistsSection
                text: qsTr("Similiar Artists")
            }

        // Ersetze den ScrollDecorator mit diesem angepassten horizontalen Scroll-Indikator
            SilicaListView {
            id: simartistView
            width: parent.width
            height: Theme.itemSizeLarge * 2.5  // Höhe vergrößert
            orientation: ListView.Horizontal
            clip: true
            spacing: Theme.paddingMedium  // Abstand zwischen den Items

            model: ListModel {}

            delegate: BackgroundItem {
                width: Theme.itemSizeLarge * 2  // Breite vergrößert
                height: simartistView.height

                Column {
                    anchors {
                        fill: parent
                        margins: Theme.paddingSmall
                    }
                    spacing: Theme.paddingMedium  // Mehr Abstand zwischen Bild und Text

                    Image {
                        width: parent.width
                        height: width  // Quadratisches Cover
                        source: model.cover
                        fillMode: Image.PreserveAspectCrop
                    }

                    Label {
                        width: parent.width
                        text: model.name
                        truncationMode: TruncationMode.Fade
                        font.pixelSize: Theme.fontSizeSmall  // Größere Schrift
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap  // Text kann umbrechen
                        maximumLineCount: 2  // Maximal zwei Zeilen
                    }
                }

                onClicked: pageStack.push(Qt.resolvedUrl("ArtistPage.qml"),
                                        { artistId: model.artistId })
            }
    }
            // Horizontaler Scroll-Indikator
            Rectangle {
                visible: simartistView.contentWidth > simartistView.width
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
                    width: Math.max(parent.width * (simartistView.width / simartistView.contentWidth), Theme.paddingLarge)
                    x: (parent.width - width) * (simartistView.contentX / (simartistView.contentWidth - simartistView.width))
                    visible: simartistView.contentWidth > simartistView.width
                }
            }
        }

        VerticalScrollDecorator {}

        onContentYChanged: {
            if (contentY > Theme.paddingLarge) {
                isHeaderCollapsed = true
            } else {
                isHeaderCollapsed = false
            }
        }
    }

    Component.onCompleted: {
        if (artistId > 0) {
            artistData = cacheManager.getArtist(artistId)
            if (!artistData) {
                console.log("Artist nicht im Cache gefunden:", artistId)
            }
            header.title = artistData.name
            artistName.text = artistData.name
            coverImage.source = artistData.image
            if (artistData.bio) {
            console.log("Verarbeite Bio...")
            var processedBio = processWimpLinks(artistData.bio)
            bioText.text = processedBio
        }
            tidalApi.getAlbumsofArtist(artistData.artistid)
            tidalApi.getTopTracksofArtist(artistData.artistid)
            tidalApi.getSimiliarArtist(artistData.artistid)
        }
    }

    Connections {
        target: tidalApi

        onArtistChanged: {
            header.title = name
            artistName.text = name
            coverImage.source = img
            bioText.text = ""
        }

        onTrackAdded: {
            topTracks.addTrack(title, artist, album, id, duration)
        }

        // Neues Signal für Alben
        onAlbumofArtist: {

            albumsView.model.append({
                title: album_info.title,
                cover: album_info.image,
                albumId: album_info.albumid
            })
        }

         onSimilarArtist: {

            simartistView.model.append({
                name: artist_info.name,
                cover: artist_info.image,
                artistId: artist_info.artistid
            })
        }

    onNoSimilarArtists: {
        // Optional: Section Header ausblenden
        similarArtistsSection.visible = false
        simartistView.visible = false
    }

    }
}
