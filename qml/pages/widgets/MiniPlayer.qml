import QtQuick 2.0
import Sailfish.Silica 1.0
import QtMultimedia 5.6
import org.nemomobile.mpris 1.0

DockedPanel {
    id: miniPlayerPanel
    width: parent.width
    height: 1.5*Theme.itemSizeExtraLarge // Reduzierte Höhe
    open: true
    dock: Dock.Bottom
    property bool isFav: false

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
            // Only propagate to children (buttons) of the DockedPanel
            mouse.accepted = !buttonsRow.contains(Qt.point(mouse.x, mouse.y)) && 
                            !favButton.contains(favButton.mapFromItem(swipeArea, mouse.x, mouse.y))
        }
        
        onMouseYChanged: {
            if (Math.abs(mouse.y - startY) > Theme.paddingMedium) {
                mouse.accepted = true
            }
        }

        onReleased: {
            var delta = startY - mouse.y
            // console.log("pageStack depth:", pageStack.depth, "delta:", delta)
            if (delta > swipeThreshold) {
                // Pop everything but FirstPage
                while (pageStack.depth > 1) {
                    pageStack.pop(null, PageStackAction.Immediate)
                }
                
                // Now we're back at FirstPage, show the playlist
                applicationWindow.mainPage.showPlaylist()
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

    IconButton {
        id: favButton
        width: Theme.iconSizeMedium
        height: Theme.iconSizeMedium
        anchors {
            verticalCenter: parent.verticalCenter
            right: parent.right
            margins: Theme.paddingLarge
        }
        icon.source: "image://theme/icon-s-favorite"
        icon.sourceSize: Qt.size(Theme.iconSizeMedium, Theme.iconSizeMedium)
        highlighted: miniPlayerPanel.isFav
        opacity: highlighted ? 1.0 : 0.3
        onClicked: {
            favManager.setTrackFavoriteInfo(playlistManager.tidalId,!miniPlayerPanel.isFav)
        }
        z:1 // to be on top of the image
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.overlayBackgroundColor //Theme.darkPrimaryColor
        opacity: 0.65

        // Hauptcontainer
        Column {
            anchors.fill: parent
            anchors.margins: Theme.paddingSmall
            spacing: Theme.paddingSmall
            z: 1 // Über dem Hintergrundbild

            // Titel
            Label {
                id: mediaTitle
                width: parent.width
                font.pixelSize: Theme.fontSizeSmall
                // font.bold: true
                horizontalAlignment: Text.AlignHCenter
                clip: true

                // Text Animation
                property int scrollDuration: 5000  // Dauer einer Richtung in ms
                property int scrollPause: 2000     // Pause an den Enden in ms

                SequentialAnimation {
                    id: scrollAnim
                    running: mediaTitle.implicitWidth > mediaTitle.width
                    loops: Animation.Infinite

                    PauseAnimation {
                        duration: mediaTitle.scrollPause
                    }

                    NumberAnimation {
                        target: mediaTitle
                        property: "x"
                        from: 0
                        to: -(mediaTitle.implicitWidth - mediaTitle.width)
                        duration: mediaTitle.scrollDuration
                        easing.type: Easing.InOutQuad
                    }

                    PauseAnimation {
                        duration: mediaTitle.scrollPause
                    }

                    NumberAnimation {
                        target: mediaTitle
                        property: "x"
                        to: 0
                        from: -(mediaTitle.implicitWidth - mediaTitle.width)
                        duration: mediaTitle.scrollDuration
                        easing.type: Easing.InOutQuad
                    }
                }

                // Reset Position wenn Text sich ändert
                onTextChanged: {
                    x = 0;
                    if (mediaTitle.implicitWidth > mediaTitle.width) {
                        scrollAnim.restart();
                    }
                }
            }
            // Buttons
            Row {
                id: buttonsRow
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.paddingMedium

                IconButton {
                    id: prevButton
                    icon.source: "image://theme/icon-m-previous"
                    // icons move around horizontally when using visible
                    onClicked:
                    {
                        console.log("prev button pressed")
                        playlistManager.previousTrackClicked()
                    }
                }

                IconButton {
                    id: playButton
                    icon.source: mediaController.isPlaying ? "image://theme/icon-m-pause" : "image://theme/icon-m-play"
                    onClicked:
                    {
                        if (mediaController.mediaPlayer.playbackState === 1) {
                            mediaController.pause()
                        } else if(mediaController.mediaPlayer.playbackState === 2) {
                            mediaController.play()
                        }
                    }
                }

                IconButton {
                    id: nextButton
                    icon.source: "image://theme/icon-m-next"
                    visible: playlistManager.canNext
                    onClicked: {
                        console.log("next button pressed")

                        mediaController.blockAutoNext = true
                        playlistManager.nextTrackClicked()
                    }
                }
            }

            // Progress Slider und Zeit
            Column {
                width: parent.width
                spacing: Theme.paddingSmall

                // Ändere den Column-Block für Progress Slider und Zeit zu:

                // Progress Slider und Zeit
                Item {
                    width: parent.width
                    height: progressSlider.height + timeRow.height + Theme.paddingSmall

                    Slider {
                        id: progressSlider
                        anchors.top: parent.top
                        width: parent.width
                        minimumValue: 0
                        maximumValue: 100
                        enabled: mediaController.duration > 0
                        visible: false
                        height: Theme.paddingMedium
                    }
                    Connections {
                        target: progressSlider
                        onReleased: {
                            mediaController.seek(progressSlider.value/100*mediaController.duration)
                        }
                    }
                    // Zeitanzeige
                    Row {
                        id: timeRow
                        anchors.top: progressSlider.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: Theme.paddingLarge

                        Label {
                            id: playedTime
                            property string pos: {
                                if ((mediaController.position / 1000) > 3599)
                                    return Format.formatDuration(minPlayer.position / 1000, Formatter.DurationLong)
                                else
                                    return Format.formatDuration(mediaController.position / 1000, Formatter.DurationShort)
                            }
                            text: pos
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }

                        Label {
                            id: playTime
                            property string dur: {
                                if ((mediaController.duration / 1000) > 3599)
                                    return Format.formatDuration(minPlayer.duration / 1000, Formatter.DurationLong)
                                else
                                    return Format.formatDuration(mediaController.duration / 1000, Formatter.DurationShort)
                            }
                            text: dur
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }
                    }
                }
                Label {
                    visible: applicationWindow.remainingMinutes > 0
                    text: visible ? qsTr("Sleep in: %1")
                        .arg(Format.formatDuration(applicationWindow.remainingMinutes * 60, Formatter.DurationLong)) : ""
                    color: Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeExtraSmall
                }

            }

        }

    }

    // Connections bleiben unverändert


    Connections {
        target: mediaController

        onPlaybackStateChanged: {
            if(mediaController.playbackState === 1)
                playButton.icon.source = "image://theme/icon-m-pause"
            else if(mediaController.playbackState === 2)
                playButton.icon.source = "image://theme/icon-m-play"
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
        onCurrentPosition: {
        if (!progressSlider.pressed) {  // Nur updaten wenn der Slider nicht gedrückt ist
            progressSlider.value = position
        }
    }
    }

    Connections {
        target: progressSlider
        onReleased: {
            mediaController.seek(progressSlider.value/100*mediaController.duration)
        }
    }

    Connections {
        target: tidalApi
         onCurrentPlayback:
         {
            mediaTitle.text = trackinfo.track_num + " - " + trackinfo.title + " - " + trackinfo.album + " - " + trackinfo.artist
            bgImage.source = trackinfo.image
            nextButton.enabled = playlistManager.canNext
            progressSlider.visible = true
            //mprisPlayer.updateTrack(title, artist, album)
            miniPlayerPanel.isFav = favManager.isFavorite(trackinfo.trackid)
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
    }

    Connections {
        target: favManager

        onUpdateFavorite: {
            if (id === playlistManager.tidalId)
                isFav = status
        }
    }
}
