import QtQuick 2.0
import Sailfish.Silica 1.0
import QtMultimedia 5.6
import Sailfish.Media 1.0
import harbour.tidalplayer 1.0


SilicaListView {
    property string track_list
    property  string track_id_list
    property bool allow_add : true
    property bool start_on_top : false
    property int highlight_index : 0

    id: trackList
    model: ListModel
    {
        id: listModel
    }

    function createListfromTrackIds()
    {
        var tracks = JSON.parse(track_id_list)
        for( var i=0, l=tracks.length; i<l; i++)
        {
            var currentTrack = JSON.parse(PythonApi.invokeTrackInfo(tracks[i]["id"]))
            listModel.append({   "name": currentTrack["name"],
                                 "id" : currentTrack["id"],
                                 "type" : currentTrack["type"],
                                 "index" : i
                             })

        }
    }

    function createListfromTracks()
    {
        var tracks = JSON.parse(track_list)
        for( var i=0, l=tracks.length; i<l; i++)
        {
            listModel.append({   "name": tracks[i]["name"],
                                 "id" : tracks[i]["id"],
                                 "type" : tracks[i]["type"]
                             })

        }
    }

    function clear()
    {
        listModel.clear();
    }

    function appendtoPlaylist()
    {
        var tracks = JSON.parse(track_list)
        for( var i=0, l=tracks.length; i<l; i++)
        {
            PlaylistManager.addTrackId(tracks[i]["id"])
        }
    }

    delegate: ListItem {
        id: listEntry
        Row {
            IconButton {
                id: playTrack
                icon.source: "image://theme/icon-m-play"
                onClicked: {
                    console.log(listModel.get(model.index).trackId)
                    PlaylistManager.playTrackId(listModel.get(model.index).id)
                }
                height: trackName.height
                visible: allow_add == true
            }

            IconButton {
                id: queueTrack
                icon.source: "image://theme/icon-m-add"
                onClicked: {
                    PlaylistManager.addTrackId(listModel.get(model.index).id)
                }
                height: trackName.height
                visible: allow_add == true
            }

            Label {
                id: trackName
                color: (listEntry.highlighted || model.index === highlight_index) ? Theme.highlightColor : Theme.primaryColor
                text: model.name
                x: Theme.horizontalPageMargin
                truncationMode: elide
                font.pixelSize: Theme.fontSizeSmall
            }

        }


        onClicked:
        {
            if(start_on_top)
                PlaylistManager.playTrack(listModel.get(model.index).index)
        }
    }
    VerticalScrollDecorator {}
}
