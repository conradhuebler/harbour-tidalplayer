import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: advancedPlayManager

    // ADVANCED PLAY LOGIC: Handles different play actions for tracks/albums/playlists.
    // All actions go through the unified PlaylistManager verbs - the backend now
    // emits one atomic 'playlist_load' signal per collection, so the previous
    // signal-collection + 500ms timer workaround for "play now" is no longer
    // needed.

    // Available play actions.
    // Four user-facing verbs, matching the PlaylistManager API:
    //   replace  — clear queue, play this from the start
    //   playnow  — insert after current and start it immediately
    //   playnext — insert after current; current track keeps playing
    //   append   — add to the end of the queue; only auto-starts if
    //              autoPlayOnAppendWhenIdle is enabled and queue is idle
    // "queue" is a backwards-compat alias of "append" (same entry, set below).
    readonly property var playActions: (function() {
        var a = {
            "replace": {
                name: qsTr("Replace Playlist & Play"),
                description: qsTr("Clear current playlist and play this item"),
                icon: "image://theme/icon-m-play"
            },
            "playnow": {
                name: qsTr("Play Now"),
                description: qsTr("Interrupt the current track and play this immediately"),
                icon: "image://theme/icon-m-play"
            },
            "playnext": {
                name: qsTr("Play Next"),
                description: qsTr("Queue this to play right after the current track"),
                icon: "image://theme/icon-m-forward"
            },
            "append": {
                name: qsTr("Add to Playlist"),
                description: qsTr("Add to the end of the playlist"),
                icon: "image://theme/icon-m-add"
            }
        }
        a["queue"] = a["append"]
        return a
    })()

    // Signals for different content types
    signal playTrack(string trackId, string action)
    signal playAlbum(var albumInfo, string action)
    signal playPlaylist(var playlistInfo, string action)
    signal playArtistTopTracks(string artistId, string action)
    signal playMix(var mixInfo, string action)

    // --- track ---
    function executeTrackAction(trackId, action) {
        console.log("AdvancedPlayManager: track action", action, trackId)
        switch (action) {
        case "replace":  playlistManager.replaceWithTrack(trackId); break
        case "playnow":  playlistManager.playNowTrack(trackId); break
        case "playnext": playlistManager.playNextTrack(trackId); break
        case "append":   playlistManager.appendTrack(trackId); break
        case "queue":    playlistManager.queueTrack(trackId); break
        }
        playTrack(trackId, action)
    }

    // --- album ---
    function executeAlbumAction(albumInfo, action) {
        console.log("AdvancedPlayManager: album action", action, albumInfo.id)
        switch (action) {
        case "replace":  playlistManager.replaceWithAlbum(albumInfo.id); break
        case "playnow":  playlistManager.playNowAlbum(albumInfo.id); break
        case "playnext": playlistManager.playNextAlbum(albumInfo.id); break
        case "append":   playlistManager.appendAlbum(albumInfo.id); break
        case "queue":    playlistManager.queueAlbum(albumInfo.id); break
        }
        playAlbum(albumInfo, action)
    }

    // --- playlist ---
    function executePlaylistAction(playlistInfo, action) {
        console.log("AdvancedPlayManager: playlist action", action, playlistInfo.id)
        switch (action) {
        case "replace":  playlistManager.replaceWithPlaylist(playlistInfo.id); break
        case "playnow":  playlistManager.playNowPlaylist(playlistInfo.id); break
        case "playnext": playlistManager.playNextPlaylist(playlistInfo.id); break
        case "append":   playlistManager.appendPlaylist(playlistInfo.id); break
        case "queue":    playlistManager.queuePlaylist(playlistInfo.id); break
        }
        playPlaylist(playlistInfo, action)
    }

    // --- artist top tracks ---
    function executeArtistAction(artistInfo, action) {
        console.log("AdvancedPlayManager: artist action", action, artistInfo.id)
        switch (action) {
        case "replace":  playlistManager.replaceWithArtistTopTracks(artistInfo.id); break
        case "playnow":  playlistManager.playNowArtistTopTracks(artistInfo.id); break
        case "playnext": playlistManager.playNextArtistTopTracks(artistInfo.id); break
        case "append":   playlistManager.appendArtistTopTracks(artistInfo.id); break
        case "queue":    playlistManager.queueArtistTopTracks(artistInfo.id); break
        }
        playArtistTopTracks(artistInfo.id, action)
    }

    // --- mix ---
    function executeMixAction(mixInfo, action) {
        console.log("AdvancedPlayManager: mix action", action, mixInfo.id)
        switch (action) {
        case "replace":  playlistManager.replaceWithMix(mixInfo.id); break
        case "playnow":  playlistManager.playNowMix(mixInfo.id); break
        case "playnext": playlistManager.playNextMix(mixInfo.id); break
        case "append":   playlistManager.appendMix(mixInfo.id); break
        case "queue":    playlistManager.queueMix(mixInfo.id); break
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

    // Generic dispatcher: routes (contentType, contentInfo, action) to the
    // matching execute*Action method. Tracks pass either an id string or an
    // object with .id/.trackid; collections always pass an info object whose
    // .id is the resource id.
    function executeAction(contentType, contentInfo, action) {
        switch (contentType) {
        case "track":
            var tid = (typeof contentInfo === 'object')
                ? (contentInfo.id || contentInfo.trackid) : contentInfo
            executeTrackAction(tid, action); break
        case "album":    executeAlbumAction(contentInfo, action); break
        case "playlist": executePlaylistAction(contentInfo, action); break
        case "artist":   executeArtistAction(contentInfo, action); break
        case "mix":      executeMixAction(contentInfo, action); break
        default:
            console.log("AdvancedPlayManager.executeAction: unknown type", contentType)
        }
    }

    // Quick action - uses default setting
    function quickPlay(contentInfo, contentType) {
        var defaultAction = applicationWindow.settings.defaultPlayAction || "replace"
        console.log("AdvancedPlayManager: Quick play with default action", defaultAction)
        executeAction(contentType, contentInfo, defaultAction)
    }

    function getActionInfo(action) {
        return playActions[action] || playActions["replace"]
    }

    Component.onCompleted: {
        console.log("AdvancedPlayManager: Initialized with default action:", applicationWindow.settings.defaultPlayAction)
    }
}
