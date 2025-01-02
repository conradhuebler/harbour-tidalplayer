import QtQuick 2.0
import io.thp.pyotherside 1.5


Item {
    id: root

    //property var currentPlaylist: []
    property int currentIndex: -1
    property bool canNext: size > 0 && currentIndex < size - 1
    property bool canPrev: currentIndex > 0
    property int size: 0 //currentPlaylist.length
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

    signal playlistFinished()
    signal listChanged()

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
        property bool initialised : false

        Component.onCompleted: {
            addImportPath(Qt.resolvedUrl('.'))

            setHandler('printConsole', function(string) {
                console.log("playlistManager::printConsole" + string)
            })

            setHandler('currentTrack', function(id, position) {
                console.log("Current track in playlist is", id, position)
                root.currentIndex = position

                root.currentTrackChanged(id)
                root.currentId(id)
                currentTrack(position)
            })

            setHandler('clearList', function() {
                root.clearList()
            })

            setHandler('containsTrack', function(id) {
                console.log(id)
                root.containsTrack(id)
            })


            /* new handler will be placed here */

            setHandler('listChanged', function() {
                root.size = getSize()
                console.log("list changed, new size: ", root.size)
                root.listChanged()
            })

            setHandler('playlistSize', function(size) {
                root.size = size
                console.log("list changed, new size: ", root.size)
                root.listChanged()
            })

            setHandler('currentIndex', function(index) {
                root.currentIndex = index
                console.log("list changed, new size: ", root.size)
                root.listChanged()
            })

            setHandler('playlistFinished', function() {
                console.log("Playlist Finished")
                canNext = false
                root.playlistFinished()
            })

            setHandler('playlistUnFinished', function() {
                console.log("Playlist unfinished")
                canNext = true
            })
            importModule('playlistmanager', function() {
                console.log("Playlistmanager module imported successfully")
                initialised = true
            })
        }

        // Python-Funktionen
        function appendTrack(id) {
            if(initialised)  call('playlistmanager.PL.AppendTrack', [id], {})
        }

        function currentTrackIndex() {
           if(initialised)  call("playlistmanager.PL.PlaylistIndex", [], function(index){
                current_track = index
            })

        }

        function getSize() {
        if(initialised) {
            root.size = playlistPython.call_sync("playlistmanager.PL.size", [])
            console.log("Playlist size:", playlistManager.size)
            return playlistManager.size
            }else
                return 0
        }

        function requestPlaylistItem(index) {
            console.log("request item", index)
            if(initialised) {
            call("playlistmanager.PL.TidalId", [index], function(id){
            console.log("got id for track", id);
                var track = cacheManager.getTrackInfo(id)
                console.log("after function", id, index, track);
                root.trackInformation(id, index, track[1], track[2], track[3], track[4], track[5])
            })
            }
        }


        function playPosition(id) {
            canNext = false
            if(initialised) call('playlistmanager.PL.PlayPosition', [id], {})
        }

        function insertTrack(id) {
            if(initialised) call('playlistmanager.PL.InsertTrack', [id], {})
        }

        function nextTrack() {
            if(initialised) call_sync('playlistmanager.PL.NextTrack', {})
        }

        function previousTrack() {
            if(initialised) call('playlistmanager.PL.PreviousTrack', {})
        }

        function restartTrack() {
            if(initialised) call('playlistmanager.PL.RestartTrack', {})
        }

        function clearPlayList() {
        if(initialised) {
            console.log("Clear list invoked")
            call('playlistmanager.PL.clearList', {})
            if(playlistStorage.playlistTitle !== "_current")
                playlistStorage.loadCurrentPlaylistState()
            }
        }

/* new functions are here */

        function playTrack(id) {
            console.log("Add track to playlist and play and rebuild playlist", id)
            call('playlistmanager.PL.PlayTrack', [id], {})
        }

        function generateList() {
            getSize()
            root.listChanged()
        }
    }

    // Öffentliche Funktionen
    function clearPlayList() {
        playlistPython.clearPlayList()
    }

    // Öffentliche Funktionen
    function play() {
        playlistPython.playPosition(0)
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
        var id = playlistPython.call_sync("playlistmanager.PL.TidalId", [index])
        root.tidalId = id
        return id
    }

    function playAlbum(id) {
        console.log("playalbum", id)
        clearPlayList()
        currentTrackIndex()
        tidalApi.playAlbumTracks(id)
    }

    function playAlbumFromTrack(id) {
        clearPlayList()
        tidalApi.playAlbumFromTrack(id)
        currentTrackIndex()
    }

    function playTrack(id) {
        console.log("Playlistmanager::playtrack", id)
        mediaController.blockAutoNext = true
        playlistPython.playTrack(id)
        currentTrackIndex()
    }

    function insertTrack(id) {
        console.log("PlaylistManager.insertTrack", id)
        playlistPython.insertTrack(id)
        currentTrackIndex()
    }

    function nextTrackClicked() {
        console.log("Next track clicked")
        mediaController.blockAutoNext = true
        playlistPython.nextTrack()
        currentTrackIndex()
        mediaController.blockAutoNext = false
        if (playlistStorage.currentPlaylistName) {
            playlistStorage.updatePosition(playlistStorage.currentPlaylistName, currentIndex);
        }
    }

    function restartTrack(id) {
        playlistPython.restartTrack()
        currentTrackIndex()
    }

    function previousTrackClicked() {
        playlistPython.canNext = false
        mediaController.blockAutoNext = true
        playlistPython.previousTrack()
        currentTrackIndex()
         if (playlistStorage.currentPlaylistName) {
            playlistStorage.updatePosition(playlistStorage.currentPlaylistName, currentIndex);
        }
    }

    function generateList() {
        console.log("Playlist changed from main.qml")
        playlistPython.generateList()
    }

    // Neue Funktionen zum Speichern/Laden
    function saveCurrentPlaylist(name) {
        var trackIds = [];
        for(var i = 0; i < size; i++) {
            trackIds.push(requestPlaylistItem(i));
        }
        playlistStorage.savePlaylist(name, trackIds, currentIndex);
        playlistStorage.currentPlaylistName = name;
    }

    function loadSavedPlaylist(name) {
        playlistStorage.loadPlaylist(name);
    }

    // Überschreibe die Navigation-Funktionen
    function nextTrack() {
        console.log("Next track called", mediaController.playbackState)
        playlistPython.nextTrack()
        currentTrackIndex()
        // Speichere Fortschritt
        if (playlistStorage.currentPlaylistName) {
            playlistStorage.updatePosition(playlistStorage.currentPlaylistName, currentIndex);
        }
    }

    function previousTrack() {
        playlistPython.canNext = false
        playlistPython.previousTrack()
        currentTrackIndex()
        // Speichere Fortschritt
        if (playlistStorage.currentPlaylistName) {
            playlistStorage.updatePosition(playlistStorage.currentPlaylistName, currentIndex);
        }
    }

    function playPosition(position) {
        playlistPython.canNext = false
        mediaController.blockAutoNext = true
        playlistPython.playPosition(position)
        currentTrackIndex()
        // Speichere Fortschritt
        if (playlistStorage.currentPlaylistName) {
            playlistStorage.updatePosition(playlistStorage.currentPlaylistName, position);
        }
    }

    function getSavedPlaylists() {
        return playlistStorage.getPlaylistInfo();
    }
}
