import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: root

    // Properties für verschiedene Verwendungszwecke
    property string title: ""
    property string playlistId: ""
    property int albumId: -1
    property string type: "current"  // "playlist" oder "current" oder "album" oder "tracklist"

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
                        playlistManager.playTrack(model.trackid)
                    }
                }
                MenuItem {
                    text: qsTr("Add to Queue")
                    onClicked: {
                        playlistManager.appendTrack(model.trackid)
                    }
                }
            }

            onClicked: {
                if (type === "current") {
                     playlistManager.playPosition(model.index)

                } else {
                   playlistManager.playTrack(model.trackid)
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
        } else if (type == "album")
        {
            tidalApi.getAlbumTracks(albumId)
        }
        else {
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
                    "trackid": trackid,
                    "duration": duration,
                    "image": image,
                    "index": index
                })
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
