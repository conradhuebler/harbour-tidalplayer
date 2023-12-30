import QtQuick 2.0
import Sailfish.Silica 1.0
import QtMultimedia 5.6
import Sailfish.Media 1.0



Column
{
    id: listView

    property string track_list
    property string track_id_list
    property bool allow_add : true
    property bool start_on_top : false
    property int highlight_index : -1
    property int type : 0
    property string title : "Track List"
    SectionHeader
    {
        anchors {
            top : parent.top
        }
        id: sectionHeader
        text: title
    }

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

    Button
    {
        text: "Play"
        onClicked:
        {
            playlistManager.clearPlayList()
            playlistManager.insertTrack(listModel.get(0).id)
            for(var i = 1; i < listModel.count; ++i)
                playlistManager.appendTrack(listModel.get(i).id)
        }
    }

SilicaListView {
    anchors {
         top: sectionHeader.bottom// Anker oben an den unteren Rand der Column
         topMargin: 120 // Abstand zwischen der Column und dem ListView
         left: parent.left // Anker links am linken Rand des Eltern-Elements (Page)
         right: parent.right // Anker rechts am rechten Rand des Eltern-Elements (Page)
         leftMargin: Theme.horizontalPageMargin
         rightMargin: Theme.horizontalPageMargin
         bottom: parent.bottom// Anker unten am unteren Rand des Eltern-Elements (Page)
     }
    model: ListModel
    {
        id: listModel
    }


    delegate: ListItem {
        id: listEntry
        Row {
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
                    text:
                    {
                        if(type == 2 )
                        {
                            model.artist
                        }
                        else if(type == 1 )
                        {
                            model.artist + " ( "+model.album +" )"
                        }
                    }
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
        menu: ContextMenu {

            MenuItem {
                text: "Play"
                onClicked: {
                    console.log(listModel.get(model.index).type)
                    if(listModel.get(model.index).type === 1)
                       playlistManager.playTrack(listModel.get(model.index).id)
                    else if(listModel.get(model.index).type === 2)
                       playlistManager.playAlbum(listModel.get(model.index).id)
                    highlight_index = model.index
                }
                visible: allow_add == true
            }


            MenuItem {
                text: "Queue"
                onClicked: {
                    playlistManager.appendTrack(listModel.get(model.index).id)
                }
                visible: allow_add == true
            }

        }
    }
    VerticalScrollDecorator { flickable: listView }

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

}
