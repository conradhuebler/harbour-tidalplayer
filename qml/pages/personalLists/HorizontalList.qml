import QtQuick 2.0
import Sailfish.Silica 1.0

SilicaListView {
    // Konstanten
    readonly property int typeTrack: 1
    readonly property int typeAlbum: 2
    readonly property int typeArtist: 3
    readonly property int typePlaylist: 4
    readonly property int typeVideo: 5
    readonly property int typeMix: 6

    property string placeholderHint : "Placeholder Hint"
    property string placeholderText : "Placeholder Text"

    function addTrack(track_info)
    {
        //console.log(track_info)
        if (track_info === undefined) {
             console.error("track_info is undefined. skip append to model")
             return;
        }
        model.append({
            "title": track_info.title,
            "image": track_info.image,
            "trackid": track_info.trackid,
            "playlistid" : "",
            "artistid": "",
            "albumid": -1,  
            "mixid": "",         
            "type" : typeTrack
        })
    }

    function addAlbum(album_info)
    {
        //console.log(album_info)
        if (album_info === undefined) {
             console.error("album_info is undefined. skip append to model")
             return;
        }
        model.append({
            "title": album_info.title,
            "image": album_info.image,
            "albumid": album_info.albumid,
            "playlistid" : "",
            "artistid": "",
            "trackid" : "",
            "mixid": "",
            "type" : typeAlbum
        })
    }

    function addArtist(artist_info)
    {
        //console.log(artist_info)
        if (artist_info === undefined) {
             console.error("artist_info is undefined. skip append to model")
             return;
        }
        model.append({
            "name": artist_info.name,
            "title": artist_info.name,
            "image": artist_info.image,
            "artistid": artist_info.artistid,
            "playlistid":  "",
            "albumid": -1,
            "trackid" : "",
            "mixid" : "",
            "type" : typeArtist
        })
    }

    function addPlaylist(playlist_info)
    {
        console.log(JSON.stringify(playlist_info))
        if (playlist_info === undefined) {
             console.error("album_info is undefined. skip append to model")
             return;
        }
        console.log("addPlaylist", playlist_info.title, playlist_info.playlistid)
        model.append({
            "title": playlist_info.title,
            "image": playlist_info.image,
            "playlistid": playlist_info.playlistid,
            "albumid":-1,
            "artistid":"",
            "trackid" : "",
            "mixid": "",
            "type" : typePlaylist
        })
    }

    function addMix(mix_info)
    {
        if (mix_info === undefined) {
             console.error("mix_info is undefined. skip append to model")
             return;
        }
        console.log("addMix", mix_info.title, mix_info.mixid, mix_info.image)
        model.append({
            "title": mix_info.title,
            "mixid": mix_info.mixid,
            "image": mix_info.image,            
            "artistid":"",
            "albumid":-1,
            "playlistid":"",
            "trackid" : "",
            "type" : typeMix
        })
    }


    id: root
    width: parent.width
    height: Theme.itemSizeLarge * 3
    orientation: ListView.Horizontal
    clip: true
    spacing: Theme.paddingMedium

    model: ListModel {
        id: recentModel
        function getEmpty()  {
            return {
                title: "Title",
                image: "image://theme/icon-m-media-playlists",
                trackid: "",
                mixid: "",
                playlistid: "",
                artistid: "",
                albumid: -1,
                type: 0
            }
        }
    }

    delegate: ListItem {
    id: delegateItem  // ID hinzugefügt für Referenzierung
    width: Theme.itemSizeLarge * 2
    height: root.height
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
                    }
                }

                menu: Component {
                    ContextMenu {
                        width: delegateItem.width
                        x: (delegateItem.width - width) / 2
                        opacity: 1
                        backgroundColor: Theme.rgba(Theme.secondaryHighlightColor, 1.0)
                        
                        // Advanced Play Menu Items
                        MenuItem {
                            text: qsTr("Replace Playlist & Play")
                            onClicked: executeAdvancedPlay("replace")
                        }
                        
                        MenuItem {
                            text: qsTr("Add to Playlist & Play") 
                            onClicked: executeAdvancedPlay("append")
                        }
                        
                        MenuItem {
                            text: qsTr("Play Now (Keep Playlist)")
                            onClicked: executeAdvancedPlay("playnow")
                        }
                        
                        MenuItem {
                            text: qsTr("Add to Queue")
                            onClicked: executeAdvancedPlay("queue")
                        }
                        
                        MenuItem {
                            text: "─────────────"
                            enabled: false
                        }
                        
                        MenuItem {
                            text: {
                                switch(model.type) {
                                    case typeTrack: return qsTr("View Album")
                                    case typeAlbum: return qsTr("View Album")
                                    case typeArtist: return qsTr("View Artist")
                                    case typePlaylist: return qsTr("View Playlist")
                                    case typeMix: return qsTr("View Mix")
                                    default: return qsTr("View Details")
                                }
                            }
                            onClicked: openDetailPage()
                        }
                        
                        // Helper functions for the menu
                        function executeAdvancedPlay(action) {
                            var contentInfo = getContentInfo()
                            var contentType = getContentType()
                            
                            if (advancedPlayManager) {
                                switch(contentType) {
                                    case "track":
                                        advancedPlayManager.executeTrackAction(contentInfo.id, action)
                                        break
                                    case "album":
                                        advancedPlayManager.executeAlbumAction(contentInfo, action)
                                        break
                                    case "artist":
                                        advancedPlayManager.executeArtistAction(contentInfo, action)
                                        break
                                    case "playlist":
                                        advancedPlayManager.executePlaylistAction(contentInfo, action)
                                        break
                                    case "mix":
                                        advancedPlayManager.executeMixAction(contentInfo, action)
                                        break
                                }
                            }
                        }
                        
                        function openDetailPage() {
                            var contentInfo = getContentInfo()
                            var contentType = getContentType()
                            
                            switch(contentType) {
                                case "album":
                                    pageStack.push(Qt.resolvedUrl("../AlbumPage.qml"), {
                                        "albumId": contentInfo.id,
                                        "albumTitle": contentInfo.title,
                                        "albumImage": contentInfo.image
                                    })
                                    break
                                case "artist":
                                    pageStack.push(Qt.resolvedUrl("../ArtistPage.qml"), {
                                        "artistId": contentInfo.id,
                                        "artistName": contentInfo.title,
                                        "artistImage": contentInfo.image
                                    })
                                    break
                                case "playlist":
                                    pageStack.push(Qt.resolvedUrl("../SavedPlaylistPage.qml"), {
                                        "playlistId": contentInfo.id,
                                        "playlistTitle": contentInfo.title,
                                        "playlistImage": contentInfo.image
                                    })
                                    break
                                case "mix":
                                    pageStack.push(Qt.resolvedUrl("../MixPage.qml"), {
                                        "mixId": contentInfo.id,
                                        "mixTitle": contentInfo.title,
                                        "mixImage": contentInfo.image
                                    })
                                    break
                            }
                        }
                        
                        function getContentInfo() {
                            return {
                                id: model.trackid || model.albumid || model.artistid || model.playlistid || model.mixid,
                                title: model.title,
                                name: model.title,
                                image: model.image
                            }
                        }
                        
                        function getContentType() {
                            switch(model.type) {
                                case typeTrack: return "track"
                                case typeAlbum: return "album"
                                case typeArtist: return "artist"
                                case typePlaylist: return "playlist"
                                case typeMix: return "mix"
                                default: return "unknown"
                            }
                        }
                    }
                }

                onClicked: {
                    // Single click opens info page (for homescreen)
                    console.log("HorizontalList: Opening info page for", model.title)
                    
                    switch(model.type) {
                        case typeAlbum:
                            pageStack.push(Qt.resolvedUrl("../AlbumPage.qml"), {
                                "albumId": model.albumid,
                                "albumTitle": model.title,
                                "albumImage": model.image
                            })
                            break
                        case typeArtist:
                            pageStack.push(Qt.resolvedUrl("../ArtistPage.qml"), {
                                "artistId": model.artistid,
                                "artistName": model.title,
                                "artistImage": model.image
                            })
                            break
                        case typePlaylist:
                            pageStack.push(Qt.resolvedUrl("../SavedPlaylistPage.qml"), {
                                "playlistId": model.playlistid,
                                "playlistTitle": model.title,
                                "playlistImage": model.image
                            })
                            break
                        case typeMix:
                            pageStack.push(Qt.resolvedUrl("../MixPage.qml"), {
                                "mixId": model.mixid,
                                "mixTitle": model.title,
                                "mixImage": model.image
                            })
                            break
                        case typeTrack:
                            // For tracks, we could show album page
                            if (model.albumid) {
                                pageStack.push(Qt.resolvedUrl("../AlbumPage.qml"), {
                                    "albumId": model.albumid,
                                    "albumTitle": model.title,
                                    "albumImage": model.image
                                })
                            }
                            break
                    }
                }
            }

                // Horizontaler Scroll-Indikator für Playlists
                Rectangle {
                    visible: root.contentWidth > root.width
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
                        width: Math.max(parent.width * (root.width / root.contentWidth), Theme.paddingLarge)
                        x: (parent.width - width) * (root.contentX / (root.contentWidth - root.width))
                        visible: root.contentWidth > root.width
                    }
                }

                ViewPlaceholder {
                    enabled: model.count === 0
                    text: placeholderHint
                    hintText: placeholderText
                }
}
