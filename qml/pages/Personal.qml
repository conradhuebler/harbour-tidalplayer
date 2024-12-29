import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: personalPage
    anchors.bottom: miniPlayerPanel.top // Panel als Referenz nutzen

    // The effective value will be restricted by ApplicationWindow.allowedOrientations
    //allowedOrientations: Orientation.All
//    anchors{
//        fill: parent
//        bottomMargin: minPlayerPanel.margin
//    }
    SilicaListView {
        id: listView
//        width: 480; height: 800
        anchors.bottom: miniPlayerPanel.top // Panel als Referenz nutzen

        model: ListModel {id: listModel }
        delegate: ListItem {
            id: listEntry
            height: 220
            Row{
            Image {
                id: coverImage
                height: 200
                //anchors.centerIn: parent.top
                fillMode: Image.PreserveAspectFit
                anchors.margins: Theme.paddingSmall
                source: model.image
            }
            Column{
            Label
            {
                id: trackName
                truncationMode: TruncationMode.Fade
                color: Theme.highlightColor
                text: model.title
            }

            Label
            {
                property string dur: {
                    if ((model.duration) > 3599) Format.formatDuration(model.duration , Formatter.DurationLong)
                    else return Format.formatDuration(model.duration , Formatter.DurationShort)
                }
                id: trackNum
                truncationMode: TruncationMode.Fade
                color: Theme.highlightColor
                text: model.num_tracks + " Tracks (" + dur + ")"
            }

                Label
                {
                    id: descriptionLabel
                    truncationMode: TruncationMode.Fade
                    color: Theme.highlightColor
                    text: description
                }
            }
            }
            menu: ContextMenu {

                MenuItem {
                    text: "Play Playlist"
                    onClicked: {
                        pythonApi.playPlaylist(listModel.get(model.index).id)
                    }

                }
            }
            onClicked:
            {
                //tracklistpage = pageStack.push(Qt.resolvedUrl("TrackList.qml"))
                //tracklistpage.
            }
        }
        anchors.fill: parent

        VerticalScrollDecorator {}
    }

    Connections
    {
        target: pythonApi
        onPersonalPlaylistAdded:
        {
            listModel.append(
                        {   "title": title,
                            "id" : id,
                            "image" : image,
                            "num_tracks" : num_tracks,
                            "description" : description,
                            "duration" : duration,

                        })
        }

        onLoginSuccess:
        {
            console.log("Personal playlists")
            pythonApi.getPersonalPlaylists()
        }
    }
}
