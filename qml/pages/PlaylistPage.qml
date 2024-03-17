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
            pLtrackList.highlight_index = position
        }
        onPlayListChanged:
        {
            //pLtrackList.clear();
            console.log("Playlist changed with playlist.qml")
            console.log(playlistManager.tracks)
            for(var i = 1; i < playlistManager.tracks; ++i)
            {
                console.log(i)
                playlistManager.requestPlaylistItem(i)
            }
        }

        onClearList:
        {
            //trackList.clear();
        }

    }
    Connections {
        target: pythonApi
        onTrackChanged:
        {
            pLtrackList.addTrack(title, artist, album, id, duration)
        }
    }

}
