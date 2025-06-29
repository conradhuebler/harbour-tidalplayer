import QtQuick 2.0
import Sailfish.Silica 1.0
import QtMultimedia 5.6
import Sailfish.Media 1.0
import Nemo.Configuration 1.0

import "widgets"
import "stuff"

Page {
    id: firstPage

    // The effective value will be restricted by ApplicationWindow.allowedOrientations
    allowedOrientations: Orientation.All
    property int currentIndex : 0
    // To enable PullDownMenu, place our content in a SilicaFlickable

    function showPlaylist() {
        swipeView.currentIndex = 2
    }

    SilicaFlickable {
        id: flickable
        anchors {
            fill: parent
            bottomMargin: minPlayerPanel.margin
        }


        // PullDownMenu and PushUpMenu must be declared in SilicaFlickable, SilicaListView or SilicaGridView
        PullDownMenu {

            MenuItem {
                text: qsTr("Saved Playlists")
                onClicked: pageStack.push(Qt.resolvedUrl("SavedPlaylistsPage.qml"))
            }

            MenuItem {
                text: qsTr("Settings")
                onClicked: {
                    minPlayerPanel.open = false
                    pageStack.push(Qt.resolvedUrl("Settings.qml"))
                }
            }

            MenuItem {
                text: qsTr("Clear Playlist")
                onClicked: {
                    playlistManager.clearPlayList()
                }
            }

            MenuItem {
                text: qsTr("Sleep Timer")
                onClicked: {
                    var dialog = pageStack.push(Qt.resolvedUrl("../dialogs/SleepTimerDialog.qml"))
                    dialog.accepted.connect(function() {
                        applicationWindow.startSleepTimer(dialog.selectedMinutes)
                    })
                }
            }

            MenuItem {
                visible: applicationWindow.remainingMinutes > 0
                text: qsTr("Cancel Sleep Timer " + applicationWindow.remainingMinutes)
                onClicked: applicationWindow.cancelSleepTimer()
            }
              MenuItem {
                text: minPlayerPanel.open ? qsTr("Hide player") : qsTr("Show player")
                onClicked: minPlayerPanel.open = !minPlayerPanel.open
                anchors.horizontalCenter: parent.horizontalCenter
            }

        }
    //    PushUpMenu {



    //    }

        TabHeader {
            id: mainPageHeader
            listView: swipeView
            indicatorOnTop: false

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
            }
            iconArray: ["image://theme/icon-m-home", "image://theme/icon-m-search", "image://theme/icon-m-media-playlists"]
            textArray: [qsTr("Personal Page"), qsTr("Search"), qsTr("Playlist")]
        }

        SlideshowView {
                  clip: true
                  id: swipeView
                  height: parent.height - getBottomOffset() // << this limits the overall size
                  itemWidth: width
                  itemHeight: height
                  orientation: Qt.Horizontal

                  function getBottomOffset()
                  {
                      if (minPlayerPanel.open) return ( 1.2 * minPlayerPanel.height )
                      return minPlayerPanel.height * 0.4
                  }

                  anchors.top: mainPageHeader.bottom
                  anchors.topMargin: Theme.paddingLarge
                  anchors.left: parent.left
                  anchors.right: parent.right
                  anchors.bottom: miniPlayerPanel.top
                  property var carouselPages: ["Personal.qml", "Search.qml", "TrackList.qml"]
                  property int initialPage: 0
                  model: carouselPages.length
                  Component.onCompleted: currentIndex = initialPage

                  delegate: Loader {
                      width: swipeView.itemWidth
                      height: swipeView.height
                      source: swipeView.carouselPages[index]
                      asynchronous: true

                    onLoaded: {
                    if (index === 2) { // TrackList
                        item.title = ""
                        item.type = "current"
                        if (playlistManager.size > 0) {
                            playlistManager.generateList()
                        }
                    }
                }
            }
        }
    }
}
