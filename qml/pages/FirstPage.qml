import QtQuick 2.0
import Sailfish.Silica 1.0
import QtMultimedia 5.6
import Sailfish.Media 1.0
import harbour.tidalplayer 1.0

Page {
    id: page

    // The effective value will be restricted by ApplicationWindow.allowedOrientations
    allowedOrientations: Orientation.All

    // To enable PullDownMenu, place our content in a SilicaFlickable
    SilicaFlickable {
        anchors.fill: parent

        // PullDownMenu and PushUpMenu must be declared in SilicaFlickable, SilicaListView or SilicaGridView
        PullDownMenu {
            MenuItem {
                text: qsTr("Settings")
                onClicked: pageStack.push(Qt.resolvedUrl("Settings.qml"))
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

        MediaPlayer {
            id: mediaPlayer
            source: url.trim()
            autoLoad: true

            function videoPlay() {
                videoPlaying = true
                if (mediaPlayer.bufferProgress == 1) {
                    mediaPlayer.play()
                } else if (isLocal) {
                    mediaPlayer.play()
                }
            }

            function videoPause() {
                videoPlaying = false
                mediaPlayer.pause()
            }

            property bool videoPlaying: false
            property string errorMsg: ""

            onPlaybackStateChanged: {
                mprisPlayer.playbackState = mediaPlayer.playbackState === MediaPlayer.PlayingState ?
                            Mpris.Playing : mediaPlayer.playbackState === MediaPlayer.PausedState ?
                                Mpris.Paused : Mpris.Stopped
            }

            onError: {
                if ( error === MediaPlayer.ResourceError ) errorMsg = qsTr("Error: Problem with allocating resources")
                else if ( error === MediaPlayer.ServiceMissing ) errorMsg = qsTr("Error: Media service error")
                else if ( error === MediaPlayer.FormatError ) errorMsg = qsTr("Error: Video or Audio format is not supported")
                else if ( error === MediaPlayer.AccessDenied ) errorMsg = qsTr("Error: Access denied to the video")
                else if ( error === MediaPlayer.NetworkError ) errorMsg = qsTr("Error: Network error")
                stop()
            }
            /*
                      onBufferProgressChanged: {
                          if (!isLocal && videoPlaying && mediaPlayer.bufferProgress == 1) {
                              mediaPlayer.play();
                          }

                          if (!isLocal && mediaPlayer.bufferProgress == 0) {
                              mediaPlayer.pause();
                          }
                      }*/

            onPositionChanged: progressSlider.value = mediaPlayer.position
        }
        SilicaListView {
            anchors.fill: parent
            // Tell SilicaFlickable the height of its content.
            contentHeight: column.height

            // Place our content in a Column.  The PageHeader is always placed at the top
            // of the page, followed by our content.
            header : Column {
                width: parent.width
                height: header.height + mainColumn.height + Theme.paddingLarge

                PageHeader {
                    id: header
                    title:  qsTr("Tidal Player")
                }
                Column {
                    id: column

                    width: page.width
                    spacing: Theme.paddingLarge

                    //Label {
                    //    x: Theme.horizontalPageMargin
                    //    text: qsTr("Hello Sailors")
                    //    color: Theme.secondaryHighlightColor
                    //    font.pixelSize: Theme.fontSizeExtraLarge
                    //}

                    TextField {
                        id: artistField
                        width: parent.width
                        placeholderText: "tracks"
                        text: "Ergo Bibamus"
                        label: "tracks"
                    }

                    Button {
                        id: simpleSearch
                        text: "Find"
                        anchors.horizontalCenter: parent.horizontalCenter
                        enabled: PythonApi.loginState
                        onClicked: {
                            PythonApi.searchTracks(artistField.text, 10)
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
                width: parent.width

                Label {
                    color: listEntry.highlighted ? Theme.highlightColor : Theme.primaryColor
                    text: model.trackName
                    x: Theme.horizontalPageMargin
                    anchors.verticalCenter: parent.verticalCenter
                }

                onClicked: {
                    //console.log(listModel.get(model.index).trackName)
                    PythonApi.getTrackUrl(listModel.get(model.index).trackId)
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
            }

            Connections {
                target: PythonApi

                onSearchFinished:
                {
                    //console.log(PythonApi.trackResults)
                    var JsonResult = JSON.parse(PythonApi.trackResults)

                    for( var i=0, l=JsonResult.length; i<l; i++) {
                        listModel.append({"trackName": JsonResult[i]["name"], "trackId" : JsonResult[i]["id"]})
                    }

                }

                onRecentTrackUrlChanged:
                {
                    mediaPlayer.source = PythonApi.trackUrl
                    console.log(PythonApi.trackUrl)
                    mediaPlayer.play();
                }

            }
            VerticalScrollDecorator {}
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
