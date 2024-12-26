import QtQuick 2.0
import io.thp.pyotherside 1.5

Item {
    id: root

    // Signals
    signal currentId(int id)
    signal currentPosition(int position)
    signal containsTrack(int id)
    signal clearList()
    signal currentTrack(int position)
    signal playListFinished()
    signal playListChanged()
    signal trackInformation(int id, int index, string title, string album, string artist, string image, int duration)

    // Properties
    property bool canNext: true
    property bool canPrev: true
    property int size: 0
    property int current_track: 0

    // Python Interface
    Python {
        id: playlistPython

        Component.onCompleted: {
            setHandler('printConsole', function(string) {
                console.log("playlistManager::printConsole" + string)
            })

            setHandler('currentTrack', function(id, position) {
                root.currentId(id)
                root.currentTrack(position)
            })

            setHandler('clearList', function() {
                root.clearList()
            })

            setHandler('containsTrack', function(id) {
                root.containsTrack(id)
            })

            setHandler('playlistFinished', function() {
                root.canNext = false
            })

            setHandler('playlistUnFinished', function() {
                root.canNext = true
            })

            importModule('playlistmanager', function() {})
        }
    }

    // Public Functions
    function appendTrack(id) {
        console.log("PlaylistMagaer.appendTrack", id)

        call('playlistmanager.PL.AppendTrack', [id], {});
        canNext = true
    }

    function currentTrackIndex()
    {
        call("playlistmanager.PL.PlaylistIndex", [], function(index){
             current_track = index
            });
    }

    function getSize()
    {
        call("playlistmanager.PL.size", [], function(name){
             tracks = name
            });
    }

    function requestPlaylistItem(index)
    {
        console.log("Request PlaylistTrack", index)
        call("playlistmanager.PL.TidalId", [index], function(id){
                var track = pythonApi.getTrackInfo(id)
                trackInformation(id, index, track[1], track[2], track[3], track[4], track[5])
            });
    }

    function playAlbum(id)
    {
        console.log("playalbum", id)
        playlistManager.clearPlayList()
        currentTrackIndex()
        pythonApi.playAlbumTracks(id)
    }

    function playAlbumFromTrack(id)
    {
        playlistManager.clearPlayList()
        pythonApi.playAlbumFromTrack(id)
        currentTrackIndex()
    }

    function playTrack(id) {
        mediaPlayer.blockAutoNext = true
        call('playlistmanager.PL.PlayTrack', [id], {});
        currentTrackIndex()
    }

    function playPosition(id) {
        console.log(id)
        playlistManager.canNext = false
        mediaPlayer.blockAutoNext = true
        call('playlistmanager.PL.PlayPosition', [id], {});
        currentTrackIndex()
    }

    function insertTrack(id) {
        console.log("PlaylistMagaer.insertTrack", id)

        call('playlistmanager.PL.InsertTrack', [id], {});
        currentTrackIndex()
    }


    function nextTrack() {
        console.log("Next track called")
        if(mediaPlayer.playbackState !== 1 )
        {
            playlistManager.canNext = false
            call('playlistmanager.PL.NextTrack', function() {});
        }
        currentTrackIndex()
    }

    function nextTrackClicked() {
        console.log("Next track called")
        mediaPlayer.blockAutoNext = true

        playlistManager.canNext = false
        call('playlistmanager.PL.NextTrack', function() {});
        currentTrackIndex()
    }

    function restartTrack(id) {
        console.log(id)

        call('playlistmanager.PL.RestartTrack', function() {});
        currentTrackIndex()
    }

    function previousTrack() {
        playlistManager.canNext = false
        call('playlistmanager.PL.PreviousTrack', function() {});
        currentTrackIndex()
    }

    function previousTrackClicked() {
        playlistManager.canNext = false
        mediaPlayer.blockAutoNext = true
        call('playlistmanager.PL.PreviousTrack', function() {});
        currentTrackIndex()
    }

    function generateList()
    {

        console.log("Playlist changed from main.qml")
        call("playlistmanager.PL.size", [], function(tracks){
            console.log("got", tracks, " as name")
            size = tracks
            playlistManager.playListChanged();
            });
    }

    function clearPlayList()
    {
        call('playlistmanager.PL.clearList', function() {});
    }
}
