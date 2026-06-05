// Claude Generated
import QtQuick 2.0
import Sailfish.Silica 1.0

HomeSection {
    id: section
    title: qsTr("Top Albums")
    cacheKey: "topalbum"
    filterPlaceholder: qsTr("Filter albums")

    Connections {
        target: tidalApi
        onFavAlbums: section.addItem("album", album_info)
    }
}
