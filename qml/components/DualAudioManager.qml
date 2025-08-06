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

    // Volume control - direct volume management during crossfades
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
    property AudioPlayerComponent activePlayer: audioPlayer1 //player1Active ? audioPlayer1 : audioPlayer2
    property AudioPlayerComponent inactivePlayer: audioPlayer2 //player1Active ? audioPlayer2 : audioPlayer1

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

    // Crossfade state tracking for buffer-based system
    property real fadeStartTime: 0
    property bool oldPlayerStartedFading: false

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
            // Handle end of media for automatic next track
            if (isActive && status === Audio.EndOfMedia) {
                console.log("DualAudioManager: Player1 reached end of media - track finished")
                trackFinished()
            }

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

            // Handle immediate switching when no crossfade is in progress
            if (isActive && !crossfadeInProgress && pendingImmediateSwitch && source.toString() === pendingSwitchUrl.toString()) {
                console.log("DualAudioManager: Player1 ready for immediate switch (no crossfade)")

                // Start new player immediately
                startPlayback()

                // Clear pending switch
                pendingImmediateSwitch = false
                pendingSwitchUrl = ""
                pendingSwitchTrackId = ""

                // Notify track info update
                trackInfoUpdateTimer.start()
            }

            // Handle track loading completion when no crossfade in progress
            if (isActive && status === Audio.Loaded && !crossfadeInProgress && source.toString() === currentTrackUrl.toString()) {
                console.log("DualAudioManager: Player1 loaded and ready to start")
                startPlayback()
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
            // Handle end of media for automatic next track
            if (isActive && status === Audio.EndOfMedia) {
                console.log("DualAudioManager: Player2 reached end of media - track finished")
                trackFinished()
            }

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

            // Handle immediate switching when no crossfade is in progress
            if (isActive && !crossfadeInProgress && pendingImmediateSwitch && source.toString() === pendingSwitchUrl.toString()) {
                console.log("DualAudioManager: Player2 ready for immediate switch (no crossfade)")

                // Start new player immediately
                startPlayback()

                // Clear pending switch
                pendingImmediateSwitch = false
                pendingSwitchUrl = ""
                pendingSwitchTrackId = ""

                // Notify track info update
                trackInfoUpdateTimer.start()
            }

            // Handle track loading completion when no crossfade in progress
            if (isActive && status === Audio.Loaded && !crossfadeInProgress && source.toString() === currentTrackUrl.toString()) {
                console.log("DualAudioManager: Player2 loaded and ready to start")
                startPlayback()
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
        console.log("DualAudioManager: Starting crossfade to:", trackId, "crossfadeInProgress:", crossfadeInProgress)

        // If crossfade in progress for same track, ignore
        if (crossfadeInProgress && currentTrackId === trackId) {
            console.log("DualAudioManager: Crossfade already in progress for same track, ignoring")
            return false
        }

        // If crossfade in progress for different track, reset and start new crossfade
        if (crossfadeInProgress && currentTrackId !== trackId) {
            console.log("DualAudioManager: Resetting previous crossfade for new track")
            crossfadeInProgress = false
            oldPlayerStartedFading = false
        }

        // Check if we have an active track playing
        var hasActiveTrack = activePlayer.playbackState === Audio.PlayingState || activePlayer.playbackState === Audio.PausedState
        console.log("DualAudioManager: Has active track playing:", hasActiveTrack, "- state:", activePlayer.playbackState)

        // Set track info early for proper state management
        currentTrackUrl = url
        currentTrackId = trackId

        // Check if already preloaded
        if (inactivePlayer.source.toString() === url.toString() && inactivePlayer.isReady()) {
            console.log("DualAudioManager: Crossfade - track already ready, switching now!")

            // Switch players and start new track immediately
            player1Active = !player1Active

            // Start new player
            activePlayer.startPlayback()

            // Start buffer-based crossfade immediately if there was an active track
            if (hasActiveTrack) {
                crossfadeInProgress = true
                fadeStartTime = Date.now()  // For mode 1 timer
                oldPlayerStartedFading = false
                console.log("DualAudioManager: Buffer-based crossfade started for preloaded track, mode", crossfadeMode)

                // For preloaded track, trigger immediate crossfade since buffer is already at 100%
                handleCrossCoupledFade()
            } else {
                crossfadeInProgress = false  // No crossfade needed
            }

            // Update track info immediately
            trackInfoUpdateTimer.start()

            resetPreloadState()
            return true
        }

        // If no active track, just load and play immediately (no crossfade needed)
        if (!hasActiveTrack) {
            console.log("DualAudioManager: No active track - loading and playing immediately")

            // Start loading into inactive player
            inactivePlayer.loadTrack(url)
            // Switch players for when track is ready
            player1Active = !player1Active

            // Set up auto-play when track is loaded
            pendingSwitchUrl = url
            pendingSwitchTrackId = trackId
            pendingImmediateSwitch = true

            // Update track info immediately
            trackInfoUpdateTimer.start()

            // No crossfade needed, just wait for track to load and play
            return true
        }

        // Load into inactive player while current continues (true crossfade)
        console.log("DualAudioManager: Loading new track for crossfade while current plays...")

        // Start loading new track into inactive player BEFORE switching
        inactivePlayer.loadTrack(url)

        // Now switch players for when the track is ready
        player1Active = !player1Active

        // Start buffer-based crossfade immediately
        if (hasActiveTrack) {
            crossfadeInProgress = true
            fadeStartTime = Date.now()  // For mode 1 timer
            oldPlayerStartedFading = false
            console.log("DualAudioManager: Buffer-based crossfade started for mode", crossfadeMode)

            // Start the new player loading - Qt will start playback when ready
            activePlayer.startPlayback()
        } else {
            crossfadeInProgress = false
            // No active track, just start the new one
            activePlayer.startPlayback()
        }

        // Update track info immediately
        trackInfoUpdateTimer.start()

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
    property bool crossfadeInProgress: false

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

    // Reset function for settings
    function resetPlayers() {
        console.log("DualAudioManager: Resetting audio players")

        // Stop both players
        audioPlayer1.stop()
        audioPlayer2.stop()

        // Reset crossfade state
        oldPlayerStartedFading = false

        // Reset all state
        crossfadeInProgress = false
        preloadInProgress = false
        pendingImmediateSwitch = false

        // Clear URLs and IDs
        currentTrackId = ""
        currentTrackUrl = ""
        nextTrackId = ""
        nextTrackUrl = ""
        pendingSwitchUrl = ""
        pendingSwitchTrackId = ""

        // Reset volumes to default
        audioPlayer1.volume = player1Active ? (playerVolume * trackVolume) : 0.0
        audioPlayer2.volume = !player1Active ? (playerVolume * trackVolume) : 0.0

        // Reset to player1 active
        player1Active = true

        // Clear playlist
        playlistItem.clear()

        console.log("DualAudioManager: Players reset complete")
    }
    Connections{
        target: audioPlayer1
        onBufferProgressChanged: {
            console.log("Buffer Progress", audioPlayer1.playerId, audioPlayer1.bufferProgress, "isActive:", audioPlayer1.isActive, "crossfadeInProgress:", crossfadeInProgress)

            // Cross-coupled: Player1's buffer progress controls Player2's crossfade
            if (audioPlayer1.isActive && audioPlayer1.source.toString() === currentTrackUrl.toString()) {
            console.log("Buffer Progress - Start Handle", audioPlayer1.playerId, audioPlayer1.bufferProgress, "isActive:", audioPlayer1.isActive, "crossfadeInProgress:", crossfadeInProgress)
                handleCrossCoupledFade()
            }
        }

        onPlayerStatusChanged: {
            // Also trigger crossfade check on status changes
            if (audioPlayer1.isActive && audioPlayer1.source.toString() === currentTrackUrl.toString()) {
                handleCrossCoupledFade()
            }
        }
    }

    Connections{
        target: audioPlayer2
        onBufferProgressChanged: {
            console.log("Buffer Progress", audioPlayer2.playerId, audioPlayer2.bufferProgress, "isActive:", audioPlayer2.isActive, "crossfadeInProgress:", crossfadeInProgress)

            // Cross-coupled: Player2's buffer progress controls Player1's crossfade
            if (audioPlayer2.isActive && audioPlayer2.source.toString() === currentTrackUrl.toString()) {
                console.log("Buffer Progress - Start Handle", audioPlayer2.playerId, audioPlayer2.bufferProgress, "isActive:", audioPlayer2.isActive, "crossfadeInProgress:", crossfadeInProgress)
                handleCrossCoupledFade()
            }
        }

        onPlayerStatusChanged: {
            // Also trigger crossfade check on status changes
            if (audioPlayer2.isActive && audioPlayer2.source.toString() === currentTrackUrl.toString()) {
                handleCrossCoupledFade()
            }
        }
    }

    // Cross-coupled crossfade handler - much simpler!
    function handleCrossCoupledFade() {

        console.log("Active Player", activePlayer.playerId)
/*        if (!crossfadeInProgress)
        {
            console.log("Early return of crossfade function")
            return
        }
        */

        // Get the old (active) and new (inactive) players
        var oldPlayer = activePlayer
        var newPlayer = inactivePlayer

        // Get buffer progress of the NEW player (loading)
        var newPlayerBufferProgress = newPlayer.getBufferProgress()

        // Get time progress for mode 1
        var elapsed = Date.now() - fadeStartTime
        var timeProgress = Math.min(elapsed / crossfadeTimeMs, 1.0)

        console.log("DualAudioManager: Cross-coupled fade - mode:", crossfadeMode, "buffer:", newPlayerBufferProgress.toFixed(2), "time:", timeProgress.toFixed(2))

        // Apply crossfade to the OLD player using the NEW player's buffer progress
        var crossfadeComplete = oldPlayer.applyCrossfade(newPlayerBufferProgress, crossfadeMode, timeProgress, crossfadeTimeMs)

        if (crossfadeComplete) {
            console.log("DualAudioManager: Cross-coupled crossfade complete - resetting state")
            crossfadeInProgress = false
            oldPlayerStartedFading = false

            // Reset both players to clean state
            audioPlayer1.resetCrossfade()
            audioPlayer2.resetCrossfade()
            console.log("Switch Players")
            if(activePlayer == audioPlayer1)
            {
                activePlayer = audioPlayer2
                inactivePlayer = audioPlayer1
            }else{
                activePlayer = audioPlayer1
                inactivePlayer = audioPlayer2
            }

            console.log("DualAudioManager: Ready for next crossfade")
        }
    }
}
