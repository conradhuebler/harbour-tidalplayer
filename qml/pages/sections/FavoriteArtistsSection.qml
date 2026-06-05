// Claude Generated
import QtQuick 2.0
import Sailfish.Silica 1.0

HomeSection {
    id: section
    title: qsTr("Favorite Artists")
    cacheKey: "favArtists"
    filterPlaceholder: qsTr("Filter artists")

    Connections {
        target: tidalApi
        onTopArtist: section.addItem("artist", artist_info)
    }
}
