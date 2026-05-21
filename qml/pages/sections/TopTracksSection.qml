// Claude Generated
import QtQuick 2.0
import Sailfish.Silica 1.0
import "../personalLists"

Column {
    id: section
    width: parent.width
    spacing: Theme.paddingMedium
    visible: applicationWindow.settings.toptrackList

    SectionHeader {
        text: qsTr("Top Tracks")
        MouseArea {
            anchors.fill: parent
            onClicked: filter.visible = !filter.visible
        }
    }

    SearchField {
        id: filter
        placeholderText: qsTr("Filter tracks")
        visible: false
        anchors.margins: Theme.paddingMedium
        onTextChanged: tracksList.filterText = text
    }

    HorizontalList {
        id: tracksList
        width: parent.width
    }

    Connections {
        target: tidalApi
        onFavTracks: {
            tracksList.addTrack(track_info)
            applicationWindow.personalPage.cacheItem("track", "track", track_info)
        }
    }

    Component.onCompleted: applicationWindow.personalPage.loadSectionItems("track", tracksList)
}
