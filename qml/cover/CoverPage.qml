import QtQuick 2.0
import Sailfish.Silica 1.0

CoverBackground {

    Image {
        id: coverImage
        width: 0.66 * parent.height
        //anchors.centerIn: parent.top
        fillMode: Image.PreserveAspectFit
        anchors.margins: Theme.paddingSmall
    }
    Column {
        anchors.top: coverImage.bottom
    Label {
        id: titleLabel
        //anchors.bottom: parent
        text: qsTr("Tidal Player")
        color: Theme.highlightColor
        anchors.margins: Theme.paddingSmall
        anchors.top: coverImage.bottom
    }
    Label {
        id: artist_albumLabel
        //anchors.bottom: parent
        color: Theme.highlightColor
        anchors.margins: Theme.paddingSmall
        anchors.top: titleLabel.bottom
    }
    }
    CoverActionList {
        id: coverAction
        CoverAction {
            id: prevButton
            iconSource: "image://theme/icon-m-simple-previous"
            onTriggered: {
                mediaPlayer.blockAutoNext = true
                playlistManager.previousTrack()
            }
        }
        CoverAction {
            iconSource: "image://theme/icon-m-simple-play"
            id: playpause
            onTriggered:
            {
                if (mediaPlayer.playbackState === 1)
                {
                    mediaPlayer.pause()
                }
                else if(mediaPlayer.playbackState === 2){
                    mediaPlayer.play()
                }
            }
        }

        CoverAction {
            id: nextButton
            iconSource: "image://theme/icon-m-simple-next"
            onTriggered: {
                mediaPlayer.blockAutoNext = true
                playlistManager.nextTrackClicked()
            }
        }

        CoverAction {
            iconSource: "image://theme/icon-cover-search"
        }
    }

    Connections
    {
        target: pythonApi
        onCurrentTrackInfo:
        {
            titleLabel.text = track_num + " - " + title
            artist_albumLabel.text = album + " - " + artist
            coverImage.source = album_image
        }
    }
    Connections
    {
        target: playlistManager
        onPlayListFinished:
        {
            titleLabel.text = ""
            artist_albumLabel.text = ""
            coverImage.source = ""
            prevButton.enabled = playlistManager.canPrev;
            nextButton.enabled = playlistManager.canNext;
        }
    }
    Connections
    {
        target: mediaPlayer
        onPlaybackStateChanged:
        {
            if(mediaPlayer.playbackState === 1)
                 playpause.iconSource = "image://theme/icon-m-simple-pause"
             else if(mediaPlayer.playbackState === 2)
                 playpause.iconSource =  "image://theme/icon-m-simple-play"
        }
    }
}
