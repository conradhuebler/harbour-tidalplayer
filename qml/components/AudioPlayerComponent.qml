import QtQuick 2.0
import QtMultimedia 5.6

// Reusable Audio Player Component for dual-player setup - Claude Generated
Audio {
    id: audioPlayer
    
    // Properties
    property string playerId: "Player"
    property bool isActive: false
    property bool hasPlaylist: false
    
    // Signals for parent coordination
    signal playerPlaying()
    signal playerPaused() 
    signal playerStopped()
    signal playerError(string error)
    signal playerStatusChanged(int status)
    signal playerPositionChanged(real position, real duration)
    signal playerDurationChanged(real duration)
    signal playerPlaybackStateChanged(int state)
    
    // Volume management - don't override during crossfade
    Component.onCompleted: {
        if (!inCrossfade) {
            volume = isActive ? 1.0 : 0.0
        }
    }
    
    onIsActiveChanged: {
        if (!inCrossfade) {
            volume = isActive ? 1.0 : 0.0
        }
    }
    
    // Event handlers
    onPlaying: {
        console.log("AudioPlayerComponent:", playerId, "started playing")
        playerPlaying()
    }
    
    onPaused: {
        console.log("AudioPlayerComponent:", playerId, "paused")
        playerPaused()
    }
    
    onStopped: {
        console.log("AudioPlayerComponent:", playerId, "stopped")
        playerStopped()
    }
    
    onError: {
        console.error("AudioPlayerComponent:", playerId, "error:", error, errorString)
        playerError(errorString)
    }
    
    onStatusChanged: {
        console.log("AudioPlayerComponent:", playerId, "status changed to:", status)
        playerStatusChanged(status)
    }
    
    onPositionChanged: {
        if (isActive) {
            playerPositionChanged(position, duration)
        }
    }
    
    onDurationChanged: {
        if (isActive) {
            playerDurationChanged(duration)
        }
    }
    
    onPlaybackStateChanged: {
        if (isActive) {
            playerPlaybackStateChanged(playbackState)
        }
    }
    
    // Public functions
    function loadTrack(url) {
        console.log("AudioPlayerComponent:", playerId, "loading track:", url)
        source = url
    }
    
    function startPlayback() {
        console.log("AudioPlayerComponent:", playerId, "starting playback")
        play()
    }
    
    function pausePlayback() {
        console.log("AudioPlayerComponent:", playerId, "pausing playback")
        pause()
    }
    
    function stopPlayback() {
        console.log("AudioPlayerComponent:", playerId, "stopping playback")
        stop()
    }
    
    function seekTo(position) {
        if (seekable) {
            console.log("AudioPlayerComponent:", playerId, "seeking to:", position)
            seek(position)
        }
    }
    
    function isLoaded() {
        return status === Audio.Loaded
    }
    
    function isReady() {
        return status === Audio.Loaded || status === Audio.Buffered
    }
    
    function getBufferProgress() {
        // Return buffer progress (0.0 to 1.0)
        var progress = 0.0
        if (status === Audio.Buffered) {
            progress = bufferProgress || 0.8  // Qt Audio property, fallback to 80%
        } else if (status === Audio.Loaded) {
            progress = 1.0  // Fully loaded
        } else if (status === Audio.Loading) {
            progress = bufferProgress || 0.3  // Use actual buffer progress or fallback
        } else {
            progress = 0.0  // No data
        }
        
        console.log("AudioPlayerComponent:", playerId, "buffer progress:", progress, "status:", status)
        return progress
    }
    
    // Crossfade control function
    property bool inCrossfade: false
    property real originalVolume: 1.0
    
    function applyCrossfade(otherPlayerBufferProgress, crossfadeMode, timeProgress, fadeTimeMs) {
        console.log("AudioPlayerComponent:", playerId, "applyCrossfade - mode:", crossfadeMode, "buffer:", otherPlayerBufferProgress.toFixed(2), "time:", timeProgress.toFixed(2))
        
        if (!inCrossfade) {
            originalVolume = volume
            inCrossfade = true
        }
        
        var fadeMultiplier = 1.0
        var shouldStop = false
        
        if (crossfadeMode === 0) {
            // Mode 0: Immediate stop
            fadeMultiplier = 0.0
            shouldStop = true
        }
        else if (crossfadeMode === 1) {
            // Mode 1: Timer-based fade
            fadeMultiplier = Math.max(0.0, 1.0 - timeProgress)
            shouldStop = (timeProgress >= 1.0 && otherPlayerBufferProgress >= 1.0)
        }
        else if (crossfadeMode === 2) {
            // Mode 2: Buffer-dependent fade
            fadeMultiplier = 1 - otherPlayerBufferProgress //Math.max(0.0, 1.0 - otherPlayerBufferProgress)
            shouldStop = (otherPlayerBufferProgress >= 1.0)
        }
        else if (crossfadeMode === 3) {
            // Mode 3: Slow fade with overlap
            fadeMultiplier = Math.max(0.0, 1.0 - (otherPlayerBufferProgress * 0.75))
            shouldStop = (otherPlayerBufferProgress >= 1.0)
        }
        
        // Apply volume change
        volume = originalVolume * fadeMultiplier
        
        console.log("AudioPlayerComponent:", playerId, "buffer ", otherPlayerBufferProgress, "fade multiplier:", fadeMultiplier.toFixed(2), "volume:", volume.toFixed(2), "shouldStop:", shouldStop)

        // Stop or reset when crossfade complete
        if (shouldStop) {

        /*
            if (crossfadeMode === 3 && otherPlayerBufferProgress < 1.0) {
                // Mode 3: Continue fading until other player fully ready
                return false
            }
            
            console.log("AudioPlayerComponent:", playerId, "crossfade complete - resetting")*/
            resetCrossfade()
            stopPlayback()
            return true  // Crossfade complete
        }
        
        return false  // Crossfade still in progress
    }
    
    function resetCrossfade() {
        console.log("AudioPlayerComponent:", playerId, "reset crossfade", "volume: ", originalVolume)
        inCrossfade = false
        volume = 1 //originalVolume
        // Note: Don't stop playback here - let the manager decide
    }
}
