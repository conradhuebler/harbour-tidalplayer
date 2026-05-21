// Claude Generated
import QtQuick 2.0
import Sailfish.Silica 1.0
import "../personalLists"

Column {
    id: section
    width: parent.width
    spacing: Theme.paddingMedium
    visible: applicationWindow.settings.recentList

    SectionHeader {
        text: qsTr("Recently played")
        MouseArea {
            anchors.fill: parent
            onClicked: filter.visible = !filter.visible
        }
    }

    SearchField {
        id: filter
        labelVisible: false
        visible: false
        anchors.margins: Theme.paddingMedium
        onTextChanged: recentList.filterText = text
    }

    HorizontalList {
        id: recentList
        width: parent.width
    }

    Connections {
        target: tidalApi
        onRecentAlbum: {
            recentList.addAlbum(album_info)
            applicationWindow.personalPage.cacheItem("recent", "album", album_info)
        }
        onRecentMix: {
            recentList.addMix(mix_info)
            applicationWindow.personalPage.cacheItem("recent", "mix", mix_info)
        }
        onRecentArtist: {
            recentList.addArtist(artist_info)
            applicationWindow.personalPage.cacheItem("recent", "artist", artist_info)
        }
        onRecentPlaylist: {
            recentList.addPlaylist(playlist_info)
            applicationWindow.personalPage.cacheItem("recent", "playlist", playlist_info)
        }
        onRecentTrack: {
            recentList.addTrack(track_info)
            applicationWindow.personalPage.cacheItem("recent", "track", track_info)
        }
    }

    Component.onCompleted: applicationWindow.personalPage.loadSectionItems("recent", recentList)
}
