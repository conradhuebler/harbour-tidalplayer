// Claude Generated
import QtQuick 2.0
import Sailfish.Silica 1.0

HomeSection {
    id: section
    title: qsTr("Popular playlists")
    cacheKey: "foryou"
    filterPlaceholder: qsTr("Filter")

    Connections {
        target: tidalApi
        onForyouAlbum:    section.addItem("album", album_info)
        onForyouArtist:   section.addItem("artist", artist_info)
        onForyouPlaylist: section.addItem("playlist", playlist_info)
        onForyouMix:      section.addItem("mix", mix_info)
    }
}
