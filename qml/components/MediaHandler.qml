import QtQuick 2.0
import Sailfish.Silica 1.0
import QtMultimedia 5.6
import Amber.Mpris 1.0

Item {
    id: mediaHandler

    // Media properties
    property string media_source
    property string track_id
    property string track_name
    property string album_name
    property string artist_name
    property string artwork_url
    property int track_duration

    property alias playlist: dualAudioManager.playlist
    property alias dualAudioManager: dualAudioManager
    
    // Track Preloading properties - Claude Generated  
    property bool preloadingEnabled: applicationWindow.settings.enableTrackPreloading || false
    property string nextTrackUrl: ""
    property string nextTrackId: ""
    property bool preloadInProgress: false
    property bool expectingPreloadResponse: false
    
    // Debug: Monitor preloading state changes
    onPreloadingEnabledChanged: {
        if (settings.debugLevel >= 1) {
            console.log("MEDIA: Track preloading", preloadingEnabled ? "enabled" : "disabled")
        }
    }
    
    // Dual Audio Manager for seamless transitions - Claude Generated
    DualAudioManager {
        id: dualAudioManager
        preloadingEnabled: mediaHandler.preloadingEnabled
        crossfadeMode: applicationWindow.settings.crossfadeMode || 1  // Default: Timer Fade
        crossfadeTimeMs: applicationWindow.settings.crossfadeTimeMs || 1000  // Default: 1 second
        playerVolume: player_volume
        trackVolume: track_volume
        
        onPositionChanged: {
            mediaHandler.mediaPositionChanged()
            
            // Debug every 30 seconds to avoid spam
            if (Math.floor(position) % 30 === 0 && Math.floor(position) > 0) {
                var timeLeft = (duration - position) / 1000
                console.log("MediaHandler: Position debug - timeLeft:", timeLeft + "s", "preloadInProgress:", preloadInProgress)
            }
            
            // Trigger preload when 10 seconds left
            if (preloadingEnabled && !preloadInProgress && duration > 0) {
                var timeLeft = (duration - position) / 1000
                if (timeLeft <= 10 && timeLeft > 0) {
                    console.log("MediaHandler: 10 seconds left, attempting preload")
                    tryPreloadNextTrack()
                }
            }
        }
        
        onDurationChanged: {
            if (duration > 0) {
                track_duration = duration
            }
            mediaHandler.mediaDurationChanged()
        }
        
        onPlaybackStateChanged: {
            mediaHandler.mediaPlaybackStateChanged()
            
            // Update MPRIS status based on playback state
            if (state === Audio.PlayingState) {
                mprisPlayer.playbackStatus = Mpris.Playing
            } else if (state === Audio.PausedState) {
                mprisPlayer.playbackStatus = Mpris.Paused
            } else if (state === Audio.StoppedState) {
                mprisPlayer.playbackStatus = Mpris.Stopped
            }
        }
        
        onTrackFinished: {
            // Try seamless transition first
            if (!blockAutoNext && playlistManager.canNext) {
                if (dualAudioManager.switchToPreloadedTrack()) {
                    console.log("MediaHandler: Seamless transition successful")
                    playlistManager.nextTrack()
                    updateTrackInfoFromPlaylist()
                } else {
                    console.log("MediaHandler: Auto-advancing to next track (normal)")
                    playlistManager.nextTrack()
                }
            } else if (!blockAutoNext) {
                console.log("MediaHandler: Playlist finished")
                playlistManager.playlistFinished()
            }
        }
        
        onPlayerError: {
            console.error("MediaHandler: Playback error:", error, "timestamp:", Date.now())
            mprisPlayer.playbackStatus = Mpris.Stopped
            
            // Handle URL expiry (403 Forbidden) - fallback to API (only if caching enabled)
            var errorStr = String(error)
            if ((errorStr.includes("Forbidden") || errorStr.includes("403")) && applicationWindow.settings.enableUrlCaching) {
                if (applicationWindow.settings.debugLevel >= 1) {
                    console.log("MediaHandler: URL expired (403) - falling back to API for current track")
                }
                
                // Get current track ID and retry via API
                var currentTrack = playlistManager.currentTrackIndex()
                if (currentTrack >= 0) {
                    var trackId = playlistManager.requestPlaylistItem(currentTrack)
                    if (trackId && trackId > 0) {
                        // Clear expired URL from cache
                        cacheManager.clearExpiredUrl(trackId.toString())
                        
                        // Force API request by calling TidalApi directly (bypasses cache)
                        tidalApi.playTrackId(trackId)
                    }
                }
            }
        }
        
        onTrackInfoChanged: {
            if (settings.debugLevel >= 2) {
                console.log("MEDIA: Track info changed, updating...")
            }
            updateTrackInfoFromPlaylist()
        }
    }
    
    // Active player reference for compatibility
    readonly property var activePlayer: dualAudioManager.activePlayer
    readonly property var audio_player: activePlayer
    
    // Playback state
    property bool player_available: playlist.itemCount > 0
    property double player_volume: 1.0
    property double track_volume: 1.0
    property bool blockAutoNext: false
    
    // Compatibility properties for existing code
    readonly property real position: dualAudioManager.activePlayer ? dualAudioManager.activePlayer.position : 0
    readonly property real duration: dualAudioManager.activePlayer ? dualAudioManager.activePlayer.duration : 0
    property real volume: dualAudioManager.activePlayer ? dualAudioManager.activePlayer.volume : 0
    readonly property int playbackState: dualAudioManager.activePlayer ? dualAudioManager.activePlayer.playbackState : Audio.StoppedState
    readonly property int status: dualAudioManager.activePlayer ? dualAudioManager.activePlayer.status : Audio.UnknownStatus
    readonly property string source: dualAudioManager.currentTrackUrl
    readonly property bool isPlaying: dualAudioManager.activePlayer ? (dualAudioManager.activePlayer.playbackState === Audio.PlayingState) : false
    
    // Current track info (compatibility) - separate properties to avoid binding conflicts
    property string current_track_title: ""
    property string current_track_artist: ""
    property string current_track_album: ""
    property string current_track_image: ""
    property int current_track_duration: 0

    // Custom signals (avoid duplicate names)
    signal mediaPositionChanged()
    signal mediaDurationChanged()
    signal mediaPlaybackStateChanged()
    signal currentTrackChanged(var trackInfo)

    // MPRIS integration using Amber.Mpris
    MprisPlayer {
        id: mprisPlayer

        serviceName: "tidalplayer"
        identity: "Tidal Music Player"
        supportedUriSchemes: ["http", "https"]
        supportedMimeTypes: ["audio/mpeg", "audio/flac", "audio/x-vorbis+ogg"]

        canControl: true
        canGoNext: playlistManager.canNext
        canGoPrevious: playlistManager.canPrev
        canPause: player_available
        canPlay: player_available
        canSeek: dualAudioManager.activePlayer ? dualAudioManager.activePlayer.seekable : false
        canQuit: false
        canRaise: true
        hasTrackList: true
        playbackStatus: Mpris.Stopped
        loopStatus: Mpris.LoopNone
        shuffle: false
        volume: player_volume

        // MPRIS control handlers
        onPauseRequested: {
            dualAudioManager.pause()
        }

        onPlayRequested: {
            dualAudioManager.play()
        }

        onPlayPauseRequested: {
            if (isPlaying) {
                dualAudioManager.pause() 
            } else {
                dualAudioManager.play()
            }
        }

        onStopRequested: {
            dualAudioManager.stop()
        }

        onNextRequested: {
            console.log('MPRIS: Next requested')
            blockAutoNext = true
            
            // Enhanced: Try immediate switch if preloading enabled
            if (preloadingEnabled && playlistManager.canNext) {
                var nextIndex = playlistManager.currentIndex + 1
                if (nextIndex < playlistManager.size) {
                    var nextTrackId = playlistManager.requestPlaylistItem(nextIndex)
                    if (nextTrackId) {
                        var nextTrackInfo = cacheManager.getTrackInfo(nextTrackId)
                        if (nextTrackInfo && nextTrackInfo.url) {
                            var bufferProgress = getInactivePlayerBufferProgress()
                            console.log('MPRIS: Next - buffer progress:', bufferProgress)
                            
                            if (switchToTrackImmediately(nextTrackInfo.url, nextTrackId)) {
                                console.log('MPRIS: Next - seamless switch successful')
                                playlistManager.nextTrack()
                                blockAutoNext = false
                                return
                            }
                        }
                    }
                }
            }
            
            // Fallback to normal next
            playlistManager.nextTrackClicked()
        }

        onPreviousRequested: {
            console.log('MPRIS: Previous requested')
            
            // Enhanced: Try immediate switch if preloading enabled
            if (preloadingEnabled && playlistManager.canPrev) {
                var prevIndex = playlistManager.currentIndex - 1
                if (prevIndex >= 0) {
                    var prevTrackId = playlistManager.requestPlaylistItem(prevIndex)
                    if (prevTrackId) {
                        var prevTrackInfo = cacheManager.getTrackInfo(prevTrackId)
                        if (prevTrackInfo && prevTrackInfo.url) {
                            var bufferProgress = getInactivePlayerBufferProgress()
                            console.log('MPRIS: Previous - buffer progress:', bufferProgress)
                            
                            if (switchToTrackImmediately(prevTrackInfo.url, prevTrackId)) {
                                console.log('MPRIS: Previous - seamless switch successful')
                                playlistManager.previousTrack()
                                return
                            }
                        }
                    }
                }
            }
            
            // Fallback to normal previous
            playlistManager.previousTrackClicked()
        }

        onSeekRequested: {
            var newPos = position + (offset / 1000000)  // Convert microseconds
            if (newPos >= 0 && newPos <= duration) {
                dualAudioManager.seek(newPos)
            }
        }

        onSetPositionRequested: {
            var seekPos = position / 1000000  // Convert microseconds to milliseconds
            if (seekPos >= 0 && seekPos <= duration) {
                dualAudioManager.seek(seekPos)
            }
        }
    }

    // Update MPRIS metadata when track properties change
    onTrack_nameChanged: {
        mprisPlayer.metaData.title = track_name
    }

    onAlbum_nameChanged: {
        mprisPlayer.metaData.albumTitle = album_name
    }

    onArtist_nameChanged: {
        mprisPlayer.metaData.contributingArtist = artist_name
    }

    onArtwork_urlChanged: {
        mprisPlayer.metaData.artUrl = artwork_url
    }

    onTrack_durationChanged: {
        if (track_duration > 0) {
            mprisPlayer.metaData.length = track_duration * 1000000  // Convert to microseconds
        }
    }

    onPlayer_volumeChanged: {
        dualAudioManager.playerVolume = player_volume
    }

    onTrack_volumeChanged: {
        dualAudioManager.trackVolume = track_volume
    }

    // Public API functions
    function play() {
        dualAudioManager.play()
    }

    function pause() {
        dualAudioManager.pause()
    }

    function stop() {
        dualAudioManager.stop()
    }

    function seek(position) {
        dualAudioManager.seek(position)
    }

    function setSource(url) {
        if (applicationWindow.settings.debugLevel >= 1) {
            if (url) {
                var safeUrl = url.indexOf('token') !== -1 ? url.split('?')[0] + "?token=***" : url
                console.log("MediaHandler: Setting source:", safeUrl.substring(0, 80) + "...")
            } else {
                console.log("MediaHandler: Setting source: NULL")
            }
        }
        media_source = url
        dualAudioManager.setSource(url)
    }

    function playUrl(url) {
        if (applicationWindow.settings.debugLevel >= 1) {
            if (settings.debugLevel >= 2) {
                if (url) {
                    var safeUrl = url.indexOf('token') !== -1 ? url.split('?')[0] + "?token=***" : url
                    console.log("MEDIA: Playing URL:", safeUrl.substring(0, 80) + "... - preloading:", preloadingEnabled)
                } else {
                    console.log("MEDIA: Playing URL: NULL - preloading:", preloadingEnabled)
                }
            }
        }
        blockAutoNext = true
        setSource(url)
        play()
        blockAutoNext = false
        
        // Reset preload state when new track starts
        if (applicationWindow.settings.debugLevel >= 2) {
            console.log("MediaHandler: Resetting preload state for new track")
        }
        resetPreloadState()
    }
    
    // Enhanced: Play track with immediate switching capability
    function playTrackWithImmediateSwitch(trackId, url) {
        console.log("MediaHandler: Playing track with immediate switch:", trackId)
        
        // Try immediate switch first if preloading enabled
        if (preloadingEnabled && switchToTrackImmediately(url, trackId)) {
            console.log("MediaHandler: Track played via immediate switch")
            return true
        } else {
            // Fallback to normal URL playing
            console.log("MediaHandler: Using normal playback for track")
            playUrl(url)
            return false
        }
    }

    // Playlist management
    function clearPlaylist() {
        dualAudioManager.clearPlaylist()
    }

    function addToPlaylist(url) {
        dualAudioManager.addToPlaylist(url)
    }

    function replacePlaylist(urls) {
        dualAudioManager.replacePlaylist(urls)
    }

    // Preload Functions - Claude Generated
    /**
     * Attempts to preload the next track in background
     */
    function tryPreloadNextTrack() {
        console.log("MediaHandler: tryPreloadNextTrack called - enabled:", preloadingEnabled, "inProgress:", preloadInProgress)
        
        if (!preloadingEnabled || preloadInProgress) {
            console.log("MediaHandler: Preload skipped - not enabled or already in progress")
            return
        }
        
        // Get next track ID from playlist manager
        var nextIndex = playlistManager.currentIndex + 1
        console.log("MediaHandler: Current index:", playlistManager.currentIndex, "Next index:", nextIndex, "Playlist size:", playlistManager.size)
        
        if (nextIndex >= playlistManager.size) {
            console.log("MediaHandler: No next track to preload")
            return
        }
        
        var nextTrackId = playlistManager.requestPlaylistItem(nextIndex)
        console.log("MediaHandler: Next track ID:", nextTrackId, "Current track ID:", track_id)
        
        if (!nextTrackId || nextTrackId === track_id) {
            console.log("MediaHandler: Invalid or same track ID, skipping preload")
            return
        }
        
        console.log("MediaHandler: Starting preload for track", nextTrackId)
        preloadInProgress = true
        expectingPreloadResponse = true
        mediaHandler.nextTrackId = nextTrackId
        
        // Request URL for next track
        tidalApi.getTrackUrlForPreload(nextTrackId)
    }
    
    /**
     * Sets the preloaded URL in the DualAudioManager
     */
    function setPreloadUrl(url) {
        if (!preloadingEnabled || !preloadInProgress) {
            return
        }
        
        console.log("MediaHandler: Starting preload in DualAudioManager:", url)
        nextTrackUrl = url
        
        // Use DualAudioManager's preload functionality
        if (dualAudioManager.startPreload(nextTrackId, url)) {
            console.log("MediaHandler: Preload started successfully")
        } else {
            console.log("MediaHandler: Failed to start preload")
            resetPreloadState()
        }
    }
    
    /**
     * Sets the crossfade URL and initiates crossfade
     */
    function setCrossfadeUrl(url, trackId) {
        if (!preloadingEnabled) {
            console.log("MediaHandler: Crossfade not enabled, falling back to normal playback")
            playUrl(url)
            return
        }
        
        console.log("MediaHandler: Starting crossfade in DualAudioManager:", url, "for track", trackId)
        
        // Set track ID immediately for proper track info display
        dualAudioManager.currentTrackId = trackId
        dualAudioManager.currentTrackUrl = url
        
        // Use DualAudioManager's crossfade functionality
        if (dualAudioManager.crossfadeToTrack(url, trackId)) {
            console.log("MediaHandler: Crossfade started successfully")
            // Update track info immediately
            updateTrackInfoFromPlaylist()
        } else {
            console.log("MediaHandler: Failed to start crossfade, using normal playback")
            playUrl(url)
        }
    }
    
    /**
     * Resets preload state
     */
    function resetPreloadState() {
        preloadInProgress = false
        nextTrackUrl = ""
        nextTrackId = ""
        expectingPreloadResponse = false
        dualAudioManager.resetPreloadState()
    }
    
    /**
     * Updates track info from current playlist position or crossfade track
     */
    function updateTrackInfoFromPlaylist() {
        var trackId = ""
        
        if (settings.debugLevel >= 3) {
            console.log("MEDIA: updateTrackInfoFromPlaylist - currentTrackId:", dualAudioManager.currentTrackId, "currentIndex:", playlistManager.currentIndex)
        }
        
        // Use crossfade track ID if available, otherwise use playlist
        if (dualAudioManager.currentTrackId) {
            trackId = dualAudioManager.currentTrackId
            console.log("MediaHandler: Using crossfade track ID:", trackId)
        } else if (playlistManager.currentIndex >= 0) {
            trackId = playlistManager.requestPlaylistItem(playlistManager.currentIndex)
            console.log("MediaHandler: Using playlist track ID:", trackId)
        }
        
        if (trackId) {
            var trackInfo = cacheManager.getTrackInfo(trackId)
            if (trackInfo) {
                track_id = trackId
                track_name = trackInfo.title || ""
                album_name = trackInfo.album || ""
                artist_name = trackInfo.artist || ""
                artwork_url = trackInfo.image || ""
                track_duration = trackInfo.duration || 0
                
                // Update compatibility properties
                current_track_title = track_name
                current_track_artist = artist_name
                current_track_album = album_name
                current_track_image = artwork_url
                current_track_duration = track_duration
                
                if (settings.debugLevel >= 2) {
                    console.log("MEDIA: Updated track info for", track_name, "by", artist_name)
                }
                
                // Emit signals for MiniPlayer and other components
                var trackData = {
                    trackid: trackId,
                    track_num: playlistManager.currentIndex + 1,
                    title: track_name,
                    artist: artist_name,
                    album: album_name,
                    image: artwork_url,
                    duration: track_duration
                }
                
                currentTrackChanged(trackData)
                
                // Also emit currentPlayback for Cover page compatibility
                if (tidalApi) {
                    tidalApi.currentPlayback(trackData)
                }
            }
        }
    }

    // Handle preload and crossfade responses - Claude Generated
    Connections {
        target: tidalApi
        onPreloadUrlReady: {
            console.log("MediaHandler: Preload URL ready - expecting:", expectingPreloadResponse, "trackId:", trackId, "nextTrackId:", nextTrackId)
            if (expectingPreloadResponse && trackId.toString() === nextTrackId.toString()) {
                console.log("MediaHandler: Received preload URL for track", trackId, "URL:", url)
                setPreloadUrl(url)
                expectingPreloadResponse = false
            } else {
                console.log("MediaHandler: Unexpected preload response for track", trackId, "(expected:", nextTrackId, ")")
            }
        }
        
        onCrossfadeUrlReady: {
            console.log("MediaHandler: Crossfade URL ready - expecting:", expectingCrossfadeResponse, "trackId:", trackId, "crossfadeTrackId:", crossfadeTrackId)
            if (expectingCrossfadeResponse && trackId.toString() === crossfadeTrackId.toString()) {
                console.log("MediaHandler: Received crossfade URL for track", trackId, "URL:", url)
                setCrossfadeUrl(url, trackId)
                expectingCrossfadeResponse = false
            } else {
                console.log("MediaHandler: Unexpected crossfade response for track", trackId, "(expected:", crossfadeTrackId, ")")
            }
        }
    }

    // Enhanced: Immediate track switching for Next/Previous/Selection - Claude Generated
    function switchToTrackImmediately(url, trackId) {
        console.log("MediaHandler: Attempting immediate track switch to", trackId)
        
        // Use DualAudioManager's crossfade switching for seamless transitions
        if (dualAudioManager.crossfadeToTrack(url, trackId)) {
            console.log("MediaHandler: Crossfade switch initiated")
            // Update track info after successful switch
            updateTrackInfoFromPlaylist()
            return true
        } else {
            console.log("MediaHandler: Crossfade switch not possible, falling back to normal loading")
            return false
        }
    }
    
    function getInactivePlayerBufferProgress() {
        return dualAudioManager.getInactivePlayerBufferProgress()
    }
    
    // Enhanced: Request track for crossfade - load URL in background while current plays
    function requestTrackForCrossfade(trackId) {
        console.log("MediaHandler: Requesting track for crossfade:", trackId)
        
        // Set up crossfade request - track will switch when URL is ready
        crossfadeTrackId = trackId
        expectingCrossfadeResponse = true
        
        // Request URL but handle as crossfade instead of normal playback
        tidalApi.getTrackUrlForCrossfade(trackId)
        
        return true
    }
    
    // Properties for crossfade requests
    property string crossfadeTrackId: ""
    property bool expectingCrossfadeResponse: false

    // Helper functions
    function seconds_to_minutes_seconds(total_seconds) {
        if (isNaN(total_seconds)) return "00:00"
        var minutes = Math.floor(total_seconds / 60)
        var seconds = Math.floor(total_seconds % 60)
        return minutes + ":" + ("00" + seconds).slice(-2)
    }

    Component.onCompleted: {
        if (settings.debugLevel >= 1) {
            console.log("MEDIA: Initialized with Amber.Mpris")
            console.log("MEDIA: Track preloading setting:", preloadingEnabled)
        }
        
        // Set up property bindings after component creation to avoid conflicts
        current_track_title = Qt.binding(function() { return track_name })
        current_track_artist = Qt.binding(function() { return artist_name })
        current_track_album = Qt.binding(function() { return album_name })
        current_track_image = Qt.binding(function() { return artwork_url })
        current_track_duration = Qt.binding(function() { return track_duration })
    }
}