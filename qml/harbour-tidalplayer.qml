import QtQuick 2.0
import Sailfish.Silica 1.0
import io.thp.pyotherside 1.5
import QtMultimedia 5.6
import Amber.Mpris 1.0
import Nemo.Configuration 1.0

import "components"
import "cover"
import "pages"
import "pages/widgets"


ApplicationWindow
{
    id: applicationWindow
    
    property var mainPage
    property alias mediaController: mediaController

    property bool loginTrue : false
    property var locale: Qt.locale()
    property date currentDate: new Date()
    property MiniPlayer minPlayerPanel : miniPlayerPanel
    property QtObject settings : QtObject
    {
        property string token_type : ""
        property string access_token : ""
        property string refresh_token : ""
        property int expiry_time : -1
        property string mail: ""
        property string audio_quality : ""
        property bool resume_playback : false
        property string last_track_url: ""
        property string last_track_id: ""
        property real last_track_position: 0.0
        property bool hide_player: false
        property bool auto_load_playlist: true
        property bool stay_logged_in: false
        property bool useNewHomescreen: false
        property string defaultPlayAction: "replace"

        property bool recentList: true
        property bool yourList: true //shows currently popular playlists
        property bool topartistList: true // your favourite artists
        property bool topalbumsList: true // your favourite albums
        property bool toptrackList: true  // your favourite tracks
        property bool personalPlaylistList: true
        property bool dailyMixesList: true // custom mixes
        property bool radioMixesList: true // personal radio stations
        property bool topArtistsList: true // your top artists (most played)
        property bool enableTrackPreloading: false // dual audio player for seamless transitions
        property int crossfadeMode: 1 // crossfade mode: 0=No Fade, 1=Timer, 2=Buffer Crossfade, 3=Buffer Fade-Out
        property int crossfadeTimeMs: 1000 // crossfade time in milliseconds
        property int debugLevel: 0 // debug logging level: 0=None, 1=Normal, 2=Informative, 3=Verbose/Spawn
        property bool enableUrlCaching: false // URL caching for faster track loading
        property var emailHistory: [] // List of previously used email addresses
        
        // Email history management functions
        function addEmailToHistory(email) {
            if (!email || email === "") return
            
            var history = emailHistory.slice() // Copy array
            var index = history.indexOf(email)
            
            if (index !== -1) {
                // Move existing email to front
                history.splice(index, 1)
            }
            
            // Add to front
            history.unshift(email)
            
            // Keep only last 5 emails
            if (history.length > 5) {
                history = history.slice(0, 5)
            }
            
            emailHistory = history
            
            if (debugLevel >= 2) {
                console.log("EMAIL: Added to history:", email, "Total entries:", history.length)
            }
        }
        
        function getEmailHistory() {
            return emailHistory || []
        }
        
        function removeEmailFromHistory(email) {
            if (!email || email === "") return false
            
            var history = emailHistory.slice() // Copy array
            var index = history.indexOf(email)
            
            if (index !== -1) {
                history.splice(index, 1)
                emailHistory = history
                
                if (debugLevel >= 2) {
                    console.log("EMAIL: Removed from history:", email, "Remaining entries:", history.length)
                }
                return true
            }
            
            if (debugLevel >= 2) {
                console.log("EMAIL: Email not found in history:", email)
            }
            return false
        }
        
        function clearEmailHistory() {
            var oldLength = (emailHistory || []).length
            emailHistory = []
            
            if (debugLevel >= 1) {
                console.log("EMAIL: Cleared history (" + oldLength + " entries removed)")
            }
        }
        
        // Quick resume functions
        function saveCurrentState() {
            if (mediaController && mediaController.track_id && mediaController.source) {
                last_track_id = mediaController.track_id
                last_track_url = mediaController.source  
                last_track_position = mediaController.position
                
                // Save to persistent storage
                lastTrackId.value = last_track_id
                lastTrackUrl.value = last_track_url
                lastTrackPosition.value = last_track_position
                
                if (settings.debugLevel >= 2) {
                    console.log("RESUME: Saved state - track:", last_track_id, "position:", (last_track_position/1000).toFixed(1) + "s")
                }
            }
        }
        
        function restoreCurrentState() {
            // Check if we have valid authentication before trying to resume
            if (!access_token || !refresh_token || 
                access_token === "" || refresh_token === "") {
                if (settings.debugLevel >= 1) {
                    console.log("RESUME: No valid tokens - skipping resume playback")
                }
                return
            }
            
            if (resume_playback && lastTrackUrl.value && lastTrackId.value) {
                if (settings.debugLevel >= 1) {
                    console.log("RESUME: Restoring track:", lastTrackId.value, "position:", (lastTrackPosition.value/1000).toFixed(1) + "s")
                }
            } else {
                if (settings.debugLevel >= 1) {
                    console.log("RESUME: Resume disabled or no saved state available")
                }
                return
            }
            
            // Set track info immediately for UI
            var trackInfo = cacheManager.getTrackInfo(lastTrackId.value)
            if (trackInfo) {
                mediaController.track_id = lastTrackId.value
                mediaController.track_name = trackInfo.title || ""
                mediaController.album_name = trackInfo.album || ""
                mediaController.artist_name = trackInfo.artist || ""
                mediaController.artwork_url = trackInfo.image || ""
                mediaController.track_duration = trackInfo.duration || 0
            }
            
            // Load track directly with cached URL - no API call needed!
            mediaController.setSource(lastTrackUrl.value)
            mediaController.play()
            
            // Seek to saved position after track loads
            resumeSeekTimer.start()
        }
    }
    
    // Resume system timers
    Timer {
        id: autoSaveTimer
        interval: 10000  // Save every 10 seconds
        repeat: true
        running: mediaController && mediaController.isPlaying
        onTriggered: {
            applicationWindow.settings.saveCurrentState()
        }
    }
    
    Timer {
        id: resumeSeekTimer
        interval: 2000  // Wait for track to load
        onTriggered: {
            if (lastTrackPosition.value > 1000) {  // Only seek if > 1 second
                if (settings.debugLevel >= 2) {
                    console.log("RESUME: Seeking to", (lastTrackPosition.value/1000).toFixed(1) + "s")
                }
                mediaController.seek(lastTrackPosition.value)
            }
        }
    }
    
    Timer {
        id: saveStateTimer
        interval: 2000
        onTriggered: applicationWindow.settings.saveCurrentState()
    }
    
    Timer {
        id: resumeRestoreTimer
        interval: 3000  // Wait 3 seconds for everything to initialize
        onTriggered: {
            if (settings.debugLevel >= 1) {
                console.log("RESUME: Attempting to restore playback...")
            }
            applicationWindow.settings.restoreCurrentState()
        }
    }
    
    // Timer to check authentication and redirect to settings if needed
    Timer {
        id: authCheckTimer
        interval: 1000  // Wait 1 second for settings to load
        repeat: false
        onTriggered: {
            var hasValidAuth = applicationWindow.settings.access_token && 
                             applicationWindow.settings.refresh_token &&
                             applicationWindow.settings.access_token !== "" &&
                             applicationWindow.settings.refresh_token !== ""
            
            if (applicationWindow.settings.debugLevel >= 1) {
                console.log("AUTH_CHECK: Checking authentication - hasValidAuth:", hasValidAuth)
            }
            
            if (!hasValidAuth) {
                if (applicationWindow.settings.debugLevel >= 1) {
                    console.log("AUTH_CHECK: No valid authentication - redirecting to settings")
                }
                showInfoNotification(qsTr("Welcome"), qsTr("Please log in to access Tidal music"))
                pageStack.push(Qt.resolvedUrl("pages/Settings.qml"))
            } else {
                if (applicationWindow.settings.debugLevel >= 1) {
                    console.log("AUTH_CHECK: User is authenticated - staying on main page")
                }
            }
        }
    }
    
    // Save state when track changes
    Connections {
        target: mediaController
        onCurrentTrackChanged: {
            if (trackInfo && trackInfo.trackid) {
                // Save with small delay to ensure track is properly loaded
                saveStateTimer.start()
            }
        }
    }

    // Configuration Storage
    ConfigurationValue {
        id: token_type
        key: "/token_type"
    }

    ConfigurationValue {
        id: access_token
        key: "/access_token"
        value: ""
    }

    ConfigurationValue {
        id: refresh_token
        key: "/refresh_token"
    }

    ConfigurationValue {
        id: expiry_time
        key: "/expiry_time"
    }

    ConfigurationValue {
        id: mail
        key: "/mail"
    }

    ConfigurationValue {
        id: audioQuality
        key: "/audioQuality"
        defaultValue: "HIGH"  // Standardwert
    }

    ConfigurationValue {
        id: resumePlayback
        key : "/resumePlayback"
        defaultValue: false
    }

    ConfigurationValue {
        id: hidePlayerOnFinished
        key : "/hidePlayerOnFinished"
        defaultValue: false
    }

    ConfigurationValue {
        id: autoLoadPlaylist
        key : "/autoLoadPlaylist"
        defaultValue: true
    }

    ConfigurationValue {
        id: stayLoggedInConfig
        key : "/stayLoggedIn"
        defaultValue: false
    }

    ConfigurationValue {
        id: useNewHomescreen
        key : "/useNewHomescreen"
        defaultValue: false
    }

    ConfigurationValue {
        id: defaultPlayAction
        key : "/defaultPlayAction"
        defaultValue: "replace"
    }

    ConfigurationValue {
        id: recentListConfig
        key : "/recentList"
        defaultValue: true
    }

    ConfigurationValue {
        id: yourListConfig
        key : "/yourList"
        defaultValue: true
    }

    ConfigurationValue {
        id: topartistListConfig
        key : "/topartistList"
        defaultValue: true
    }

    ConfigurationValue {
        id: topalbumsListConfig
        key : "/topalbumsList"
        defaultValue: true
    }

    ConfigurationValue {
        id: toptrackListConfig
        key : "/toptrackList"
        defaultValue: true
    }

    ConfigurationValue {
        id: personalPlaylistListConfig
        key : "/personalPlaylistList"
        defaultValue: true
    }

    ConfigurationValue {
        id: dailyMixesListConfig
        key : "/dailyMixesList"
        defaultValue: true
    }
    
    ConfigurationValue {
        id: radioMixesListConfig
        key : "/radioMixesList"
        defaultValue: true
    }
    
    ConfigurationValue {
        id: lastTrackUrl
        key: "/lastTrackUrl"
        defaultValue: ""
    }
    
    ConfigurationValue {
        id: lastTrackId
        key: "/lastTrackId"
        defaultValue: ""
    }
    
    ConfigurationValue {
        id: lastTrackPosition
        key: "/lastTrackPosition"
        defaultValue: true
    }
    
    ConfigurationValue {
        id: topArtistsListConfig
        key : "/topArtistsList"
        defaultValue: true
    }
    
    ConfigurationValue {
        id: enableTrackPreloadingConfig
        key : "/enableTrackPreloading"
        defaultValue: false
    }
    
    ConfigurationValue {
        id: crossfadeModeConfig
        key : "/crossfadeMode"
        defaultValue: 1  // Default: Timer Fade
    }
    
    ConfigurationValue {
        id: crossfadeTimeMsConfig
        key : "/crossfadeTimeMs"
        defaultValue: 1000  // Default: 1 second
    }
    
    ConfigurationValue {
        id: debugLevelConfig
        key : "/debugLevel"
        defaultValue: 0  // Default: No debug output
    }
    
    ConfigurationValue {
        id: enableUrlCachingConfig
        key : "/enableUrlCaching"
        defaultValue: false  // Default: Disabled
    }
    
    ConfigurationValue {
        id: emailHistoryConfig
        key : "/emailHistory"
        defaultValue: "[]"  // JSON array of email addresses
    }

    property int remainingMinutes: 0
    property string timerAction: "pause"
    property bool timerNotificationShown: false

    property var sleepTimer: Timer {
        id: sleepTimer
        interval: 60000  // 1 Minute
        repeat: true
        onTriggered: {
            remainingMinutes--
            
            // Show notification when 5 minutes remaining
            if (remainingMinutes === 5 && !timerNotificationShown) {
                timerNotificationShown = true
                showSystemMessage(qsTr("Sleep Timer"), qsTr("5 minutes remaining"))
            }
            
            // Show final countdown notifications
            if (remainingMinutes === 1) {
                showSystemMessage(qsTr("Sleep Timer"), qsTr("1 minute remaining"))
            }
            
            if (remainingMinutes <= 0) {
                stop()
                remainingMinutes = 0
                timerNotificationShown = false
                executeTimerAction()
            }
        }
    }

    // Enhanced function to start timer with action
    function startSleepTimer(minutes, action) {
        if (settings.debugLevel >= 1) {
            console.log("SLEEP: Starting sleep timer:", minutes, "minutes, action:", action || "pause")
        }
        if (minutes > 0) {
            remainingMinutes = minutes
            timerAction = action || "pause"
            timerNotificationShown = false
            sleepTimer.start()
            
            // Show start notification
            var actionText = ""
            switch (timerAction) {
                case "pause": actionText = qsTr("pause playback"); break
                case "stop": actionText = qsTr("stop playback"); break
                case "fade": actionText = qsTr("fade out and pause"); break
                case "close": actionText = qsTr("close application"); break
                default: actionText = qsTr("pause playback")
            }
            
            showSystemMessage(qsTr("Sleep Timer Started"), 
                             qsTr("Will %1 in %2").arg(actionText).arg(formatTimerDuration(minutes)))
        }
    }

    // Function to cancel timer
    function cancelSleepTimer() {
        if (sleepTimer.running) {
            sleepTimer.stop()
            remainingMinutes = 0
            timerNotificationShown = false
            showSystemMessage(qsTr("Sleep Timer"), qsTr("Timer cancelled"))
        }
    }

    // Execute the selected action when timer expires
    function executeTimerAction() {
        if (settings.debugLevel >= 1) {
            console.log("SLEEP: Executing timer action:", timerAction)
        }
        
        switch (timerAction) {
            case "stop":
                mediaController.stop()
                showSystemMessage(qsTr("Sleep Timer"), qsTr("Playback stopped"))
                break
                
            case "fade":
                // Implement fade out over 10 seconds
                fadeOutTimer.start()
                showSystemMessage(qsTr("Sleep Timer"), qsTr("Fading out..."))
                break
                
            case "close":
                showSystemMessage(qsTr("Sleep Timer"), qsTr("Closing application"))
                Qt.quit()
                break
                
            case "pause":
            default:
                mediaController.pause()
                showSystemMessage(qsTr("Sleep Timer"), qsTr("Playback paused"))
                break
        }
    }

    // Fade out timer for smooth volume reduction
    Timer {
        id: fadeOutTimer
        interval: 200  // Update every 200ms
        repeat: true
        property real originalVolume: 1.0
        property int fadeSteps: 0
        property int maxFadeSteps: 50  // 10 seconds total (50 * 200ms)
        
        onTriggered: {
            if (fadeSteps === 0) {
                originalVolume = mediaController.volume || 1.0
            }
            
            fadeSteps++
            var newVolume = originalVolume * (1.0 - (fadeSteps / maxFadeSteps))
            
            if (newVolume <= 0.0 || fadeSteps >= maxFadeSteps) {
                mediaController.pause()
                mediaController.volume = originalVolume  // Restore volume for next play
                stop()
                fadeSteps = 0
                showSystemMessage(qsTr("Sleep Timer"), qsTr("Playback paused"))
            } else {
                mediaController.volume = newVolume
            }
        }
    }

    // Format duration for timer display
    function formatTimerDuration(minutes) {
        if (minutes < 60) {
            return qsTr("%1 minutes").arg(minutes)
        } else {
            var hours = Math.floor(minutes / 60)
            var mins = minutes % 60
            if (mins === 0) {
                return qsTr("%n hour(s)", "", hours)
            } else {
                return qsTr("%1 hours %2 minutes").arg(hours).arg(mins)
            }
        }
    }

    // Show system message/notification
    function showSystemMessage(title, message) {
        console.log("System message:", title, "-", message)
        // Create a simple notification banner
        var component = Qt.createComponent("components/NotificationBanner.qml")
        if (component.status === Component.Ready) {
            var banner = component.createObject(applicationWindow, {
                "title": title,
                "message": message
            })
            if (banner) {
                banner.show()
            }
        }
    }

    // Sailfish-native RemorsePopup for notifications
    RemorsePopup {
        id: notificationRemorse
    }

    // Global notification functions using RemorsePopup
    function showErrorNotification(title, message) {
        console.log("ERROR:", title, "-", message)
        var fullMessage = title + (message ? "\n" + message : "")
        notificationRemorse.execute(fullMessage, function() {
            // Optional action after timeout - currently empty
        }, 8000) // 8 seconds timeout
    }

    function showWarningNotification(title, message) {
        console.log("WARNING:", title, "-", message)
        var fullMessage = title + (message ? "\n" + message : "")
        notificationRemorse.execute(fullMessage, function() {
            // Optional action after timeout - currently empty
        }, 6000) // 6 seconds timeout
    }

    function showSuccessNotification(title, message) {
        console.log("SUCCESS:", title, "-", message)
        var fullMessage = title + (message ? "\n" + message : "")
        notificationRemorse.execute(fullMessage, function() {
            // Optional action after timeout - currently empty
        }, 4000) // 4 seconds timeout
    }

    function showInfoNotification(title, message) {
        console.log("INFO:", title, "-", message)
        var fullMessage = title + (message ? "\n" + message : "")
        notificationRemorse.execute(fullMessage, function() {
            // Optional action after timeout - currently empty
        }, 5000) // 5 seconds timeout
    }

    // Switch to main page after successful login
    function switchToMainPage() {
        if (settings.debugLevel >= 1) {
            console.log("AUTH: Switching to main page after successful login, current depth:", pageStack.depth)
        }
        
        // Use timer to delay navigation slightly to ensure login process is complete
        switchTimer.start()
    }
    
    Timer {
        id: switchTimer
        interval: 500  // Wait 500ms for login to settle
        repeat: false
        onTriggered: {
            if (settings.debugLevel >= 1) {
                console.log("AUTH: Executing delayed switch to main page, pageStack depth:", pageStack.depth)
            }
            
            // Navigate back to first page
            if (pageStack.depth > 1) {
                pageStack.pop(pageStack.find(function(page) {
                    return page === applicationWindow.mainPage
                }))
            }
        }
    }



    TidalApi {
        id: tidalApi
        // its twice defined here in this file, the second time in connections
        /*onLoginFailed: {
            authManager.clearTokens()
            console.log("Login failed")
            pageStack.push(Qt.resolvedUrl("pages/Settings.qml"))
        }*/
    }


    PlaylistManager {
        id: playlistManager
        onCurrentTrackChanged: {
            if (track) {
                if (settings.debugLevel >= 2) {
                    console.log("PLAYLIST: Track changed to", track, "- preloading enabled:", mediaController.preloadingEnabled)
                }
                
                // Enhanced: Use crossfade system if preloading enabled
                if (mediaController.preloadingEnabled) {
                    // Only use URL cache if it has valid URLs with tokens
                    var cachedUrl = null
                    if (applicationWindow.settings.enableUrlCaching) {
                        cachedUrl = cacheManager.getCachedUrl(track.toString())
                    }
                    
                    if (cachedUrl) {
                        if (applicationWindow.settings.debugLevel >= 2) {
                            var hasToken = cachedUrl.indexOf('token') !== -1
                            var safeUrl = hasToken ? cachedUrl.split('?')[0] + "?token=***" : cachedUrl
                            console.log("PLAYLIST: Using crossfade for track", track, "with URL cache:", safeUrl.substring(0, 80) + "...")
                            console.log("PLAYLIST: URL cache has token:", hasToken ? "YES" : "NO")
                        }
                        if (!mediaController.switchToTrackImmediately(cachedUrl, track)) {
                            // Fallback to API request
                            if (settings.debugLevel >= 1) {
                                console.log("PLAYLIST: Crossfade failed, requesting fresh URL")
                            }
                            mediaController.requestTrackForCrossfade(track)
                        }
                    } else {
                        // Always request fresh URL with token via crossfade system
                        if (applicationWindow.settings.debugLevel >= 1) {
                            console.log("PlaylistManager: No valid cached URL for track", track, "- requesting fresh URL via crossfade system")
                        }
                        mediaController.requestTrackForCrossfade(track)
                    }
                } else {
                    // Preloading disabled, use normal API
                    tidalApi.playTrackId(track)
                }
            }
        }

    }

    FavoritesManager {
        id: favManager
    }

    TidalCache
    {
        id: cacheManager
    }

    PlaylistStorage {
        id: playlistStorage

        //property string currentPlaylistName: ""

        onPlaylistLoaded: {
            // Wenn eine Playlist geladen wird
            playlistTitle = name;
            playlistManager.forceClearPlayList();
            trackIds.forEach(function(trackId) {
                playlistManager.appendTrack(trackId);
            });
            // Setze die gespeicherte Position
            if (position >= 0) {
                playlistManager.playPosition(position);
            }
        }
    }


    MediaHandler
    {
        id: mediaController  // Keep same ID for compatibility
    }

    AdvancedPlayManager {
        id: advancedPlayManager
    }

    // MPRIS Player is now handled in MediaHandler

    initialPage: Component {
        FirstPage {
            id: firstpage
            Component.onCompleted: {
                // Store reference to the page
                applicationWindow.mainPage = this
                
                // Check if authentication is needed and redirect to settings
                authCheckTimer.start()
            }
        }
    }
    cover: CoverPage {
        application: applicationWindow
        //home : firstpage
    }
    allowedOrientations: defaultAllowedOrientations


    MiniPlayer {
        parent: pageStack
        id: miniPlayerPanel
        z:10
    }



    AuthManager {
            id: authManager
        }



    BusyIndicator {
        size: BusyIndicatorSize.Large
        anchors.centerIn: parent
        running: tidalApi.loading
    }

    Connections {
        target: tidalApi
        onOAuthSuccess: {
            authManager.updateTokens(type, token, rtoken, date)
        }
        onOAuthRefresh: {
            // AuthManager.refreshTokens is now called directly from TidalApi.qml handler
            if (settings.debugLevel >= 3) {
                console.log("AUTH: OAuth refresh signal received:", token)
            } else if (settings.debugLevel >= 1) {
                console.log("AUTH: OAuth refresh signal received (length:", token.length, "chars)")
            }
        }
        onLoginFailed: {
            authManager.clearTokens()
            console.log("Login failed")
            showErrorNotification(qsTr("Login Failed"), qsTr("Authentication failed. Please check your credentials."))
            pageStack.push(Qt.resolvedUrl("pages/Settings.qml"))
        }
    }


    Connections
    {
        target: playlistManager
        onCurrentId:
        {
            console.log("PlaylistManager: CurrentId signal for", id, "- preloading enabled:", mediaController.preloadingEnabled)
            
            // Skip if preloading enabled - handled by onCurrentTrackChanged to avoid duplicates
            if (mediaController.preloadingEnabled) {
                console.log("PlaylistManager: Skipping currentId processing - handled by onCurrentTrackChanged")
                return
            } else {
                // Preloading disabled, use normal API
                tidalApi.playTrackId(id)
            }
        }
    }


    // MPRIS connections are now handled internally in MediaHandler

    Connections
    {
    target: authManager
        onUpdateSettings:
        {
            token_type.value = applicationWindow.settings.token_type
            access_token.value = applicationWindow.settings.access_token
            refresh_token.value = applicationWindow.settings.refresh_token
            expiry_time.value = applicationWindow.settings.expiry_time
            mail.value = applicationWindow.settings.mail
            audioQuality.value = applicationWindow.settings.audio_quality
            resumePlayback.value = applicationWindow.settings.resume_playback
            hidePlayerOnFinished.value = applicationWindow.settings.hide_player
            autoLoadPlaylist.value = applicationWindow.settings.auto_load_playlist
            stayLoggedInConfig.value = applicationWindow.settings.stay_logged_in
            useNewHomescreen.value = applicationWindow.settings.useNewHomescreen
            defaultPlayAction.value = applicationWindow.settings.defaultPlayAction

            recentListConfig.value = applicationWindow.settings.recentList
            yourListConfig.value = applicationWindow.settings.yourList
            topartistListConfig.value = applicationWindow.settings.topartistList
            topalbumsListConfig.value = applicationWindow.settings.topalbumsList
            toptrackListConfig.value = applicationWindow.settings.toptrackList
            personalPlaylistListConfig.value = applicationWindow.settings.personalPlaylistList
            dailyMixesListConfig.value = applicationWindow.settings.dailyMixesList
            radioMixesListConfig.value = applicationWindow.settings.radioMixesList
            topArtistsListConfig.value = applicationWindow.settings.topArtistsList
            enableTrackPreloadingConfig.value = applicationWindow.settings.enableTrackPreloading
            crossfadeModeConfig.value = applicationWindow.settings.crossfadeMode
            crossfadeTimeMsConfig.value = applicationWindow.settings.crossfadeTimeMs
            debugLevelConfig.value = applicationWindow.settings.debugLevel
            enableUrlCachingConfig.value = applicationWindow.settings.enableUrlCaching
            lastTrackUrl.value = applicationWindow.settings.last_track_url
            lastTrackId.value = applicationWindow.settings.last_track_id
            lastTrackPosition.value = applicationWindow.settings.last_track_position
            
            // Save email history
            try {
                emailHistoryConfig.value = JSON.stringify(applicationWindow.settings.emailHistory || [])
            } catch (e) {
                console.log("EMAIL: Error saving history:", e)
            }
        }
    }

    // PERFORMANCE: Defer non-critical initialization
    Timer {
        id: deferredInitTimer
        interval: 100  // 100ms delay
        running: false
        repeat: false
        onTriggered: {
            // Load non-critical settings after initial UI render
            applicationWindow.settings.recentList = recentListConfig.value
            applicationWindow.settings.yourList = yourListConfig.value
            applicationWindow.settings.topartistList = topartistListConfig.value
            applicationWindow.settings.topalbumsList = topalbumsListConfig.value
            applicationWindow.settings.toptrackList = toptrackListConfig.value
            applicationWindow.settings.personalPlaylistList = personalPlaylistListConfig.value
            applicationWindow.settings.dailyMixesList = dailyMixesListConfig.value
            applicationWindow.settings.radioMixesList = radioMixesListConfig.value
            applicationWindow.settings.topArtistsList = topArtistsListConfig.value
            
            console.log("Deferred settings loaded")
            
            // Try to restore playback after all settings are loaded
            if (applicationWindow.settings.resume_playback) {
                // Only start resume timer if we have valid authentication and are showing main page
                if (applicationWindow.settings.access_token && 
                    applicationWindow.settings.refresh_token &&
                    applicationWindow.settings.access_token !== "" &&
                    applicationWindow.settings.refresh_token !== "" &&
                    applicationWindow.loginTrue) {
                    
                    if (applicationWindow.settings.debugLevel >= 2) {
                        console.log("RESUME: Starting resume timer - authenticated and on main page")
                    }
                    resumeRestoreTimer.start()
                } else {
                    if (applicationWindow.settings.debugLevel >= 1) {
                        console.log("RESUME: Skipping resume - not authenticated or on settings page")
                    }
                }
            }
        }
    }

    Component.onCompleted:
    {
        // CRITICAL settings - load immediately
        applicationWindow.settings.token_type = token_type.value
        applicationWindow.settings.access_token = access_token.value
        applicationWindow.settings.refresh_token = refresh_token.value
        applicationWindow.settings.expiry_time = expiry_time.value
        applicationWindow.settings.mail = mail.value
        applicationWindow.settings.audio_quality = audioQuality.value
        applicationWindow.settings.resume_playback = resumePlayback.value
        applicationWindow.settings.hide_player = hidePlayerOnFinished.value
        applicationWindow.settings.auto_load_playlist = autoLoadPlaylist.value
        applicationWindow.settings.stay_logged_in = stayLoggedInConfig.value
        applicationWindow.settings.useNewHomescreen = useNewHomescreen.value
        applicationWindow.settings.defaultPlayAction = defaultPlayAction.value
        applicationWindow.settings.enableTrackPreloading = enableTrackPreloadingConfig.value
        applicationWindow.settings.crossfadeMode = crossfadeModeConfig.value
        applicationWindow.settings.crossfadeTimeMs = crossfadeTimeMsConfig.value
        applicationWindow.settings.debugLevel = debugLevelConfig.value
        applicationWindow.settings.enableUrlCaching = enableUrlCachingConfig.value
        applicationWindow.settings.last_track_url = lastTrackUrl.value
        applicationWindow.settings.last_track_id = lastTrackId.value
        applicationWindow.settings.last_track_position = lastTrackPosition.value
        
        // Load email history
        try {
            var historyJson = emailHistoryConfig.value
            applicationWindow.settings.emailHistory = historyJson ? JSON.parse(historyJson) : []
            if (applicationWindow.settings.debugLevel >= 2) {
                console.log("EMAIL: Loaded history with", applicationWindow.settings.emailHistory.length, "entries")
            }
        } catch (e) {
            console.log("EMAIL: Error loading history, resetting:", e)
            applicationWindow.settings.emailHistory = []
        }
        tidalApi.quality = audioQuality.value

        // LOG LEVEL INFORMATION - Display current debug configuration
        var debugLevel = applicationWindow.settings.debugLevel || 0
        var debugLevelNames = ["None", "Normal", "Informative", "Verbose/Spawn"]
        var levelName = debugLevelNames[debugLevel] || ("Custom:" + debugLevel)
        console.log("STARTUP: Tidal Player initialized with debug level", debugLevel, "(" + levelName + ")")
        if (debugLevel >= 1) {
            console.log("STARTUP: Track preloading:", applicationWindow.settings.enableTrackPreloading ? "enabled" : "disabled")
            console.log("STARTUP: Crossfade mode:", applicationWindow.settings.crossfadeMode, "time:", applicationWindow.settings.crossfadeTimeMs + "ms")
            console.log("STARTUP: New homescreen:", applicationWindow.settings.useNewHomescreen ? "enabled" : "disabled")
            console.log("STARTUP: URL caching:", applicationWindow.settings.enableUrlCaching ? "enabled" : "disabled")
        }

        // PERFORMANCE: Critical initialization first
        authManager.checkAndLogin()
        // MPRIS is now initialized in MediaHandler
        
        // PERFORMANCE: Defer non-critical settings loading
        deferredInitTimer.start()
    }

    Component.onDestruction:
    {
        // Save resume state before closing
        if (settings.debugLevel >= 1) {
            console.log("RESUME: App closing - saving current state")
        }
        if (settings) {
            settings.saveCurrentState()
        }
        
        // Save all settings
        token_type.value = applicationWindow.settings.token_type
        access_token.value = applicationWindow.settings.access_token
        refresh_token.value = applicationWindow.settings.refresh_token
        expiry_time.value = applicationWindow.settings.expiry_time
        mail.value = applicationWindow.settings.mail
        audioQuality.value = applicationWindow.settings.audio_quality
        resumePlayback.value = applicationWindow.settings.resume_playback
        hidePlayerOnFinished.value = applicationWindow.settings.hide_player
        autoLoadPlaylist.value = applicationWindow.settings.auto_load_playlist
        stayLoggedInConfig.value = applicationWindow.settings.stay_logged_in

        recentListConfig.value = applicationWindow.settings.recentList
        yourListConfig.value = applicationWindow.settings.yourList
        topartistListConfig.value = applicationWindow.settings.topartistList
        topalbumsListConfig.value = applicationWindow.settings.topalbumsList
        toptrackListConfig.value = applicationWindow.settings.toptrackList
        personalPlaylistListConfig.value = applicationWindow.settings.personalPlaylistList

        dailyMixesListConfig.value = applicationWindow.settings.dailyMixesList
        radioMixesListConfig.value = applicationWindow.settings.radioMixesList
        topArtistsListConfig.value = applicationWindow.settings.topArtistsList
        enableTrackPreloadingConfig.value = applicationWindow.settings.enableTrackPreloading
        crossfadeModeConfig.value = applicationWindow.settings.crossfadeMode
        crossfadeTimeMsConfig.value = applicationWindow.settings.crossfadeTimeMs
        debugLevelConfig.value = applicationWindow.settings.debugLevel
        enableUrlCachingConfig.value = applicationWindow.settings.enableUrlCaching
        lastTrackUrl.value = applicationWindow.settings.last_track_url
        lastTrackId.value = applicationWindow.settings.last_track_id
        lastTrackPosition.value = applicationWindow.settings.last_track_position
    }

}
