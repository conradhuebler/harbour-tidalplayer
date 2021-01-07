import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.tidalplayer 1.0

CoverBackground {

    Image {
        id: coverImage
        width: 0.66 * parent.height
        //anchors.centerIn: parent.top
        fillMode: Image.PreserveAspectFit
        anchors.margins: Theme.paddingSmall
    }

    Label {
        id: label
        //anchors.bottom: parent
        text: qsTr("Tidal Player")
        color: Theme.highlightColor
        anchors.margins: Theme.paddingSmall
        anchors.top: coverImage.bottom
    }

    CoverActionList {
        id: coverAction

        CoverAction {
            id: prevButton
            iconSource: "image://theme/icon-cover-next"
        }

        CoverAction {
            iconSource: "image://theme/icon-cover-pause"
        }

        CoverAction {
            iconSource: "image://theme/icon-cover-search"
        }
    }

    Connections
    {
        target: PlaylistManager
        onCurrenTrackIDChanged:
        {
            var trackInfo = JSON.parse(PythonApi.invokeTrackInfo(PlaylistManager.trackID))
            label.text = trackInfo["track_num"] + " - " + trackInfo["name"] + " - "  +trackInfo["album"] + " - " + trackInfo["artist"]
            coverImage.source = trackInfo["cover"]
        }
        onPlaylistFinished:
        {
            label.text = ""
            coverImage.source = ""
            prevButton.enabled = PlaylistManager.canPrev();
            nextButton.enabled = PlaylistManager.canNext();
        }
    }
}
