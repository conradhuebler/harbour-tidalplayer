// Claude Generated — the play queue as a cover flow over the blurred artwork
// of the centred track. Ported from qml-tidalplayer's CoverFlowOverlay.
import QtQuick 2.0
import Sailfish.Silica 1.0

import "widgets"

Page {
    id: page
    allowedOrientations: Orientation.All

    property bool _rebuilding: false

    function rebuild() {
        _rebuilding = true
        var wanted = playlistManager.size
        for (var i = 0; i < wanted; ++i) {
            var id = playlistManager.requestPlaylistItem(i)
            var track = cacheManager.getTrackInfo(id)
            var row = {
                "trackid": "" + id,
                "title": track && track.title ? track.title : qsTr("Track %1").arg(i + 1),
                "artist": track && track.artist ? track.artist : "",
                "album": track && track.album ? track.album : "",
                "image": track && track.image ? track.image : ""
            }
            if (i < queueModel.count)
                queueModel.set(i, row)
            else
                queueModel.append(row)
        }
        while (queueModel.count > wanted)
            queueModel.remove(queueModel.count - 1)

        _rebuilding = false
        if (playlistManager.currentIndex >= 0)
            flow.positionAt(playlistManager.currentIndex)

        if (applicationWindow.settings && applicationWindow.settings.debugLevel >= 1)
            console.log("CoverFlow: queue rebuilt,", queueModel.count, "tracks")
    }

    // Fill in a row whose track info only arrived from the backend after the
    // model was built.
    function updateTrack(trackInfo) {
        if (!trackInfo || !trackInfo.trackid)
            return
        for (var i = 0; i < queueModel.count; ++i) {
            if (queueModel.get(i).trackid === "" + trackInfo.trackid) {
                queueModel.set(i, {
                    "trackid": "" + trackInfo.trackid,
                    "title": trackInfo.title ? trackInfo.title : "",
                    "artist": trackInfo.artist ? trackInfo.artist : "",
                    "album": trackInfo.album ? trackInfo.album : "",
                    "image": trackInfo.image ? trackInfo.image : ""
                })
            }
        }
    }

    ListModel { id: queueModel }

    Component.onCompleted: rebuild()

    Connections {
        target: playlistManager
        onListChanged: rebuild()
        onCurrentTrack: {
            if (playlistManager.currentIndex >= 0)
                flow.positionAt(playlistManager.currentIndex)
        }
    }

    Connections {
        target: tidalApi
        onCacheTrack: page.updateTrack(track_info)
    }

    BlurBackdrop {
        anchors.fill: parent
        source: flow.valueAt(flow.currentIndex, "image")
        dim: 0.6
        fadeOut: false
    }

    SilicaFlickable {
        anchors {
            fill: parent
            bottomMargin: miniPlayerPanel.margin
        }
        contentHeight: height

        PullDownMenu {
            MenuItem {
                text: qsTr("Show as list")
                onClicked: {
                    pageStack.pop()
                    applicationWindow.mainPage.showPlaylist()
                }
            }
            MenuItem {
                text: qsTr("Jump to current track")
                enabled: playlistManager.currentIndex >= 0
                onClicked: flow.positionAt(playlistManager.currentIndex)
            }
        }

        PageHeader {
            id: header
            title: qsTr("Play Queue")
            description: queueModel.count > 0
                         ? qsTr("%1 of %2").arg(flow.currentIndex + 1).arg(queueModel.count)
                         : ""
        }

        CoverFlow {
            id: flow
            anchors {
                top: header.bottom
                left: parent.left
                right: parent.right
                bottom: hint.top
                bottomMargin: Theme.paddingLarge
            }
            model: queueModel
            titleRole: "title"
            subtitleRole: "artist"
            imageRole: "image"
            highlightIndex: playlistManager.currentIndex
            visible: queueModel.count > 0

            onActivated: playlistManager.playPosition(index)
        }

        Label {
            id: hint
            anchors {
                bottom: parent.bottom
                left: parent.left
                right: parent.right
                bottomMargin: Theme.paddingLarge
                leftMargin: Theme.horizontalPageMargin
                rightMargin: Theme.horizontalPageMargin
            }
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            font.pixelSize: Theme.fontSizeExtraSmall
            color: Theme.secondaryColor
            visible: queueModel.count > 0
            text: qsTr("Tap the centred cover to play it")
        }

        ViewPlaceholder {
            enabled: queueModel.count === 0
            text: qsTr("Nothing queued")
            hintText: qsTr("Play an album, playlist or mix to browse its covers here")
        }
    }
}
