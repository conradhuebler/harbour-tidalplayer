import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: root

    // Properties für verschiedene Verwendungszwecke
    property string title: ""
    property string playlistId: ""
    property int albumId: -1
    property string type: "current"  // "playlist" oder "current" oder "album" oder "tracklist"
    property int currentIndex: playlistManager.currentIndex
    property alias model: listModel
    Timer {
        id: updateTimer
        interval: 100  // 100ms Verzögerung
        repeat: false
        onTriggered: {
            console.log(playlistManager.size)
            for(var i = 0; i < playlistManager.size; ++i) {
                var id = playlistManager.requestPlaylistItem(i)
                var track = cacheManager.getTrackInfo(id)
                if (track) {
                    listModel.append({
                        "title": track.title,
                        "artist": track.artist,
                        "album": track.album,
                        "id": track.id,
                        "trackid": track.id,
                        "duration": track.duration,
                        "image": track.image,
                        "index": i
                    })
                } else {
                    console.log("No track data for index:", i)
                }
            }
        }
    }

    SilicaListView {
        id: tracks
        anchors.fill: parent
        // highlightFollowsCurrentItem: true //introduced by Pawel for removing of tracks

        header: PageHeader {
            title: root.title
        }
        height: parent.height
        clip: true  // Verhindert Überläufe

        PullDownMenu {
            MenuItem {
                text: qsTr("Play All")
                onClicked: {
                    if (type === "playlist") {
                        playlistManager.clearPlayList()
                        tidalApi.playPlaylist(playlistId)
                    }
                }
                visible: type === "playlist"
            }
            visible: type === "playlist"
        }

        model: ListModel {
            id: listModel
        }

        delegate: ListItem {
            id: listEntry
            width: parent.width
            contentHeight: contentRow.height + Theme.paddingMedium

            // Highlight für aktuellen Track
            highlighted: type === "current" && model.index === root.currentIndex

            Rectangle {
                visible: type === "current" && model.index === root.currentIndex
                anchors.fill: parent
                color: Theme.rgba(Theme.highlightBackgroundColor, 0.2)
                z: -1
            }

            Row {
                id: contentRow
                anchors {
                    left: parent.left
                    right: parent.right
                    margins: Theme.horizontalPageMargin
                }
                spacing: Theme.paddingMedium

                // Optionaler Indikator für aktuellen Track
                Label {
                    visible: type === "current" && model.index === root.currentIndex
                    text: "▶"  // oder ein anderes Symbol
                    color: Theme.highlightColor
                    font.pixelSize: Theme.fontSizeMedium
                    width: visible ? implicitWidth : 0
                    verticalAlignment: Text.AlignVCenter
                    height: coverImage.height
                }

                Image {
                    id: coverImage
                    width: Theme.itemSizeMedium
                    height: Theme.itemSizeMedium
                    fillMode: Image.PreserveAspectCrop
                    source: model.image || ""
                    asynchronous: true

                    Rectangle {
                        color: Theme.rgba(Theme.highlightBackgroundColor, 0.1)
                        anchors.fill: parent
                        visible: coverImage.status !== Image.Ready
                    }
                }

                Column {
                    width: parent.width - coverImage.width - parent.spacing
                    spacing: Theme.paddingSmall

                    Label {
                        width: parent.width
                        text: model.title
                        color: {
                            if (type === "current" && model.index === root.currentIndex) {
                                return Theme.highlightColor
                            }
                            return listEntry.highlighted ? Theme.highlightColor : Theme.primaryColor
                        }
                        font.pixelSize: Theme.fontSizeMedium
                        truncationMode: TruncationMode.Fade
                        font.bold: type === "current" && model.index === root.currentIndex
                    }

                    Row {
                        width: parent.width
                        spacing: Theme.paddingSmall

                        Label {
                            text: model.artist
                            color: {
                                if (type === "current" && model.index === root.currentIndex) {
                                    return Theme.secondaryHighlightColor
                                }
                                return listEntry.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                            }
                            font.pixelSize: Theme.fontSizeSmall
                        }

                        Label {
                            text: " • "
                            color: listEntry.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                            font.pixelSize: Theme.fontSizeSmall
                        }

                        Label {
                            property string dur: (model.duration > 3599)
                                ? Format.formatDuration(model.duration, Formatter.DurationLong)
                                : Format.formatDuration(model.duration, Formatter.DurationShort)
                            text: dur
                            color: {
                                if (type === "current" && model.index === root.currentIndex) {
                                    return Theme.secondaryHighlightColor
                                }
                                return listEntry.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                            }
                            font.pixelSize: Theme.fontSizeSmall
                        }
                    }
                }
            }

            onClicked: {
                if (type === "current") {
                    playlistManager.playPosition(Math.floor(model.index))  // Stelle sicher, dass es ein Integer ist
                } else {
                    playlistManager.playTrack(model.trackid)
                }
            }

            menu: ContextMenu {
                MenuItem {
                    text: qsTr("Play Now")
                    onClicked: {
                        if (type === "current") {
                            playlistManager.playPosition(Math.floor(model.index))  // Stelle sicher, dass es ein Integer ist
                        } else {
                            playlistManager.playTrack(model.trackid)
                        }
                    }
                }
                MenuItem {
                    text: qsTr("Add to Queue")
                    onClicked: {
                        playlistManager.appendTrack(model.trackid)
                    }
                    visible: type !== "current"
                }
                MenuItem {
                    text: qsTr("Remove from Queue")
                    onClicked: {
                        var orgIndex = model.index
                        var orgTrackId = playlistManager.requestPlaylistItem(model.index)
                        var playingState = mediaController.isPlaying
                        var removingPrevTrack = orgIndex < currentIndex
                        var removingSelected = currentIndex === model.index
                        console.log("removingPrevTrack:",orgIndex)
                        playlistManager.removeTrack(orgTrackId)
                        if (type === "current") {
                            if (playlistManager.size === 0) {
                                playlistManager.playlistFinished()
                                return
                            }
                            if (removingSelected)
                            {   // intention: if user removes the currently played song
                                // then move next if possible, else stop playing
                                if (playingState) {
                                    playlistManager.playPosition(model.index)
                                } else {
                                    playlistManager.setTrack(orgIndex) }// to inform cover
                                return
                            }
                            if (removingPrevTrack ) {
                                // remove a track before selected
                                console.log("removePrevTrack:", orgIndex, currentIndex)
                                var newIndex = Math.max(0, currentIndex - 1)
                                if (playingState) {
                                    playlistManager.playPosition(newIndex)
                                 } else {
                                    model.index = newIndex
                                    currentIndex = newIndex
                                    playlistManager.setTrack(newIndex)  
                                }
                            }
                            // no action needed for removal after current track
                        }
                    }
                    visible: type === "current"
                }
            }
        }

        ViewPlaceholder {
            enabled: listModel.count === 0
            text: qsTr("No Tracks")
            hintText: type === "playlist" ?
                     qsTr("This playlist is empty") :
                     qsTr("No tracks in queue")
        }

        VerticalScrollDecorator {}
    }

    Component.onCompleted: {
        if (type === "playlist") {
            tidalApi.getPlaylistTracks(playlistId)
        } else if (type == "album") {
            tidalApi.getAlbumTracks(albumId)
        } else {
            playlistManager.generateList()
        }
    }

    Connections {
        target: tidalApi
        onPlaylistTrackAdded: {
            if (type === "playlist") {
                listModel.append({
                    "title": track_info.title,
                    "artist": track_info.artist,
                    "album": track_info.album,
                    "trackid": track_info.trackid,
                    "duration": track_info.duration,
                    "image": track_info.image
                })
            }
        }

        onAlbumTrackAdded: {
            if (type === "album") {
                listModel.append({
                    "title": track_info.title,
                    "artist": track_info.artist,
                    "album": track_info.album,
                    "trackid": track_info.trackid,
                    "duration": track_info.duration,
                    "image": track_info.image
                })
            }
        }

        onTopTracksofArtist: {
            if (type === "tracklist") {
                listModel.append({
                    "title": track_info.title,
                    "artist": track_info.artist,
                    "album": track_info.album,
                    "trackid": track_info.trackid,
                    "duration": track_info.duration,
                    "image": track_info.image
                })
            }
        }
    }

    Connections {
        target: playlistManager
        onTrackInformation: {
            if (type === "current") {
                listModel.append({
                    "title": title,
                    "artist": artist,
                    "album": album,
                    "trackid": id,
                    "duration": duration,
                    "image": image,
                    "index": index
                })
            }
        }

        onCurrentTrack: {
            if (type === "current") {
                tracks.positionViewAtIndex(position, ListView.Center)
            }
        }

        onClearList: {
            console.log("Playlist must be cleared")
            if (type === "current") {
                listModel.clear()
            }
        }

        onListChanged: {
            console.log("update playlist")
            if (type === "current") {
                console.log("update current playlist")
                listModel.clear()
                updateTimer.start()
            }
        }
    }
}
