import QtQuick 2.0
import Sailfish.Silica 1.0
import io.thp.pyotherside 1.5
import QtMultimedia 5.6
import org.nemomobile.mpris 1.0
import Nemo.Configuration 1.0

import "components"

import "pages"
import "pages/widgets"


ApplicationWindow
{
    property bool loginTrue : false
    property var locale: Qt.locale()
    property date currentDate: new Date()
    property MiniPlayer minPlayerPanel : miniPlayerPanel

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

    PlaylistManager {
        id: playlistManager
        onCurrentTrackChanged: {
            if (track) {
                pythonApi.playTrackId(track.id)
                console.log("playlistmanager call id", track)
            }
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
        signal authUrl(string url)
        signal loginSuccess()
        signal loginFailed()
        signal trackSearchFinished()
        signal artistSearchFinished()
        signal albumSearchFinished()
        signal searchFinished()

        signal trackAdded(int id, string title, string album, string artist, string image, int duration)
        signal albumAdded(int id, string title, string artist, string image, int duration)
        signal artistAdded(int id, string name, string image)
        signal playlistSearchAdded(int id, string name, string image, int duration, string uid)

        signal trackChanged(int id, string title, string album, string artist, string image, int duration)
        signal albumChanged(int id, string title, string artist, string image)
        signal artistChanged(int id, string name, string img)

        signal personalPlaylistAdded(string id, string title, string image, int num_tracks, string description, int duration)
        signal playlistAdded(string id, string title, string image, int num_tracks, string description, int duration)

        signal currentTrackInfo(string title, int track_num, string album, string artist, int duration, string album_image, string artist_image)

        property string artistsResults
        property string albumsResults
        property string tracksResults

        property bool albums: true
        property bool artists: true
        property bool tracks: true
        property bool playlists : true

        property string playlist_track : ""
        property string playlist_artist: ""
        property string playlist_album : ""
        property string playlist_image : ""
        property int playlist_duration : 0
        property int playlist_track_id : 0


        id: pythonApi

        Component.onCompleted: {
            addImportPath(Qt.resolvedUrl('.'));


            setHandler('get_url', function(newvalue) {
                pythonApi.authUrl(newvalue);
            });

            setHandler('printConsole', function(string)
            {
               console.log("pythonApi::printConsole" + string)
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

            setHandler('addArtist', function(id, name, image){
                pythonApi.artistAdded(id, name,image)
            }
            );

            setHandler('addAlbum', function(id, title, album, artist, image, duration){
                pythonApi.albumAdded(id, title, album, artist, image, duration)
            }
            );

            setHandler('addPlaylist', function(id, name, image, duration, uid){
                pythonApi.playlistSearchAdded(id, name, image, duration, uid)
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

            setHandler('oauth_failed',function() {
                pythonApi.loginFailed()
            });

            setHandler('playUrl', function(url) {
                mediaPlayer.source = url;
                mediaPlayer.play()
            });

            setHandler('insertTrack', function(id)
            {
                console.log("inserted to PL", id)
                playlistManager.insertTrack(id)
            });

            setHandler('addTracktoPL', function(id)
            {
                console.log("appended to PL", id)
                playlistManager.appendTrack(id)
            });

            setHandler('fillFinished', function()
            {
                playlistManager.generateList()
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


        function genericSearch(text) {
            call("tidal.Tidaler.genericSearch", [text], {});
        }


        function playTrackId(id)
        {
            call("tidal.Tidaler.getTrackUrl", [id], function(name)
            {
                print(name[0], name[1])
                console.log(name)
                if(typeof name === 'undefined')
                    console.log(typeof name)
                else
                    console.log(typeof name)
            });
        }


        function getTrackInfo(id)
        {
            console.log("getTrackInfo ", id)
            var track = (call_sync("tidal.Tidaler.getTrackInfo", [id], function(track) {
                console.log(track)
            }));
            console.log(track)
            return track
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


    MiniPlayer {
        parent: pageStack
        id: miniPlayerPanel
        z:10
    }


    AuthManager {
            id: authManager
        }

        TidalApi {
            id: tidalApi
            onOAuthSuccess: {
                // type, token, rtoken, date werden als Parameter übergeben
                authManager.updateTokens(type, token, rtoken, date)
            }
            onLoginSuccess: {
                loginTrue = true
            }
            onLoginFailed: {
                loginTrue = false
                authManager.clearTokens()
            }
            // Neue Handler für Tracks
            onTrackAdded: {
                // Wenn ein Track aus der Suche hinzugefügt wird
                console.log("TidalApi: Track added signal", id, title)
                playlistManager.appendTrack({
                    id: id,
                    title: title,
                    album: album,
                    artist: artist,
                    image: image,
                    duration: duration
                })
            }
        }

        Component.onCompleted: {
            authManager.checkAndLogin()
            mprisPlayer.setCanControl(true)
            importModule('playlistmanager', function () {
                console.log("Playlist module imported successfully")
            });

        }

    Connections {
        target: tidalApi
        onOAuthSuccess: {
            authManager.updateTokens(type, token, rtoken, date)
        }
        onLoginFailed: {
            authManager.clearTokens()
        }
    }


    Connections
    {
        target: playlistManager
        onCurrentId:
        {
            console.log("From playlistmanager")
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
