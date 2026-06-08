import QtQuick 2.0
import QtFeedback 5.0

Item {
    id: root

    // Properties (gleiche Interface wie aktueller PlaylistManager)
    property int currentIndex: -1
    property bool canNext: playlist.length > 0 && currentIndex < playlist.length - 1
    property bool canPrev: currentIndex > 0
    property int size: playlist.length
    property int current_track: -1
    property int tidalId: 0
    property bool skipTrack: false

    // True while a collection (album/playlist/mix/...) is being fetched
    // from the backend. MediaHandler uses this to avoid prematurely
    // declaring the playlist finished when a track ends before the
    // remaining items have been appended.
    property bool isLoadingCollection: false
    
    // Playlist statistics - Claude Generated
    property int totalTracks: playlist.length
    property int totalDurationSeconds: 0
    property string totalDurationFormatted: "00:00"
    property int currentTrackPosition: currentIndex + 1  // 1-based for UI
    property string playlistProgress: currentTrackPosition + " / " + totalTracks

    // Core playlist data (ersetzt Python-Array)
    property var playlist: []

    // Signals (kompatibel mit aktueller Implementation)
    signal currentTrackChanged(var track)
    signal trackInformation(int id, int index, string title, string album, string artist, string image, int duration)
    signal currentId(int id)
    signal currentPosition(int position)
    signal containsTrack(int id)
    signal clearList()
    signal currentTrack(int position)
    signal selectedTrackChanged(var trackinfo)
    signal playlistFinished()
    signal listChanged()

    // Timers
    Timer {
        id: updateTimer
        interval: 1000
        repeat: false
        onTriggered: {
            playlistStorage.loadCurrentPlaylistState()
        }
    }

    Timer {
        id: skipTrackGracePeriod
        interval: 5000
        repeat: false
        onTriggered: {
            skipTrack = false
        }
    }

    ThemeEffect {
        id: buttonEffect
        effect: ThemeEffect.PressStrong
    }

    // Check if user is authenticated for playlist operations
    function isAuthenticated() {
        return applicationWindow.settings.access_token && 
               applicationWindow.settings.refresh_token &&
               applicationWindow.settings.access_token !== "" &&
               applicationWindow.settings.refresh_token !== ""
    }

    // Private Methods
    function _notifyPlaylistState() {
        var isLastTrack = currentIndex >= playlist.length - 1
        size = playlist.length
        
        if (isLastTrack && playlist.length > 0) {
            playlistFinished()
        }
        
        listChanged()
    }

    function _notifyCurrentTrack() {
        if (currentIndex >= 0 && currentIndex < playlist.length) {
            var trackId = playlist[currentIndex]
            currentTrackChanged(trackId)
            currentId(trackId)
            currentTrack(currentIndex)
        }
    }

    function _getTrackInfo(trackId) {
        return cacheManager.getTrackInfo(trackId)
    }

    // Core Playlist Methods (ersetzt Python-Logik)
    function appendTrack(trackId) {
        if (applicationWindow.settings && applicationWindow.settings.debugLevel >= 1)
            console.log('PlaylistManager.appendTrack', trackId)
        
        // Check authentication before allowing playlist modifications
        if (!isAuthenticated()) {
            if (applicationWindow.settings.debugLevel >= 1) {
                console.log("PlaylistManager: Cannot add track - not authenticated")
            }
            applicationWindow.showWarningNotification(qsTr("Login Required"), qsTr("Please log in to manage playlists"))
            return false
        }
        
        if (trackId) {
            playlist.push(trackId)
            updatePlaylistStatistics()
            _notifyPlaylistState()
            canNext = true
        }
        return true
    }

    function appendTrackSilent(trackId) {
        if (applicationWindow.settings && applicationWindow.settings.debugLevel >= 1)
            console.log('PlaylistManager.appendTrackSilent', trackId)
        if (trackId) {
            playlist.push(trackId)
            canNext = true
        }
    }

    function appendTracksBatch(trackIds) {
        if (applicationWindow.settings && applicationWindow.settings.debugLevel >= 1)
            console.log('PlaylistManager.appendTracksBatch', trackIds.length, 'tracks')
        if (trackIds && trackIds.length > 0) {
            // Optimized: Add all tracks at once instead of one by one
            playlist = playlist.concat(trackIds)
            updatePlaylistStatistics()
            _notifyPlaylistState()
            canNext = playlist.length > 0 && currentIndex < playlist.length - 1
        }
    }

    // Insert a list of tracks immediately after currentIndex (used by play_now).
    // Existing tail tracks are preserved after the inserted block.
    function insertTracksBatch(trackIds) {
        if (applicationWindow.settings && applicationWindow.settings.debugLevel >= 1)
            console.log('PlaylistManager.insertTracksBatch', trackIds ? trackIds.length : 0, 'tracks')
        if (!trackIds || trackIds.length === 0) return
        var insertPos = Math.max(0, currentIndex + 1)
        var head = playlist.slice(0, insertPos)
        var tail = playlist.slice(insertPos)
        playlist = head.concat(trackIds).concat(tail)
        updatePlaylistStatistics()
        _notifyPlaylistState()
        canNext = playlist.length > 0 && currentIndex < playlist.length - 1
    }

    function insertTrack(trackId) {
        if (applicationWindow.settings && applicationWindow.settings.debugLevel >= 1)
            console.log('PlaylistManager.insertTrack', trackId)
        if (trackId) {
            var insertPos = Math.max(0, currentIndex + 1)
            playlist.splice(insertPos, 0, trackId)
            updatePlaylistStatistics()
            _notifyPlaylistState()
            _notifyCurrentTrack()
        }
    }

    function removeTrack(trackId) {
        if (applicationWindow.settings && applicationWindow.settings.debugLevel >= 1)
            console.log('PlaylistManager.removeTrack', trackId)
        if (trackId) {
            var index = playlist.indexOf(trackId)
            if (index >= 0) {
                playlist.splice(index, 1)
                
                // Adjust currentIndex if necessary
                if (index < currentIndex) {
                    currentIndex--
                } else if (index === currentIndex && currentIndex >= playlist.length) {
                    currentIndex = playlist.length - 1
                }
                
                updatePlaylistStatistics()
                _notifyPlaylistState()
            }
        }
    }

    function moveTrack(fromIndex, toIndex, silent) {
        if (applicationWindow.settings && applicationWindow.settings.debugLevel >= 1)
            console.log('PlaylistManager.moveTrack', 'from:', fromIndex, 'to:', toIndex)
        
        // Validate indices
        if (fromIndex < 0 || fromIndex >= playlist.length || toIndex < 0 || toIndex >= playlist.length) {
            if (applicationWindow.settings && applicationWindow.settings.debugLevel >= 1)
                console.log('PlaylistManager.moveTrack: Invalid indices')
            return false
        }
        
        // If indices are the same, do nothing
        if (fromIndex === toIndex) {
            return true
        }
        
        // Get the track ID being moved
        var trackId = playlist[fromIndex]
        
        // Remove from original position
        playlist.splice(fromIndex, 1)
        
        // Insert at new position
        playlist.splice(toIndex, 0, trackId)
        
        // Adjust currentIndex if the currently playing track was moved
        if (currentIndex === fromIndex) {
            currentIndex = toIndex
        } else if (fromIndex < currentIndex && toIndex >= currentIndex) {
            // Moving a track before current towards the end
            currentIndex--
        } else if (fromIndex > currentIndex && toIndex <= currentIndex) {
            // Moving a track after current towards the beginning
            currentIndex++
        }
        
        updatePlaylistStatistics()
        if (!silent)
          _notifyPlaylistState()
        
        return true
    }

    function playTrack(trackId) {
        if (applicationWindow.settings && applicationWindow.settings.debugLevel >= 1)
            console.log('Playlistmanager::playtrack', trackId)
        
        // Check authentication before allowing track playback
        if (!isAuthenticated()) {
            if (applicationWindow.settings.debugLevel >= 1) {
                console.log("PlaylistManager: Cannot play track - not authenticated")
            }
            applicationWindow.showWarningNotification(qsTr("Login Required"), qsTr("Please log in to play music"))
            return false
        }
        
        if (trackId) {
            mediaController.blockAutoNext = true
            var insertPos = Math.max(0, currentIndex + 1)
            playlist.splice(insertPos, 0, trackId)
            currentIndex = insertPos
            updatePlaylistStatistics()
            _notifyPlaylistState()
            _notifyCurrentTrack()
        }
        return true
    }

    function nextTrack() {
        if (applicationWindow.settings && applicationWindow.settings.debugLevel >= 1)
            console.log('Next track called', mediaController.playbackState)
        if (currentIndex < playlist.length - 1) {
            currentIndex++
            _notifyCurrentTrack()
            
            // Save progress
            if (playlistStorage.playlistTitle) {
                playlistStorage.updatePosition(playlistStorage.playlistTitle, currentIndex)
            }
        }
    }

    function previousTrack() {
        if (currentIndex > 0) {
            currentIndex--
            _notifyCurrentTrack()
            
            // Save progress
            if (playlistStorage.playlistTitle) {
                playlistStorage.updatePosition(playlistStorage.playlistTitle, currentIndex)
            }
        }
    }

    function playPosition(position) {
        try {
            position = parseInt(position)
            if (position >= 0 && position < playlist.length) {
                mediaController.blockAutoNext = true
                currentIndex = position
                _notifyCurrentTrack()
                
                // Save progress
                if (playlistStorage.playlistTitle) {
                    playlistStorage.updatePosition(playlistStorage.playlistTitle, position)
                }
            }
        } catch (e) {
            if (applicationWindow.settings && applicationWindow.settings.debugLevel >= 1)
                console.log('Invalid position value:', position)
        }
    }

    function restartTrack() {
        _notifyCurrentTrack()
        mediaController.seek(0)
    }

    function clearPlayList() {
        if (applicationWindow.settings && applicationWindow.settings.debugLevel >= 1)
            console.log('Clear list invoked')
        currentIndex = -1
        playlist = []
        clearList()
        _notifyPlaylistState()
        
        if (playlistStorage.playlistTitle !== '_current') {
            playlistStorage.loadCurrentPlaylistState()
        }
    }

    function forceClearPlayList() {
        if (applicationWindow.settings && applicationWindow.settings.debugLevel >= 1)
            console.log('Force Clear list invoked')
        currentIndex = -1
        playlist = []
        clearList()
        _notifyPlaylistState()
    }

    // Public API Methods (kompatibel mit aktueller Implementation)
    function getSize() {
        return playlist.length
    }

    function requestPlaylistItem(index) {
        try {
            index = parseInt(index)
            if (index >= 0 && index < playlist.length) {
                tidalId = playlist[index]
                return playlist[index]
            }
        } catch (e) {
            if (applicationWindow.settings && applicationWindow.settings.debugLevel >= 1)
                console.log('Invalid index:', index)
        }
        return 0
    }

    function currentTrackIndex() {
        return currentIndex
    }

    function generateList() {
        if (applicationWindow.settings && applicationWindow.settings.debugLevel >= 1)
            console.log('Generate current playlist view, size:', playlist.length)
        // Just trigger list changed - TrackList will populate itself via updateTimer
        listChanged()
    }

    // Navigation Functions with feedback
    function doFeedback() {
        buttonEffect.play()
    }

    function nextTrackClicked() {
        if (applicationWindow.settings && applicationWindow.settings.debugLevel >= 1)
            console.log('Next track clicked')
        mediaController.blockAutoNext = true
        nextTrack()
        mediaController.blockAutoNext = false
    }

    function previousTrackClicked() {
        // First press should restart current track
        if (!skipTrack || !canPrev) {
            restartTrack()
            skipTrack = true
            skipTrackGracePeriod.restart()
            return
        }

        // Second press within grace period goes to previous
        mediaController.blockAutoNext = true
        previousTrack()
    }

    function setTrack(index) {
        if (applicationWindow.settings && applicationWindow.settings.debugLevel >= 1)
            console.log('Playlistmanager::settrack', index)
        var trackId = requestPlaylistItem(index)
        currentIndex = index
        if (applicationWindow.settings && applicationWindow.settings.debugLevel >= 1)
            console.log('trackId:', trackId)
        
        playlistStorage.updatePosition(playlistStorage.playlistTitle, index)
        var track = cacheManager.getTrackInfo(trackId)
        trackInformation(trackId, index, track[1], track[2], track[3], track[4], track[5])
        selectedTrackChanged(track)
    }

    // ----- Unified collection API ------------------------------------------
    // Four verbs per item type:
    //   replaceWith<X>(id)  - clear queue, load X, play from start
    //   append<X>(id)       - load X to end of queue, no playback change
    //   playNow<X>(id)      - insert X after current, play first inserted
    //   queue<X>(id)        - alias of append<X>
    //
    // Internally all of them go through _loadCollection(), which sets
    // isLoadingCollection and dispatches to the matching tidalApi loader.
    // The TidalApi 'playlist_load' handler applies the mode atomically once
    // all tracks have arrived, so nextTrack() can never race against an
    // incomplete queue.

    function _loadCollection(kind, id, mode) {
        if (!isAuthenticated()) {
            applicationWindow.showWarningNotification(
                qsTr("Login Required"),
                qsTr("Please log in to play music"))
            return
        }
        doFeedback()
        if (applicationWindow.settings.debugLevel >= 1) {
            console.log("PlaylistManager._loadCollection", kind, id, "mode=" + mode)
        }
        isLoadingCollection = true
        tidalApi.loadCollection(kind, id, mode)
    }

    // Apply a batch payload received from the backend (via TidalApi's
    // playlist_load handler). Owns the mode->operation dispatch so that the
    // wire-format layer doesn't need to know about playlist internals.
    // payload: { source, source_id, mode, track_ids, start_track_id }
    function applyLoad(payload) {
        var trackIds = payload.track_ids || []
        if (applicationWindow.settings.debugLevel >= 1) {
            console.log("PlaylistManager.applyLoad:", payload.source,
                        "mode=" + payload.mode,
                        "count=" + trackIds.length,
                        "start=" + payload.start_track_id)
        }
        if (trackIds.length === 0) {
            isLoadingCollection = false
            return
        }
        var mode = payload.mode || "replace"
        var startTrackId = payload.start_track_id || ""

        if (mode === "replace") {
            var startIdx = 0
            if (startTrackId) {
                for (var i = 0; i < trackIds.length; i++) {
                    if (trackIds[i].toString() === startTrackId.toString()) {
                        startIdx = i
                        break
                    }
                }
            }
            _replaceWithTracks(trackIds, startIdx)
        } else if (mode === "append" || mode === "queue") {
            var firstAppendedIdx = playlist.length
            var queueWasIdle = currentIndex < 0
            appendTracksBatch(trackIds)
            if (queueWasIdle && applicationWindow.settings.autoPlayOnAppendWhenIdle) {
                playPosition(firstAppendedIdx)
            }
        } else if (mode === "play_now") {
            var pnInsertIdx = currentIndex + 1
            insertTracksBatch(trackIds)
            playPosition(pnInsertIdx)
        } else if (mode === "play_next") {
            insertTracksBatch(trackIds)
        }

        isLoadingCollection = false
    }

    // Atomic replace: clear queue, swap in tracks, jump to startIdx. The
    // storage-side clearList() listeners still fire so the auto-saved
    // playlist is reset, but we emit only a single listChanged() for the
    // final state instead of three (clear + append + jump) like a naive
    // sequence of forceClearPlayList + appendTracksBatch + playPosition.
    function _replaceWithTracks(trackIds, startIdx) {
        currentIndex = -1
        playlist = trackIds.slice()
        clearList()
        updatePlaylistStatistics()
        _notifyPlaylistState()
        playPosition(startIdx)
    }

    // --- single track ---
    function replaceWithTrack(trackId) {
        if (!isAuthenticated() || !trackId) return
        doFeedback()
        forceClearPlayList()
        appendTrack(trackId)
        playPosition(0)
    }
    // appendTrack() and playTrack() already exist above and stay.
    function queueTrack(trackId) { appendTrack(trackId) }
    function playNowTrack(trackId) { playTrack(trackId) }
    // Play-next single track: insert after current without interrupting it.
    function playNextTrack(trackId) {
        if (!isAuthenticated() || !trackId) return
        insertTracksBatch([trackId])
    }

    // --- album ---
    function replaceWithAlbum(id)  { _loadCollection("album", id, "replace") }
    function appendAlbum(id)       { _loadCollection("album", id, "append") }
    function playNowAlbum(id)      { _loadCollection("album", id, "play_now") }
    function playNextAlbum(id)     { _loadCollection("album", id, "play_next") }
    function queueAlbum(id)        { _loadCollection("album", id, "queue") }

    // --- album from track (play the album that contains trackId, starting at it) ---
    function replaceWithAlbumFromTrack(trackId) {
        _loadCollection("album_from_track", trackId, "replace")
    }

    // --- playlist ---
    function replaceWithPlaylist(id) { _loadCollection("playlist", id, "replace") }
    function appendPlaylist(id)      { _loadCollection("playlist", id, "append") }
    function playNowPlaylist(id)     { _loadCollection("playlist", id, "play_now") }
    function playNextPlaylist(id)    { _loadCollection("playlist", id, "play_next") }
    function queuePlaylist(id)       { _loadCollection("playlist", id, "queue") }

    // --- mix ---
    function replaceWithMix(id) { _loadCollection("mix", id, "replace") }
    function appendMix(id)      { _loadCollection("mix", id, "append") }
    function playNowMix(id)     { _loadCollection("mix", id, "play_now") }
    function playNextMix(id)    { _loadCollection("mix", id, "play_next") }
    function queueMix(id)       { _loadCollection("mix", id, "queue") }

    // --- artist top tracks ---
    function replaceWithArtistTopTracks(id) { _loadCollection("artist_top", id, "replace") }
    function appendArtistTopTracks(id)      { _loadCollection("artist_top", id, "append") }
    function playNowArtistTopTracks(id)     { _loadCollection("artist_top", id, "play_now") }
    function playNextArtistTopTracks(id)    { _loadCollection("artist_top", id, "play_next") }
    function queueArtistTopTracks(id)       { _loadCollection("artist_top", id, "queue") }

    // --- artist radio ---
    function replaceWithArtistRadio(id) { _loadCollection("artist_radio", id, "replace") }
    function appendArtistRadio(id)      { _loadCollection("artist_radio", id, "append") }
    function playNowArtistRadio(id)     { _loadCollection("artist_radio", id, "play_now") }
    function playNextArtistRadio(id)    { _loadCollection("artist_radio", id, "play_next") }
    function queueArtistRadio(id)       { _loadCollection("artist_radio", id, "queue") }

    // Playlist Storage Integration
    function saveCurrentPlaylist(name) {
        var trackIds = playlist.slice() // Copy array
        playlistStorage.savePlaylist(name, trackIds, currentIndex)
        playlistStorage.playlistTitle = name
    }

    function loadSavedPlaylist(name) {
        if (applicationWindow.settings && applicationWindow.settings.debugLevel >= 1)
            console.log('Load playlist', name)
        playlistStorage.loadPlaylist(name)
    }

    function deleteSavedPlaylist(name) {
        playlistStorage.deletePlaylist(name)
    }

    function getSavedPlaylists() {
        return playlistStorage.getPlaylistInfo()
    }
    
    // Resume synchronization - find track in current playlist and sync index
    function syncCurrentTrack(trackId) {
        if (settings.debugLevel >= 1) {
            console.log("PLAYLIST: Syncing current track", trackId, "in playlist of size", playlist.length)
        }
        
        // Find track in current playlist
        for (var i = 0; i < playlist.length; i++) {
            if (playlist[i].toString() === trackId.toString()) {
                if (settings.debugLevel >= 1) {
                    console.log("PLAYLIST: Found track at index", i, "updating currentIndex")
                }
                currentIndex = i
                
                // Trigger UI updates
                canNext = (i < playlist.length - 1)
                canPrev = (i > 0)
                
                if (settings.debugLevel >= 1) {
                    console.log("PLAYLIST: Sync complete - canNext:", canNext, "canPrev:", canPrev)
                }
                return true
            }
        }
        
        if (settings.debugLevel >= 1) {
            console.log("PLAYLIST: Track not found in current playlist, loading auto-saved playlist")
        }
        
        // Track not in current playlist - try loading auto-saved playlist
        playlistStorage.loadCurrentPlaylistState()
        return false
    }
    
    // Calculate total playlist duration - Claude Generated
    function updatePlaylistStatistics() {
        totalTracks = playlist.length
        var totalSeconds = 0
        
        for (var i = 0; i < playlist.length; i++) {
            var trackId = playlist[i]
            var trackInfo = cacheManager.getTrackInfo(trackId)
            if (trackInfo && trackInfo.duration) {
                totalSeconds += trackInfo.duration
            }
        }
        
        totalDurationSeconds = totalSeconds
        totalDurationFormatted = formatDuration(totalSeconds)
        
        if (settings.debugLevel >= 2) {
            console.log("PLAYLIST: Statistics updated - tracks:", totalTracks, "duration:", totalDurationFormatted)
        }
    }
    
    // Format duration in MM:SS or HH:MM:SS
    function formatDuration(seconds) {
        if (isNaN(seconds) || seconds < 0) return "00:00"
        
        var hours = Math.floor(seconds / 3600)
        var minutes = Math.floor((seconds % 3600) / 60)
        var secs = Math.floor(seconds % 60)
        
        if (hours > 0) {
            return hours + ":" + ("00" + minutes).slice(-2) + ":" + ("00" + secs).slice(-2)
        } else {
            return minutes + ":" + ("00" + secs).slice(-2)
        }
    }

    // Login state connection to trigger auto-load after login
    Connections {
        target: tidalApi
        onLoginSuccess: {
            if (applicationWindow.settings && applicationWindow.settings.debugLevel >= 1)
                console.log('Login successful, attempting auto-load playlist')
            // Small delay to ensure all settings are loaded
            autoLoadTimer.start()
        }
    }
    
    Timer {
        id: autoLoadTimer
        interval: 500  // 500ms delay after login
        repeat: false
        onTriggered: {
            playlistStorage.loadCurrentPlaylistState()
        }
    }

    // Component lifecycle
    Component.onCompleted: {
        if (applicationWindow.settings && applicationWindow.settings.debugLevel >= 1)
            console.log('Pure QML PlaylistManager loaded')
        // Don't auto-load immediately - wait for login success instead
        // updateTimer.start()
    }
}
