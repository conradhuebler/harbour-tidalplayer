import QtQuick 2.0
import Sailfish.Silica 1.0
import QtMultimedia 5.6
import Sailfish.Media 1.0


SilicaListView {
    property string track_list
    property  string track_id_list
    property bool allow_add : true
    property bool start_on_top : false
    property int highlight_index : 0


    function addTrack(title, artist, album, id, duration)
    {
        listModel.append(
                    {"name": title,
                     "artist" : artist,
                     "album" : album,
                     "id" : id,
                     "type" : 1,
                     "duration" : duration
                        })
    }

    model: ListModel
    {
        id: listModel
    }


    delegate: ListItem {
        id: listEntry
        Row {
            IconButton {
                id: playTrack
                icon.source: "image://theme/icon-m-play"
                onClicked: {
                    mediaPlayer.blockAutoNext = true
                    playlistManager.playTrack(listModel.get(model.index).id)
                }
                height: trackName.height
                visible: allow_add == true
            }

            IconButton {
                id: queueTrack
                icon.source: "image://theme/icon-m-add"
                onClicked: {
                    playlistManager.appendTrack(listModel.get(model.index).id)
                }
                height: trackName.height
                visible: allow_add == true
            }

            Column {
                Label {
                    property string dur: {
                        if ((model.duration) > 3599) Format.formatDuration(model.duration , Formatter.DurationLong)
                        else return Format.formatDuration(model.duration , Formatter.DurationShort)
                    }
                    id: trackName
                    color: (listEntry.highlighted || model.index === highlight_index) ? Theme.highlightColor : Theme.primaryColor
                    text: model.name + " (" + dur +")"
                    x: Theme.horizontalPageMargin
                    truncationMode: elide
                    font.pixelSize: Theme.fontSizeSmall
                }

                Label {

                    id: artistName
                    color: (listEntry.highlighted || model.index === highlight_index) ? Theme.highlightColor : Theme.primaryColor
                    text: model.artist + " ( "+model.album +" )"
                    visible: listModel.get(model.index).type === 1
                    x: Theme.horizontalPageMargin
                    truncationMode: elide
                    font.pixelSize: Theme.fontSizeSmall
                }
            }
        }


        onClicked:
        {
            if(start_on_top)
            {
                mediaPlayer.blockAutoNext = true
                playlistManager.playPosition(model.index)
            }
        }

    }
    VerticalScrollDecorator {}

    Connections{
        target: playlistManager

        onContainsTrack:
        {
            pythonApi.getTrackInfo(id)
        }
    }

    Component.onCompleted: {
        playlistManager.generateList()
    }
}
