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
    property int crossfadeTimeMs: 2000  // Configurable fade time (reduced from 3500ms)

    // Volume control - separate normal vs crossfade volume
    property real normalVolume: playerVolume * trackVolume
    property real player1Volume: player1Active ? normalVolume : 0.0
    property real player2Volume: !player1Active ? normalVolume : 0.0

    // Crossfade volume overrides (set during crossfade)
    property real player1CrossfadeVolume: -1  // -1 means use normal volume
    property real player2CrossfadeVolume: -1  // -1 means use normal volume

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

    // Player references - exported for Settings display
    property AudioPlayerComponent audioPlayer1: audioPlayer1
    property AudioPlayerComponent audioPlayer2: audioPlayer2
    
    // Active player reference
    property AudioPlayerComponent activePlayer: player1Active ? audioPlayer1 : audioPlayer2
    property AudioPlayerComponent inactivePlayer: player1Active ? audioPlayer2 : audioPlayer1

    // Timer for track info updates
    Timer {
        id: trackInfoUpdateTimer
        interval: 50
        repeat: false
        onTriggered: trackInfoChanged()
    }

    // Crossfade state tracking
    property real fadeStartTime: 0
    property bool crossfadeInProgress: false
    property bool playerSwitchLocked: false  // Prevent concurrent switches

    // Audio Player 1 with Playlist
    AudioPlayerComponent {
        id: audioPlayer1
        playerId: "Player1"
        isActive: player1Active
        hasPlaylist: true
        //volume: player1CrossfadeVolume >= 0 ? player1CrossfadeVolume : player1Volume
        parentManager: dualManager

        playlist: Playlist {
            id: playlistItem
            playbackMode: Playlist.Sequential

            onCurrentItemSourceChanged: {
                if (audioPlayer1.isActive && currentItemSource) {
                    console.log('DualAudioManager: Playlist track changed to:', currentItemSource)
                    currentTrackUrl = currentItemSource
                    trackInfoUpdateTimer.start()
                }
            }

            // WICHTIG: Automatischer Titelwechsel über Playlist
            onItemInserted: function(start_index, end_index) {
                console.log('DualAudioManager: Items inserted:', start_index, '-', end_index)
            }

            // Playlist automatic next track
            onCurrentIndexChanged: {
                console.log('DualAudioManager: Playlist index changed to:', currentIndex)
                if (audioPlayer1.isActive && currentItemSource) {
                    console.log('DualAudioManager: Auto-advancing to next track via playlist')
                    currentTrackUrl = currentItemSource
                    trackInfoUpdateTimer.start()
                }
            }
        }

        onPlayerPlaying: {
            if (isActive) {
                console.log("DualAudioManager: Player1 started playing")
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
                // Nur trackFinished wenn nicht durch Crossfade gestoppt
                if (!crossfadeInProgress) {
                    trackFinished()
                }
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
            // KORRIGIERT: EndOfMedia für automatischen Titelwechsel
            if (isActive && status === Audio.EndOfMedia) {
                console.log("DualAudioManager: Player1 reached end of media")

                // Only block auto-advance if there's an ongoing crossfade to a different track
                // Allow auto-advance if it's part of the normal playlist flow
                if (playerSwitchLocked && crossfadeInProgress) {
                    console.log("DualAudioManager: Auto-advance blocked - crossfade in progress")
                    return
                }

                // Check if next track is preloaded and ready for seamless switch
                if (preloadingEnabled && nextTrackId && inactivePlayer.isReady()) {
                    console.log("DualAudioManager: Auto-advance using preloaded track - seamless switch!")
                    
                    // Use preloaded track for seamless transition
                    player1Active = !player1Active
                    currentTrackUrl = nextTrackUrl
                    currentTrackId = nextTrackId
                    
                    activePlayer.startPlayback()
                    
                    // Update playlist to reflect the change
                    if (playlistItem.itemCount > 1 && playlistItem.currentIndex < playlistItem.itemCount - 1) {
                        playlistItem.next()
                    }
                    
                    resetPreloadState()
                    trackInfoUpdateTimer.start()
                    
                } else {
                    // Fallback to normal playlist advance
                    if (playlistItem.itemCount > 1 && playlistItem.currentIndex < playlistItem.itemCount - 1) {
                        console.log("DualAudioManager: Auto-advancing to next track in playlist (normal)")
                        playlistItem.next()  // Playlist automatisch weiter
                    } else {
                        console.log("DualAudioManager: End of playlist reached")
                        trackFinished()
                    }
                }
            }

            if (!isActive && status === Audio.Loaded && source.toString() === nextTrackUrl.toString()) {
                console.log("DualAudioManager: Player1 preload ready")
                preloadReady()
            }

            // Handle crossfade when inactive player is ready
            if (!isActive && crossfadeInProgress && (status === Audio.Loaded || status === Audio.Buffered)) {
                handleCrossfadeStep()
            }

            if (isActive && !crossfadeInProgress && pendingImmediateSwitch && source.toString() === pendingSwitchUrl.toString()) {
                console.log("DualAudioManager: Player1 ready for immediate switch (no crossfade)")
                startPlayback()
                pendingImmediateSwitch = false
                pendingSwitchUrl = ""
                pendingSwitchTrackId = ""
                trackInfoUpdateTimer.start()
            }

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
        volume: player2CrossfadeVolume >= 0 ? player2CrossfadeVolume : player2Volume
        parentManager: dualManager

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
                // Nur trackFinished wenn nicht durch Crossfade gestoppt
                if (!crossfadeInProgress) {
                    trackFinished()
                }
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
            // Player2 hat keine Playlist, also direkt trackFinished bei EndOfMedia
            if (isActive && status === Audio.EndOfMedia) {
                console.log("DualAudioManager: Player2 reached end of media - track finished")
                
                // Only block trackFinished if there's an ongoing crossfade
                if (!crossfadeInProgress) {
                    trackFinished()
                } else {
                    console.log("DualAudioManager: TrackFinished blocked - crossfade in progress")
                }
            }

            if (!isActive && status === Audio.Loaded && source.toString() === nextTrackUrl.toString()) {
                console.log("DualAudioManager: Player2 preload ready")
                preloadReady()
            }

            // Handle crossfade when inactive player is ready
            if (!isActive && crossfadeInProgress && (status === Audio.Loaded || status === Audio.Buffered)) {
                handleCrossfadeStep()
            }

            if (isActive && !crossfadeInProgress && pendingImmediateSwitch && source.toString() === pendingSwitchUrl.toString()) {
                console.log("DualAudioManager: Player2 ready for immediate switch (no crossfade)")
                startPlayback()
                pendingImmediateSwitch = false
                pendingSwitchUrl = ""
                pendingSwitchTrackId = ""
                trackInfoUpdateTimer.start()
            }

            if (isActive && status === Audio.Loaded && !crossfadeInProgress && source.toString() === currentTrackUrl.toString()) {
                console.log("DualAudioManager: Player2 loaded and ready to start")
                startPlayback()
            }
        }
    }

    // Timer für kontinuierliche Crossfade-Updates
    Timer {
        id: crossfadeUpdateTimer
        interval: 50  // 50ms für smooth crossfade
        repeat: true
        running: crossfadeInProgress
        onTriggered: handleCrossfadeStep()
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
        if (applicationWindow.settings && applicationWindow.settings.debugLevel >= 1) {
            if (url) {
                var urlStr = String(url)
                var safeUrl = urlStr.indexOf('token') !== -1 ? urlStr.split('?')[0] + "?token=***" : urlStr
                console.log("DualAudioManager: Setting source:", safeUrl.substring(0, 100) + "...")
            } else {
                console.log("DualAudioManager: Setting source: NULL")
            }
        }
        currentTrackUrl = url

        playlistItem.clear()
        if (url) {
            playlistItem.addItem(url)
        }
    }

    // Crossfade version: Load in inactive player without stopping current
    function crossfadeToTrack(url, trackId) {
        console.log("DualAudioManager: Starting crossfade to:", trackId, "mode:", crossfadeMode)

        // Prevent concurrent switches during crossfade or playlist operations
        if (playerSwitchLocked) {
            console.log("DualAudioManager: Player switch locked, ignoring crossfade request for", trackId)
            return false
        }

        if (crossfadeInProgress && currentTrackId === trackId) {
            console.log("DualAudioManager: Crossfade already in progress for same track, ignoring")
            return false
        }

        if (crossfadeInProgress) {
            console.log("DualAudioManager: Resetting previous crossfade for new track")
            completeCrossfade()
        }

        // Lock player switches during crossfade
        playerSwitchLocked = true

        var hasActiveTrack = activePlayer.playbackState === Audio.PlayingState || activePlayer.playbackState === Audio.PausedState
        console.log("DualAudioManager: Has active track playing:", hasActiveTrack)

        currentTrackUrl = url
        currentTrackId = trackId

        // Mode 0: Sofortiger Wechsel ohne Crossfade
        if (crossfadeMode === 0) {
            console.log("DualAudioManager: Mode 0 - immediate switch")
            // Player 1 stoppt, Player 2 bekommt URL und startet
            activePlayer.stopPlayback()
            player1Active = !player1Active
            activePlayer.loadTrack(url)
            // Player startet automatisch wenn ready (über onPlayerStatusChanged)
            trackInfoUpdateTimer.start()
            
            // Unlock immediately for mode 0
            Qt.callLater(function() { playerSwitchLocked = false })
            
            return true
        }

        // Für Modi 1-3: Crossfade starten
        if (!hasActiveTrack) {
            console.log("DualAudioManager: No active track - loading and playing immediately")
            inactivePlayer.loadTrack(url)
            player1Active = !player1Active
            pendingSwitchUrl = url
            pendingSwitchTrackId = trackId
            pendingImmediateSwitch = true
            trackInfoUpdateTimer.start()
            
            // Unlock after brief delay since no crossfade is needed
            Qt.callLater(function() { playerSwitchLocked = false })
            
            return true
        }

        console.log("DualAudioManager: Starting crossfade mode", crossfadeMode)

        // Crossfade initialisieren
        crossfadeInProgress = true
        fadeStartTime = Date.now()

        // Zweiten Player laden
        inactivePlayer.loadTrack(url)

        // Player wechseln (neuer wird aktiv)
        player1Active = !player1Active

        trackInfoUpdateTimer.start()
        return true
    }

    // KORRIGIERTE Crossfade-Implementierung mit richtiger Player-Zuordnung
    function handleCrossfadeStep() {
        if (!crossfadeInProgress) return

        // KORRIGIERT: Player-Zuordnung
        var oldPlayer = inactivePlayer  // Der gerade ausfadende Player (war aktiv, ist jetzt inaktiv)
        var newPlayer = activePlayer    // Der neue Player (ist jetzt aktiv)

        var newPlayerBuffer = newPlayer.getBufferProgress()
        var newPlayerReady = newPlayer.isReady()
        var elapsed = Date.now() - fadeStartTime
        var timeProgress = Math.min(elapsed / crossfadeTimeMs, 1.0)

        // Reduce log spam - only log every 500ms or important events
        if (applicationWindow.settings && applicationWindow.settings.debugLevel >= 3 && elapsed % 500 < 50) {
            console.log("DualAudioManager: Crossfade step - mode:", crossfadeMode,
                       "buffer:", newPlayerBuffer.toFixed(2), "ready:", newPlayerReady,
                       "time:", timeProgress.toFixed(2), "oldPlayer:", oldPlayer.playerId, "newPlayer:", newPlayer.playerId)
        }

        if (crossfadeMode === 1) {
            // Mode 1: Zeitbasiertes Fading während der neue lädt
            var oldVolume = normalVolume * (1.0 - timeProgress)
            setCrossfadeVolume(oldPlayer, oldVolume)

            // Neuer Player startet wenn ready
            if (newPlayerReady && newPlayer.playbackState !== Audio.PlayingState) {
                console.log("DualAudioManager: Starting new player")
                newPlayer.startPlayback()
                setCrossfadeVolume(newPlayer, normalVolume)
            }

            // Crossfade komplett wenn Zeit abgelaufen und neuer Player läuft
            if (timeProgress >= 1.0 && newPlayer.playbackState === Audio.PlayingState) {
                completeCrossfade()
            }
        }
        else if (crossfadeMode === 2) {
            // Mode 2: Buffer-abhängiger Crossfade (beide Player gleichzeitig)
            var fadeProgress = newPlayerBuffer * 0.5  // Halb so schnell wie Buffer
            var oldVolume = normalVolume * (1.0 - fadeProgress)
            var newVolume = normalVolume * fadeProgress

            setCrossfadeVolume(oldPlayer, oldVolume)

            // Neuer Player startet wenn ready
            if (newPlayerReady && newPlayer.playbackState !== Audio.PlayingState) {
                console.log("DualAudioManager: Starting new player")
                newPlayer.startPlayback()
            }

            if (newPlayer.playbackState === Audio.PlayingState) {
                setCrossfadeVolume(newPlayer, newVolume)
            }

            // Crossfade komplett wenn Buffer voll
            if (newPlayerBuffer >= 1.0) {
                completeCrossfade()
            }
        }
        else if (crossfadeMode === 3) {
            // Mode 3: Buffer-abhängiger Fade-out (nur alter Player)
            var oldVolume = normalVolume * (1.0 - newPlayerBuffer*0.75)
            setCrossfadeVolume(oldPlayer, oldVolume)

            // Neuer Player startet wenn ready (volle Lautstärke)
            if (newPlayerReady && newPlayer.playbackState !== Audio.PlayingState) {
                console.log("DualAudioManager: Starting new player")
                newPlayer.startPlayback()
                setCrossfadeVolume(newPlayer, normalVolume)
            }

            // Crossfade komplett wenn Buffer voll
            if (newPlayerBuffer >= 1.0) {
                completeCrossfade()
            }
        }
    }

    function completeCrossfade() {
        console.log("DualAudioManager: Crossfade complete - restoring volumes")

        crossfadeInProgress = false
        crossfadeUpdateTimer.stop()

        // Volumes wiederherstellen
        clearCrossfadeVolumes()

        // Inaktiven Player stoppen
        inactivePlayer.stopPlayback()

        // Unlock player switches
        playerSwitchLocked = false

        console.log("DualAudioManager: Crossfade finished - ready for next")
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

    function startPreload(trackId, url) {
        if (!preloadingEnabled || preloadInProgress) {
            return false
        }

        console.log("DualAudioManager: Starting preload for track", trackId)
        nextTrackId = trackId
        nextTrackUrl = url
        preloadInProgress = true

        inactivePlayer.loadTrack(url)
        return true
    }

    function switchToTrackImmediately(url, trackId) {
        console.log("DualAudioManager: Immediate switch to track", trackId)

        // Check if player switching is locked
        if (playerSwitchLocked) {
            console.log("DualAudioManager: Cannot switch - player switching locked")
            return false
        }

        if (inactivePlayer.source.toString() === url.toString() && inactivePlayer.isReady()) {
            console.log("DualAudioManager: Track already preloaded - seamless switch!")

            // Lock during switch
            playerSwitchLocked = true
            
            player1Active = !player1Active
            currentTrackUrl = url
            currentTrackId = trackId

            activePlayer.startPlayback()
            resetPreloadState()
            
            // Unlock after brief delay to ensure switch completes
            Qt.callLater(function() { playerSwitchLocked = false })
            
            return true
        }

        console.log("DualAudioManager: Starting crossfade load")
        inactivePlayer.loadTrack(url)

        return waitForLoadAndSwitch(url, trackId)
    }

    function waitForLoadAndSwitch(url, trackId) {
        pendingSwitchUrl = url
        pendingSwitchTrackId = trackId
        pendingImmediateSwitch = true
        return true
    }

    property string pendingSwitchUrl: ""
    property string pendingSwitchTrackId: ""
    property bool pendingImmediateSwitch: false

    function getInactivePlayerBufferProgress() {
        return inactivePlayer.getBufferProgress()
    }

    function switchToPreloadedTrack() {
        if (!preloadingEnabled || !nextTrackUrl) {
            console.log("DualAudioManager: No preloaded track available")
            return false
        }

        if (!inactivePlayer.isReady() || inactivePlayer.source.toString() !== nextTrackUrl.toString()) {
            console.log("DualAudioManager: Preload not ready")
            return false
        }

        console.log("DualAudioManager: Switching to preloaded track")

        player1Active = !player1Active
        activePlayer.startPlayback()

        currentTrackUrl = nextTrackUrl
        currentTrackId = nextTrackId

        resetPreloadState()
        return true
    }

    function resetPreloadState() {
        preloadInProgress = false
        nextTrackUrl = ""
        nextTrackId = ""
    }

    function triggerPreload() {
        console.log("DualAudioManager: Preload trigger (handled by MediaHandler)")
    }

    property alias playlist: playlistItem

    function resetPlayers() {
        console.log("DualAudioManager: Resetting audio players")

        audioPlayer1.stop()
        audioPlayer2.stop()

        crossfadeInProgress = false
        preloadInProgress = false
        pendingImmediateSwitch = false

        currentTrackId = ""
        currentTrackUrl = ""
        nextTrackId = ""
        nextTrackUrl = ""
        pendingSwitchUrl = ""
        pendingSwitchTrackId = ""

        clearCrossfadeVolumes()
        player1Active = true
        playlistItem.clear()

        console.log("DualAudioManager: Players reset complete")
    }

    function setCrossfadeVolume(player, volume) {
        // Only log volume changes at debug level 3 to reduce spam
        if (applicationWindow.settings && applicationWindow.settings.debugLevel >= 3) {
            console.log("DualAudioManager: Setting volume", volume.toFixed(2), "for", player.playerId)
        }
        if (player === audioPlayer1) {
            player.volume = volume //player1CrossfadeVolume = volume
        } else if (player === audioPlayer2) {
             player.volume = volume //player2CrossfadeVolume = volume
        }
    }

    function clearCrossfadeVolumes() {
        player1CrossfadeVolume = -1
        player2CrossfadeVolume = -1
    }
}
