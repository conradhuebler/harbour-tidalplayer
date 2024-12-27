import QtQuick 2.0
import Sailfish.Silica 1.0
import QtMultimedia 5.6
import Sailfish.Media 1.0

Column {
    id: listView
    width: parent.width

    property string track_list
    property string track_id_list
    property bool allow_add: true
    property bool start_on_tap: false
    property int highlight_index: -1
    property int type: 0
    property bool allow_play: true
    property string title: "Track List"

    onHighlight_indexChanged: {
        if (highlight_index >= 0) {
            tracks.positionViewAtIndex(highlight_index, ListView.Center)
        }
    }

    SectionHeader {
        id: sectionHeader
        width: parent.width
        text: title
    }

    IconButton {
        id: playButton
        icon.source: "image://theme/icon-m-simple-play"
        visible: allow_play
        onClicked: {
            playlistManager.clearPlayList()
            playlistManager.insertTrack(listModel.get(0).id)
            for(var i = 1; i < listModel.count; ++i)
                playlistManager.appendTrack(listModel.get(i).id)
        }
    }

    SilicaListView {
        id: tracks
        width: parent.width
        height: parent.height - sectionHeader.height - (playButton.visible ? playButton.height : 0)
        clip: true

        model: ListModel {
            id: listModel
            onCountChanged: console.log("List model count:", count)
        }

        delegate: ListItem {
            id: listEntry
            width: parent.width
            highlighted: model.index === highlight_index

            Rectangle {
                visible: model.index === highlight_index
                anchors.fill: parent
                color: Theme.highlightBackgroundColor
                opacity: 0.2
            }

            Row {
                spacing: Theme.paddingMedium
                anchors {
                    left: parent.left
                    right: parent.right
                    leftMargin: Theme.horizontalPageMargin
                    rightMargin: Theme.horizontalPageMargin
                }

                Image {
                    id: coverImage
                    height: 100
                    width: height
                    fillMode: Image.PreserveAspectFit
                    source: getImageSource(listModel.get(model.index).type, model.image)
                }

                Column {
                    width: parent.width - coverImage.width - parent.spacing
                    spacing: Theme.paddingSmall

                    Row {
                        width: parent.width
                        spacing: Theme.paddingSmall

                        Label {
                            id: trackName
                            width: parent.width - timeLabel.width - parent.spacing
                            color: (model.index === highlight_index) ?
                                   Theme.highlightColor : Theme.primaryColor
                            text: model.name
                            font.bold: model.index === highlight_index
                            truncationMode: TruncationMode.Fade
                            font.pixelSize: Theme.fontSizeSmall
                        }

                        Label {
                            id: timeLabel
                            property string dur: {
                                if ((model.duration) > 3599)
                                    return Format.formatDuration(model.duration, Formatter.DurationLong)
                                return Format.formatDuration(model.duration, Formatter.DurationShort)
                            }
                            color: (model.index === highlight_index) ?
                                   Theme.highlightColor : Theme.primaryColor
                            text: "(" + dur + ")"
                            font.bold: model.index === highlight_index
                            font.pixelSize: Theme.fontSizeSmall
                        }
                    }

                    Row {
                        width: parent.width
                        spacing: Theme.paddingSmall
                        visible: listModel.get(model.index).type === 1

                        Label {
                            id: artistName
                            color: (model.index === highlight_index) ?
                                   Theme.highlightColor : Theme.secondaryColor
                            text: model.artist
                            font.bold: model.index === highlight_index
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }

                        Label {
                            id: albumName
                            color: (model.index === highlight_index) ?
                                   Theme.highlightColor : Theme.secondaryColor
                            text: " - " + model.album
                            font.bold: model.index === highlight_index
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }
                    }
                }
            }

            onClicked: {
                if(start_on_tap) {
                    mediaPlayer.blockAutoNext = true
                    playlistManager.playPosition(model.index)
                    highlight_index = model.index
                }
            }

            menu: ContextMenu {
                MenuItem {
                    text: "Play"
                    visible: allow_add
                    onClicked: {
                        console.log(listModel.get(model.index).type)
                        if(listModel.get(model.index).type === 1) {
                            console.log("play track ", listModel.get(model.index).id)
                            playlistManager.playTrack(listModel.get(model.index).id)
                        }
                        else if(listModel.get(model.index).type === 2)
                            playlistManager.playAlbum(listModel.get(model.index).id)
                        highlight_index = model.index
                    }
                }

                MenuItem {
                    text: "Queue"
                    visible: allow_add
                    onClicked: {
                        playlistManager.appendTrack(listModel.get(model.index).id)
                    }
                }
            }

            Component.onCompleted: {
                if (model.index === highlight_index) {
                    ListView.view.positionViewAtIndex(model.index, ListView.Center)
                }
            }
        }

        ViewPlaceholder {
            enabled: listModel.count === 0
            text: "No tracks"
            textFormat: Text.StyledText
        }

        VerticalScrollDecorator { }
    }

    function getImageSource(type, imageUrl) {
        if (!imageUrl || imageUrl === "") {
            switch(type) {
                case 1: return "image://theme/icon-m-media-songs"
                case 2: return "image://theme/icon-m-media-albums"
                case 3: return "image://theme/icon-m-media-artists"
                case 4: return "image://theme/icon-m-media-playlists"
                case 5: return "image://theme/icon-m-video"
                default: return "image://theme/icon-m-media-songs"
            }
        }
        return imageUrl
    }

    function addTrack(title, artist, album, id, duration) {
        console.log("Adding track to model:", title, artist, album)
        listModel.append({
            "name": title,
            "artist": artist,
            "album": album,
            "id": id,
            "type": 1,
            "duration": duration,
            "image": ""
        })
        console.log("Current model count:", listModel.count)
    }

    function setTrack(index, id, title, artist, album, image, duration) {
        console.log("Setting track at index:", index, title)
        listModel.set(index, {
            "name": title,
            "artist": artist,
            "album": album,
            "id": id,
            "type": 1,
            "duration": duration,
            "image": image
        })
    }

    function scrollTo(index) {
        tracks.positionViewAtIndex(index, ListView.Center)
    }

    function clear() {
        console.log("Clearing list model")
        listModel.clear()
    }

    Connections {
        target: playlistManager
        onContainsTrack: {
            pythonApi.getTrackInfo(id)
        }
    }

    Component.onCompleted: {
        console.log("TrackList component completed")
        playlistManager.generateList()
    }
}
