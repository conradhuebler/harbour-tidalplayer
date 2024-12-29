import QtQuick 2.0
import Sailfish.Silica 1.0
import QtMultimedia 5.6
import Sailfish.Media 1.0

import "widgets"
import "stuff"

Page {
    id: searchPage

    // The effective value will be restricted by ApplicationWindow.allowedOrientations
    allowedOrientations: Orientation.All

    // To enable PullDownMenu, place our content in a SilicaFlickable
    SilicaFlickable {
        clip: true
        anchors {
            fill: parent
        }
        contentHeight: parent.height - miniPlayerPanel.height

        // PullDownMenu and PushUpMenu must be declared in SilicaFlickable, SilicaListView or SilicaGridView
        PullDownMenu {
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
                text: minPlayerPanel.open ? "Hide player" : "Show player"
                onClicked: minPlayerPanel.open = !minPlayerPanel.open
                anchors.horizontalCenter: parent.horizontalCenter
            }

        }

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
                  height: parent.height - miniPlayerPanel.height
                  itemWidth: width
                  itemHeight: height
                  orientation: Qt.Horizontal

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
