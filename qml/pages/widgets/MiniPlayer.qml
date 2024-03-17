import QtQuick 2.0
import Sailfish.Silica 1.0
import QtMultimedia 5.6
import org.nemomobile.mpris 1.0

//import "SwipeArea"

DockedPanel {
    id: miniPlayerPanel
    //parent: pageStack.currentPage

    width: parent.width
    height: 2*Theme.itemSizeExtraLarge + Theme.paddingLarge
    open: true
    dock: Dock.Bottom

    property string url: ""
    property int track_id

    function play()
    {
        mediaPlayer.source = url;
        mediaPlayer.play();
        progressSlider.visible = true
        show();
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.overlayBackgroundColor
        opacity: 0.8
        SwipeArea {
            anchors.fill: parent
            onSwipeDown: minPlayerPanel.hide()
        }
    }
    Image {
        id: bgImage
        height: 0.75 * parent.height
        fillMode: Image.PreserveAspectFit
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
    }

    Label {
        id: mediaTitle
        anchors.top: parent.top
        anchors.topMargin: Theme.paddingSmall
        anchors.horizontalCenter: parent.horizontalCenter
        truncationMode: TruncationMode.Fade
        width: parent.width - 2 * Theme.paddingLarge
        //horizontalAlignment: (contentWidth > width) ? Text.AlignLeft : Text.AlignHCenter
    }

    Label {
        id: playTime
        anchors.top: mediaTitle.bottom
        anchors.topMargin: Theme.paddingSmall / 6
        property string pos: {
            if ((mediaPlayer.position / 1000) > 3599) Format.formatDuration(minPlayer.position / 1000, Formatter.DurationLong)
            else return Format.formatDuration(mediaPlayer.position / 1000, Formatter.DurationShort)
        }
        property string dur: {
            if ((mediaPlayer.duration / 1000) > 3599) Format.formatDuration(minPlayer.duration / 1000, Formatter.DurationLong)
            else return Format.formatDuration(mediaPlayer.duration / 1000, Formatter.DurationShort)
        }
        text: pos + " / " + dur;
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize: Theme.fontSizeExtraSmall
    }

    Slider {
        id: progressSlider
        anchors.top: playTime.bottom
        anchors.topMargin: Theme.paddingSmall / 6
        width: parent.width
        minimumValue: 0
        maximumValue: 100
        visible: false
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: progressSlider.bottom
        anchors.topMargin: Theme.paddingSmall / 4
        IconButton {
            id : prevButton
            icon.source: "image://theme/icon-m-previous"
            visible:  playlistManager.canPrev;
            onClicked: {
                playlistManager.previousTrackClicked()
            }
        }
        IconButton {
            id:playButton
            icon.source: mediaPlayer.isPlaying ? "image://theme/icon-m-pause" : "image://theme/icon-m-play"
            onClicked: {
                if (mediaPlayer.playbackState == 1)
                {
                    mediaPlayer.pause()
                }
                else if(mediaPlayer.playbackState == 2){
                    mediaPlayer.play()
                }
            }
        }
        IconButton {
            id: nextButton
            icon.source: "image://theme/icon-m-next"
            visible: playlistManager.canNext;
            onClicked: {
                console.log("play next")
                mediaPlayer.blockAutoNext = true
                playlistManager.nextTrackClicked()
            }
        }
    }

    Connections
    {
        target: mediaPlayer
        onCurrentPosition:
        {
            progressSlider.value = position
        }
        onPlaybackStateChanged:
        {
            if(mediaPlayer.playbackState === 1)
                        playButton.icon.source = "image://theme/icon-m-pause"
             else if(mediaPlayer.playbackState === 2)
                 playButton.icon.source =  "image://theme/icon-m-play"
        }
    }

    Connections
    {
        target: progressSlider
        onReleased: {
            mediaPlayer.seek(progressSlider.value/100*mediaPlayer.duration)
        }
    }

    Connections
    {
        target: pythonApi
        onCurrentTrackInfo:
        {

            mediaTitle.text = track_num + " - " + title + " - "  +album + " - " + artist
            bgImage.source = album_image
            prevButton.enabled = playlistManager.canPrev;
            nextButton.enabled = playlistManager.canNext;
            progressSlider.visible = true
            mprisPlayer.updateTrack(title, artist, album)
        }
    }

    Connections
    {
        target: playlistManager
        onPlayListFinished :
        {
            mediaTitle.text = ""
            bgImage.source = ""
            minPlayerPanel.hide(100);
            progressSlider.visible = false
        }
    }

    Component.onCompleted: {
        //mprisPlayer.canControl = true;
        //if (minPlayer.playbackState == MediaPlayer.PlayingState) mprisPlayer.playbackStatus = Mpris.Playing
        //else mprisPlayer.playbackStatus = Mpris.Paused
    }
}

