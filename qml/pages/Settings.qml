import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Configuration 1.0

Page {
    id: page
    allowedOrientations: Orientation.All

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
                visible: tidalApi.loginTrue
                text: qsTr("Stay logged in")
                description: qsTr("Keep your session active")
                // Verbinde dies mit deiner Konfiguration
                checked: false
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
                id: hidePlayerOnFinished
                visible: tidalApi.loginTrue
                text: qsTr("Hide player on finished")
                description: qsTr("Hide player when playback is finished")
                checked: applicationWindow.settings.hide_player
                onClicked: {
                    applicationWindow.settings.hide_player = hidePlayerOnFinished.checked
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
