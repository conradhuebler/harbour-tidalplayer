import QtQuick 2.0
import io.thp.pyotherside 1.5
import QtFeedback 5.0  


Item {
    id: root

    Timer {
        id: updateTimer
        interval: 1000  // 100ms Verzögerung
        repeat: false
        onTriggered: {

                playlistStorage.loadCurrentPlaylistState()
        }
    }

    Timer {
        id: skipTrackGracePeriod
        interval: 5000
        repeat: false
        onTriggered: {
            skipTrack = false
        }
    }

    //property var currentPlaylist: []
    property int currentIndex: -1
    property bool canNext: size > 0 && currentIndex < size - 1
    property bool canPrev: currentIndex > 0
    property int size: 0 //currentPlaylist.length
    property int current_track: -1
    property int tidalId : 0
    property bool skipTrack : false

    signal currentTrackChanged(var track)
    signal playlistChanged()
    signal trackInformation(int id, int index, string title, string album, string artist, string image, int duration)
    signal currentId(int id)
    signal currentPosition(int position)
    signal containsTrack(int id)
    signal clearList()
    signal currentTrack(int position)
    signal selectedTrackChanged(var trackinfo)  // signal that position in playlist has changed (no playing it)

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
                console.log("Playlist must be cleared")

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

            setHandler('playlistManagerLoaded', function()
            {
                console.log("Playlistmanager loaded")
                initialised = true
                updateTimer.start()
            })

            importModule('playlistmanager', function() {
                console.log("Playlistmanager module imported successfully")
            })
        }

        // Python-Funktionen
        function appendTrack(id) {
            if(initialised)  call('playlistmanager.PL.AppendTrack', [id], {})
        }

        function appendTrackSilent(id) {
            if(initialised)  call('playlistmanager.PL.AppendTrackSilent', [id], {})
        }

        function currentTrackIndex() {
           if(initialised)  call("playlistmanager.PL.PlaylistIndex", [], function(index){
                current_track = index
            })
        }

        function removeTrack(id) {
            if(initialised)  call('playlistmanager.PL.RemoveTrack', [id], {})            
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

        function forceClearPlayList() {
            console.log("Force Clear list invoked")
            call('playlistmanager.PL.clearList', {})
        }

/* new functions are here */

        function playTrack(id) {
            console.log("Add track to playlist and play and rebuild playlist", id)
            call('playlistmanager.PL.PlayTrack', [id], {})
        }

        function generateList() {
        console.log("Generate current database")
            getSize()
            console.log("current size", root.size)
            root.listChanged()
        }
    }

    // Öffentliche Funktionen
    function clearPlayList() {
        playlistPython.clearPlayList()
    }

    function forceClearPlayList() {
        playlistPython.forceClearPlayList()
    }

    function play() {
        playlistPython.playPosition(0)
    }

    function appendTrack(id) {
        console.log("PlaylistManager.appendTrack", id)
        playlistPython.appendTrack(id)
        canNext = true
    }

    function appendTrackSilent(id) {
        console.log("PlaylistManager.appendTrackSilent", id)
        // why not silent ?
        playlistPython.appendTrack(id)
        canNext = true
    }

    // id: trackid
    function removeTrack(id){
        console.log("PlaylistManager.removeTrack", id)
        playlistPython.removeTrack(id)
        // todo:
        // update canNext / canPrev
    }

    function currentTrackIndex() {
        playlistPython.currentTrackIndex()
    }

    function getSize() {
        playlistPython.getSize()
    }

    // the name of this method is misleading, i did expect a track-info not the id
    function requestPlaylistItem(index) {
        var id = playlistPython.call_sync("playlistmanager.PL.TidalId", [index])
        root.tidalId = id
        return id
    }

    function playPlaylist(id) {
        tidalApi.playPlaylist(id)
        currentTrackIndex()
    }

    ThemeEffect {
        id: buttonEffect
        effect: ThemeEffect.PressStrong  // or ThemeEffect.Press, PressWeak, etc.
    }

    // Function to trigger feedback
    function doFeedback() {
        buttonEffect.play()
    }

    function playMix(id) {
        doFeedback()
        console.log("playMix", id)
        tidalApi.playMix(id)
        currentTrackIndex()
    }

    function playAlbum(id, startPlay) {
        doFeedback()
        var shouldPlay = startPlay === undefined ? true : startPlay
        console.log("playalbum", id, startPlay)
        tidalApi.playAlbumTracks(id,shouldPlay)
        currentTrackIndex()
    }

    function playAlbumFromTrack(id) {
        doFeedback()
        clearPlayList()
        tidalApi.playAlbumFromTrack(id)
        currentTrackIndex()
    }

    function playArtistTracks(id, startPlay) {
        doFeedback()
        var shouldPlay = startPlay === undefined ? true : startPlay
        console.log("Playlistmanager::playartist", id, startPlay)
        tidalApi.playArtistTracks(id,shouldPlay)
        currentTrackIndex()
    }

    function playArtistRadio(id, startPlay) {
        doFeedback()
        var shouldPlay = startPlay === undefined ? true : startPlay
        console.log("Playlistmanager::playartist", id, startPlay)
        tidalApi.playArtistRadio(id,shouldPlay)
        currentTrackIndex()
    }

    function playTrack(id) {
        console.log("Playlistmanager::playtrack", id)
        mediaController.blockAutoNext = true
        playlistPython.playTrack(id)
        currentTrackIndex()
    }

    function setTrack(index) {
        console.log("Playlistmanager::settrack", index)
        var trackId = requestPlaylistItem(index)
        currentIndex = index
        console.log("trackId:",trackId)
        playlistStorage.updatePosition(playlistStorage.playlistTitle, index)
        var track = cacheManager.getTrackInfo(trackId)
        root.trackInformation(trackId, index, track[1], track[2], track[3], track[4], track[5])
        root.selectedTrackChanged(track)

        //todo: update in playlistcache ?
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
        if (playlistStorage.playlistTitle) {
            playlistStorage.updatePosition(playlistStorage.playlistTitle, currentIndex);
        }
    }

    function restartTrack(id) {
        playlistPython.restartTrack()
        // for whatever reason we need to seek(0) here
        mediaController.seek(0)
        currentTrackIndex()
    }

    function previousTrackClicked() {
        // first press of the previous track button should skip to
        // the beginning of the current track
        // TODO: Add a setting to enable/disable this feature?
        if(!skipTrack || !canPrev)
        {
            restartTrack(currentId)
            skipTrack = true
            // if this is not what we want, give a 5s grace period
            // to click the previous track again and actually skip
            // to the previous song
            skipTrackGracePeriod.restart()
            return
        }

        playlistPython.canNext = false
        mediaController.blockAutoNext = true
        playlistPython.previousTrack()
        currentTrackIndex()
        if (playlistStorage.playlistTitle) {
            playlistStorage.updatePosition(playlistStorage.playlistTitle, currentIndex);
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
        playlistStorage.playlistTitle = name;
    }

    function loadSavedPlaylist(name) {
        console.log("Load playlist", name)
        //playlistStorage.playlistTitle = name;
        //clearPlayList()
        playlistStorage.loadPlaylist(name);
    }

    function deleteSavedPlaylist(name) {
        playlistStorage.deletePlaylist(name);
    }

    // Überschreibe die Navigation-Funktionen
    function nextTrack() {
        console.log("Next track called", mediaController.playbackState)
        playlistPython.nextTrack()
        currentTrackIndex()
        // Speichere Fortschritt
        if (playlistStorage.playlistTitle) {
            playlistStorage.updatePosition(playlistStorage.playlistTitle, currentIndex);
        }
    }

    function previousTrack() {
        playlistPython.canNext = false
        playlistPython.previousTrack()
        currentTrackIndex()
        // Speichere Fortschritt
        if (playlistStorage.playlistTitle) {
            playlistStorage.updatePosition(playlistStorage.playlistTitle, currentIndex);
        }
    }

    function playPosition(position) {
        playlistPython.canNext = false
        mediaController.blockAutoNext = true
        playlistPython.playPosition(position)
        currentTrackIndex()
        // Speichere Fortschritt
        if (playlistStorage.playlistTitle) {
            playlistStorage.updatePosition(playlistStorage.playlistTitle, position);
        }
    }

    function getSavedPlaylists() {
        return playlistStorage.getPlaylistInfo();
    }

}
