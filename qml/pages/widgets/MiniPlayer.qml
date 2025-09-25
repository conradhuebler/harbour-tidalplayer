import QtQuick 2.0
import Sailfish.Silica 1.0
import QtMultimedia 5.6
import org.nemomobile.mpris 1.0

DockedPanel {
    id: miniPlayerPanel
    width: parent.width
    height: getPlayerHeight()
    open: tidalApi.loginTrue
    dock: Dock.Bottom
    property bool isFav: false
    
    // Three-state MiniPlayer system - Claude Generated
    property int playerState: 2  // 0=Hidden, 1=Mini, 2=Normal
    property real hiddenHeight: 0
    property real miniHeight: Theme.itemSizeLarge * 1.5 + Theme.paddingLarge
    property real normalHeight: Theme.itemSizeExtraLarge * 2.25
    
    function getPlayerHeight() {
        switch(playerState) {
            case 0: return hiddenHeight
            case 1: return miniHeight
            case 2: return normalHeight
            default: return normalHeight
        }
    }
    
    // Smooth height transitions
    Behavior on height {
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutCubic
        }
    }

    MouseArea {
        id: swipeArea
        anchors.fill: parent
        z: 0  // Same level as background image
        
        property real startY: 0
        property real swipeThreshold: 100
        
        preventStealing: true
        propagateComposedEvents: false
        
        onPressed: {
            startY = mouse.y
            // Check if touch is on interactive controls - exclude them from swipe handling
            var touchOnControls = controlsContainer.contains(Qt.point(mouse.x, mouse.y))
            var touchOnProgressArea = progressContainer.visible && progressContainer.contains(Qt.point(mouse.x, mouse.y))
            
            mouse.accepted = !touchOnControls && !touchOnProgressArea
            
            if (applicationWindow.settings.debugLevel >= 3) {
                console.log("SWIPE: Touch at", mouse.x, mouse.y, "controls:", touchOnControls, "progress:", touchOnProgressArea, "accepted:", mouse.accepted)
            }
        }
        
        onMouseYChanged: {
            if (Math.abs(mouse.y - startY) > Theme.paddingMedium) {
                mouse.accepted = true
            }
        }

        onReleased: {
            var delta = startY - mouse.y
            
            // Upward swipe: Show playlist
            if (delta > swipeThreshold) {
                while (pageStack.depth > 1) {
                    pageStack.pop(null, PageStackAction.Immediate)
                }
                applicationWindow.mainPage.showPlaylist()
            } 
            // Tap gesture: Toggle between Mini and Normal mode
            else if (Math.abs(delta) < Theme.paddingMedium) {
                if (playerState === 1) {
                    playerState = 2  // Mini -> Normal
                } else if (playerState === 2) {
                    playerState = 1  // Normal -> Mini
                }
            }
        }
    }    

    // Hintergrundbild
    Image {
        id: bgImage
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        opacity: 0.85 // Transparenter Hintergrund
        z: 0 // Hinter allen anderen Elementen
    }


    Rectangle {
        anchors.fill: parent
        color: Theme.overlayBackgroundColor //Theme.darkPrimaryColor
        opacity: 0.65

        // Neu strukturierter Hauptcontainer - Claude Generated
        Column {
            anchors.fill: parent
            anchors.margins: Theme.paddingSmall
            spacing: Theme.paddingSmall
            z: 1 // Über dem Hintergrundbild

            // 1. Button Row - Neue Anordnung: Prev links, Play/Pause + Star center, Next rechts
            Item {
                id: controlsContainer
                width: parent.width
                height: Theme.itemSizeMedium
                visible: playerState >= 1  // Sichtbar in Mini und Normal

                IconButton {
                    id: prevButton
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    icon.source: "image://theme/icon-m-previous"
                    enabled: playlistManager.canPrev
                    onClicked: {
                        console.log("prev button pressed")
                        playlistManager.previousTrackClicked()
                    }
                }

                // Center group mit Play/Pause und Favorite
                Row {
                    id: centerControls
                    anchors.centerIn: parent
                    spacing: Theme.paddingLarge

                    IconButton {
                        id: playButton
                        icon.source: mediaController.isPlaying ? "image://theme/icon-m-pause" : "image://theme/icon-m-play"
                        onClicked: {
                            if (mediaController.isPlaying) {
                                mediaController.pause()
                            } else {
                                mediaController.play()
                            }
                        }
                    }

                    IconButton {
                        id: favButton
                        icon.source: "image://theme/icon-s-favorite"
                        width: nextButton.width
                        height: nextButton.height
                        scale: 1.5
                        highlighted: miniPlayerPanel.isFav
                        opacity: highlighted ? 1.0 : 0.3
                        onClicked: {
                            favManager.setTrackFavoriteInfo(playlistManager.tidalId, !miniPlayerPanel.isFav)
                        }
                    }
                }

                IconButton {
                    id: nextButton
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    icon.source: "image://theme/icon-m-next"
                    enabled: playlistManager.canNext
                    onClicked: {
                        console.log("next button pressed")
                        mediaController.blockAutoNext = true
                        playlistManager.nextTrackClicked()
                    }
                }
            }

            // 2. Track Title - Scrollend, sichtbar in Mini und Normal
            Item {
                id: titleContainer
                width: parent.width
                height: mediaTitle.implicitHeight + Theme.paddingSmall
                visible: playerState >= 1
                clip: true

                Label {
                    id: mediaTitle
                    // Dynamische Breite basierend auf Text oder Container
                    width: Math.max(parent.width, implicitWidth)
                    font.pixelSize: Theme.fontSizeMedium
                    font.bold: true
                    horizontalAlignment: needsScrolling ? Text.AlignLeft : Text.AlignHCenter
                    anchors.verticalCenter: parent.verticalCenter
                    wrapMode: Text.NoWrap
                    elide: Text.ElideNone
                    
                    // Hilfseigenschaft für bessere Lesbarkeit
                    property bool needsScrolling: implicitWidth > titleContainer.width

                    // Scrolling Animation - überarbeitet
                    property int scrollDuration: 4000
                    property int scrollPause: 1500

                    SequentialAnimation {
                        id: scrollAnim
                        running: mediaTitle.needsScrolling
                        loops: Animation.Infinite

                        PauseAnimation { duration: mediaTitle.scrollPause }
                        
                        // Scroll nach rechts (zeige den Anfang -> Ende)
                        NumberAnimation {
                            target: mediaTitle
                            property: "x"
                            from: (titleContainer.width - mediaTitle.implicitWidth) / 2  // Start zentriert
                            to: -(mediaTitle.implicitWidth - titleContainer.width) - Theme.paddingMedium  // Ende mit Padding
                            duration: mediaTitle.scrollDuration
                            easing.type: Easing.InOutQuad
                        }
                        
                        PauseAnimation { duration: mediaTitle.scrollPause }
                        
                        // Scroll zurück nach links
                        NumberAnimation {
                            target: mediaTitle
                            property: "x"
                            to: (titleContainer.width - mediaTitle.implicitWidth) / 2  // Zurück zur Mitte
                            from: -(mediaTitle.implicitWidth - titleContainer.width) - Theme.paddingMedium
                            duration: mediaTitle.scrollDuration
                            easing.type: Easing.InOutQuad
                        }
                    }

                    onTextChanged: {
                        if (applicationWindow.settings.debugLevel >= 2) {
                            console.log("TITLE: Text changed to:", text, "implicitWidth:", implicitWidth, "containerWidth:", titleContainer.width, "needsScrolling:", needsScrolling)
                        }
                        
                        if (needsScrolling) {
                            // Starte linksbündig für Scrolling
                            x = (titleContainer.width - implicitWidth) / 2
                            scrollAnim.restart()
                        } else {
                            // Zentriere statischen Text
                            x = 0
                            scrollAnim.stop()
                        }
                    }
                }
            }

            // 3. Progress Slider mit inline Zeit - Nur in Normal mode
            Item {
                id: progressContainer
                width: parent.width
                height: Math.max(Theme.fontSizeExtraSmall, Theme.paddingMedium) + Theme.paddingSmall
                visible: playerState === 2

                // Target time (visible when dragging) - Moved above the row
                Label {
                    id: targetTime
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: sliderRow.bottom
                    anchors.bottomMargin: Theme.paddingSmall
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.highlightColor
                    visible: progressSlider.pressed
                    text: {
                        if (progressSlider.pressed && mediaController.duration > 0) {
                            var targetSeconds = (progressSlider.value / 100) * (mediaController.duration / 1000)
                            return "→ " + (targetSeconds > 3599 ? 
                                Format.formatDuration(targetSeconds, Formatter.DurationLong) :
                                Format.formatDuration(targetSeconds, Formatter.DurationShort))
                        }
                        return ""
                    }
                }

                // Row with aligned slider and time labels
                Row {
                    id: sliderRow
                    anchors.centerIn: parent
                    width: parent.width
                    spacing: Theme.paddingMedium

                    // Current time links
                    Label {
                        id: currentTime
                        anchors.verticalCenter: parent.verticalCenter
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: Theme.secondaryColor
                        text: {
                            var pos = mediaController.position / 1000
                            return pos > 3599 ? 
                                Format.formatDuration(pos, Formatter.DurationLong) :
                                Format.formatDuration(pos, Formatter.DurationShort)
                        }
                    }

                    Slider {
                        id: progressSlider
                        width: parent.width - currentTime.width - totalTime.width - parent.spacing * 2
                        anchors.verticalCenter: parent.verticalCenter
                        minimumValue: 0
                        maximumValue: 100
                        enabled: mediaController.duration > 0
                        visible: mediaController.duration > 0
                        //height: Theme.paddingMedium
                        z: 10

                        onPressedChanged: {
                            if (applicationWindow.settings.debugLevel >= 2) {
                                console.log("SLIDER: Pressed state changed to", pressed)
                            }
                        }
                    }

                    // Total time rechts
                    Label {
                        id: totalTime
                        anchors.verticalCenter: parent.verticalCenter
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: Theme.secondaryColor
                        text: {
                            var dur = mediaController.duration / 1000
                            return dur > 3599 ? 
                                Format.formatDuration(dur, Formatter.DurationLong) :
                                Format.formatDuration(dur, Formatter.DurationShort)
                        }
                    }
                }
            }

            // 4. Playlist Info mit Next Track - Nur in Normal mode
            Label {
                id: playlistInfo
                width: parent.width
                font.pixelSize: Theme.fontSizeExtraSmall
                anchors.topMargin: Theme.paddingLarge
                color: Theme.secondaryColor
                horizontalAlignment: Text.AlignHCenter
                visible: playerState === 2
                wrapMode: Text.WordWrap

                text: {
                    var infoText = ""
                    
                    // Sleep Timer hat Priorität
                    if (applicationWindow.remainingSeconds > 0) {
                        infoText = qsTr("Sleep in: %1")
                            .arg(Format.formatDuration(applicationWindow.remainingSeconds, Formatter.DurationShort))
                    } else {
                        // Playlist Info
                        if (playlistManager.totalTracks > 0) {
                            infoText = playlistManager.playlistProgress + " • " + playlistManager.totalDurationFormatted
                            
                            // Next Track Info
                            var nextIndex = playlistManager.currentIndex + 1
                            if (nextIndex < playlistManager.totalTracks) {
                                var nextTrackId = playlistManager.requestPlaylistItem(nextIndex)
                                var nextTrackInfo = cacheManager.getTrackInfo(nextTrackId)
                                if (nextTrackInfo) {
                                    infoText += "\n" + qsTr("Next: %1 - %2").arg(nextTrackInfo.artist).arg(nextTrackInfo.title)
                                }
                            }
                        }
                    }
                    
                    return infoText
                }
            }
        }

    }

    // Connections bleiben unverändert


    Connections {
        target: mediaController

        onPlaybackStateChanged: {
            if (mediaController.playbackState === Audio.PlayingState) {
                playButton.icon.source = "image://theme/icon-m-pause"
            } else {
                playButton.icon.source = "image://theme/icon-m-play"
            }
        }

        /*
        onCurrentTrack: {
            mediaTitle.text = track_num + " - " + mediaController.current_track_title
            + " - "
            + mediaController.current_track_album
            + " - "
            + mediaController.current_track_artist
            bgImage.source = mediaController.current_track_image
            //prevButton.enabled = playlistManager.canPrev
            //nextButton.enabled = playlistManager.canNext
            progressSlider.visible = true
        }*/
        onPositionChanged: {
            if (!progressSlider.pressed && mediaController.duration > 0) {
                progressSlider.value = (mediaController.position / mediaController.duration) * 100
            }
        }
    }

    Connections {
        target: progressSlider
        onReleased: {
            if (mediaController.duration > 0) {
                var seekPosition = (progressSlider.value / 100) * mediaController.duration
                if (applicationWindow.settings.debugLevel >= 1) {
                    console.log("SLIDER: Seeking to position", seekPosition, "ms (", Math.round(seekPosition/1000), "s )")
                }
                // Use DualAudioManager's seek function instead of MediaController's
                mediaController.dualAudioManager.seek(seekPosition)
            }
        }
    }

    Connections {
        target: mediaController
        onCurrentTrackChanged: {
            mediaTitle.text = trackInfo.track_num + " - " + trackInfo.title + " - " + trackInfo.album + " - " + trackInfo.artist
            bgImage.source = trackInfo.image
            nextButton.enabled = playlistManager.canNext
            progressSlider.visible = true
            miniPlayerPanel.isFav = favManager.isFavorite(trackInfo.trackid)
        }
    }

    Connections {
        target: playlistManager
        onPlaylistFinished: {
            console.log("Playlist finished, hide player: " + applicationWindow.settings.hide_player)
            if (applicationWindow.settings.hide_player) {
                mediaTitle.text = ""
                bgImage.source = ""    
                minPlayerPanel.hide(100)
                progressSlider.visible = false
            }
        }
        onListChanged:
        {
            nextButton.enabled = playlistManager.canNext
            prevButton.enabled = playlistManager.canPrev
        }
    }

    Connections {
        target: favManager

        onUpdateFavorite: {
            if (id === playlistManager.tidalId)
                isFav = status
        }
    }
}
