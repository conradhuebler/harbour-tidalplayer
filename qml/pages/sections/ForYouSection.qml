// Claude Generated
import QtQuick 2.0
import Sailfish.Silica 1.0
import "../personalLists"

Column {
    id: section
    width: parent.width
    spacing: Theme.paddingMedium
    visible: applicationWindow.settings.yourList

    SectionHeader {
        text: qsTr("Popular playlists")
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
        onTextChanged: foryouList.filterText = text
    }

    HorizontalList {
        id: foryouList
        width: parent.width
    }

    Connections {
        target: tidalApi
        onForyouAlbum: {
            foryouList.addAlbum(album_info)
            applicationWindow.personalPage.cacheItem("foryou", "album", album_info)
        }
        onForyouArtist: {
            foryouList.addArtist(artist_info)
            applicationWindow.personalPage.cacheItem("foryou", "artist", artist_info)
        }
        onForyouPlaylist: {
            foryouList.addPlaylist(playlist_info)
            applicationWindow.personalPage.cacheItem("foryou", "playlist", playlist_info)
        }
        onForyouMix: {
            foryouList.addMix(mix_info)
            applicationWindow.personalPage.cacheItem("foryou", "mix", mix_info)
        }
    }

    Component.onCompleted: applicationWindow.personalPage.loadSectionItems("foryou", foryouList)
}
