import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Configuration 1.0

import "../components/"

Page {
    id: page
    allowedOrientations: Orientation.All

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

            SectionHeader {
                text: qsTr("Account")
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

                onTextChanged: {
                    mail.value = text
                }
            }

            Item {
                width: parent.width
                height: Theme.paddingLarge
            }

            TextSwitch {
                id: stayLoggedIn
                visible: tidalApi.loginTrue
                text: qsTr("Stay logged in")
                description: qsTr("Prevent automatic logout on token errors")
                checked: applicationWindow.settings.stay_logged_in
                onClicked: {
                    applicationWindow.settings.stay_logged_in = stayLoggedIn.checked
                    console.log("Stay logged in setting:", stayLoggedIn.checked)
                }
            }

            Button {
                anchors {
                    left: parent.left
                    right: parent.right
                    margins: Theme.horizontalPageMargin
                }
                text: qsTr("Login with Tidal")
                visible: !tidalApi.loginTrue
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("../dialogs/OAuth.qml"))
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
                onClicked: {
                    authManager.clearTokens()
                    token_type.value = "clear"
                    access_token.value = "clear"
                    tidalApi.loginTrue = false
                }
            }

            SectionHeader {
                text: qsTr("Interface")
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
                    applicationWindow.settings.audio_quality = qualities[currentIndex]
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
                    //### re-ini - try (1)
                    //tidalApi.reInitSession()
                    //### re-init - try (2)
                    authManager.checkAndLogin()
                    // seems that tidalApi.ini does not get called
                    tidalApi.reInit()
                    // seems that mpris player still needs a PushUpMenu
                    // on wifi - mobile network switch checkAndLogin() does not suffice
                    mprisPlayer.setCanControl(true)
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
                id: player1Status
                text: {
                    statusTrigger; // Force re-evaluation when statusTrigger changes
                    if (applicationWindow.mediaController && applicationWindow.mediaController.dualAudioManager && applicationWindow.mediaController.dualAudioManager.audioPlayer1) {
                        var status = applicationWindow.mediaController.dualAudioManager.audioPlayer1.status
                        var position = Math.floor(applicationWindow.mediaController.dualAudioManager.audioPlayer1.position / 1000)
                        var duration = Math.floor(applicationWindow.mediaController.dualAudioManager.audioPlayer1.duration / 1000)
                        return qsTr("Player 1: ") + status + (duration > 0 ? " (" + position + "s/" + duration + "s)" : "")
                    }
                    return qsTr("Player 1: Not Available")
                }
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.secondaryColor
                visible: tidalApi.loginTrue
                wrapMode: Text.WordWrap
            }

            Label {
                id: player2Status
                text: {
                    statusTrigger; // Force re-evaluation when statusTrigger changes
                    if (applicationWindow.mediaController && applicationWindow.mediaController.dualAudioManager && applicationWindow.mediaController.dualAudioManager.audioPlayer2) {
                        var status = applicationWindow.mediaController.dualAudioManager.audioPlayer2.status
                        var position = Math.floor(applicationWindow.mediaController.dualAudioManager.audioPlayer2.position / 1000)
                        var duration = Math.floor(applicationWindow.mediaController.dualAudioManager.audioPlayer2.duration / 1000)
                        return qsTr("Player 2: ") + status + (duration > 0 ? " (" + position + "s/" + duration + "s)" : "")
                    }
                    return qsTr("Player 2: Not Available")
                }
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.secondaryColor
                visible: tidalApi.loginTrue
                wrapMode: Text.WordWrap
            }

            Label {
                id: activePlayerStatus
                text: {
                    statusTrigger; // Force re-evaluation when statusTrigger changes
                    if (applicationWindow.mediaController && applicationWindow.mediaController.dualAudioManager) {
                        var activePlayer = applicationWindow.mediaController.dualAudioManager.player1Active ? "Player 1" : "Player 2"
                        var preloadEnabled = applicationWindow.settings.enableTrackPreloading ? qsTr("Enabled") : qsTr("Disabled")
                        return qsTr("Active Player: ") + activePlayer + qsTr(" | Preloading: ") + preloadEnabled
                    }
                    return qsTr("Active Player: Unknown")
                }
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.highlightColor
                visible: tidalApi.loginTrue
                wrapMode: Text.WordWrap
            }

            Label {
                id: crossfadeStatus
                text: {
                    var modeNames = [qsTr("No Fade"), qsTr("Timer"), qsTr("Buffer Crossfade"), qsTr("Buffer Fade-Out")]
                    var modeName = modeNames[applicationWindow.settings.crossfadeMode] || qsTr("Unknown")
                    return qsTr("Crossfade Mode: ") + modeName + " (" + applicationWindow.settings.crossfadeTimeMs + "ms)"
                }
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.secondaryHighlightColor
                visible: tidalApi.loginTrue
                wrapMode: Text.WordWrap
            }

            SectionHeader {
                text: qsTr("Debug Settings")
            }

            ComboBox {
                id: debugLevelCombo
                label: qsTr("Debug Level")
                description: qsTr("Controls console logging output")
                
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
                        applicationWindow.settings.debugLevel = currentItem.value
                        debugLevelConfig.value = currentItem.value
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

        }

        VerticalScrollDecorator {}


    Component.onCompleted: {
        var savedQuality = applicationWindow.settings.audio_quality
        var idx = audioQuality.qualities.indexOf(savedQuality)
        idx >= 0 ? idx : 1  // default to HIGH (index 1) if not found
        audioQuality.currentIndex = idx
       }
    }
}
