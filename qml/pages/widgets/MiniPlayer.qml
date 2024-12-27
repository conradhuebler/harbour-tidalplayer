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


    property string url: ""
    property int track_id

    function play() {
        mediaPlayer.source = url;
        mediaPlayer.play();
        progressSlider.visible = true
        show();
    }

    // Hintergrundbild
    Image {
        id: bgImage
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        opacity: 0.3 // Transparenter Hintergrund
        z: 0 // Hinter allen anderen Elementen
    }

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
                //visible: playlistManager.canPrev
                onClicked: playlistManager.previousTrackClicked()
            }

            IconButton {
                id: playButton
                icon.source: mediaPlayer.isPlaying ? "image://theme/icon-m-pause" : "image://theme/icon-m-play"
                onClicked: {
                    if (mediaPlayer.playbackState == 1) {
                        mediaPlayer.pause()
                    } else if(mediaPlayer.playbackState == 2) {
                        mediaPlayer.play()
                    }
                }
            }

            IconButton {
                id: nextButton
                icon.source: "image://theme/icon-m-next"
                //visible: playlistManager.canNext
                onClicked: {
                    mediaPlayer.blockAutoNext = true
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
                            visible: false
                            height: Theme.paddingMedium
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
                                    if ((mediaPlayer.position / 1000) > 3599)
                                        return Format.formatDuration(minPlayer.position / 1000, Formatter.DurationLong)
                                    else
                                        return Format.formatDuration(mediaPlayer.position / 1000, Formatter.DurationShort)
                                }
                                text: pos
                                font.pixelSize: Theme.fontSizeExtraSmall
                            }

                            Label {
                                id: playTime
                                property string dur: {
                                    if ((mediaPlayer.duration / 1000) > 3599)
                                        return Format.formatDuration(minPlayer.duration / 1000, Formatter.DurationLong)
                                    else
                                        return Format.formatDuration(mediaPlayer.duration / 1000, Formatter.DurationShort)
                                }
                                text: dur
                                font.pixelSize: Theme.fontSizeExtraSmall
                            }
                        }
                    }

        }
    }

    // Connections bleiben unverändert
    Connections {
        target: mediaPlayer
        onCurrentPosition: {
            progressSlider.value = position
        }
        onPlaybackStateChanged: {
            if(mediaPlayer.playbackState === 1)
                playButton.icon.source = "image://theme/icon-m-pause"
            else if(mediaPlayer.playbackState === 2)
                playButton.icon.source = "image://theme/icon-m-play"
        }
    }

    Connections {
        target: progressSlider
        onReleased: {
            mediaPlayer.seek(progressSlider.value/100*mediaPlayer.duration)
        }
    }

    Connections {
        target: pythonApi
        onCurrentTrackInfo: {
            mediaTitle.text = track_num + " - " + title + " - " + album + " - " + artist
            bgImage.source = album_image
            prevButton.enabled = playlistManager.canPrev
            nextButton.enabled = playlistManager.canNext
            progressSlider.visible = true
            mprisPlayer.updateTrack(title, artist, album)
        }
    }

    Connections {
        target: playlistManager
        onPlayListFinished: {
            mediaTitle.text = ""
            bgImage.source = ""
            minPlayerPanel.hide(100)
            progressSlider.visible = false
        }
    }
}
