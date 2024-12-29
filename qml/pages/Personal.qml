import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: personalPage
    anchors.fill: parent
    anchors.bottomMargin: miniPlayerPanel.height

    SilicaListView {
        id: listView
        anchors.fill: parent
        spacing: Theme.paddingMedium
        clip: true

        header: PageHeader {
            title: "Personal Playlists"
        }

        model: ListModel {
            id: listModel
        }

        delegate: ListItem {
            id: listEntry
            contentHeight: contentRow.height + 2 * Theme.paddingMedium
            width: parent.width

            Row {
                id: contentRow
                anchors {
                    left: parent.left
                    right: parent.right
                    margins: Theme.horizontalPageMargin
                    verticalCenter: parent.verticalCenter
                }
                spacing: Theme.paddingMedium

                Image {
                    id: coverImage
                    width: Theme.itemSizeExtraLarge
                    height: Theme.itemSizeExtraLarge
                    fillMode: Image.PreserveAspectCrop
                    source: model.image
                    smooth: true
                    asynchronous: true

                    Rectangle {
                        color: Theme.rgba(Theme.highlightBackgroundColor, 0.1)
                        anchors.fill: parent
                        visible: coverImage.status !== Image.Ready
                    }
                }

                Column {
                    width: parent.width - coverImage.width - parent.spacing
                    spacing: Theme.paddingSmall

                    Label {
                        id: titleLabel
                        width: parent.width
                        text: model.title
                        color: listEntry.highlighted ? Theme.highlightColor : Theme.primaryColor
                        font.pixelSize: Theme.fontSizeMedium
                        font.bold: true
                        truncationMode: TruncationMode.Fade
                    }

                    Label {
                        id: trackCountLabel
                        width: parent.width
                        property string duration: {
                            return (model.duration > 3599)
                                ? Format.formatDuration(model.duration, Formatter.DurationLong)
                                : Format.formatDuration(model.duration, Formatter.DurationShort)
                        }
                        text: model.num_tracks + " Tracks • " + duration
                        color: listEntry.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                        font.pixelSize: Theme.fontSizeSmall
                    }

                    Label {
                        id: descriptionLabel
                        width: parent.width
                        text: model.description || ""  // Fallback wenn keine Beschreibung
                        color: listEntry.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                        font.pixelSize: Theme.fontSizeExtraSmall
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        visible: text !== ""  // Nur anzeigen wenn Text vorhanden
                    }
                }
            }

            menu: ContextMenu {
                MenuItem {
                    text: qsTr("Play Playlist")
                    onClicked: {
                        tidalApi.playPlaylist(model.id)
                        playlistManager.nextTrack()
                    }
                }
            }

            onClicked: {
                    pageStack.push(Qt.resolvedUrl("SavedPlaylistPage.qml"), {
                    playlistTitle: model.title,
                    playlistId: model.id,
                    type: "playlist"  // Um zu kennzeichnen, dass es eine Playlist ist
                })
                console.log(model.id)
            }
        }

        ViewPlaceholder {
            enabled: listModel.count === 0
            text: qsTr("No Playlists")
            hintText: qsTr("Your personal playlists will appear here")
        }

        VerticalScrollDecorator {}
    }

    Connections {
        target: tidalApi
        onPersonalPlaylistAdded: {
            listModel.append({
                "title": title,
                "id": id,
                "image": image,
                "num_tracks": num_tracks,
                "description": description,
                "duration": duration
            })
        }

        onLoginSuccess: {
            console.log("Loading personal playlists")
            tidalApi.getPersonalPlaylists()
        }
    }
}
