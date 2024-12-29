import QtQuick 2.0
import io.thp.pyotherside 1.5

Item {
    id: root

    property var currentPlaylist: []
    property int currentIndex: -1
    property bool canNext: currentPlaylist.length > 0 && currentIndex < currentPlaylist.length - 1
    property bool canPrev: currentIndex > 0
    property int size: currentPlaylist.length
    property int current_track: -1
    property int tidalId : 0

    signal currentTrackChanged(var track)
    signal playlistChanged()
    signal trackInformation(int id, int index, string title, string album, string artist, string image, int duration)
    signal currentId(int id)
    signal currentPosition(int position)
    signal containsTrack(int id)
    signal clearList()
    signal currentTrack(int position)
    signal playListFinished()
    signal playListChanged()

    Python {
        id: playlistPython

        property bool canNext: true
        property bool canPrev: true
        property int current_track: 0

        property string playlist_track
        property string playlist_artist
        property string playlist_album
        property string playlist_image
        property int playlist_duration
        property int playlist_track_id


        Component.onCompleted: {
            addImportPath(Qt.resolvedUrl('.'))

            setHandler('printConsole', function(string) {
                console.log("playlistManager::printConsole" + string)
            })

            setHandler('currentTrack', function(id, position) {
                console.log("Current track in playlist is", id, position)
                playlistManager.currentTrackChanged(id)
                playlistManager.currentId(id)
                currentTrack(position)
            })

            setHandler('clearList', function() {
                playlistManager.clearList()
            })

            setHandler('containsTrack', function(id) {
                console.log(id)
                playlistManager.containsTrack(id)
            })

            setHandler('playlistFinished', function() {
                console.log("Playlist Finished")
                canNext = false
            })

            setHandler('playlistUnFinished', function() {
                console.log("Playlist unfinished")
                canNext = true
            })
            /* new handler will be placed here */


            importModule('playlistmanager', function() {})
        }

        // Python-Funktionen
        function appendTrack(id) {
            call('playlistmanager.PL.AppendTrack', [id], {})
        }

        function currentTrackIndex() {
            call("playlistmanager.PL.PlaylistIndex", [], function(index){
                current_track = index
            })
        }

        function getSize() {
        /*
            call("playlistmanager.PL.size", [], function(name){
                playlistManager.size = name
                console.log(name)
            })
            console.log(playlistManager.size)*/
            playlistManager.size = playlistPython.call_sync("playlistmanager.PL.size", [])
            console.log("Playlist size:", playlistManager.size)
            return playlistManager.size
        }

        function requestPlaylistItem(index) {
            console.log("request item", index)
            call("playlistmanager.PL.TidalId", [index], function(id){
            console.log("got id for track", id);
                var track = cacheManager.getTrackInfo(id)
                console.log("after function", id, index, track);
                playlistManager.trackInformation(id, index, track[1], track[2], track[3], track[4], track[5])
            })
        }


        function playPosition(id) {
            canNext = false
            call('playlistmanager.PL.PlayPosition', [id], {})
        }

        function insertTrack(id) {
            call('playlistmanager.PL.InsertTrack', [id], {})
        }

        function nextTrack() {
            call('playlistmanager.PL.NextTrack', {})
        }

        function previousTrack() {
            call('playlistmanager.PL.PreviousTrack', {})
        }

        function restartTrack() {
            call('playlistmanager.PL.RestartTrack', {})
        }

        function clearPlayList() {
            call('playlistmanager.PL.clearList', {})
        }

/* new functions are here */

        function playTrack(id) {
            call('playlistmanager.PL.PlayTrack', [id], {})
        }

        function generateList() {
            getSize()
            playlistManager.playListChanged()
/*
            call("playlistmanager.PL.size", [], function(tracks){
                playlistManager.size = tracks
                console.log("Current playlist size", size)
                playlistManager.playListChanged()
            })
            */
        }
    }

    // Öffentliche Funktionen
    function clearPlayList() {
        playlistPython.clearPlayList()
    }

    function appendTrack(id) {
        console.log("PlaylistManager.appendTrack", id)
        playlistPython.appendTrack(id)
        canNext = true
    }

    function currentTrackIndex() {
        playlistPython.currentTrackIndex()
    }

    function getSize() {
        playlistPython.getSize()
    }

    function requestPlaylistItem(index) {
        console.log("Request PlaylistTrack", index)
        var id = playlistPython.call_sync("playlistmanager.PL.TidalId", [index])
        playlistManager.tidalId = id
        console.log("Current playlist tidalid and size", playlistManager.tidalId, playlistManager.size)
    }

    function playAlbum(id) {
        console.log("playalbum", id)
        clearPlayList()
        currentTrackIndex()
        pythonApi.playAlbumTracks(id)
    }

    function playAlbumFromTrack(id) {
        clearPlayList()
        pythonApi.playAlbumFromTrack(id)
        currentTrackIndex()
    }

    function playTrack(id) {
        console.log("Playlistmanager::playtrack", id)
        mediaController.blockAutoNext = true
        playlistPython.playTrack(id)
        currentTrackIndex()
    }

    function playPosition(id) {
        console.log(id)
        playlistPython.canNext = false
        mediaController.blockAutoNext = true
        playlistPython.playPosition(id)
        currentTrackIndex()
    }

    function insertTrack(id) {
        console.log("PlaylistManager.insertTrack", id)
        playlistPython.insertTrack(id)
        currentTrackIndex()
    }

    function nextTrack() {
        console.log("Next track called")
        if(mediaPlayer.playbackState !== 1) {
            playlistPython.canNext = false
            playlistPython.nextTrack()
        }
        currentTrackIndex()
    }

    function nextTrackClicked() {
        console.log("Next track called")
        mediaPlayer.blockAutoNext = true
        playlistPython.canNext = false
        playlistPython.nextTrack()
        currentTrackIndex()
    }

    function restartTrack(id) {
        console.log(id)
        playlistPython.restartTrack()
        currentTrackIndex()
    }

    function previousTrack() {
        playlistPython.canNext = false
        playlistPython.previousTrack()
        currentTrackIndex()
    }

    function previousTrackClicked() {
        playlistPython.canNext = false
        mediaPlayer.blockAutoNext = true
        playlistPython.previousTrack()
        currentTrackIndex()
    }

    function generateList() {
        console.log("Playlist changed from main.qml")
        playlistPython.generateList()
    }
}
