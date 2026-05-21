// Claude Generated
import QtQuick 2.0
import Sailfish.Silica 1.0
import "../personalLists"

Column {
    id: section
    width: parent ? parent.width : 0
    spacing: Theme.paddingMedium
    visible: applicationWindow.settings.topArtistsList

    SectionHeader {
        text: qsTr("Favorite Artists")
    }

    HorizontalList {
        id: topArtistList
        width: parent.width
    }

    Connections {
        target: tidalApi
        onTopArtist: topArtistList.addArtist(artist_info)
    }
}
