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
        if (applicationWindow.settings && applicationWindow.settings.debugLevel >= 1) {
            console.log("AudioPlayerComponent:", playerId, "loading track:", url ? String(url).substring(0, 100) + "..." : "NULL")
        }
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
        var progress = 0.0
        if (status === Audio.Buffered) {
            progress = bufferProgress !== undefined ? bufferProgress : 0.8
        } else if (status === Audio.Loaded) {
            progress = 1.0
        } else if (status === Audio.Loading) {
            progress = bufferProgress !== undefined ? bufferProgress : 0.3
        } else {
            progress = 0.0
        }

        return progress
    }

    // Crossfade control function
    property bool inCrossfade: false
    property real originalVolume: 1.0
    property var parentManager: null

    // VEREINFACHTE applyCrossfade - die komplexe Logik ist jetzt in handleCrossfade()
    function applyCrossfade(otherPlayerBufferProgress, crossfadeMode, timeProgress, fadeTimeMs) {
        // Diese Funktion ist jetzt nur noch für Kompatibilität da
        // Die eigentliche Logik ist in DualAudioManager.handleCrossfade()
        return false
    }

    function resetCrossfade() {
        if (applicationWindow.settings && applicationWindow.settings.debugLevel >= 2) {
            console.log("AudioPlayerComponent:", playerId, "reset crossfade")
        }
        inCrossfade = false

        if (parentManager && parentManager.clearCrossfadeVolumes) {
            parentManager.clearCrossfadeVolumes()
        }
    }
}
