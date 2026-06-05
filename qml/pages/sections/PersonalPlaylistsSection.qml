// Claude Generated
import QtQuick 2.0
import Sailfish.Silica 1.0

HomeSection {
    id: section
    title: qsTr("Personal Playlists")
    cacheKey: "personalPlaylist"
    filterPlaceholder: qsTr("Filter playlists")

    Connections {
        target: tidalApi
        onPersonalPlaylistAdded: section.addItem("playlist", playlist_info)
    }
}
