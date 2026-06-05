// Claude Generated
import QtQuick 2.0
import Sailfish.Silica 1.0
import "../personalLists"

Column {
    id: section
    width: parent ? parent.width : 0
    spacing: Theme.paddingMedium

    SectionHeader {
        text: qsTr("Top Artists")
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
        placeholderText: qsTr("Filter artists")
        visible: false
        anchors.margins: Theme.paddingMedium
        property int debounceInterval: 600

        Timer {
            id: debounceTimer
            interval: filter.debounceInterval
            repeat: false
            onTriggered: artistList.filterText = filter.text
        }

        onTextChanged: debounceTimer.restart()
    }

    HorizontalList {
        id: artistList
        width: parent.width
    }

    Connections {
        target: tidalApi
        onFavArtists: {
            artistList.addArtist(artist_info)
            applicationWindow.personalPage.cacheItem("artist", "artist", artist_info)
        }
    }

    Component.onCompleted: applicationWindow.personalPage.loadSectionItems("artist", artistList)
}
