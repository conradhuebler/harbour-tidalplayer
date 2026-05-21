// Claude Generated
import QtQuick 2.0
import Sailfish.Silica 1.0
import "../personalLists"

Column {
    id: section
    width: parent ? parent.width : 0
    spacing: Theme.paddingMedium
    visible: applicationWindow.settings.topalbumsList

    SectionHeader {
        text: qsTr("Top Albums")
        MouseArea {
            anchors.fill: parent
            onClicked: {
                filter.visible = !filter.visible
                if (filter.visible) filter.forceActiveFocus()
            }
        }
    }

    SearchField {
        id: filter
        placeholderText: qsTr("Filter albums")
        visible: false
        anchors.margins: Theme.paddingMedium
        onTextChanged: albumsList.filterText = text
    }

    HorizontalList {
        id: albumsList
        width: parent.width
    }

    Connections {
        target: tidalApi
        onFavAlbums: {
            albumsList.addAlbum(album_info)
            applicationWindow.personalPage.cacheItem("album", "album", album_info)
        }
    }

    Component.onCompleted: applicationWindow.personalPage.loadSectionItems("album", albumsList)
}
