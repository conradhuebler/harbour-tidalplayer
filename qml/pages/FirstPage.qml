import QtQuick 2.0
import Sailfish.Silica 1.0
import QtMultimedia 5.6
import Sailfish.Media 1.0
import harbour.tidalplayer 1.0


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
            /*
            MenuItem {
                text: qsTr("Show Page 2")
                onClicked: pageStack.push(Qt.resolvedUrl("SecondPage.qml"))
            }
            */
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
                    title:  qsTr("Tidal Player")
                }
                Column {
                    id: column

                    width: searchPage.width
                    spacing: Theme.paddingLarge

                    //Label {
                    //    x: Theme.horizontalPageMargin
                    //    text: qsTr("Hello Sailors")
                    //    color: Theme.secondaryHighlightColor
                    //    font.pixelSize: Theme.fontSizeExtraLarge
                    //}

                    TextField {
                        id: searchString
                        width: parent.width
                        placeholderText: "Type and Search"
                        text: "Corvus Corax"
                        label: "What are you looking for?"
                    }

                    Button {
                        id: simpleSearch
                        text: "Find"
                        anchors.horizontalCenter: parent.horizontalCenter
                        enabled: PythonApi.loginState
                        onClicked: {
                            listModel.clear()
                            PythonApi.searchTracks(searchString.text, 10)
                            PythonApi.searchArtists(searchString.text, 10)
                            PythonApi.searchAlbums(searchString.text, 10)
                        }
                    }
                    Connections {
                        target: PythonApi

                        onLoginStateChanged:
                        {
                            simpleSearch.enabled = PythonApi.LoginState
                        }
                    }
                }
            }

            model: ListModel { id: listModel }

            delegate: ListItem {
                id: listEntry
                //width: parent.width

                Row {
                    IconButton {
                        id: playTrack
                        icon.source: "image://theme/icon-m-play"
                        onClicked: {
                            PlaylistManager.playTrackId(listModel.get(model.index).id)
                        }
                        height: trackName.height
                        visible: listModel.get(model.index).type == 1
                    }

                    IconButton {
                        id: queueTrack
                        icon.source: "image://theme/icon-m-add"
                        onClicked: {
                            PlaylistManager.addTrackId(listModel.get(model.index).id)
                        }
                        height: trackName.height
                        visible: listModel.get(model.index).type == 1

                    }

                    Label {
                        id: trackName
                        color: listEntry.highlighted ? Theme.highlightColor : Theme.primaryColor
                        text: model.name
                        x: Theme.horizontalPageMargin
                        truncationMode: elide
                        font.pixelSize: Theme.fontSizeSmall
                    }

                }

                menu: ContextMenu {

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
                    if(listModel.get(model.index).type == 1)
                    {
                        pageStack.push(Qt.resolvedUrl("TrackPage.qml"))
                        PythonApi.getTrackInfo(listModel.get(model.index).id)
                    }else if(listModel.get(model.index).type == 2)
                    {
                        pageStack.push(Qt.resolvedUrl("AlbumPage.qml"))
                        PythonApi.getAlbumInfo(listModel.get(model.index).id)
                    }else if(listModel.get(model.index).type == 3)
                    {
                        pageStack.push(Qt.resolvedUrl("ArtistPage.qml"))
                        PythonApi.getArtistInfo(listModel.get(model.index).id)
                    }
                }
            }

            Connections {
                target: PythonApi

                onTrackSearchFinished:
                {
                    //console.log(PythonApi.trackResults)
                    var JsonResult = JSON.parse(PythonApi.trackResults)

                    for( var i=0, l=JsonResult.length; i<l; i++) {
                        listModel.append(
                                    {   "name": JsonResult[i]["name"],
                                        "id" : JsonResult[i]["id"],
                                        "type" : JsonResult[i]["type"]
                                    })
                    }

                }

                onArtistSearchFinished:
                {
                    console.log(PythonApi.artistsResults)
                    var JsonResult = JSON.parse(PythonApi.artistsResults)

                    for( var i=0, l=JsonResult.length; i<l; i++) {
                        listModel.append(
                                    {   "name": JsonResult[i]["name"],
                                        "id" : JsonResult[i]["id"],
                                        "type" : JsonResult[i]["type"]
                                    })
                    }

                }

                onAlbumSearchFinished:
                {
                    console.log(PythonApi.albumsResults)
                    var JsonResult = JSON.parse(PythonApi.albumsResults)

                    for( var i=0, l=JsonResult.length; i<l; i++) {
                        listModel.append(
                                    {   "name": JsonResult[i]["name"],
                                        "id" : JsonResult[i]["id"],
                                        "type" : JsonResult[i]["type"]
                                    })
                    }

                }
/*
                onRecentTrackUrlChanged:
                {
                    minPlayerPanel.url = PythonApi.trackUrl
                    console.log(PythonApi.trackUrl)
                    minPlayerPanel.play();
                }
                */

            }
            VerticalScrollDecorator {}
        }


        MiniPlayer {
            id: minPlayerPanel
        }

        TrackPage {
            id: trackPage
        }

    }

    /*
    Component.onCompleted: {
           Settings.CheckLogin
       }

    Connections {
        target: Settings
        onLoginReadFinished:
        {
            PythonApi.setLogin(Settings.LoginPasswort, Settings.LoginPasswort)
        }
    }
    */
}
