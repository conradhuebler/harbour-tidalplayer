import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page

    SilicaListView {
        id: listView
        anchors.fill: parent

        header: PageHeader {
            title: qsTr("Saved Playlists")
        }

        PullDownMenu {
            MenuItem {
                text: qsTr("Save current playlist")
                onClicked: {
                    var dialog = pageStack.push(savePlaylistDialog)
                }
            }
        }

        model: ListModel {
            id: playlistModel
        }

        delegate: ListItem {
            id: delegate  // ID hinzugefügt
            width: parent.width
            contentHeight: column.height + Theme.paddingMedium

            Column {
                id: column
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
                spacing: Theme.paddingSmall

                Label {
                    width: parent.width
                    text: model.name
                    color: delegate.highlighted ? Theme.highlightColor : Theme.primaryColor
                    truncationMode: TruncationMode.Fade
                }

                Label {
                    width: parent.width
                    text: qsTr("Track %1 of %2").arg(model.position + 1).arg(model.trackCount)
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.secondaryColor
                }

                Label {
                    width: parent.width
                    text: Qt.formatDateTime(new Date(model.lastPlayed), "dd.MM.yyyy hh:mm")
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.secondaryColor
                }
            }

            menu: ContextMenu {
                MenuItem {
                    text: qsTr("Load")
                    onClicked: {
                        playlistManager.loadSavedPlaylist(model.name)
                    }
                }
                MenuItem {
                    text: qsTr("Delete")
                    onClicked: {
                        Remorse.itemAction(delegate, qsTr("Deleting"), function() {
                            playlistManager.deleteSavedPlaylist(model.name)
                            loadPlaylists()
                        })
                    }
                }
            }
        }


        ViewPlaceholder {
            enabled: listView.count === 0
            text: qsTr("No saved playlists")
            hintText: qsTr("Pull down to save the current playlist")
        }

        VerticalScrollDecorator {}
    }

    Component {
        id: savePlaylistDialog

        Dialog {
            canAccept: nameField.text.length > 0

            Column {
                width: parent.width
                spacing: Theme.paddingMedium

                DialogHeader {
                    title: qsTr("Save Playlist")
                }

                TextField {
                    id: nameField
                    width: parent.width
                    placeholderText: qsTr("Enter playlist name")
                    label: qsTr("Playlist name")
                    EnterKey.enabled: text.length > 0
                    EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                    EnterKey.onClicked: accept()
                }
            }

            onAccepted: {
                playlistManager.saveCurrentPlaylist(nameField.text)
                loadPlaylists()
            }
        }
    }

    function loadPlaylists() {
        playlistModel.clear()
        var playlists = playlistManager.getSavedPlaylists()
        for(var i = 0; i < playlists.length; i++) {
            playlistModel.append(playlists[i])
        }
    }

    Component.onCompleted: {
        loadPlaylists()
    }
}
