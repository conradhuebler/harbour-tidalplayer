import QtQuick 2.0
import io.thp.pyotherside 1.5

Item {
    id: root

    // Signals
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

    // Properties
    property string artistsResults
    property string albumsResults
    property string tracksResults

    property bool albums: true
    property bool artists: true
    property bool tracks: true
    property bool playlists: true

    property string playlist_track: ""
    property string playlist_artist: ""
    property string playlist_album: ""
    property string playlist_image: ""
    property int playlist_duration: 0
    property int playlist_track_id: 0

    // Python Interface
    Python {
        id: pythonTidal

        Component.onCompleted: {
            addImportPath(Qt.resolvedUrl('.'))

            setHandler('get_url', function(newvalue) {
                root.authUrl(newvalue)
            })

            setHandler('printConsole', function(string) {
                console.log("pythonApi::printConsole" + string)
            })

            setHandler('trackInfo', function(id, title, album, artist, image, duration) {
                root.trackChanged(id, title, album, artist, image, duration)
            })

            setHandler('albumInfo', function(id, title, artist, image) {
                root.albumChanged(id, title, artist, image)
            })

            setHandler('artistInfo', function(id, name, img) {
                root.artistChanged(id, name, img)
            })

            setHandler('addTrack', function(id, title, album, artist, image, duration) {
                root.trackAdded(id, title, album, artist, image, duration)
            })

            setHandler('addArtist', function(id, name, image) {
                root.artistAdded(id, name, image)
            })

            setHandler('addAlbum', function(id, title, album, artist, image, duration) {
                root.albumAdded(id, title, album, artist, image, duration)
            })

            setHandler('addPlaylist', function(id, name, image, duration, uid) {
                root.playlistSearchAdded(id, name, image, duration, uid)
            })

            setHandler('trackSearchFinished', function() {
                root.trackSearchFinished()
            })

            setHandler('artistsSearchFinished', function() {
                root.artistSearchFinished()
            })

            setHandler('albumsSearchFinished', function() {
                root.albumSearchFinished()
            })

            setHandler('oauth_success', function() {
                root.loginIn()
            })

            setHandler('oauth_login_success', function() {
                root.loginSuccess()
            })

            setHandler('oauth_login_failed', function() {
                root.loginFailed()
            })

            setHandler('playUrl', function(url) {
                mediaController.setSource(url)
                mediaController.play()
            })

            setHandler('insertTrack', function(id) {
                playlistManager.insertTrack(id)
            })

            setHandler('addTracktoPL', function(id) {
                playlistManager.appendTrack(id)
            })

            setHandler('fillFinished', function() {
                playlistManager.generateList()
            })

            setHandler('currentTrackInfo', function(title, track_num, album, artist, duration, album_image, artist_image) {
                root.currentTrackInfo(title, track_num, album, artist, duration, album_image, artist_image)
            })

            setHandler('addPersonalPlaylist', function(id, name, image, num_tracks, description, duration) {
                root.personalPlaylistAdded(id, name, image, num_tracks, description, duration)
            })

            setHandler('setPlaylist', function(id, title, image, num_tracks, description, duration) {
                root.playlistAdded(id, title, image, num_tracks, description, duration)
            })

            importModule('tidal', function() {})
        }
    }

    // Public Functions
    function printLogin()
    {
        console.log(token_type.value+ "\n" +  access_token.value + "\n" + refresh_token.value + "\n" + expiry_time.value)
    }

    function getOAuth() {
        call('tidal.Tidaler.request_oauth', function() {});
    }

    function loginIn() {
        console.log("Want login now")
        //console.log(expiry_time.value)
        //console.log(currentDate.toLocaleString(locale, "yyyy-MM-ddThh:mm:ss"))
        //print(Date.fromLocaleString(locale, expiry_time.value, "yyyy-MM-ddThh:mm:ss"));
        //console.log(Date.fromLocaleString(locale, expiry_time.value, "yyyy-MM-ddThh:mm:ss") < currentDate)
        if(Date.fromLocaleString(locale, expiry_time.value, "yyyy-MM-ddThh:mm:ss") > currentDate)
        {
            console.log("Valid login time");
            //console.log(token_type.value, access_token.value, refresh_token.value, expiry_time.value);
            call('tidal.Tidaler.login', [token_type.value, access_token.value, refresh_token.value, expiry_time.value], {});
        }
        else
        {
            console.log("inValid login time");
            //console.log(token_type.value, refresh_token.value, refresh_token.value, expiry_time.value);
            call('tidal.Tidaler.login', [token_type.value, refresh_token.value, refresh_token.value, expiry_time.value], {});
            console.log("Need to renew login")
        }

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
