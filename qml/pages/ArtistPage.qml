import QtQuick 2.0
import Sailfish.Silica 1.0
import QtMultimedia 5.6
import Sailfish.Media 1.0
import "widgets"

Page {
    id: artistPage
    property int artistId: -1
    property var artistData: null
    property bool isHeaderCollapsed: false
    property bool isFav: false
    property bool initialized: false

    function processWimpLinks(text) {
        if (!text) return ""
        var parts = text.split("[wimpLink")
        var result = parts[0]
        for (var i = 1; i < parts.length; i++) {
            var part = parts[i]
            try {
                if (part.indexOf('artistId="') >= 0) {
                    var idMatch = part.match(/artistId="(\d+)"/)
                    var textMatch = part.match(/](.*?)\[/)
                    if (idMatch && textMatch) {
                        result += '<a href="artist:' + idMatch[1] + '" style="color: ' + Theme.highlightColor + '">' + textMatch[1] + '</a>'
                        result += part.split("[/wimpLink]")[1] || ""
                    }
                } else if (part.indexOf('albumId="') >= 0) {
                    var idMatch = part.match(/albumId="(\d+)"/)
                    var textMatch = part.match(/](.*?)\[/)
                    if (idMatch && textMatch) {
                        result += '<a href="album:' + idMatch[1] + '" style="color: ' + Theme.highlightColor + '">' + textMatch[1] + '</a>'
                        result += part.split("[/wimpLink]")[1] || ""
                    }
                } else {
                    result += "[wimpLink" + part
                }
            } catch (e) {
                console.log("Fehler beim Verarbeiten eines Links:", e)
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
        contentHeight: mainColumn.height + Theme.paddingLarge + getBottomOffset()
        height: parent.height + miniPlayerPanel.height + getBottomOffset()

        function getBottomOffset()
        {
            if (minPlayerPanel.open) return ( 1.2 * minPlayerPanel.height )
            return minPlayerPanel.height * 0.4
        }


        PullDownMenu {

        MenuItem {
            text: qsTr("Share")
            onClicked: {
                if (artistData) {
                    var shareText = qsTr("Check out this artist: %1").arg(artistData.name)
                    var shareUrl = "https://tidal.com/artist/" + artistData.artistid;
                    var shareData = {
                        text: shareText,
                        url: shareUrl
                    };
                    Clipboard.text = shareText + "\n" + shareUrl;
                }
            }
        }
        
            MenuItem {
                text: minPlayerPanel.open ? qsTr("Hide player") : qsTr("Show player")
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

            Item {
                id: artistInfoContainer
                width: parent.width
                height: width * 0.4
                clip: true

                Behavior on height {
                    NumberAnimation { duration: 200 }
                }

                Row {
                    width: parent.width
                    height: parent.height
                    spacing: Theme.paddingMedium
                    x: Theme.paddingMedium

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

                        IconButton {
                            id: favButton
                            width: Theme.iconSizeMedium
                            height: Theme.iconSizeMedium
                            anchors {
                                top: coverImage.top
                                right: coverImage.right
                                margins: Theme.paddingSmall
                            }
                            icon.source: "image://theme/icon-s-favorite"
                            icon.sourceSize: Qt.size(Theme.iconSizeMedium, Theme.iconSizeMedium)
                            highlighted: isFav
                            onClicked: {
                               favManager.setArtistFavoriteInfo(artistId,!isFav)
                            }
                            z:1 // tobe on top of the image
                        }
                    }

                    Column {
                        width: parent.width - coverImage.width - parent.spacing - Theme.paddingLarge * 2
                        height: parent.height
                        spacing: Theme.paddingSmall
                        y: (parent.height - height) / 2

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
                                    textFormat: Text.RichText
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

                            VerticalScrollDecorator {
                                flickable: bioFlickable
                            }
                        }
                    }
                }
            }

            SectionHeader {
                text: qsTr("Albums")
            }

            SilicaListView {
                id: albumsView
                width: parent.width
                height: Theme.itemSizeLarge * 3
                orientation: ListView.Horizontal
                clip: true
                spacing: Theme.paddingMedium

                model: ListModel {}

                delegate: BackgroundItem {
                    width: Theme.itemSizeLarge * 2
                    height: albumsView.height

                    Column {
                        width: parent.width
                        height: parent.height
                        spacing: Theme.paddingMedium
                        x: Theme.paddingSmall
                        y: Theme.paddingSmall

                        Image {
                            width: parent.width - 2 * Theme.paddingSmall
                            height: width
                            source: model.cover
                            fillMode: Image.PreserveAspectCrop
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
            }

            SectionHeader {
                text: qsTr("Popular Tracks")
            }

            Row {
                id: artistControlBar
                width: parent.width
                height: Theme.itemSizeSmall
                spacing: Theme.paddingMedium
                anchors {
                    left: parent.left
                    right: parent.right
                    margins: Theme.paddingMedium
                }

                IconButton {
                    id: playButton
                    width: Theme.iconSizeMedium
                    height: Theme.iconSizeMedium
                    anchors {
                        verticalCenter: parent.verticalCenter
                    }
                    icon.source: "image://theme/icon-m-play"
                    icon.sourceSize: Qt.size(Theme.iconSizeMedium, Theme.iconSizeMedium)
                    onClicked: {
                        playlistManager.clearPlayList()
                        playlistManager.playArtistTracks(artistId, true)  // true for autoPlay
                    }
                }

                Label {
                    text: qsTr("Play top ") + topTracks.model.count + " " + qsTr(" tracks")
                    font.pixelSize: Theme.fontSizeSmall
                    anchors.verticalCenter: parent.verticalCenter
                }

                /*Label {
                    text: "  " + topTracks.model.count + " " + qsTr("Tracks")
                    font.pixelSize: Theme.fontSizeTiny
                    color: Theme.secondaryColor
                    anchors.verticalCenter: parent.verticalCenter
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 150 } } 
                }*/

                IconButton {
                    id: playRadioButton
                    width: Theme.iconSizeMedium
                    height: Theme.iconSizeMedium
                    anchors {
                        verticalCenter: parent.verticalCenter
                        leftMargin: Theme.paddingMedium
                    }
                    icon.source: "image://theme/icon-m-play"
                    icon.sourceSize: Qt.size(Theme.iconSizeMedium, Theme.iconSizeMedium)
                    onClicked: {
                        playlistManager.clearPlayList()
                        playlistManager.playArtistRadio(artistId, true)  // true for autoPlay
                    }
                }

                Label {
                    text: qsTr("Play Radio")
                    font.pixelSize: Theme.fontSizeSmall
                    anchors.verticalCenter: parent.verticalCenter
                }

                Item {
                    width: Theme.paddingLarge
                    height: parent.height
                }
            }
            // Add separator
            Separator {
                width: parent.width
                color: Theme.primaryColor
                horizontalAlignment: Qt.AlignHCenter
            }

            TrackList {
                id: topTracks
                width: parent.width
                height: Theme.itemSizeLarge * 6
                type: "tracklist"
            }

            SectionHeader {
                id: similarArtistsSection
                text: qsTr("Similar Artists")
            }

            SilicaListView {
                id: simartistView
                width: parent.width
                height: Theme.itemSizeLarge * 2.5
                orientation: ListView.Horizontal
                clip: true
                spacing: Theme.paddingMedium

                model: ListModel {}

                delegate: BackgroundItem {
                    width: Theme.itemSizeLarge * 2
                    height: simartistView.height

                    Column {
                        width: parent.width
                        height: parent.height
                        spacing: Theme.paddingMedium
                        x: Theme.paddingSmall
                        y: Theme.paddingSmall

                        Image {
                            width: parent.width - 2 * Theme.paddingSmall
                            height: width
                            source: model.cover
                            fillMode: Image.PreserveAspectCrop
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

            isFav = favManager.isFavorite(artistId)

            tidalApi.getAlbumsofArtist(artistId)
            tidalApi.getTopTracksofArtist(artistId)
            tidalApi.getSimiliarArtist(artistId)
            //todo: tidalApi.getArtistRadio(artistId)

            artistData = cacheManager.getArtistInfo(artistId)
            if (artistData) {
                if (!artistData.image) {
                    artistData.image = "image://theme/icon-m-media-artists"
                }
                header.title = artistData.name
                artistName.text = artistData.name
                coverImage.source = artistData.image
                if (artistData.bio) {
                    console.log("Verarbeite Bio...")
                    var processedBio = processWimpLinks(artistData.bio)
                    bioText.text = processedBio
                }
                initialized = true
                return
            }
            console.log("Artist nicht im Cache gefunden:", artistId)
        }
    }

    Connections {
        target: favManager

        onUpdateFavorite: {
            if (id === artistId)
                isFav = status
        }
    }

    Connections {
        target: tidalApi

        onCacheArtist: {
            if (initialized) {
                return
            }
            if (artistId == artist_info.artistid) {
                if (!artist_info.image) {
                    artist_info.image = "image://theme/icon-m-media-artists"
                }
                header.title = artist_info.name
                artistName.text = artist_info.name
                coverImage.source = artist_info.image
                if (artist_info.bio) {
                    console.log("Verarbeite Bio...")
                    var processedBio = processWimpLinks(artist_info.bio)
                    bioText.text = processedBio
                }
                initialized = true
            }
        }

        onTrackAdded: {
            topTracks
            .addTrack(title, artist, album, id, duration)
        }

        onAlbumofArtist: {
            albumsView.model.append({
                title: album_info.title,
                cover: album_info.image,
                albumId: album_info.albumid
            })
        }

        onSimilarArtist: {
            if (artist_info === undefined) {
                console.log("artist_info is undefined. skip append to model")
                return
            }
            simartistView.model.append({
                name: artist_info.name,
                cover: artist_info.image,
                artistid: artist_info.artistid
            })
        }

        onNoSimilarArtists: {
            similarArtistsSection.visible = false
            simartistView.visible = false
        }
    }
}
