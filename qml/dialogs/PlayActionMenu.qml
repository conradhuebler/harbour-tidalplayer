import QtQuick 2.0
import Sailfish.Silica 1.0

ContextMenu {
    id: playActionMenu
    
    // PLAY ACTION MENU: Context menu for advanced play actions
    
    property var contentInfo
    property string contentType  // "track", "album", "playlist", "artist", "mix"
    property var advancedPlayManager
    
    // Menu items for different play actions
    MenuItem {
        text: advancedPlayManager.playActions["replace"].name
        onClicked: {
            executeAction("replace")
        }
    }
    
    MenuItem {
        text: advancedPlayManager.playActions["append"].name
        onClicked: {
            executeAction("append")
        }
    }
    
    MenuItem {
        text: advancedPlayManager.playActions["playnow"].name
        onClicked: {
            executeAction("playnow")
        }
    }
    
    MenuItem {
        text: advancedPlayManager.playActions["queue"].name
        onClicked: {
            executeAction("queue")
        }
    }
    
    // Separator
    MenuItem {
        text: "─────────────"
        enabled: false
    }
    
    // Content-specific actions
    MenuItem {
        text: contentType === "album" ? qsTr("View Album") :
              contentType === "artist" ? qsTr("View Artist") :
              contentType === "playlist" ? qsTr("View Playlist") :
              contentType === "mix" ? qsTr("View Mix") :
              qsTr("View Details")
        onClicked: {
            openDetailPage()
        }
    }
    
    MenuItem {
        text: qsTr("Add to Favorites")
        visible: contentType !== "track" // Tracks have separate favorite logic
        onClicked: {
            addToFavorites()
        }
    }
    
    // Execute the selected play action
    function executeAction(action) {
        if (!advancedPlayManager || !contentInfo) {
            console.error("PlayActionMenu: Missing advancedPlayManager or contentInfo")
            return
        }
        
        console.log("PlayActionMenu: Executing", action, "for", contentType)
        
        switch (contentType) {
            case "track":
                advancedPlayManager.executeTrackAction(contentInfo.id, action)
                break
            case "album":
                advancedPlayManager.executeAlbumAction(contentInfo, action)
                break
            case "playlist":
                advancedPlayManager.executePlaylistAction(contentInfo, action)
                break
            case "artist":
                advancedPlayManager.executeArtistAction(contentInfo, action)
                break
            case "mix":
                advancedPlayManager.executeMixAction(contentInfo, action)
                break
            default:
                console.warn("PlayActionMenu: Unknown content type:", contentType)
        }
    }
    
    // Open detail page for the content
    function openDetailPage() {
        if (!contentInfo) return
        
        console.log("PlayActionMenu: Opening detail page for", contentType)
        
        switch (contentType) {
            case "album":
                pageStack.push(Qt.resolvedUrl("../pages/AlbumPage.qml"), {
                    album_id: contentInfo.id,
                    album_title: contentInfo.title,
                    album_image: contentInfo.image
                })
                break
            case "artist":
                pageStack.push(Qt.resolvedUrl("../pages/ArtistPage.qml"), {
                    artist_id: contentInfo.id,
                    artist_name: contentInfo.name,
                    artist_image: contentInfo.image
                })
                break
            case "playlist":
                pageStack.push(Qt.resolvedUrl("../pages/PlaylistPage.qml"), {
                    playlist_id: contentInfo.id,
                    playlist_title: contentInfo.title,
                    playlist_image: contentInfo.image
                })
                break
            case "mix":
                pageStack.push(Qt.resolvedUrl("../pages/MixPage.qml"), {
                    mix_id: contentInfo.id,
                    mix_title: contentInfo.title,
                    mix_image: contentInfo.image
                })
                break
            case "track":
                // For tracks, we could show album or artist page
                if (contentInfo.album_id) {
                    pageStack.push(Qt.resolvedUrl("../pages/AlbumPage.qml"), {
                        album_id: contentInfo.album_id,
                        album_title: contentInfo.album,
                        album_image: contentInfo.image
                    })
                }
                break
        }
    }
    
    // Add content to favorites
    function addToFavorites() {
        if (!contentInfo) return
        
        console.log("PlayActionMenu: Adding to favorites:", contentType, contentInfo.title || contentInfo.name)
        
        switch (contentType) {
            case "album":
                tidalApi.addAlbumToFavorites(contentInfo.id)
                break
            case "artist":
                tidalApi.addArtistToFavorites(contentInfo.id)
                break
            case "playlist":
                tidalApi.addPlaylistToFavorites(contentInfo.id)
                break
            case "mix":
                tidalApi.addMixToFavorites(contentInfo.id)
                break
            case "track":
                tidalApi.addTrackToFavorites(contentInfo.id)
                break
        }
    }
}