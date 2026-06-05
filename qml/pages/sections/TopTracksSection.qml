// Claude Generated
import QtQuick 2.0
import Sailfish.Silica 1.0

HomeSection {
    id: section
    title: qsTr("Top Tracks")
    cacheKey: "toptrack"
    filterPlaceholder: qsTr("Filter tracks")

    Connections {
        target: tidalApi
        onFavTracks: section.addItem("track", track_info)
    }
}
