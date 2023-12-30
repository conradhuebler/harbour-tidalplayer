import QtQuick 2.0
import Sailfish.Silica 1.0
import QtMultimedia 5.6
import Sailfish.Media 1.0

import "widgets"


Page {
    id: searchPage

    // The effective value will be restricted by ApplicationWindow.allowedOrientations
    allowedOrientations: Orientation.All

    // To enable PullDownMenu, place our content in a SilicaFlickable
    SilicaFlickable {
        anchors {
            fill: parent
            bottomMargin: minPlayerPanel.margin
        }

        // PullDownMenu and PushUpMenu must be declared in SilicaFlickable, SilicaListView or SilicaGridView
        PullDownMenu {
            MenuItem {
                text: qsTr("Settings")
                onClicked: pageStack.push(Qt.resolvedUrl("Settings.qml"))
            }

            MenuItem {
                text: qsTr("Show Playlist")
                onClicked:
                {
                    onClicked: pageStack.push(Qt.resolvedUrl("PlaylistPage.qml"))
                }
            }

            MenuItem {
                text: minPlayerPanel.open ? "Hide player" : "Show player"
                onClicked: minPlayerPanel.open = !minPlayerPanel.open
                anchors.horizontalCenter: parent.horizontalCenter
            }

            MenuItem {
                text: qsTr("Show Personal Page")
                onClicked: pageStack.push(Qt.resolvedUrl("Personal.qml"))
            }

        }
        PushUpMenu {
            MenuItem {
                text: "Clear"
                onClicked: listModel.clear()
            }
        }

        SilicaListView {

            anchors.fill: parent
            // Tell SilicaFlickable the height of its content.
//            contentHeight: column.height

            // Place our content in a Column.  The PageHeader is always placed at the top
            // of the page, followed by our content.
            header : Column {
                width: parent.width
                //height: header.height + mainColumn.height + Theme.paddingLarge

                PageHeader {
                    id: header
                    title:  qsTr("Look for anything in Tidal")
                }
                Column {
                    id: column

                    width: searchPage.width
                    spacing: Theme.paddingSmall

                    TextField {
                        id: searchString
                        width: parent.width
                        placeholderText: "Type and Search"
                        text: ""
                        label: "What are you looking for?"
                        EnterKey.enabled: text.length > 0
                        EnterKey.iconSource: "image://theme/icon-m-search"

                        EnterKey.onClicked: {
                            listModel.clear()
                            pythonApi.genericSearch(searchString.text)
                        }
                    }
                    SectionHeader
                    {
                        id: searchHeader
                        anchors.bottom: searchString
                        text:  qsTr("Want to find?")
                    }

                    Row {
                        width: parent.width
                        anchors {
                            leftMargin: Theme.horizontalPageMargin
                            rightMargin: Theme.horizontalPageMargin
                            bottom: searchHeader
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
                            checked: true
                            onCheckedChanged: pythonApi.playlists = checked

                        }
                    }

                    Connections {
                        target: pythonApi
                        onLoginSuccess:
                        {
                            searchString.label = "Find"
                            searchString.enabled = loginTrue
                        }
                        onLoginFailed:
                        {
                            searchString.label = "Please go to the settings and login via OAuth"
                            searchString.enabled = loginTrue
                        }
                    }
                }
            }

            model: ListModel { id: listModel }

            delegate: ListItem {

                id: listEntry
                //width: parent.width

                Row {

                    anchors {
                        left: parent.left
                        leftMargin: Theme.horizontalPageMargin
                        right: parent.right
                        rightMargin: Theme.horizontalPageMargin
                        verticalCenter: parent.verticalCenter
                    }
                    IconButton {
                        id: mediaType
                        icon.source: {
                            if(listModel.get(model.index).type === 1)
                                "image://theme/icon-m-media-songs"
                            else if(listModel.get(model.index).type === 3)
                                "image://theme/icon-m-media-artists"
                            else if (listModel.get(model.index).type === 2)
                                "image://theme/icon-m-media-albums"
                        }

                        height: trackName.height
                    }

                    Column {
                    Label {
                        property string dur: {
                            if ((model.duration) > 3599) Format.formatDuration(model.duration, Formatter.DurationLong)
                            else return Format.formatDuration(model.duration, Formatter.DurationShort)
                        }
                        id: trackName
                        color: listEntry.highlighted ? Theme.highlightColor : Theme.primaryColor
                        text: model.name + " (" + dur +")"
                        x: Theme.horizontalPageMargin
                        truncationMode: elide
                        font.pixelSize: Theme.fontSizeSmall
                    }

                    Label {
                        id: artistName
                        color: listEntry.highlighted ? Theme.highlightColor : Theme.primaryColor
                        text: model.artist + " ( "+model.album +" )"
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
                               playlistManager.playTrack(listModel.get(model.index).id)
                            else if(listModel.get(model.index).type === 2)
                               playlistManager.playAlbum(listModel.get(model.index).id)

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
                        pageStack.push(Qt.resolvedUrl("TrackPage.qml"))
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
                                    "type" : 3
                                })
                }


                onAlbumAdded:
                {
                    listModel.append(
                                {   "name": title,
                                    "id" : id,
                                    "type" : 2
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
