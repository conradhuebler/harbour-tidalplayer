import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Configuration 1.0

import "../components/"

Page {
    id: page
    allowedOrientations: Orientation.All

    // Configuration values - Claude Generated
    ConfigurationValue {
        id: useNewHomescreen
        key: "/useNewHomescreen"
        defaultValue: false
    }

    ConfigurationValue {
        id: mail
        key: "/mail"
        defaultValue: ""
    }

    ConfigurationValue {
        id: defaultPlayAction
        key: "/defaultPlayAction"
        defaultValue: "replace"
    }

    ConfigurationValue {
        id: debugLevelConfig
        key: "/debugLevel"
        defaultValue: 0
    }

    ConfigurationValue {
        id: enableUrlCachingConfig
        key: "/enableUrlCaching"
        defaultValue: false
    }

    // Auto-refresh timer for status display - Claude Generated
    Timer {
        id: statusUpdateTimer
        interval: 1000  // Update every second
        repeat: true
        running: tidalApi.loginTrue && page.status === PageStatus.Active
        onTriggered: {
            // Trigger text re-evaluation by updating a dummy property
            statusTrigger = !statusTrigger
        }
    }
    
    // Dummy property to trigger status label updates
    property bool statusTrigger: false

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge

            PageHeader {
                title: qsTr("Settings")
            }

            // LOGIN REQUIRED STATE - Only show login when not authenticated
            SectionHeader {
                text: qsTr("Login Required")
                visible: !tidalApi.loginTrue
            }
            
            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                text: qsTr("Please sign in to access your Tidal music library and configure the app")
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.primaryColor
                wrapMode: Text.WordWrap
                visible: !tidalApi.loginTrue
            }

            TextField {
                id: emailField
                width: parent.width
                text: applicationWindow.settings.mail || ""
                label: qsTr("Email address")
                placeholderText: qsTr("Enter your email")
                EnterKey.enabled: text.length > 0
                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: focus = false
                visible: !tidalApi.loginTrue

                onTextChanged: {
                    mail.value = text
                }
            }

            Item {
                width: parent.width
                height: Theme.paddingLarge
                visible: !tidalApi.loginTrue
            }

            Button {
                anchors {
                    left: parent.left
                    right: parent.right
                    margins: Theme.horizontalPageMargin
                }
                text: qsTr("Login with Tidal")
                visible: !tidalApi.loginTrue
                preferredWidth: Theme.buttonWidthLarge
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("../dialogs/OAuth.qml"))
                }
            }

            SectionHeader {
                text: qsTr("Interface")
            }
            
            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                text: qsTr("Customize the app interface and behavior")
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.secondaryColor
                wrapMode: Text.WordWrap
            }

            TextSwitch {
                text: qsTr("New Homescreen")
                description: qsTr("Use configurable homescreen with drag & drop sections")
                checked: applicationWindow.settings.useNewHomescreen || false
                onCheckedChanged: {
                    applicationWindow.settings.useNewHomescreen = checked
                    useNewHomescreen.value = checked
                }
            }

            Button {
                anchors {
                    left: parent.left
                    right: parent.right
                    margins: Theme.horizontalPageMargin
                }
                text: qsTr("Homescreen Layout")
                //description: qsTr("Configure sections and ordering for the new homescreen")
                //visible: applicationWindow.settings.useNewHomescreen || false
                //enabled: tidalApi.loginTrue
                onClicked: {
                    if (tidalApi.loginTrue) {
                        pageStack.push(Qt.resolvedUrl("HomescreenSettings.qml"), {
                            homescreenManager: applicationWindow.homescreenManager
                        })
                    }
                }
            }

            ComboBox {
                label: qsTr("Default Play Action")
                description: qsTr("What happens when you tap on a track/album")
                
                menu: ContextMenu {
                    MenuItem { 
                        text: qsTr("Replace Playlist & Play")
                        property string value: "replace"
                    }
                    MenuItem { 
                        text: qsTr("Add to Playlist & Play") 
                        property string value: "append"
                    }
                    MenuItem { 
                        text: qsTr("Play Now (Keep Playlist)")
                        property string value: "playnow"
                    }
                    MenuItem { 
                        text: qsTr("Add to Queue")
                        property string value: "queue"
                    }
                }
                
                currentIndex: {
                    var action = applicationWindow.settings.defaultPlayAction || "replace"
                    switch (action) {
                        case "replace": return 0
                        case "append": return 1
                        case "playnow": return 2
                        case "queue": return 3
                        default: return 0
                    }
                }
                
                onCurrentItemChanged: {
                    if (currentItem) {
                        applicationWindow.settings.defaultPlayAction = currentItem.value
                        defaultPlayAction.value = currentItem.value
                    }
                }
            }

            SectionHeader {
                text: qsTr("Playback")
                visible: tidalApi.loginTrue
            }
            
            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                text: qsTr("Configure audio quality and playback behavior")
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.secondaryColor
                wrapMode: Text.WordWrap
                visible: tidalApi.loginTrue
            }

            ComboBox {
                id: audioQuality
                visible: tidalApi.loginTrue
                label: qsTr("Audio Quality")
                description: qsTr("Select streaming quality")
                property var qualities: ["LOW", "HIGH", "LOSSLESS", "HI_RES"]
                menu: ContextMenu {
                    MenuItem { text: qsTr("Low (96 kbps)") }
                    MenuItem { text: qsTr("High (320 kbps)") }
                    MenuItem { text: qsTr("Lossless (FLAC)") }
                    MenuItem { text: qsTr("Master (MQA)") }
                }
                onCurrentIndexChanged: {
                    if (currentIndex >= 0 && currentIndex < qualities.length) {
                        applicationWindow.settings.audio_quality = qualities[currentIndex]
                    }
                }
            }

            TextSwitch {
                id: resumePlayback
                visible: tidalApi.loginTrue
                text: qsTr("Resume playback on startup")
                description: qsTr("Resume playback after starting the app")
                checked: applicationWindow.settings.resume_playback
                onClicked: {
                    applicationWindow.settings.resume_playback = resumePlayback.checked
                }
            }

            TextSwitch {
                id: enableTrackPreloading
                visible: tidalApi.loginTrue
                text: qsTr("Enable Track Pre-loading")
                description: qsTr("Load next track in background for seamless playback (experimental)")
                checked: applicationWindow.settings.enableTrackPreloading || false
                onClicked: {
                    applicationWindow.settings.enableTrackPreloading = enableTrackPreloading.checked
                    console.log("Settings: Track preloading toggle clicked:", enableTrackPreloading.checked ? "enabled" : "disabled")
                    console.log("Settings: applicationWindow.settings.enableTrackPreloading =", applicationWindow.settings.enableTrackPreloading)
                }
            }

            ComboBox {
                id: crossfadeMode
                visible: tidalApi.loginTrue && (applicationWindow.settings.enableTrackPreloading || false)
                label: qsTr("Crossfade Mode")
                description: qsTr("How tracks transition during seamless playback")
                
                menu: ContextMenu {
                    MenuItem { 
                        text: qsTr("No Fade Out")
                        property int value: 0
                    }
                    MenuItem { 
                        text: qsTr("Timer Fade Out") 
                        property int value: 1
                    }
                    MenuItem { 
                        text: qsTr("Buffer-Dependent Crossfade")
                        property int value: 2
                    }
                    MenuItem { 
                        text: qsTr("Buffer Fade-Out Only")
                        property int value: 3
                    }
                }
                
                currentIndex: {
                    var mode = applicationWindow.settings.crossfadeMode || 1
                    switch (mode) {
                        case 0: return 0
                        case 1: return 1
                        case 2: return 2
                        case 3: return 3
                        default: return 1
                    }
                }
                
                onCurrentItemChanged: {
                    if (currentItem) {
                        applicationWindow.settings.crossfadeMode = currentItem.value
                        console.log("Settings: Crossfade mode changed to:", currentItem.value)
                    }
                }
            }

            Slider {
                id: crossfadeTime
                visible: tidalApi.loginTrue && (applicationWindow.settings.enableTrackPreloading || false) && (applicationWindow.settings.crossfadeMode === 1)
                width: parent.width
                label: qsTr("Fade Out Time")
                minimumValue: 200
                maximumValue: 5000
                stepSize: 100
                value: applicationWindow.settings.crossfadeTimeMs || 1000
                valueText: value + " ms"
                
                onValueChanged: {
                    applicationWindow.settings.crossfadeTimeMs = value
                    console.log("Settings: Crossfade time changed to:", value + "ms")
                }
            }

            TextSwitch {
                id: hidePlayerOnFinished
                visible: tidalApi.loginTrue
                text: qsTr("Hide player on finished")
                description: qsTr("Hide player when playback is finished")
                checked: applicationWindow.settings.hide_player
                onClicked: {
                    applicationWindow.settings.hide_player = hidePlayerOnFinished.checked
                }
            }

            TextSwitch {
                id: autoLoadPlaylist
                visible: tidalApi.loginTrue
                text: qsTr("Auto-load last playlist")
                description: qsTr("Automatically load the last playlist on startup")
                checked: applicationWindow.settings.auto_load_playlist
                onClicked: {
                    applicationWindow.settings.auto_load_playlist = autoLoadPlaylist.checked
                }
            }

            Button {
                anchors {
                    left: parent.left
                    right: parent.right
                    margins: Theme.horizontalPageMargin
                }
                text: qsTr("Sleep Timer")
                visible: tidalApi.loginTrue
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("../dialogs/SleepTimerDialog.qml"))
                }
            }

            SectionHeader {
                text: qsTr("Home")
                visible: tidalApi.loginTrue
            }

            TextSwitch {
                id: recentList
                visible: tidalApi.loginTrue
                text: qsTr("Show Recent")
                description: qsTr("Show recently played tracks, playlist, albums and mixes")
                checked: applicationWindow.settings.recentList
                onClicked: {
                    applicationWindow.settings.recentList = recentList.checked
                }
            }

            TextSwitch {
                id: yourList
                visible: tidalApi.loginTrue
                text: qsTr("Show Popular Playlists")
                description: qsTr("Show popular playlists")
                checked: applicationWindow.settings.yourList
                onClicked: {
                    applicationWindow.settings.yourList = yourList.checked
                }
            }

            TextSwitch {
                id: topartistList
                visible: tidalApi.loginTrue
                text: qsTr("Show Favourite Artists")
                description: qsTr("Show your favourite artists")
                checked: applicationWindow.settings.topartistList
                onClicked: {
                    applicationWindow.settings.topartistList = topartistList.checked
                }
            }

            TextSwitch {
                id: topalbumsList
                visible: tidalApi.loginTrue
                text: qsTr("Show Favourite Albums")
                description: qsTr("Show your favourite played albums")
                checked: applicationWindow.settings.topalbumsList
                onClicked: {
                    applicationWindow.settings.topalbumsList = topalbumsList.checked
                }
            }

            TextSwitch {
                id: toptrackList
                visible: tidalApi.loginTrue
                text: qsTr("Show Favourite Tracks")
                description: qsTr("Show your favourite played tracks")
                checked: applicationWindow.settings.toptrackList
                onClicked: {
                    applicationWindow.settings.toptrackList = toptrackList.checked
                }
            }

            TextSwitch {
                id: personalPlaylistList
                visible: tidalApi.loginTrue
                text: qsTr("Show Personal Playlists")
                description: qsTr("Show your personal playlists")
                checked: applicationWindow.settings.personalPlaylistList
                onClicked: {
                    applicationWindow.settings.personalPlaylistList = personalPlaylistList.checked
                }
            }

            TextSwitch {
                id: dailyMixesList
                visible: tidalApi.loginTrue
                text: qsTr("Show Custom Mixes")
                description: qsTr("Show custom mixes")
                checked: applicationWindow.settings.dailyMixesList
                onClicked: {
                    applicationWindow.settings.dailyMixesList = dailyMixesList.checked
                }
            }

            TextSwitch {
                id: radioMixesList
                visible: tidalApi.loginTrue
                text: qsTr("Show Personal Radio Stations")
                description: qsTr("Show personal radio stations")
                checked: applicationWindow.settings.radioMixesList
                onClicked: {
                    applicationWindow.settings.radioMixesList = radioMixesList.checked
                }
            }

            TextSwitch {
                id: topArtistsList
                visible: tidalApi.loginTrue
                text: qsTr("Show Recent Favorite Artists")
                description: qsTr("Show recent favorite artists")
                checked: applicationWindow.settings.topArtistsList
                onClicked: {
                    applicationWindow.settings.topArtistsList = topArtistsList.checked
                }
            }            

            SectionHeader {
                text: qsTr("Maintenance")

            }
            Button {
                anchors {
                    left: parent.left
                    right: parent.right
                    margins: Theme.horizontalPageMargin
                }
                text: qsTr("Re-Init session")
                visible: tidalApi.loginTrue
                onClicked: {
                    authManager.checkAndLogin()
                    tidalApi.reInit()
                }
            }
            Button {
                anchors {
                    left: parent.left
                    right: parent.right
                    margins: Theme.horizontalPageMargin
                }
                text: qsTr("Reset Cache")
                visible: true
                onClicked: {
                    cacheManager.clearCache()
                }
            }

            Button {
                anchors {
                    left: parent.left
                    right: parent.right
                    margins: Theme.horizontalPageMargin
                }
                text: qsTr("Reset Audio Players")
                visible: tidalApi.loginTrue
                onClicked: {
                    if (applicationWindow.mediaController && applicationWindow.mediaController.dualAudioManager) {
                        applicationWindow.mediaController.dualAudioManager.resetPlayers()
                    }
                }
            }

            SectionHeader {
                text: qsTr("Audio Player Status")
                visible: tidalApi.loginTrue
            }
            
            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                text: qsTr("Real-time status of dual audio players for crossfade system")
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.secondaryColor
                wrapMode: Text.WordWrap
                visible: tidalApi.loginTrue
            }

            // Player Status Container - Claude Generated
            Rectangle {
                width: parent.width - 2 * Theme.horizontalPageMargin
                height: playerStatusColumn.height + 2 * Theme.paddingMedium
                x: Theme.horizontalPageMargin
                color: Theme.rgba(Theme.highlightBackgroundColor, 0.1)
                radius: Theme.paddingSmall
                border.color: Theme.rgba(Theme.highlightBackgroundColor, 0.2)
                border.width: 1
                visible: tidalApi.loginTrue
                
                Column {
                    id: playerStatusColumn
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: Theme.paddingMedium
                    }
                    spacing: Theme.paddingSmall
                    
                    Label {
                        id: player1Status
                        width: parent.width
                        text: {
                            statusTrigger; // Force re-evaluation when statusTrigger changes
                            try {
                                var dualManager = applicationWindow.mediaController.dualAudioManager

                                if (dualManager && dualManager.audioPlayer1) {
                                    var player = dualManager.audioPlayer1
                                    var status = player.status
                                    var position = Math.floor(player.position / 1000)
                                    var duration = Math.floor(player.duration / 1000)
                                    var isActive = dualManager.player1Active ? " (ACTIVE)" : ""
                                    var statusText = getStatusText(status)
                                    return qsTr("Player 1: ") + statusText + isActive + (duration > 0 ? " (" + position + "s/" + duration + "s)" : "")
                                }
                            } catch (e) {
                                console.log("Settings: Error accessing Player1 status:", e)
                            }
                            return qsTr("Player 1: Not Available")
                        }
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.primaryColor
                        wrapMode: Text.WordWrap
                    }
                    
                    Label {
                        id: player2Status
                        width: parent.width
                        text: {
                            statusTrigger; // Force re-evaluation when statusTrigger changes
                            try {
                                var dualManager = applicationWindow.mediaController.dualAudioManager
                                if (dualManager && dualManager.audioPlayer2) {
                                    var player = dualManager.audioPlayer2
                                    var status = player.status
                                    var position = Math.floor(player.position / 1000)
                                    var duration = Math.floor(player.duration / 1000)
                                    var isActive = !dualManager.player1Active ? " (ACTIVE)" : ""
                                    var statusText = getStatusText(status)
                                    return qsTr("Player 2: ") + statusText + isActive + (duration > 0 ? " (" + position + "s/" + duration + "s)" : "")
                                }
                            } catch (e) {
                                console.log("Settings: Error accessing Player2 status:", e)
                            }
                            return qsTr("Player 2: Not Available")
                        }
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.primaryColor
                        wrapMode: Text.WordWrap
                    }
                    
                    Label {
                        id: activePlayerStatus
                        width: parent.width
                        text: {
                            statusTrigger; // Force re-evaluation when statusTrigger changes
                            try {
                                var dualManager = applicationWindow.mediaController.dualAudioManager
                                if (dualManager && dualManager.activePlayer) {
                                    var activePlayer = dualManager.activePlayer
                                    var status = activePlayer.status
                                    var position = Math.floor(activePlayer.position / 1000)
                                    var duration = Math.floor(activePlayer.duration / 1000)
                                    var playerNum = dualManager.player1Active ? "1" : "2"
                                    var statusText = getStatusText(status)
                                    return qsTr("Active: Player ") + playerNum + " - " + statusText + (duration > 0 ? " (" + position + "s/" + duration + "s)" : "")
                                }
                            } catch (e) {
                                console.log("Settings: Error accessing Active Player status:", e)
                            }
                            return qsTr("Active Player: Not Available")
                        }
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: Theme.highlightColor
                        font.bold: true
                        wrapMode: Text.WordWrap
                    }
                }
            }


            SectionHeader {
                text: qsTr("Advanced & Debug")
            }
            
            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                text: qsTr("Advanced settings for debugging and development")
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.secondaryColor
                wrapMode: Text.WordWrap
            }

            ComboBox {
                id: debugLevelCombo
                label: qsTr("Debug Level")
                description: qsTr("Higher levels show more detailed logs but may affect performance")
                
                menu: ContextMenu {
                    MenuItem { 
                        text: qsTr("None (0)") 
                        property int value: 0
                    }
                    MenuItem { 
                        text: qsTr("Normal (1)") 
                        property int value: 1
                    }
                    MenuItem { 
                        text: qsTr("Informative (2)") 
                        property int value: 2
                    }
                    MenuItem { 
                        text: qsTr("Verbose/Spawn (3)") 
                        property int value: 3
                    }
                }
                
                onCurrentItemChanged: {
                    if (currentItem) {
                        var newLevel = currentItem.value
                        var levelNames = ["None", "Normal", "Informative", "Verbose/Spawn"]
                        console.log("SETTINGS: Debug level changed to", newLevel, "(" + levelNames[newLevel] + ")")
                        applicationWindow.settings.debugLevel = newLevel
                        debugLevelConfig.value = newLevel
                    }
                }
                
                Component.onCompleted: {
                    // Set current selection based on saved setting
                    var savedLevel = applicationWindow.settings.debugLevel || 0
                    for (var i = 0; i < menu.children.length; i++) {
                        if (menu.children[i].value === savedLevel) {
                            currentIndex = i
                            break
                        }
                    }
                }
            }
            
            SectionHeader {
                text: qsTr("Experimental Features")
            }
            
            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                text: qsTr("⚠️ Warning: These features are experimental and may cause crashes or unexpected behavior")
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.errorColor
                wrapMode: Text.WordWrap
            }
            
            TextSwitch {
                id: enableUrlCaching
                text: qsTr("Enable URL Caching")
                description: qsTr("Cache track URLs for faster loading (may cause issues)")
                checked: applicationWindow.settings.enableUrlCaching || false
                onCheckedChanged: {
                    applicationWindow.settings.enableUrlCaching = checked
                    enableUrlCachingConfig.value = checked
                }
            }

            // ACCOUNT SETTINGS - Only show at the end when authenticated
            SectionHeader {
                text: qsTr("Account")
                visible: tidalApi.loginTrue
            }
            
            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                text: qsTr("Manage your Tidal account and authentication settings")
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.secondaryColor
                wrapMode: Text.WordWrap
                visible: tidalApi.loginTrue
            }

            TextField {
                id: emailFieldLoggedIn
                width: parent.width
                text: applicationWindow.settings.mail || ""
                label: qsTr("Email address")
                placeholderText: qsTr("Enter your email")
                EnterKey.enabled: text.length > 0
                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: focus = false
                visible: tidalApi.loginTrue
                readOnly: true
                color: Theme.secondaryColor

                onTextChanged: {
                    if (!readOnly) mail.value = text
                }
            }

            TextSwitch {
                id: stayLoggedInEnd
                visible: tidalApi.loginTrue
                text: qsTr("Stay logged in")
                description: qsTr("Prevent automatic logout on token errors")
                checked: applicationWindow.settings.stay_logged_in
                onClicked: {
                    applicationWindow.settings.stay_logged_in = stayLoggedInEnd.checked
                    console.log("Stay logged in setting:", stayLoggedInEnd.checked)
                }
            }

            // Email History Management
            SectionHeader {
                text: qsTr("Email History")
                visible: tidalApi.loginTrue && applicationWindow.settings.getEmailHistory().length > 0
            }
            
            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                text: qsTr("Previously used email addresses for quick login")
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.secondaryColor
                wrapMode: Text.WordWrap
                visible: tidalApi.loginTrue && applicationWindow.settings.getEmailHistory().length > 0
            }

            Repeater {
                model: tidalApi.loginTrue ? applicationWindow.settings.getEmailHistory() : []
                delegate: ListItem {
                    width: parent.width
                    contentHeight: emailLabel.height + Theme.paddingMedium
                    
                    Row {
                        anchors {
                            left: parent.left
                            right: parent.right
                            margins: Theme.horizontalPageMargin
                            verticalCenter: parent.verticalCenter
                        }
                        spacing: Theme.paddingMedium
                        
                        Label {
                            id: emailLabel
                            text: modelData
                            color: modelData === applicationWindow.settings.mail ? Theme.highlightColor : Theme.primaryColor
                            font.bold: modelData === applicationWindow.settings.mail
                            width: parent.width - deleteButton.width - parent.spacing
                            truncationMode: TruncationMode.Elide
                        }
                        
                        IconButton {
                            id: deleteButton
                            icon.source: "image://theme/icon-m-delete"
                            onClicked: {
                                var dialog = pageStack.push(Qt.resolvedUrl("../dialogs/ConfirmationDialog.qml"), {
                                    title: qsTr("Remove Email"),
                                    message: qsTr("Remove '%1' from email history?").arg(modelData),
                                    acceptText: qsTr("Remove"),
                                    cancelText: qsTr("Cancel")
                                })
                                
                                if (dialog && dialog.accepted) {
                                    dialog.accepted.connect(function() {
                                        if (applicationWindow.settings.debugLevel >= 1) {
                                            console.log("EMAIL: User confirmed removal of", modelData)
                                        }
                                        applicationWindow.settings.removeEmailFromHistory(modelData)
                                    })
                                }
                            }
                        }
                    }
                    
                    onClicked: {
                        // Select this email for login
                        if (modelData !== applicationWindow.settings.mail) {
                            applicationWindow.settings.mail = modelData
                            if (applicationWindow.settings.debugLevel >= 1) {
                                console.log("EMAIL: Selected from history:", modelData)
                            }
                        }
                    }
                }
            }
            
            Button {
                anchors {
                    left: parent.left
                    right: parent.right
                    margins: Theme.horizontalPageMargin
                }
                text: qsTr("Clear Email History")
                visible: tidalApi.loginTrue && applicationWindow.settings.getEmailHistory().length > 0
                onClicked: {
                    var dialog = pageStack.push(Qt.resolvedUrl("../dialogs/ConfirmationDialog.qml"), {
                        title: qsTr("Clear Email History"),
                        message: qsTr("Remove all email addresses from history?"),
                        acceptText: qsTr("Clear All"),
                        cancelText: qsTr("Cancel")
                    })
                    
                    if (dialog && dialog.accepted) {
                        dialog.accepted.connect(function() {
                            if (applicationWindow.settings.debugLevel >= 1) {
                                console.log("EMAIL: User confirmed clearing all history")
                            }
                            applicationWindow.settings.clearEmailHistory()
                        })
                    }
                }
            }

            Button {
                anchors {
                    left: parent.left
                    right: parent.right
                    margins: Theme.horizontalPageMargin
                }
                text: qsTr("Logout")
                visible: tidalApi.loginTrue
                color: Theme.errorColor
                onClicked: {
                    var dialog = pageStack.push(Qt.resolvedUrl("../dialogs/ConfirmationDialog.qml"), {
                        title: qsTr("Confirm Logout"),
                        message: qsTr("Are you sure you want to logout? This will clear your stored credentials."),
                        acceptText: qsTr("Logout"),
                        cancelText: qsTr("Cancel")
                    })
                    
                    if (dialog && dialog.accepted) {
                        dialog.accepted.connect(function() {
                            if (applicationWindow.settings.debugLevel >= 1) {
                                console.log("SETTINGS: User confirmed logout")
                            }
                            authManager.forceLogout()
                        })
                    } else {
                        console.log("Warning: ConfirmationDialog or accepted signal not available")
                        // Fallback - logout directly if dialog fails
                        if (applicationWindow.settings.debugLevel >= 1) {
                            console.log("SETTINGS: Dialog failed, performing direct logout")
                        }
                        authManager.forceLogout()
                    }
                }
            }

        }

        VerticalScrollDecorator {}


    Component.onCompleted: {
        var savedQuality = applicationWindow.settings.audio_quality
        var idx = audioQuality.qualities.indexOf(savedQuality)
        idx >= 0 ? idx : 1  // default to HIGH (index 1) if not found
        audioQuality.currentIndex = idx
       }
    }

    // Helper function to convert Audio status codes to readable text
    function getStatusText(status) {
        switch(status) {
            case 0: return qsTr("Unknown")
            case 1: return qsTr("No Media")
            case 2: return qsTr("Loading")
            case 3: return qsTr("Loaded")
            case 4: return qsTr("Buffering")
            case 5: return qsTr("Buffered")
            case 6: return qsTr("End of Media")
            case 7: return qsTr("Invalid Media")
            default: return qsTr("Status ") + status
        }
    }
}
