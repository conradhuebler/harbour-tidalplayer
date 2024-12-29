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
                mediaController.blockAutoNext = true
                playlistManager.previousTrack()
            }
        }
        CoverAction {
            iconSource: "image://theme/icon-m-simple-play"
            id: playpause
            onTriggered:
            {
                if (mediaController.playbackState === 1)
                {
                    mediaController.pause()
                }
                else if(mediaController.playbackState === 2){
                    mediaController.play()
                }
            }
        }

        CoverAction {
            id: nextButton
            iconSource: "image://theme/icon-m-simple-next"
            onTriggered: {
                mediaController.blockAutoNext = true
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
        onCurrentPlayback:
        {
            titleLabel.text = trackinfo.track_num + " - " + trackinfo.title
            artist_albumLabel.text = trackinfo.album + " - " + trackinfo.artist
            coverImage.source = trackinfo.image
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
        target: mediaController
        onPlaybackStateChanged:
        {
            if(mediaController.playbackState === 1)
                 playpause.iconSource = "image://theme/icon-m-simple-pause"
             else if(mediaController.playbackState === 2)
                 playpause.iconSource =  "image://theme/icon-m-simple-play"
        }
    }
}
