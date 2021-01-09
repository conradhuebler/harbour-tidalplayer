import QtQuick 2.0
import Sailfish.Silica 1.0
import QtMultimedia 5.6
import org.nemomobile.mpris 1.0
import harbour.tidalplayer 1.0

//import "SwipeArea"

DockedPanel {
    id: minPlayerPanel
    parent: pageStack.currentPage

    width: parent.width
    height: 2*Theme.itemSizeExtraLarge + Theme.paddingLarge

    dock: Dock.Bottom

    property string url: ""
    property int track_id
    function prev() {
        PlaylistManager.prevTrack()
    }

    function next() {
        PlaylistManager.nextTrack()
    }

    function play()
    {
        mediaPlayer.source = url;
        mediaPlayer.play();
        progressSlider.visible = true
        show();
    }

    function playPlaylist()
    {
        console.log(minPlayerPanel.track_id)
        PythonApi.getTrackUrl(minPlayerPanel.track_id)
        PythonApi.getTrackInfo(minPlayerPanel.track_id)
    }

    MprisPlayer{
        id: mprisPlayer
    }

    MediaPlayer {
        id: mediaPlayer
        autoLoad: true


        property bool videoPlaying: false
        property string errorMsg: ""

        onPlaybackStateChanged: {
            /*
                mprisPlayer.playbackState = mediaPlayer.playbackState === MediaPlayer.PlayingState ?
                            Mpris.Playing : mediaPlayer.playbackState === MediaPlayer.PausedState ?
                                Mpris.Paused : Mpris.Stopped
*/
        }

        onError: {
            if ( error === MediaPlayer.ResourceError ) errorMsg = qsTr("Error: Problem with allocating resources")
            else if ( error === MediaPlayer.ServiceMissing ) errorMsg = qsTr("Error: Media service error")
            else if ( error === MediaPlayer.FormatError ) errorMsg = qsTr("Error: Video or Audio format is not supported")
            else if ( error === MediaPlayer.AccessDenied ) errorMsg = qsTr("Error: Access denied to the video")
            else if ( error === MediaPlayer.NetworkError ) errorMsg = qsTr("Error: Network error")
            stop()
        }

        onStopped:
        {
            if(PlaylistManager.keepTrack === false)
            {
                if(PlaylistManager.canNext())
                    PlaylistManager.nextTrack()
                else
                    progressSlider.visible = false
            }
        }

        onPositionChanged:
        {
            progressSlider.value = mediaPlayer.position/mediaPlayer.duration*100
        }
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
            //visible: mediaPlayer.isPlaylist && modelPlaylist.isPrev();
            onClicked: {
                prev();
            }
        }
        IconButton {
            icon.source: mediaPlayer.isPlaying ? "image://theme/icon-m-pause" : "image://theme/icon-m-play"
            onClicked: {
                //console.debug("isPlayling: " + minPlayer.isPlaying)
                if (mediaPlayer.isPlaying)
                {
                    //console.debug("Pause")
                    mediaPlayer.pause()
                }
                else {
                    //console.debug("Play")
                    //play()
                    PlaylistManager.play()
                }
            }
        }
        IconButton {
            id: nextButton
            icon.source: "image://theme/icon-m-next"
            //visible: mediaPlayer.isPlaylist && modelPlaylist.isNext();
            onClicked: {
                next();
            }
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
        target: PythonApi
        onRecentTrackUrlChanged :
        {
            console.log(PythonApi.trackUrl)

            url = PythonApi.trackUrl
            minPlayerPanel.play();
            //PythonApi.getPlayingTrackInfo(track_id)
        }

        onPlayingTrackInfoChanged:
        {
            console.log(PythonApi.playingTrackInfo)
            var trackInfo = JSON.parse(PythonApi.playingTrackInfo)
            mediaTitle.text = trackInfo["track_num"] + " - " + trackInfo["name"] + " - "  +trackInfo["album"] + " - " + trackInfo["artist"]
            bgImage.source = trackInfo["image"]
        }
    }
    Connections
    {
        target: PlaylistManager
        onCurrenTrackIDChanged:
        {
            console.log(PlaylistManager.trackID)
            var trackInfo = JSON.parse(PythonApi.invokeTrackInfo(PlaylistManager.trackID))
            mediaTitle.text = trackInfo["track_num"] + " - " + trackInfo["name"] + " - "  +trackInfo["album"] + " - " + trackInfo["artist"]
            bgImage.source = trackInfo["image"]
            PythonApi.getTrackUrl(PlaylistManager.trackID);
            prevButton.enabled = PlaylistManager.canPrev();
            nextButton.enabled = PlaylistManager.canNext();
        }

        onPlaylistFinished:
        {
            mediaTitle.text = ""
            bgImage.source = ""
            minPlayerPanel.hide(100);
        }
    }

    Component.onCompleted: {
        //mprisPlayer.canControl = true;
        //if (minPlayer.playbackState == MediaPlayer.PlayingState) mprisPlayer.playbackStatus = Mpris.Playing
        //else mprisPlayer.playbackStatus = Mpris.Paused
    }
}

