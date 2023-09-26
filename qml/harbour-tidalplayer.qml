import QtQuick 2.0
import Sailfish.Silica 1.0
import io.thp.pyotherside 1.5
import QtMultimedia 5.6
import org.nemomobile.mpris 1.0
import Nemo.Configuration 1.0

import "pages"
import "pages/widgets"


ApplicationWindow
{
    property bool loginTrue : false
    property MiniPlayer minPlayerPanel : miniPlayerPanel

    ConfigurationValue {
      id: token_type
      key:"/token_type"
    }

    ConfigurationValue {
      id: access_token
      key:"/access_token"
      value:""
    }

    ConfigurationValue {
      id: refresh_token
      key:"/refresh_token"
    }

    ConfigurationValue {
      id: expiry_time
      key:"/expiry_time"
    }


    MiniPlayer {
        id: miniPlayerPanel
    }

    MprisPlayer{
        id: mprisPlayer
        canControl: true

        canGoNext: true
        canGoPrevious: true
        canPause: true
        canPlay: true
        canSeek: true

        serviceName: "tidalplayer"
        identity: "Tidal Music Player"

        function updateTrack(track, artist, album)
        {
                console.debug("Title changed to: " + track)
                var metadata = mprisPlayer.metadata
                metadata[Mpris.metadataToString(Mpris.Title)] = track
                metadata[Mpris.metadataToString(Mpris.Artist)] = artist

                metadata[Mpris.metadataToString(Mpris.Album)] = album

                mprisPlayer.metadata = metadata

        }

    }

    MediaPlayer {
        id: mediaPlayer
        autoLoad: true
        signal currentPosition(int position)
        property bool blockAutoNext : false
        property bool isPlaying : false
        property bool videoPlaying: false
        property string errorMsg: ""

        onError: {
            if ( error === MediaPlayer.ResourceError ) errorMsg = qsTr("Error: Problem with allocating resources")
            else if ( error === MediaPlayer.ServiceMissing ) errorMsg = qsTr("Error: Media service error")
            else if ( error === MediaPlayer.FormatError ) errorMsg = qsTr("Error: Video or Audio format is not supported")
            else if ( error === MediaPlayer.AccessDenied ) errorMsg = qsTr("Error: Access denied to the video")
            else if ( error === MediaPlayer.NetworkError ) errorMsg = qsTr("Error: Network error")
            stop()
            isPlaying = false
        }

        onStopped:
        {
            console.log("playing stopped", playlistManager.canNext, blockAutoNext)
            if(!blockAutoNext)
            {
                console.log("playing next is not blocked", playlistManager.canNext, blockAutoNext)

                if(playlistManager.canNext)
                {
                    playlistManager.nextTrack()
                }
                else
                {
                    console.log("there is no next track to play", playlistManager.canNext, blockAutoNext)

                    playlistManager.playListFinished()
                    isPlaying = false
                }
            }else
            console.log("playing next was blocked", playlistManager.canNext, blockAutoNext)

            blockAutoNext = false
        }

        onPositionChanged:
        {
            mediaPlayer.currentPosition(mediaPlayer.position/mediaPlayer.duration*100)
        }

        onPlaying:
        {
            isPlaying = true
            //mprisPlayer.canPause = true
            mprisPlayer.canGoNext = playlistManager.canNext
            mprisPlayer.canGoPrevious = playlistManager.canPrev
            mprisPlayer.playbackStatus = Mpris.Playing
        }

        onPaused:
        {
            mprisPlayer.playbackStatus = Mpris.Paused
        }
    }

    Python {
        signal currentId(int id)
        signal currentPosition(int position)
        signal containsTrack(int id)
        signal clearList()
        signal currentTrack(int position)
        signal playListFinished()

        property bool canNext : true
        property bool canPrev : true

        id: playlistManager

        Component.onCompleted: {

            setHandler('currentTrack', function(id, position) {
                console.log(id, position)
                playlistManager.currentId(id);
                playlistManager.currentTrack(position)
            });

            setHandler('clearList', function() {
                playlistManager.clearList();
            });

            setHandler('containsTrack', function(id) {
                console.log(id)
                playlistManager.containsTrack(id);
            });

            setHandler('playlistFinished', function() {
                console.log("Playlist Finished")
                canNext = false
            });

            setHandler('playlistUnFinished', function() {
                console.log("Playlist unfinished")
                canNext = true
            });

            importModule('playlistmanager', function () {});
        }

        function appendTrack(id) {
            console.log(id)
            call('playlistmanager.PL.AppendTrack', [id], {});
            canNext = true
        }

        function playAlbum(id)
        {
            console.log("playalbum", id)
            playlistManager.clearPlayList()
            pythonApi.playAlbumTracks(id)
        }

        function playAlbumFromTrack(id)
        {
            playlistManager.clearPlayList()
            pythonApi.playAlbumFromTrack(id)

        }

        function playTrack(id) {
            mediaPlayer.blockAutoNext = true
            call('playlistmanager.PL.PlayTrack', [id], {});
        }

        function playPosition(id) {
            console.log(id)
            playlistManager.canNext = false
            mediaPlayer.blockAutoNext = true
            call('playlistmanager.PL.PlayPosition', [id], {});
        }

        function insertTrack(id) {
            console.log(id)

            call('playlistmanager.PL.InsertTrack', [id], {});
        }


        function nextTrack() {
            console.log("Next track called")
            if(mediaPlayer.playbackState !== 1 )
            {
                playlistManager.canNext = false
                call('playlistmanager.PL.NextTrack', function() {});
            }

        }

        function nextTrackClicked() {
            console.log("Next track called")
            mediaPlayer.blockAutoNext = true

            playlistManager.canNext = false
            call('playlistmanager.PL.NextTrack', function() {});

        }

        function restartTrack(id) {
            console.log(id)

            call('playlistmanager.PL.RestartTrack', function() {});
        }

        function previousTrack() {
            playlistManager.canNext = false
            call('playlistmanager.PL.PreviousTrack', function() {});
        }

        function previousTrackClicked() {
            playlistManager.canNext = false
            mediaPlayer.blockAutoNext = true
            call('playlistmanager.PL.PreviousTrack', function() {});
        }

        function generateList()
        {
            console.log("build playlist")
            call('playlistmanager.PL.GenerateList', function() {});
        }

        function clearPlayList()
        {
            call('playlistmanager.PL.clearList', function() {});
        }
    }

    Python {
        signal authUrl(string url)
        signal loginSuccess()
        signal loginFailed()
        signal trackSearchFinished()
        signal artistSearchFinished()
        signal albumSearchFinished()
        signal searchFinished()

        signal trackAdded(int id, string title, string album, string artist, string image, int duration)
        signal albumAdded(int id, string title, string artist, string image)
        signal artistAdded(int id, string name)

        signal trackChanged(int id, string title, string album, string artist, string image, int duration)
        signal albumChanged(int id, string title, string artist, string image)
        signal artistChanged(int id, string name, string img)

        signal personalPlaylistAdded(string id, string title, string image, int num_tracks, string description, int duration)
        signal playlistAdded(string id, string title, string image, int num_tracks, string description, int duration)

        signal currentTrackInfo(string title, int track_num, string album, string artist, int duration, string album_image, string artist_image)

        property string artistsResults
        property string albumsResults
        property string tracksResults

        id: pythonApi

        Component.onCompleted: {
            addImportPath(Qt.resolvedUrl('.'));


            setHandler('get_url', function(newvalue) {
                pythonApi.authUrl(newvalue);
            });


            setHandler('trackInfo', function(id, title, album, artist, image, duration) {
                pythonApi.trackChanged(id, title, album, artist, image, duration)
            });

            setHandler('albumInfo', function(id, title, artist, image) {
                pythonApi.albumChanged(id, title, artist, image)
            });

            setHandler('artistInfo', function(id, name, img) {
                pythonApi.artistChanged(id, name, img)
            });


            setHandler('addTrack', function(id, title, album, artist, image, duration){
                pythonApi.trackAdded(id, title, album, artist, image, duration)
            }
            );

            setHandler('addArtist', function(id, name){
                pythonApi.artistAdded(id, name)
            }
            );

            setHandler('addAlbum', function(id, title, album, artist, image){
                pythonApi.albumAdded(id, title, album, artist, image)
            }
            );

            setHandler('trackSearchFinished', function() {
                pythonApi.trackSearchFinished()
            });

            setHandler('artistsSearchFinished', function() {
                pythonApi.artistSearchFinished()

            });

            setHandler('albumsSearchFinished', function() {
                pythonApi.albumSearchFinished()
            });

            setHandler('oauth_success', function() {
                pythonApi.loginIn()
            });

            setHandler('oauth_login_success', function() {
                loginTrue = true
                console.log("Login Successful")
                pythonApi.loginSuccess()
            });

            setHandler('oauth_login_failed', function() {
                loginTrue = false
                pythonApi.loginFailed()
            });

            setHandler('get_token', function(type, token, rtoken, date) {
                token_type.value = type
                access_token.value = token

                refresh_token.value = rtoken
                expiry_time.value = date
                pythonApi.loginSuccess()
                pythonApi.loginIn()

            });

            setHandler('oauth_updated', function(type, token, rtoken, date) {
                token_type.value = type
                access_token.value = token

                refresh_token.value = rtoken
                expiry_time.value = date
                pythonApi.loginSuccess()
                pythonApi.loginIn()

            });

            setHandler('oauth_failed',function() {
                pythonApi.loginFailed()
            });

            setHandler('playUrl', function(url) {
                mediaPlayer.source = url;
                mediaPlayer.play()
            });

            setHandler('addTracktoPL', function(id)
            {
                console.log(id)
                //pythonApi.playAlbumTracks(id)
                playlistManager.appendTrack(id)
                //playlistManager.playPosition(0)
            });

            setHandler('fillFinished', function()
            {
                playlistManager.playPosition(0)
            });

            setHandler('currentTrackInfo', function(title, track_num, album, artist, duration, album_image, artist_image)
            {
                pythonApi.currentTrackInfo(title, track_num, album, artist, duration, album_image, artist_image)
            });

            setHandler('addPersonalPlaylist', function(id, name, image, num_tracks, description, duration)
            {
                pythonApi.personalPlaylistAdded(id, name, image, num_tracks, description, duration)
            });

            setHandler('setPlaylist', function(id, title, image, num_tracks, description, duration)
            {
                pythonApi.playlistAdded(id, title, image, num_tracks, description, duration)
            });

            importModule('tidal', function () {});

        }

        function printLogin()
        {
            console.log(token_type.value+ "\n" +  access_token.value + "\n" + refresh_token.value + "\n" + expiry_time.value)
        }

        function getOAuth() {
            call('tidal.Tidaler.request_oauth', function() {});
        }

        function loginIn() {
            console.log("Want login now")
            call('tidal.Tidaler.login', [token_type.value, access_token.value, refresh_token.value, expiry_time.value], {});
        }

        function genericSearch(text) {
            call("tidal.Tidaler.genericSearch", [text], {});
        }

        function playTrackId(id)
        {
            call("tidal.Tidaler.getTrackUrl", [id], {});
        }


        function getTrackInfo(id)
        {
            call("tidal.Tidaler.getTrackInfo", [id], {});
        }

        function getAlbumTracks(id)
        {
            call("tidal.Tidaler.getAlbumTracks", [id], {});
        }

        function getAlbumInfo(id)
        {
            call("tidal.Tidaler.getAlbumInfo", [id], {});
        }

        function getArtistInfo(id)
        {
            call("tidal.Tidaler.getArtistInfo", [id], {});
        }

        function playAlbumTracks(id)
        {
            call("tidal.Tidaler.playAlbumTracks", [id], {});
        }

        function playAlbumFromTrack(id)
        {
            call("tidal.Tidaler.playAlbumfromTrack", [id], {});
        }

        function getPersonalPlaylists(id)
        {
            call("tidal.Tidaler.getPersonalPlaylists", [], {});
        }

        function getPersonalPlaylist(id)
        {
            call("tidal.Tidaler.getPersonalPlaylist", [id], {});
        }

        function playPlaylist(id)
        {
            playlistManager.clearPlayList()
            call("tidal.Tidaler.playPlaylist", [id], {});
        }

    }

    initialPage: Component { FirstPage { } }
    cover: Qt.resolvedUrl("cover/CoverPage.qml")
    allowedOrientations: defaultAllowedOrientations


    Component.onCompleted: {
        pythonApi.loginIn()
        mprisPlayer.setCanControl(true)
    }
    Connections
    {
        target: playlistManager
        onCurrentId:
        {
            pythonApi.playTrackId(id)
        }
    }

    Connections{
        target: mprisPlayer
        onPlayRequested :
        {
            console.log("play requested")
            mediaPlayer.play()
        }

        onPauseRequested :
        {
            console.log("pause requested")
            mediaPlayer.pause()
        }

        onPlayPauseRequested :
        {
            console.log("playpause requested")

            if (mediaPlayer.playbackState == 1)
            {
                mediaPlayer.pause()
            }
            else if(mediaPlayer.playbackState == 2){
                mediaPlayer.play()
            }
        }

        onNextRequested :
        {
            console.log("play next")
            mediaPlayer.blockAutoNext = true
            playlistManager.nextTrackClicked()
        }

        onPreviousRequested :
        {
            playlistManager.previousTrackClicked()
        }
    }
}
