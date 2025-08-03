import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: advancedPlayManager

    // ADVANCED PLAY LOGIC: Handles different play actions for tracks/albums/playlists
    
    // Available play actions
    readonly property var playActions: ({
        "replace": {
            name: qsTr("Replace Playlist & Play"),
            description: qsTr("Clear current playlist and play this item"),
            icon: "image://theme/icon-m-play"
        },
        "append": {
            name: qsTr("Add to Playlist & Play"),
            description: qsTr("Add to end of playlist and start playing"),
            icon: "image://theme/icon-m-add"
        },
        "playnow": {
            name: qsTr("Play Now (Keep Playlist)"),
            description: qsTr("Play immediately but keep current playlist"),
            icon: "image://theme/icon-m-media-artists"
        },
        "queue": {
            name: qsTr("Add to Queue"),
            description: qsTr("Add to end of playlist without playing"),
            icon: "image://theme/icon-m-tabs"
        }
    })
    
    // Signals for different content types
    signal playTrack(string trackId, string action)
    signal playAlbum(var albumInfo, string action)
    signal playPlaylist(var playlistInfo, string action)
    signal playArtistTopTracks(string artistId, string action)
    signal playMix(var mixInfo, string action)
    
    // Execute play action for track
    function executeTrackAction(trackId, action) {
        console.log("AdvancedPlayManager: Execute track action", action, "for track", trackId)
        
        switch (action) {
            case "replace":
                console.log("AdvancedPlayManager: Replace playlist with track", trackId)
                playlistManager.clearPlayList()
                playlistManager.addTrack(trackId)
                playlistManager.playTrack(trackId)
                tidalApi.playTrackId(trackId)
                break
                
            case "append":
                console.log("AdvancedPlayManager: Append track and play", trackId)
                playlistManager.addTrack(trackId)
                playlistManager.playTrack(trackId)
                tidalApi.playTrackId(trackId)
                break
                
            case "playnow":
                console.log("AdvancedPlayManager: Play track now, keep playlist", trackId)
                // Store current playlist position
                var currentPos = playlistManager.currentIndex
                tidalApi.playTrackId(trackId)
                // Playlist remains unchanged, will return to current position after track
                break
                
            case "queue":
                console.log("AdvancedPlayManager: Queue track", trackId)
                playlistManager.addTrack(trackId)
                // Don't start playing
                break
        }
        
        playTrack(trackId, action)
    }
    
    // Execute play action for album
    function executeAlbumAction(albumInfo, action) {
        console.log("AdvancedPlayManager: Execute album action", action, "for album", albumInfo.title)
        
        switch (action) {
            case "replace":
                console.log("AdvancedPlayManager: Replace playlist with album")
                playlistManager.clearPlayList()
                // Request album tracks and add them
                tidalApi.getAlbumTracks(albumInfo.id)
                break
                
            case "append":
                console.log("AdvancedPlayManager: Append album tracks")
                // Request album tracks and add to end
                tidalApi.getAlbumTracks(albumInfo.id)
                break
                
            case "playnow":
                console.log("AdvancedPlayManager: Play album now, keep playlist")
                // Play first track of album immediately
                tidalApi.getAlbumTracks(albumInfo.id)
                break
                
            case "queue":
                console.log("AdvancedPlayManager: Queue album tracks")
                tidalApi.getAlbumTracks(albumInfo.id)
                break
        }
        
        playAlbum(albumInfo, action)
    }
    
    // Execute play action for playlist
    function executePlaylistAction(playlistInfo, action) {
        console.log("AdvancedPlayManager: Execute playlist action", action, "for playlist", playlistInfo.title)
        
        switch (action) {
            case "replace":
                console.log("AdvancedPlayManager: Replace with playlist")
                playlistManager.clearPlayList()
                tidalApi.getPlaylistTracks(playlistInfo.id)
                break
                
            case "append":
                console.log("AdvancedPlayManager: Append playlist tracks")
                tidalApi.getPlaylistTracks(playlistInfo.id)
                break
                
            case "playnow":
                console.log("AdvancedPlayManager: Play playlist now")
                tidalApi.getPlaylistTracks(playlistInfo.id)
                break
                
            case "queue":
                console.log("AdvancedPlayManager: Queue playlist tracks")
                tidalApi.getPlaylistTracks(playlistInfo.id)
                break
        }
        
        playPlaylist(playlistInfo, action)
    }
    
    // Execute play action for artist (top tracks)
    function executeArtistAction(artistInfo, action) {
        console.log("AdvancedPlayManager: Execute artist action", action, "for artist", artistInfo.name)
        
        switch (action) {
            case "replace":
                console.log("AdvancedPlayManager: Replace with artist top tracks")
                playlistManager.clearPlayList()
                tidalApi.getArtistTopTracks(artistInfo.id)
                break
                
            case "append":
                console.log("AdvancedPlayManager: Append artist top tracks")
                tidalApi.getArtistTopTracks(artistInfo.id)
                break
                
            case "playnow":
                console.log("AdvancedPlayManager: Play artist top tracks now")
                tidalApi.getArtistTopTracks(artistInfo.id)
                break
                
            case "queue":
                console.log("AdvancedPlayManager: Queue artist top tracks")
                tidalApi.getArtistTopTracks(artistInfo.id)
                break
        }
        
        playArtistTopTracks(artistInfo.id, action)
    }
    
    // Execute play action for mix
    function executeMixAction(mixInfo, action) {
        console.log("AdvancedPlayManager: Execute mix action", action, "for mix", mixInfo.title)
        
        switch (action) {
            case "replace":
                console.log("AdvancedPlayManager: Replace with mix")
                playlistManager.clearPlayList()
                tidalApi.getMixTracks(mixInfo.id)
                break
                
            case "append":
                console.log("AdvancedPlayManager: Append mix tracks")
                tidalApi.getMixTracks(mixInfo.id)
                break
                
            case "playnow":
                console.log("AdvancedPlayManager: Play mix now")
                tidalApi.getMixTracks(mixInfo.id)
                break
                
            case "queue":
                console.log("AdvancedPlayManager: Queue mix tracks")
                tidalApi.getMixTracks(mixInfo.id)
                break
        }
        
        playMix(mixInfo, action)
    }
    
    // Create context menu for play actions
    function createPlayMenu(parent, contentInfo, contentType) {
        var component = Qt.createComponent("../dialogs/PlayActionMenu.qml")
        if (component.status === Component.Ready) {
            var menu = component.createObject(parent, {
                contentInfo: contentInfo,
                contentType: contentType,
                advancedPlayManager: advancedPlayManager
            })
            return menu
        } else {
            console.error("AdvancedPlayManager: Failed to create PlayActionMenu:", component.errorString())
            return null
        }
    }
    
    // Quick action - uses default setting
    function quickPlay(contentInfo, contentType) {
        var defaultAction = applicationWindow.settings.defaultPlayAction || "replace"
        console.log("AdvancedPlayManager: Quick play with default action", defaultAction)
        
        switch (contentType) {
            case "track":
                executeTrackAction(contentInfo.id, defaultAction)
                break
            case "album":
                executeAlbumAction(contentInfo, defaultAction)
                break
            case "playlist":
                executePlaylistAction(contentInfo, defaultAction)
                break
            case "artist":
                executeArtistAction(contentInfo, defaultAction)
                break
            case "mix":
                executeMixAction(contentInfo, defaultAction)
                break
        }
    }
    
    // Get action info
    function getActionInfo(action) {
        return playActions[action] || playActions["replace"]
    }
    
    Component.onCompleted: {
        console.log("AdvancedPlayManager: Initialized with default action:", applicationWindow.settings.defaultPlayAction)
    }
}