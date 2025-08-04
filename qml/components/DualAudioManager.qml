import QtQuick 2.0
import QtMultimedia 5.6

// Dual Audio Player Manager for seamless transitions - Claude Generated
Item {
    id: dualManager
    
    // Properties
    property bool preloadingEnabled: false
    property bool player1Active: true
    property double playerVolume: 1.0
    property double trackVolume: 1.0
    
    // Crossfade modes: 0=No Fade, 1=Timer Fade, 2=Buffer Dependent Fade, 3=Buffer Fade-Out Only
    property int crossfadeMode: 1  // Default: Timer Fade
    property int crossfadeTimeMs: 1000  // Configurable fade time
    
    // Volume control for crossfading (avoid binding loops)
    property real player1Volume: player1Active ? (playerVolume * trackVolume) : 0.0
    property real player2Volume: !player1Active ? (playerVolume * trackVolume) : 0.0
    
    // Preload state
    property string nextTrackUrl: ""
    property string nextTrackId: ""
    property bool preloadInProgress: false
    
    // Current track info
    property string currentTrackId: ""
    property string currentTrackUrl: ""
    
    // Signals for MediaHandler
    signal positionChanged(real position, real duration)
    signal durationChanged(real duration)
    signal playbackStateChanged(int state)
    signal trackFinished()
    signal preloadReady()
    signal playerError(string error)
    signal trackInfoChanged()
    
    // Active player reference
    readonly property AudioPlayerComponent activePlayer: player1Active ? audioPlayer1 : audioPlayer2
    readonly property AudioPlayerComponent inactivePlayer: player1Active ? audioPlayer2 : audioPlayer1
    
    // Timer for track info updates
    Timer {
        id: trackInfoUpdateTimer
        interval: 50
        repeat: false
        onTriggered: trackInfoChanged()
    }
    
    // Timer for crossfade fade-out
    Timer {
        id: fadeOutTimer
        interval: 200  // 200ms overlap
        repeat: false
        onTriggered: {
            console.log("DualAudioManager: Crossfade - fading out old player")
            // The old player is now the inactive one after the switch
            // Set its volume to normal inactive level (which is 0.0 from the volume binding)
            // The volume binding will handle this automatically
            console.log("DualAudioManager: Crossfade complete")
        }
    }
    
    // Timer for crossfade modes
    Timer {
        id: crossfadeTimer
        interval: 10  // Update every 50ms for smooth transition
        repeat: true
        running: false
        
        property real fadeStartTime: 0
        property bool player1WasActive: true  // Remember which player was active before switch
        
        onTriggered: {
            if (crossfadeMode === 0) {
                // No fade - just stop
                stop()
                return
            }
            
            var elapsed = Date.now() - fadeStartTime
            var progress = Math.min(elapsed / crossfadeTimeMs, 1.0)
            
            if (crossfadeMode === 1) {
                // Timer-based fade out
                var fadeVolume = (1.0 - progress) * (playerVolume * trackVolume)
                var fullVolume = playerVolume * trackVolume
                
                if (player1WasActive) {
                    // Player1 was active, now fading out. Player2 is new active player
                    audioPlayer1.volume = Math.max(0.0, fadeVolume)  // Fade out old player
                    audioPlayer2.volume = fullVolume  // New player at full volume
                } else {
                    // Player2 was active, now fading out. Player1 is new active player  
                    audioPlayer2.volume = Math.max(0.0, fadeVolume)  // Fade out old player
                    audioPlayer1.volume = fullVolume  // New player at full volume
                }
                
                console.log("DualAudioManager: Timer fade - progress:", progress.toFixed(2), "oldVolume:", fadeVolume.toFixed(2), "newVolume:", fullVolume.toFixed(2))
            }
            else if (crossfadeMode === 2) {
                // Buffer-dependent crossfade (fade old, play new)
                var bufferProgress = activePlayer.getBufferProgress()  // Check new active player buffer
                var fadeVolume = Math.max(0.0, (1.0 - bufferProgress) * (playerVolume * trackVolume))
                var fullVolume = playerVolume * trackVolume
                
                if (player1WasActive) {
                    // Player1 was active, now fading out based on Player2 buffer
                    audioPlayer1.volume = fadeVolume  // Fade based on new track buffer
                    audioPlayer2.volume = fullVolume  // New player at full volume
                } else {
                    // Player2 was active, now fading out based on Player1 buffer
                    audioPlayer2.volume = fadeVolume  // Fade based on new track buffer
                    audioPlayer1.volume = fullVolume  // New player at full volume
                }
                
                console.log("DualAudioManager: Buffer crossfade - buffer:", bufferProgress.toFixed(2), "oldVolume:", fadeVolume.toFixed(2), "newVolume:", fullVolume.toFixed(2))
                
                // Complete when fully buffered
                if (bufferProgress >= 1.0) {
                    progress = 1.0
                }
            }
            else if (crossfadeMode === 3) {
                // Buffer-dependent fade-out only (don't start new track)
                var bufferProgress = inactivePlayer.getBufferProgress()  // Check buffer of track waiting to play
                var fadeVolume = Math.max(0.0, (1.0 - bufferProgress) * (playerVolume * trackVolume))
                console.log(bufferProgress)
                if (player1WasActive) {
                    // Player1 was active, fading out based on Player2 buffer, Player2 stays silent
                    audioPlayer1.volume = fadeVolume  // Fade out based on buffer progress
                    audioPlayer2.volume = 0.0  // Keep new player silent
                } else {
                    // Player2 was active, fading out based on Player1 buffer, Player1 stays silent  
                    audioPlayer2.volume = fadeVolume  // Fade out based on buffer progress
                    audioPlayer1.volume = 0.0  // Keep new player silent
                }
                
                console.log("DualAudioManager: Buffer fade-out only - buffer:", bufferProgress.toFixed(2), "fadeVolume:", fadeVolume.toFixed(2), "originalVolume:", (playerVolume * trackVolume).toFixed(2))
                
                // Complete when fully buffered (track is ready but we don't start it)
                if (bufferProgress >= 1.0) {
                    console.log("DualAudioManager: Buffer fade-out complete - track ready but not started")
                    progress = 1.0
                }
            }
            
            // Complete fade
            if (progress >= 1.0) {
                console.log("DualAudioManager: Crossfade complete")
                stop()
                
                if (crossfadeMode === 3) {
                    // Buffer fade-out only mode - now start the new track
                    console.log("DualAudioManager: Fade-out complete, starting new track")
                    activePlayer.startPlayback()
                    
                    // Set correct volumes: active player full, inactive player silent
                    var fullVolume = playerVolume * trackVolume
                    if (player1Active) {
                        audioPlayer1.volume = fullVolume
                        audioPlayer2.volume = 0.0
                    } else {
                        audioPlayer2.volume = fullVolume
                        audioPlayer1.volume = 0.0
                    }
                } else {
                    // Reset volumes to normal binding-controlled values
                    // The bindings will set the correct volumes based on player1Active
                    console.log("DualAudioManager: Volumes reset to binding control")
                }
            }
        }
        
        function startCrossfade() {
            if (crossfadeMode === 0) {
                console.log("DualAudioManager: No crossfade mode - instant switch")
                return  // No fade out
            }
            
            player1WasActive = !player1Active  // Store which player WAS active before switch
            fadeStartTime = Date.now()
            
            // Initialize volumes for crossfade
            var fullVolume = playerVolume * trackVolume
            if (crossfadeMode === 3) {
                // Buffer fade-out only mode - new player stays silent
                if (player1WasActive) {
                    audioPlayer1.volume = fullVolume  // Old player starts at full, will fade
                    audioPlayer2.volume = 0.0  // New player stays silent
                } else {
                    audioPlayer2.volume = fullVolume  // Old player starts at full, will fade
                    audioPlayer1.volume = 0.0  // New player stays silent
                }
            } else {
                // Normal crossfade modes - both players active
                if (player1WasActive) {
                    // Player1 was active, will fade out. Player2 is new, should be full volume
                    audioPlayer1.volume = fullVolume  // Start at full
                    audioPlayer2.volume = fullVolume  // New player at full
                } else {
                    // Player2 was active, will fade out. Player1 is new, should be full volume
                    audioPlayer2.volume = fullVolume  // Start at full
                    audioPlayer1.volume = fullVolume  // New player at full
                }
            }
            
            start()
            
            console.log("DualAudioManager: Starting crossfade mode", crossfadeMode, "duration:", crossfadeTimeMs + "ms")
        }
    }
    
    // Audio Player 1 with Playlist
    AudioPlayerComponent {
        id: audioPlayer1
        playerId: "Player1"
        isActive: player1Active
        hasPlaylist: true
        volume: player1Volume
        
        playlist: Playlist {
            id: playlistItem
            playbackMode: Playlist.Sequential
            
            onCurrentItemSourceChanged: {
                if (audioPlayer1.isActive && currentItemSource) {
                    console.log('DualAudioManager: Playlist track changed to:', currentItemSource)
                    currentTrackUrl = currentItemSource
                    // Notify that track info should be updated
                    trackInfoUpdateTimer.start()
                }
            }
            
            onItemInserted: function(start_index, end_index) {
                console.log('DualAudioManager: Items inserted:', start_index, '-', end_index)
            }
        }
        
        onPlayerPlaying: {
            if (isActive) {
                console.log("DualAudioManager: Player1 started playing")
                // Notify MediaHandler for MPRIS status update
                dualManager.playbackStateChanged(Audio.PlayingState)
            }
        }
        
        onPlayerPaused: {
            if (isActive) {
                console.log("DualAudioManager: Player1 paused")
                dualManager.playbackStateChanged(Audio.PausedState)
            }
        }
        
        onPlayerStopped: {
            if (isActive) {
                console.log("DualAudioManager: Player1 stopped")
                dualManager.playbackStateChanged(Audio.StoppedState)
                trackFinished()
            }
        }
        
        onPlayerError: {
            if (isActive) {
                dualManager.playerError(error)
            }
        }
        
        onPlayerPositionChanged: {
            if (isActive) {
                dualManager.positionChanged(position, duration)
                
                // Check for preload trigger
                if (preloadingEnabled && !preloadInProgress && duration > 0) {
                    var timeLeft = (duration - position) / 1000
                    if (timeLeft <= 10 && timeLeft > 0) {
                        console.log("DualAudioManager: Player1 - triggering preload")
                        triggerPreload()
                    }
                }
            }
        }
        
        onPlayerDurationChanged: {
            if (isActive) {
                dualManager.durationChanged(duration)
            }
        }
        
        onPlayerPlaybackStateChanged: {
            if (isActive) {
                dualManager.playbackStateChanged(state)
            }
        }
        
        onPlayerStatusChanged: {
            if (!isActive && status === Audio.Loaded && source === nextTrackUrl) {
                console.log("DualAudioManager: Player1 preload ready")
                preloadReady()
            }
            
            // Debug crossfade switching
            if (!isActive && status === Audio.Loaded) {
                console.log("DualAudioManager: Player1 loaded - checking crossfade conditions:")
                console.log("  - isActive:", isActive)
                console.log("  - status:", status, "(Audio.Loaded =", Audio.Loaded, ")")
                console.log("  - pendingImmediateSwitch:", pendingImmediateSwitch)
                console.log("  - source:", source)
                console.log("  - pendingSwitchUrl:", pendingSwitchUrl)
                console.log("  - URL match:", source === pendingSwitchUrl)
                console.log("  - source toString():", source.toString())
                console.log("  - pendingSwitchUrl toString():", pendingSwitchUrl.toString())
                console.log("  - URL match toString():", source.toString() === pendingSwitchUrl.toString())
            }
            
            // Handle immediate switching / crossfade
            if (!isActive && status === Audio.Loaded && pendingImmediateSwitch && source.toString() === pendingSwitchUrl.toString()) {
                console.log("DualAudioManager: Player1 ready for crossfade switch!")
                
                // Store reference to old active player for volume crossfade
                var oldActivePlayer = activePlayer
                
                // Switch immediately with crossfade
                player1Active = !player1Active
                currentTrackUrl = pendingSwitchUrl
                currentTrackId = pendingSwitchTrackId
                
                // Update playlist if switching to Player2 (so it matches the current track)
                updatePlaylistForCrossfade()
                
                // Start new player
                activePlayer.startPlayback()
                
                // Start crossfade based on mode
                crossfadeTimer.startCrossfade()
                
                // Clear pending switch
                pendingImmediateSwitch = false
                pendingSwitchUrl = ""
                pendingSwitchTrackId = ""
                
                // Notify track info update
                trackInfoUpdateTimer.start()
            }
        }
    }
    
    // Audio Player 2 (No Playlist)
    AudioPlayerComponent {
        id: audioPlayer2
        playerId: "Player2"  
        isActive: !player1Active
        hasPlaylist: false
        volume: player2Volume
        
        onPlayerPlaying: {
            if (isActive) {
                console.log("DualAudioManager: Player2 started playing")
                dualManager.playbackStateChanged(Audio.PlayingState)
            }
        }
        
        onPlayerPaused: {
            if (isActive) {
                console.log("DualAudioManager: Player2 paused")
                dualManager.playbackStateChanged(Audio.PausedState)
            }
        }
        
        onPlayerStopped: {
            if (isActive) {
                console.log("DualAudioManager: Player2 stopped")
                dualManager.playbackStateChanged(Audio.StoppedState)
                trackFinished()
            }
        }
        
        onPlayerError: {
            if (isActive) {
                dualManager.playerError(error)
            }
        }
        
        onPlayerPositionChanged: {
            if (isActive) {
                dualManager.positionChanged(position, duration)
                
                // Check for preload trigger
                if (preloadingEnabled && !preloadInProgress && duration > 0) {
                    var timeLeft = (duration - position) / 1000
                    if (timeLeft <= 10 && timeLeft > 0) {
                        console.log("DualAudioManager: Player2 - triggering preload")
                        triggerPreload()
                    }
                }
            }
        }
        
        onPlayerDurationChanged: {
            if (isActive) {
                dualManager.durationChanged(duration)
            }
        }
        
        onPlayerPlaybackStateChanged: {
            if (isActive) {
                dualManager.playbackStateChanged(state)
            }
        }
        
        onPlayerStatusChanged: {
            if (!isActive && status === Audio.Loaded && source === nextTrackUrl) {
                console.log("DualAudioManager: Player2 preload ready")
                preloadReady()
            }
            
            // Debug crossfade switching
            if (!isActive && status === Audio.Loaded) {
                console.log("DualAudioManager: Player2 loaded - checking crossfade conditions:")
                console.log("  - isActive:", isActive)
                console.log("  - status:", status, "(Audio.Loaded =", Audio.Loaded, ")")
                console.log("  - pendingImmediateSwitch:", pendingImmediateSwitch)
                console.log("  - source:", source)
                console.log("  - pendingSwitchUrl:", pendingSwitchUrl)
                console.log("  - URL match:", source === pendingSwitchUrl)
                console.log("  - source toString():", source.toString())
                console.log("  - pendingSwitchUrl toString():", pendingSwitchUrl.toString())
                console.log("  - URL match toString():", source.toString() === pendingSwitchUrl.toString())
            }
            
            // Handle immediate switching / crossfade
            if (!isActive && status === Audio.Loaded && pendingImmediateSwitch && source.toString() === pendingSwitchUrl.toString()) {
                console.log("DualAudioManager: Player2 ready for crossfade switch!")
                
                // Store reference to old active player for volume crossfade
                var oldActivePlayer = activePlayer
                
                // Switch immediately with crossfade
                player1Active = !player1Active
                currentTrackUrl = pendingSwitchUrl
                currentTrackId = pendingSwitchTrackId
                
                // Update playlist if switching to Player2 (so it matches the current track)
                updatePlaylistForCrossfade()
                
                // Start new player
                activePlayer.startPlayback()
                
                // Start crossfade based on mode
                crossfadeTimer.startCrossfade()
                
                // Clear pending switch
                pendingImmediateSwitch = false
                pendingSwitchUrl = ""
                pendingSwitchTrackId = ""
                
                // Notify track info update
                trackInfoUpdateTimer.start()
            }
        }
    }
    
    // Public API
    function play() {
        activePlayer.startPlayback()
    }
    
    function pause() {
        activePlayer.pausePlayback()
    }
    
    function stop() {
        activePlayer.stopPlayback()
    }
    
    function seek(position) {
        activePlayer.seekTo(position)
    }
    
    function setSource(url) {
        console.log("DualAudioManager: Setting source:", url)
        currentTrackUrl = url
        
        // Clear playlist and add single item (only Player1 has playlist)
        playlistItem.clear()
        if (url) {
            playlistItem.addItem(url)
        }
    }
    
    // Crossfade version: Load in inactive player without stopping current
    function crossfadeToTrack(url, trackId) {
        console.log("DualAudioManager: Starting crossfade to:", trackId)
        
        // Check if we have an active track playing
        var hasActiveTrack = activePlayer.playbackState === Audio.PlayingState || activePlayer.playbackState === Audio.PausedState
        console.log("DualAudioManager: Has active track playing:", hasActiveTrack, "- state:", activePlayer.playbackState)
        
        // Check if already preloaded
        if (inactivePlayer.source.toString() === url.toString() && inactivePlayer.isReady()) {
            console.log("DualAudioManager: Crossfade - track already ready, switching now!")
            
            // Immediate switch with crossfade (or just switch if no active track)
            player1Active = !player1Active
            currentTrackUrl = url
            currentTrackId = trackId
            
            // Start new player
            activePlayer.startPlayback()
            
            // Only fade out if there was an active track
            if (hasActiveTrack) {
                fadeOutTimer.start()
            }
            resetPreloadState()
            return true
        }
        
        // If no active track, just load and play immediately (no crossfade needed)
        if (!hasActiveTrack) {
            console.log("DualAudioManager: No active track - loading and playing immediately")
            
            // Set track info for status handlers
            currentTrackUrl = url
            currentTrackId = trackId
            
            // Load into inactive player
            inactivePlayer.loadTrack(url)
            
            // Don't switch yet - wait for the track to load, then switch and play
            // Set up pending switch to start playback when loaded
            pendingSwitchUrl = url
            pendingSwitchTrackId = trackId
            pendingImmediateSwitch = true
            
            return true
        }
        
        // Load into inactive player while current continues (true crossfade)
        console.log("DualAudioManager: Loading new track for crossfade while current plays...")
        inactivePlayer.loadTrack(url)
        
        // Set up pending switch
        pendingSwitchUrl = url
        pendingSwitchTrackId = trackId
        pendingImmediateSwitch = true
        
        return true
    }
    
    function clearPlaylist() {
        playlistItem.clear()
    }
    
    function addToPlaylist(url) {
        playlistItem.addItem(url)
    }
    
    function replacePlaylist(urls) {
        playlistItem.clear()
        for (var i = 0; i < urls.length; i++) {
            playlistItem.addItem(urls[i])
        }
    }
    
    // Preload functions
    function startPreload(trackId, url) {
        if (!preloadingEnabled || preloadInProgress) {
            return false
        }
        
        console.log("DualAudioManager: Starting preload for track", trackId)
        nextTrackId = trackId
        nextTrackUrl = url
        preloadInProgress = true
        
        // Load into inactive player
        inactivePlayer.loadTrack(url)
        return true
    }
    
    // Enhanced: Immediate track switching for Next/Previous/Selection with crossfade
    function switchToTrackImmediately(url, trackId) {
        console.log("DualAudioManager: Immediate switch to track", trackId)
        
        // Check if the inactive player already has this track loaded
        if (inactivePlayer.source.toString() === url.toString() && inactivePlayer.isReady()) {
            console.log("DualAudioManager: Track already preloaded - seamless switch!")
            
            // Switch players immediately
            player1Active = !player1Active
            currentTrackUrl = url
            currentTrackId = trackId
            
            // Start playing immediately (crossfade)
            activePlayer.startPlayback()
            resetPreloadState()
            return true
        }
        
        // Otherwise start crossfade loading: Keep current track playing while loading new
        console.log("DualAudioManager: Starting crossfade load - keeping current track playing")
        inactivePlayer.loadTrack(url)
        
        // Important: Don't stop current player, let it continue until new one is ready
        // Wait for it to be ready, then switch
        return waitForLoadAndSwitch(url, trackId)
    }
    
    function waitForLoadAndSwitch(url, trackId) {
        // This will be called when the player status changes to loaded
        pendingSwitchUrl = url
        pendingSwitchTrackId = trackId
        pendingImmediateSwitch = true
        return true
    }
    
    // Properties for immediate switching
    property string pendingSwitchUrl: ""
    property string pendingSwitchTrackId: ""
    property bool pendingImmediateSwitch: false
    
    function getInactivePlayerBufferProgress() {
        // Return buffer progress of inactive player (0.0 to 1.0)
        return inactivePlayer.getBufferProgress()
    }
    
    function switchToPreloadedTrack() {
        if (!preloadingEnabled || !nextTrackUrl) {
            console.log("DualAudioManager: No preloaded track available")
            return false
        }
        
        // Check if inactive player has the preloaded track ready
        if (!inactivePlayer.isReady() || inactivePlayer.source.toString() !== nextTrackUrl.toString()) {
            console.log("DualAudioManager: Preload not ready")
            console.log("DualAudioManager: Inactive player ready:", inactivePlayer.isReady())
            console.log("DualAudioManager: Source match:", inactivePlayer.source.toString() === nextTrackUrl.toString())
            return false
        }
        
        console.log("DualAudioManager: Switching to preloaded track - seamless transition!")
        
        // Switch active player
        player1Active = !player1Active
        console.log("DualAudioManager: Switched to", player1Active ? "Player1" : "Player2")
        
        // Start playing the now-active player
        activePlayer.startPlayback()
        
        // Update current track info
        currentTrackUrl = nextTrackUrl
        currentTrackId = nextTrackId
        
        // Reset preload state
        resetPreloadState()
        
        return true
    }
    
    function resetPreloadState() {
        preloadInProgress = false
        nextTrackUrl = ""
        nextTrackId = ""
    }
    
    function updatePlaylistForCrossfade() {
        // Ensure the playlist stays in sync regardless of which player is active
        // Player1 uses the playlist directly, but we need to keep it current when switching
        console.log("DualAudioManager: Synchronizing playlist after crossfade")
        
        // The playlist should be managed by the PlaylistManager, not here
        // We just ensure the currently active player reflects the right track
        // The position updates will handle the rest
    }
    
    function triggerPreload() {
        // This is called by the active player, but MediaHandler handles the actual preload
        // Don't reset state here, just ignore duplicate triggers
        console.log("DualAudioManager: Preload trigger ignored (handled by MediaHandler)")
    }
    
    // Expose playlist for external access
    property alias playlist: playlistItem
}
