// Claude Generated
import QtQuick 2.0
import Sailfish.Silica 1.0
import "../personalLists"

Column {
    id: section
    width: parent.width
    spacing: Theme.paddingMedium
    visible: applicationWindow.settings.personalPlaylistList

    SectionHeader {
        text: qsTr("Personal Playlists")
        MouseArea {
            anchors.fill: parent
            onClicked: filter.visible = !filter.visible
        }
    }

    SearchField {
        id: filter
        placeholderText: qsTr("Filter playlists")
        visible: false
        anchors.margins: Theme.paddingMedium
        onTextChanged: playlistList.filterText = text
    }

    HorizontalList {
        id: playlistList
        width: parent.width
    }

    Connections {
        target: tidalApi
        onPersonalPlaylistAdded: {
            playlistList.addPlaylist(playlist_info)
            applicationWindow.personalPage.cacheItem("playlist", "playlist", playlist_info)
        }
    }

    Component.onCompleted: applicationWindow.personalPage.loadSectionItems("playlist", playlistList)
}
