import QtQuick 2.0
import Sailfish.Silica 1.0

CoverBackground {
    id: cover

    property bool isPlaying: coverImage.source != ""
    property var application
    property var home
    Image {
        id: defaultLogo
        visible: !isPlaying
        source: "/usr/share/icons/hicolor/86x86/apps/harbour-tidalplayer.png"
        anchors.centerIn: parent
        // width: parent.width * 0.5
        // height: width
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        opacity: 0.5
    }

    Image {
        id: backgroundImage
        anchors.fill: parent
        source: coverImage.source
        fillMode: Image.PreserveAspectCrop
        opacity: 0.1
        asynchronous: true
    }

    Rectangle {
        id: gradient
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 1.0; color: Theme.rgba(Theme.primaryColor, 0.1) }
        }
    }

    Image {
        id: coverImage
        width: parent.width - 2 * Theme.paddingMedium
        height: width
        anchors {
            top: parent.top
            topMargin: Theme.paddingLarge
            horizontalCenter: parent.horizontalCenter
        }
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        visible: source != ""

        Rectangle {
            color: Theme.rgba(Theme.highlightBackgroundColor, 0.1)
            anchors.fill: parent
            visible: coverImage.status !== Image.Ready && coverImage.source != ""
        }
    }

    Column {
        anchors {
            top: coverImage.source ? coverImage.bottom : parent.verticalCenter
            topMargin: Theme.paddingMedium
            left: parent.left
            right: parent.right
            leftMargin: Theme.paddingMedium
            rightMargin: Theme.paddingMedium
        }
        spacing: Theme.paddingSmall

        Label {
            id: titleLabel
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: Theme.fontSizeMedium
            color: Theme.primaryColor
            truncationMode: TruncationMode.Fade
            maximumLineCount: 2
            wrapMode: Text.Wrap
            text: qsTr("Tidal Player")
        }

        Label {
            id: artist_albumLabel
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.secondaryColor
            truncationMode: TruncationMode.Fade
            maximumLineCount: 2
            wrapMode: Text.Wrap
            text: qsTr("No track playing")
        }

        // Sleep Timer Display
        Label {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: Theme.fontSizeExtraSmall
            color: Theme.highlightColor
            visible: application && application.remainingMinutes > 0
            text: visible ? qsTr("🕐 Sleep: %1").arg(formatSleepTime(application.remainingMinutes)) : ""
            
            // Live update
            Timer {
                interval: 60000  // Update every minute
                running: parent.visible
                repeat: true
                onTriggered: {
                    if (application && application.remainingMinutes > 0) {
                        parent.text = qsTr("🕐 Sleep: %1").arg(formatSleepTime(application.remainingMinutes))
                    }
                }
            }
        }
    }

    Row {
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: Theme.paddingLarge
        }
        spacing: Theme.paddingMedium
        visible: !isPlaying

        Label {
            text: qsTr("Tap to navigate")
            color: Theme.secondaryColor
            font.pixelSize: Theme.fontSizeExtraSmall
        }
    }

    CoverActionList {
        id: playbackActions
        enabled: isPlaying

        CoverAction {
            id: prevButton
            iconSource: "image://theme/icon-cover-previous"
            onTriggered: {
                mediaController.blockAutoNext = true
                playlistManager.previousTrack()
            }
        }

        CoverAction {
            id: playpause
            iconSource: "image://theme/icon-cover-play"
            onTriggered: {
                if (mediaController.playbackState === 1) {
                    mediaController.pause()
                } else if(mediaController.playbackState === 2) {
                    mediaController.play()
                }
            }
        }

        CoverAction {
            id: nextButton
            iconSource: "image://theme/icon-cover-next"
            onTriggered: {
                mediaController.blockAutoNext = true
                playlistManager.nextTrackClicked()
            }
        }
    }

    CoverActionList {
        id: navigationActions
        enabled: !isPlaying


        CoverAction {
            iconSource: "image://theme/icon-m-home"  // Icon für Playlists
            onTriggered: {
                application.activate()
                home.currentIndex = 0  // Playlists Tab
            }
        }

        CoverAction {
            iconSource: "image://theme/icon-m-search"
            onTriggered: {
                application.activate()
                home.currentIndex = 1  // Search Tab
            }
        }
        CoverAction {
            iconSource: "image://theme/icon-m-media-playlists"  // Icon für Current
            onTriggered: {
                application.activate()
                home.currentIndex = 2  // Current Tab
            }
        }
    }

    Connections {
        target: tidalApi
        onCurrentPlayback: {
            titleLabel.text = trackinfo.title
            artist_albumLabel.text = trackinfo.artist + "\n" + trackinfo.album
            coverImage.source = trackinfo.image
        }
    }

    // Format sleep time for display
    function formatSleepTime(minutes) {
        if (minutes < 60) {
            return qsTr("%1m").arg(minutes)
        } else {
            var hours = Math.floor(minutes / 60)
            var mins = minutes % 60
            if (mins === 0) {
                return qsTr("%1h").arg(hours)
            } else {
                return qsTr("%1h %2m").arg(hours).arg(mins)
            }
        }
    }

    Connections {
        target: playlistManager
        onPlaylistFinished: {
            titleLabel.text = qsTr("Tidal Player")
            artist_albumLabel.text = qsTr("No track playing")
            coverImage.source = ""
            // prevButton.enabled = playlistManager.canPrev
            // nextButton.enabled = playlistManager.canNext
        }
        onSelectedTrackChanged: {
            console.log("hurra playlist")
            console.log(trackinfo.title)
            // i need a call back with an trackinfo object
            titleLabel.text = trackinfo.title
            artist_albumLabel.text = trackinfo.artist + "\n" + trackinfo.album
            coverImage.source = trackinfo.image
        }
    }

    Connections {
        target: mediaController
        onPlaybackStateChanged: {
            if(mediaController.playbackState === 1)
                playpause.iconSource = "image://theme/icon-cover-pause"
            else if(mediaController.playbackState === 2)
                playpause.iconSource = "image://theme/icon-cover-play"
        }
    }
}
