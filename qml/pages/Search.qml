import QtQuick 2.0
import Sailfish.Silica 1.0
import QtMultimedia 5.6
import Sailfish.Media 1.0

import "widgets"
import "stuff"

Item {
    id: searchPage

    // The effective value will be restricted by ApplicationWindow.allowedOrientations
    //allowedOrientations: Orientation.All

    // To enable PullDownMenu, place our content in a SilicaFlickable
    SilicaFlickable {
        anchors {
            fill: parent
            bottomMargin: minPlayerPanel.margin
        }
        clip: miniPlayerPanel.expanded
        contentHeight: parent.height - Theme.itemSizeExtraLarge - Theme.paddingLarge
        anchors.bottom: miniPlayerPanel.top // Panel als Referenz nutzen

        Column
        {

           // width: parent.width
            //height: header.height + mainColumn.height + Theme.paddingLarge

                id: header
                width: searchPage.width
                spacing: Theme.paddingSmall
                TextField {
                    id: searchString
                    width: parent.width
                    placeholderText: "Type and Search"
                    text: ""
                    label: "Please wait for login ..."
                    EnterKey.enabled: text.length > 0
                    EnterKey.iconSource: "image://theme/icon-m-search"

                    EnterKey.onClicked: {
                        listModel.clear()
                        pythonApi.genericSearch(searchString.text)
                        focus = false
                    }

                }

                Row {
                    //width: parent.width
                    anchors {
                        leftMargin: Theme.horizontalPageMargin
                        rightMargin: Theme.horizontalPageMargin
                       // bottom: searchString
                    }
                    Switch {
                        id: searchAlbum
                        anchors {
                            leftMargin: Theme.horizontalPageMargin
                            rightMargin: Theme.horizontalPageMargin
                        }
                        icon.source: "image://theme/icon-m-media-albums"
                        checked: true
                        onCheckedChanged: pythonApi.albums = checked
                    }
                    Switch {
                        id: searchArtists
                        anchors {
                            leftMargin: Theme.horizontalPageMargin
                            rightMargin: Theme.horizontalPageMargin
                        }
                        icon.source: "image://theme/icon-m-media-artists"
                        checked: true
                        onCheckedChanged: pythonApi.artists = checked

                    }
                    Switch {
                        id: searchTracks

                        anchors {
                            leftMargin: Theme.horizontalPageMargin
                            rightMargin: Theme.horizontalPageMargin
                        }
                        icon.source: "image://theme/icon-m-media-songs"
                        checked: true
                        onCheckedChanged: pythonApi.tracks = checked

                    }
                    Switch {
                        id: searchPlaylists

                        anchors {
                            leftMargin: Theme.horizontalPageMargin
                            rightMargin: Theme.horizontalPageMargin
                        }
                        icon.source: "image://theme/icon-m-media-playlists"
                        checked: false
                        enabled: false
                        //onCheckedChanged: pythonApi.playlists = checked

                    }
                }

                Connections {
                    target: pythonApi
                    onLoginSuccess:
                    {
                        searchString.label = "Find"
                        searchString.enabled = pythonApi.loginTrue
                    }
                    onLoginFailed:
                    {
                        searchString.label = "Please go to the settings and login via OAuth"
                        searchString.enabled = pythonApi.loginTrue
                    }
                }

        }

        SilicaListView {
            anchors {
                 top: header.bottom// Anker oben an den unteren Rand der Column
                 topMargin: 120 // Abstand zwischen der Column und dem ListView
                 left: parent.left // Anker links am linken Rand des Eltern-Elements (Page)
                 right: parent.right // Anker rechts am rechten Rand des Eltern-Elements (Page)
                 leftMargin: Theme.horizontalPageMargin
                 rightMargin: Theme.horizontalPageMargin
                 bottom: parent.bottom// Anker unten am unteren Rand des Eltern-Elements (Page)
             }
            // Tell SilicaFlickable the height of its content.
//            contentHeight: column.height

            // Place our content in a Column.  The PageHeader is always placed at the top
            // of the page, followed by our content.
            //header : Column {
            //}

            model: ListModel { id: listModel }

            delegate: ListItem {

                id: listEntry

                Row {
                    anchors {
                        left: parent.left
                        leftMargin: Theme.horizontalPageMargin
                        right: parent.right
                        rightMargin: Theme.horizontalPageMargin
                        verticalCenter: parent.verticalCenter
                    }

                    Image {
                        id: mediaType
                        source: {
                            if(model.image === "")
                            {
                            if(listModel.get(model.index).type === 1)
                                "image://theme/icon-m-media-songs"
                            else if(listModel.get(model.index).type === 3)
                                "image://theme/icon-m-media-artists"
                            else if (listModel.get(model.index).type === 2)
                                "image://theme/icon-m-media-albums"
                            else if (listModel.get(model.index).type === 4)
                                "image://theme/icon-m-media-playlists"
                            else if (listModel.get(model.index).type === 5)
                                "image://theme/icon-m-video"
                            }
                            else
                                model.image
                        }
                        fillMode: Image.PreserveAspectFit

                        //width: 32
                    }

                    Column {
                    Label {
                        property string dur: {
                            if ((model.duration) > 3599) Format.formatDuration(model.duration, Formatter.DurationLong)
                            else return Format.formatDuration(model.duration, Formatter.DurationShort)
                        }
                        id: trackName
                        color: listEntry.highlighted ? Theme.highlightColor : Theme.primaryColor
                        text:
                        {
                            if(listModel.get(model.index).type === 1)
                                model.name + " (" + dur +")"
                            else if(listModel.get(model.index).type === 3)
                                model.name
                            else if (listModel.get(model.index).type === 2)
                                model.name + " (" + dur +")"
                            else if (listModel.get(model.index).type === 4)
                                model.name + " (" + dur +")"

                        }
                        x: Theme.horizontalPageMargin
                        truncationMode: elide
                        font.pixelSize: Theme.fontSizeSmall
                    }

                    Label {
                        id: artistName
                        color: listEntry.highlighted ? Theme.highlightColor : Theme.primaryColor
                        text: model.artist + " ( " + model.album + " )"
                        visible: listModel.get(model.index).type === 1
                        x: Theme.horizontalPageMargin
                        truncationMode: elide
                        font.pixelSize: Theme.fontSizeSmall
                    }
                    }

                }
                menu: ContextMenu {

                    MenuItem {
                        text: "Play"
                        onClicked: {
                            console.log(listModel.get(model.index).type)
                            if(listModel.get(model.index).type === 1)
                            {
                               console.log("play track ", listModel.get(model.index).id)
                               playlistManager.playTrack(listModel.get(model.index).id)
                            }
                            else if(listModel.get(model.index).type === 2)
                               playlistManager.playAlbum(listModel.get(model.index).id)
                            else if(listModel.get(model.index).type === 4)
                               pythonApi.playPlaylist(listModel.get(model.index).uid)

                        }

                    }


                    MenuItem {
                        text: "Play Album"
                        visible: listModel.get(model.index).type === 1
                        onClicked: {
                            playlistManager.playAlbumFromTrack(listModel.get(model.index).id)
                        }

                    }

                    MenuItem {
                        text: "Queue"
                        onClicked: {
                            playlistManager.appendTrack(listModel.get(model.index).id)
                        }

                    }

                    MenuItem {
                        text: "Remove"
                        onClicked: {
                            listEntry.remorseAction("Deleting", function() {
                                listModel.remove(model.index)
                            })
                        }
                    }
                }

                onClicked:
                {
                    if(listModel.get(model.index).type === 1)
                    {
                        pageStack.push(Qt.resolvedUrl("AlbumPage.qml"))
                        pythonApi.getTrackInfo(listModel.get(model.index).id)
                    }else if(listModel.get(model.index).type === 2)
                    {
                        pageStack.push(Qt.resolvedUrl("AlbumPage.qml"))
                        pythonApi.getAlbumInfo(listModel.get(model.index).id)
                    }else if(listModel.get(model.index).type === 3)
                    {
                        pageStack.push(Qt.resolvedUrl("ArtistPage.qml"))
                        pythonApi.getArtistInfo(listModel.get(model.index).id)
                    }
                }
            }

            Connections {
                target: pythonApi

                onTrackAdded:
                {
                    listModel.append(
                                {   "name": title,
                                    "artist" : artist,
                                    "album" : album,
                                    "id" : id,
                                    "type" : 1,
                                    "image" : image,
                                    "duration" : duration
                                })
                }

                onArtistAdded:
                {
                    listModel.append(
                                {   "name": name,
                                    "id" : id,
                                    "type" : 3,
                                    "image" : image
                                })
                }


                onAlbumAdded:
                {
                    listModel.append(
                                {   "name": title,
                                    "id" : id,
                                    "type" : 2,
                                    "image" : image,
                                    "duration" : duration
                                })
                }

                onPlaylistSearchAdded:
                {
                    console.log(id)
                    listModel.append(
                                {   "name": name,
                                    "id" : id,
                                    "type" : 4,
                                    "image" : image,
                                    "duration" : duration,
                                    "uid" : uid
                                })
                }

            }
            VerticalScrollDecorator {}
        }



        TrackPage {
            id: trackPage
        }

    }
}
