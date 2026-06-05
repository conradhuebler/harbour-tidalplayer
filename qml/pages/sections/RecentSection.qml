// Claude Generated
import QtQuick 2.0
import Sailfish.Silica 1.0

HomeSection {
    id: section
    title: qsTr("Recently played")
    cacheKey: "recent"
    filterPlaceholder: qsTr("Filter")

    Connections {
        target: tidalApi
        onRecentAlbum:    section.addItem("album", album_info)
        onRecentMix:      section.addItem("mix", mix_info)
        onRecentArtist:   section.addItem("artist", artist_info)
        onRecentPlaylist: section.addItem("playlist", playlist_info)
        onRecentTrack:    section.addItem("track", track_info)
    }
}
