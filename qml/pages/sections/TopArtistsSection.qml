// Claude Generated
import QtQuick 2.0
import Sailfish.Silica 1.0

HomeSection {
    id: section
    title: qsTr("Top Artists")
    cacheKey: "topartist"
    filterPlaceholder: qsTr("Filter artists")
    filterDebounceMs: 600

    Connections {
        target: tidalApi
        onFavArtists: section.addItem("artist", artist_info)
    }
}
