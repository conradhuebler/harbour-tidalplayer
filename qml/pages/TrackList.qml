import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: root

    // Properties für verschiedene Verwendungszwecke
    property string title: ""
    property string playlistId: ""
    property string type: "current"  // "playlist" oder "current"

    Timer {
        id: updateTimer
        interval: 100  // 100ms Verzögerung
        repeat: false
        onTriggered: {
            console.log(playlistManager.size)
            for(var i = 0; i < playlistManager.size; ++i) {
                console.log("Requesting item", i)
                var id = playlistManager.requestPlaylistItem(i)
                console.log("here id", id)
                var track = cacheManager.getTrackInfo(id)
                if (track) {
                    console.log("Adding track:", track.title)
                console.log("Track details:", JSON.stringify({
                    title: track.title,
                    artist: track.artist,
                    album: track.album,
                    id: id,
                    duration: track.duration,
                    image: track.image,
                    index: i
                }))
                listModel.append({
                    "title": track.title,
                    "artist": track.artist,
                    "album": track.album,
                    "id": track.id,
                    "duration": track.duration,
                    "image": track.image,
                    "index": track.index
                })
                } else {
                    console.log("No track data for index:", i)
                }
            }
            //highlight_index = playlistManager.current_track
        }
    }

    SilicaListView {
        id: tracks
        anchors.fill: parent

        header: PageHeader {
            title: root.title
        }
        height: parent.height
        clip: true  // Verhindert Überläufe

        // Debug-Rechteck um die View-Grenzen zu sehen

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
            onCountChanged: console.log("ListModel count changed to:", count)
        }

        delegate: ListItem {
            id: listEntry
            width: parent.width
            contentHeight: contentRow.height + Theme.paddingMedium

            Row {
                id: contentRow
                anchors {
                    left: parent.left
                    right: parent.right
                    margins: Theme.horizontalPageMargin
                }
                spacing: Theme.paddingMedium

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
                        color: listEntry.highlighted ? Theme.highlightColor : Theme.primaryColor
                        font.pixelSize: Theme.fontSizeMedium
                        truncationMode: TruncationMode.Fade
                    }

                    Row {
                        width: parent.width
                        spacing: Theme.paddingSmall

                        Label {
                            text: model.artist
                            color: listEntry.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
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
                            color: listEntry.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                            font.pixelSize: Theme.fontSizeSmall
                        }
                    }
                }
            }

            menu: ContextMenu {
                MenuItem {
                    text: qsTr("Play Now")
                    onClicked: {
                        playlistManager.playTrack(model.id)
                    }
                }
                MenuItem {
                    text: qsTr("Add to Queue")
                    onClicked: {
                        playlistManager.appendTrack(model.id)
                    }
                }
            }

            onClicked: {
                if (type === "playlist") {
                    playlistManager.playTrack(model.id)
                } else {
                    playlistManager.playPosition(model.index)
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
            // Playlist-Tracks laden
            tidalApi.getPlaylistTracks(playlistId)
        } else {
            // Aktuelle Playlist laden
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
                    "id": track_info.id,
                    "duration": track_info.duration,
                    "image": track_info.image
                })
            }
        }
    }

    Connections {
        target: playlistManager
        onTrackInformation: {
            if (type !== "playlist") {
                listModel.append({
                    "title": title,
                    "artist": artist,
                    "album": album,
                    "id": id,
                    "duration": duration,
                    "image": image,
                    "index": index
                })
            }
        }

        onListChanged: {
        console.log("update playlist")
            if (type !== "playlist") {
                console.log("update current playlist")
                //listModel.clear()
                updateTimer.start()
            }
        }
    }
}
