import QtQuick 2.0
import Sailfish.Silica 1.0
import QtMultimedia 5.6
import Sailfish.Media 1.0

import "widgets"


Item {
    id: playlistPage

    // To enable PullDownMenu, place our content in a SilicaFlickable
    SilicaFlickable {
        width: parent.width
        anchors.fill: parent
        clip: miniPlayerPanel.expanded
        contentHeight: parent.height - Theme.itemSizeExtraLarge - Theme.paddingLarge

            TrackList {
                id: pLtrackList
                title :  "Current Playlist"
                allow_add: false
                start_on_tap : true
                allow_play: false
                anchors {
                    top : parent.bottom
                    fill: parent
                    horizontalCenter: parent.horizontalCenter
                }
            }

   }

    Connections
    {
        target: playlistManager
        onCurrentTrack:
        {
            pLtrackList.highlight_index = playlistManager.current_track
        }
        onPlayListChanged:
        {
            pLtrackList.clear();
            console.log("Playlist changed with playlist.qml", playlistManager.size)
            for(var i = 0; i < playlistManager.size; ++i)
            {
                console.log(i)
                playlistManager.requestPlaylistItem(i)
                pLtrackList.addTrack(playlistManager.playlist_track, playlistManager.playlist_artist, playlistManager.playlist_album, playlistManager.playlist_track_id, playlistManager.playlist_duration)
            }
        }

        onClearList:
        {
            pLtrackList.clear();
        }

        onTrackInformation:
        {
            pLtrackList.setTrack(index, id, title, artist, album, image, duration)
            console.log(image)
        }

    }
    Connections {
        target: pythonApi
        onTrackChanged:
        {
            console.log("PlaylistPage::onTrackChanged in pythonApi", title)
            pLtrackList.addTrack(title, artist, album, id, duration)
        }


    }

}
