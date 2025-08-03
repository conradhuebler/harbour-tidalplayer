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
    
    property FirstPage mainPage

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
        id: topArtistsListConfig
        key : "/topArtistsList"
        defaultValue: true
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
        console.log("Starting sleep timer:", minutes, "minutes, action:", action || "pause")
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
        console.log("Executing timer action:", timerAction)
        
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
                tidalApi.playTrackId(track)
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
            id: firstpage  // Diese ID wird nun über applicationWindow.firstPage verfügbar
            Component.onCompleted: {
                // Store reference to the page
                applicationWindow.mainPage = this
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
            console.log("OAuth refresh signal received:", token)
        }
        onLoginFailed: {
            authManager.clearTokens()
            console.log("Login failed")
            pageStack.push(Qt.resolvedUrl("pages/Settings.qml"))
        }
    }


    Connections
    {
        target: playlistManager
        onCurrentId:
        {
            tidalApi.playTrackId(id)
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
        tidalApi.quality = audioQuality.value

        // PERFORMANCE: Critical initialization first
        authManager.checkAndLogin()
        // MPRIS is now initialized in MediaHandler
        
        // PERFORMANCE: Defer non-critical settings loading
        deferredInitTimer.start()
    }

    Component.onDestruction:
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

        recentListConfig.value = applicationWindow.settings.recentList
        yourListConfig.value = applicationWindow.settings.yourList
        topartistListConfig.value = applicationWindow.settings.topartistList
        topalbumsListConfig.value = applicationWindow.settings.topalbumsList
        toptrackListConfig.value = applicationWindow.settings.toptrackList
        personalPlaylistListConfig.value = applicationWindow.settings.personalPlaylistList

        dailyMixesListConfig.value = applicationWindow.settings.dailyMixesList
        radioMixesListConfig.value = applicationWindow.settings.radioMixesList
        topArtistsListConfig.value = applicationWindow.settings.topArtistsList
    }

}
