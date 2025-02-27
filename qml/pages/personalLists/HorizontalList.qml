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
            "type" : typeArtist
        })
    }

    function addPlaylist(playlist_info)
    {
        console.log(playlist_info)
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
            "type" : typePlaylist
        })
    }

    function addMix(mix_info)
    {
        console.log(mix_info)
        if (mix_info === undefined) {
             console.error("mix_info is undefined. skip append to model")
             return;
        }
        model.append({
            "title": mix_info.title,
            "image": mix_info.image,
            "mixid": mix_info.mixid,
            "artistid":"",
            "albumid":-1,
            "playlistid":"",
            "trackid" : "",
            "type" : typePlaylist
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

                menu: ContextMenu {
                    width: delegateItem.width  // same with as item
                    x: (delegateItem.width - width) / 2 // center menue item
                    opacity: 1
                    backgroundColor: Theme.rgba(Theme.secondaryHighlightColor, 1.0)
                    MenuItem {
                        text: {
                        switch(model.type) {
                            case 1: // Track
                                    "Play Track"
                                break
                            case 2: // Album
                                    "Play Album"
                                break
                            case 3: // Artist
                                    "Play Artist Radio todo"
                                break
                            case 4: // Playlist
                                    "Play Playlist"
                            break

                            case 5: // Mix
                                    "Play Mix"
                            break;
                            }
                        }

                        opacity: 1
                        onClicked: {
                            switch(model.type) {
                            case 1: // Track
                                    //playlistManager.clearPlayList()
                                    playlistManager.playTrack(model.trackid)
                                break
                            case 2: // Album
                                playlistManager.clearPlayList()
                                playlistManager.playAlbum(model.albumid)
                                break
                            case 3: // Artist
                                playlistManager.clearPlayList()
                                playlistManager.playArtistTracks(model.artistid, true)  // true for autoPlay                            
                                // Todo
                                break
                            case 4: // Playlist
                                    playlistManager.clearPlayList()
                                    // todo: playlistManager.playPlaylist(model.playlistid) //todo: extend tidalApi with playPlaylist
                                    console.log("Play Playlist", model.playlistid, model.name)  
                                    tidalApi.playPlaylist(model.playlistid,true) //todo: extend tidalApi with playPlaylist
                            break

                            case 5: // Mix
                                    playlistManager.clearPlayList()
                                    tidalApi.playPlaylist(model.mixid,true) //todo: use playlistmanager ?
                            break;
                            }
                        }
                    }
                }

                onClicked: {
                switch(model.type) {
                    case 1: // Track
                        //pageStack.push(Qt.resolvedUrl("../TrackPage.qml"),
                        //{
                        //    "albumId": model.albumid
                        //})e
                        break
                    case 2: // Album
                        pageStack.push(Qt.resolvedUrl("../AlbumPage.qml"),
                        {
                            "albumId" :model.albumid
                        })

                        break
                    case 3: // Artist
                        pageStack.push(Qt.resolvedUrl("../ArtistPage.qml"),
                        {
                            "artistId" :model.artistid
                        })
                        break
                    case 4: // Playlist
                        console.log("Playlist", item.playlistid, item.name)
                        console.log("Playlist", model.playlistid, mode.name)
                        pageStack.push(Qt.resolvedUrl("../SavedPlaylistPage.qml"),
                        {
                            "playlistId" :model.playlistid,
                            "playlistTitle" : model.name
                        })
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
