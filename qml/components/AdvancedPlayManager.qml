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
                playlistManager.appendTrack(trackId)
                playlistManager.playPosition(0)  // Play the first (and only) track
                break
                
            case "append":
                console.log("AdvancedPlayManager: Append track and play", trackId)
                playlistManager.appendTrack(trackId)
                playlistManager.playPosition(playlistManager.size - 1)  // Play the just-added track
                break
                
            case "playnow":
                console.log("AdvancedPlayManager: Play track now, keep playlist", trackId)
                // Insert track after current position and play immediately
                var currentIndex = playlistManager.currentIndex
                playlistManager.currentIndex = currentIndex  // Set position for insertTrack
                playlistManager.insertTrack(trackId)
                playlistManager.playPosition(currentIndex + 1)
                break
                
            case "queue":
                console.log("AdvancedPlayManager: Queue track", trackId)
                // Add to end of playlist without playing
                playlistManager.appendTrack(trackId)
                break
        }
        
        playTrack(trackId, action)
    }
    
    // Execute play action for album
    function executeAlbumAction(albumInfo, action) {
        console.log("AdvancedPlayManager: Execute album action", action, "for album", albumInfo.title)
        
        switch (action) {
            case "replace":
                console.log("AdvancedPlayManager: Replace playlist with album", albumInfo.id)
                playlistManager.clearPlayList()
                playlistManager.playAlbum(albumInfo.id, true)
                break
                
            case "append":
                console.log("AdvancedPlayManager: Append album and play", albumInfo.id)
                playlistManager.playAlbum(albumInfo.id, true)
                break
                
            case "playnow":
                console.log("AdvancedPlayManager: Play album now, keep playlist", albumInfo.id)
                // For play now, we need to insert tracks after current position
                // We'll use a special approach: request tracks and insert them when they arrive
                pendingPlayNowAction = {
                    type: "album",
                    albumInfo: albumInfo
                }
                tidalApi.getAlbumTracks(albumInfo.id)
                break
                
            case "queue":
                console.log("AdvancedPlayManager: Queue album", albumInfo.id)
                playlistManager.playAlbum(albumInfo.id, false)
                break
        }
        
        playAlbum(albumInfo, action)
    }
    
    // Only need pending action for "play now" functionality
    property var pendingPlayNowAction: null
    
    // Execute play action for playlist
    function executePlaylistAction(playlistInfo, action) {
        console.log("AdvancedPlayManager: Execute playlist action", action, "for playlist", playlistInfo.title)
        
        switch (action) {
            case "replace":
                console.log("AdvancedPlayManager: Replace playlist with playlist", playlistInfo.id)
                playlistManager.clearPlayList()
                playlistManager.playPlaylist(playlistInfo.id, true)
                break
                
            case "append":
                console.log("AdvancedPlayManager: Append playlist and play", playlistInfo.id)
                playlistManager.playPlaylist(playlistInfo.id, true)
                break
                
            case "playnow":
                console.log("AdvancedPlayManager: Play playlist now, keep current", playlistInfo.id)
                // For play now, we need to insert tracks after current position
                pendingPlayNowAction = {
                    type: "playlist",
                    playlistInfo: playlistInfo
                }
                tidalApi.getPlaylistTracks(playlistInfo.id)
                break
                
            case "queue":
                console.log("AdvancedPlayManager: Queue playlist", playlistInfo.id)
                playlistManager.playPlaylist(playlistInfo.id, false)
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
                console.log("AdvancedPlayManager: Replace playlist with mix", mixInfo.id)
                playlistManager.clearPlayList()
                playlistManager.playMix(mixInfo.id, true)
                break
                
            case "append":
                console.log("AdvancedPlayManager: Append mix and play", mixInfo.id)
                playlistManager.playMix(mixInfo.id, true)
                break
                
            case "playnow":
                console.log("AdvancedPlayManager: Play mix now, keep current", mixInfo.id)
                // For play now, we need to insert tracks after current position
                pendingPlayNowAction = {
                    type: "mix",
                    mixInfo: mixInfo
                }
                tidalApi.getMixTracks(mixInfo.id)
                break
                
            case "queue":
                console.log("AdvancedPlayManager: Queue mix", mixInfo.id)
                playlistManager.playMix(mixInfo.id, false)
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
    
    // Helper function to get first track ID from album (cache lookup)
    function getFirstTrackFromCache(albumId) {
        // Try to find any track in cache that belongs to this album
        var allKeys = Object.keys(cacheManager.trackCache)
        for (var i = 0; i < allKeys.length; i++) {
            var trackInfo = cacheManager.getTrack(allKeys[i])
            if (trackInfo && trackInfo.albumid && trackInfo.albumid.toString() === albumId.toString()) {
                return trackInfo.trackid
            }
        }
        return null
    }
    
    // Collection for "play now" tracks
    property var playNowTracks: []
    
    // Handle track collection for "play now" actions
    Connections {
        target: tidalApi
        
        onAlbumTrackAdded: {
            if (pendingPlayNowAction && pendingPlayNowAction.type === "album") {
                playNowTracks.push(track_info.trackid)
                // Restart timer to wait for more tracks
                playNowTimer.restart()
            }
        }
        
        onPlaylistTrackAdded: {
            if (pendingPlayNowAction && pendingPlayNowAction.type === "playlist") {
                playNowTracks.push(track_info.trackid)
                playNowTimer.restart()
            }
        }
        
        onMixTrackAdded: {
            if (pendingPlayNowAction && pendingPlayNowAction.type === "mix") {
                playNowTracks.push(track_info.trackid)
                playNowTimer.restart()
            }
        }
    }
    
    // Timer to execute "play now" after tracks are collected
    Timer {
        id: playNowTimer
        interval: 500  // Wait 500ms after last track
        repeat: false
        onTriggered: {
            if (pendingPlayNowAction && playNowTracks.length > 0) {
                console.log("AdvancedPlayManager: Executing play now with", playNowTracks.length, "tracks")
                executePlayNowAction(playNowTracks)
                
                // Reset state
                pendingPlayNowAction = null
                playNowTracks = []
            }
        }
    }
    
    // Execute the actual "play now" logic
    function executePlayNowAction(trackIds) {
        var currentIndex = playlistManager.currentIndex
        console.log("AdvancedPlayManager: Inserting", trackIds.length, "tracks after position", currentIndex)
        
        // Insert tracks in reverse order to maintain order
        // (each insertTrack inserts at currentIndex + 1, so reverse order keeps correct sequence)
        for (var i = trackIds.length - 1; i >= 0; i--) {
            playlistManager.insertTrack(trackIds[i])
        }
        
        // Play first inserted track (now at currentIndex + 1)
        playlistManager.playPosition(currentIndex + 1)
    }

    Component.onCompleted: {
        console.log("AdvancedPlayManager: Initialized with default action:", applicationWindow.settings.defaultPlayAction)
    }
}