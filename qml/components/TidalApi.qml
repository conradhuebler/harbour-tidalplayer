import QtQuick 2.0
import io.thp.pyotherside 1.5

Item {
    id: root

    // Wichtige Login/Auth Signale
    signal authUrl(string url)
    signal oAuthSuccess(string type, string token, string rtoken, string date)
    signal loginSuccess()
    signal loginFailed()

    // Search Signale
    signal trackSearchFinished()
    signal artistSearchFinished()
    signal albumSearchFinished()
    signal searchFinished()

    // Item Signale
    signal trackAdded(int id, string title, string album, string artist, string image, int duration)
    signal albumAdded(int id, string title, string artist, string image, int duration)
    signal artistAdded(int id, string name, string image)

    signal cacheTrack(int id, string title, string album, string artist, string image, int duration)
    signal cacheAlbum(int id, string title, string artist, string image, int duration)
    signal cacheArtist(int id, string name, string image)

    signal playlistSearchAdded(int id, string name, string image, int duration, string uid)
    signal personalPlaylistAdded(string id, string title, string image, int num_tracks, string description, int duration)
    signal playlistAdded(string id, string title, string image, int num_tracks, string description, int duration)

    // Info Change Signale
    signal trackChanged(int id, string title, string album, string artist, string image, int duration)
    signal albumChanged(int id, string title, string artist, string image)
    signal artistChanged(int id, string name, string img)
    signal currentTrackInfo(string title, int track_num, string album, string artist, int duration, string album_image, string artist_image)

    /* new signals come here*/
    signal searchResults(var search_results)
    signal playurl(string url)
    signal currentPlayback(var trackinfo)

    // Properties für die Suche
    property string artistsResults
    property string albumsResults
    property string tracksResults

    property bool albums: true
    property bool artists: true
    property bool tracks: true
    property bool playlists: true

    property bool loginTrue: false

    property string playlist_track: ""
    property string playlist_artist: ""
    property string playlist_album: ""
    property string playlist_image: ""

    property string current_track_title : ""
    property string current_track_artist : ""
    property string current_track_album : ""
    property string current_track_image : ""

    property string quality: ""


    property int playlist_duration: 0
    property int playlist_track_id: 0

    Python {
        id: pythonTidal

        Component.onCompleted: {
            addImportPath(Qt.resolvedUrl('../'))

            // Login Handler
            setHandler('get_url', function(newvalue) {
                pythonApi.authUrl(newvalue)
            })
            setHandler('oauth_success', function() {
                pythonApi.loginSuccess()
            })
            setHandler('oauth_login_success', function() {
                pythonApi.loginSuccess()
            })
            setHandler('oauth_failed', function() {
                pythonApi.loginFailed()
            })
            setHandler('get_token', function(type, token, rtoken, date) {
                console.log("Got new token from session")
                console.log(type, token, rtoken, date)
                pythonApi.oAuthSuccess(type, token, rtoken, date)
            })

            // Debug Handler
            setHandler('printConsole', function(string) {
                console.log("pythonApi::printConsole " + string)
            })

            // Search Handler
            setHandler('cacheTrack', function(id, title, album, artist, image, duration) {
                pythonApi.cacheTrack(id, title, album, artist, image, duration)
            })
            setHandler('cacheArtist', function(id, name, image) {
                pythonApi.cacheArtist(id, name, image)
            })
            setHandler('cacheAlbum', function(id, title, artist, image, duration) {
                pythonApi.cacheAlbum(id, title, artist, image, duration)
            })


            // Search Handler
            setHandler('addTrack', function(id, title, album, artist, image, duration) {
                pythonApi.trackAdded(id, title, album, artist, image, duration)
            })
            setHandler('addArtist', function(id, name, image) {
                pythonApi.artistAdded(id, name, image)
            })
            setHandler('addAlbum', function(id, title, artist, image, duration) {
                pythonApi.albumAdded(id, title, artist, image, duration)
            })
            setHandler('addPlaylist', function(id, name, image, duration, uid) {
                pythonApi.playlistSearchAdded(id, name, image, duration, uid)
            })


            // Search Finished Handler
            setHandler('trackSearchFinished', function() {
                pythonApi.trackSearchFinished()
            })
            setHandler('artistsSearchFinished', function() {
                pythonApi.artistSearchFinished()
            })
            setHandler('albumsSearchFinished', function() {
                pythonApi.albumSearchFinished()
            })

            setHandler('fillStarted', function()
            {
                playlistManager.nextTrack();
            });

            setHandler('fillFinished', function()
            {
                playlistManager.generateList()
                //playlistManager.nextTrack();
            });

            // Info Handler
            setHandler('trackInfo', function(id, title, album, artist, image, duration) {
                pythonApi.trackChanged(id, title, album, artist, image, duration)
            })
            setHandler('albumInfo', function(id, title, artist, image) {
                pythonApi.albumChanged(id, title, artist, image)
            })
            setHandler('artistInfo', function(id, name, img) {
                pythonApi.artistChanged(id, name, img)
            })

            // Playlist Handler
            setHandler('addPersonalPlaylist', function(id, name, image, num_tracks, description, duration) {
                pythonApi.personalPlaylistAdded(id, name, image, num_tracks, description, duration)
            })
            setHandler('setPlaylist', function(id, title, image, num_tracks, description, duration) {
                pythonApi.playlistAdded(id, title, image, num_tracks, description, duration)
            })
            setHandler('currentTrackInfo', function(title, track_num, album, artist, duration, album_image, artist_image) {
                pythonApi.currentTrackInfo(title, track_num, album, artist, duration, album_image, artist_image)
            })

            setHandler('addTracktoPL', function(id)
            {
                console.log("appended to PL", id)
                playlistManager.appendTrack(id)
            });
             // URL Handler
            setHandler('playUrl', function(url) {
                mediaPlayer.source = url
                mediaPlayer.play()
            })

            /* new handler will be placed here */

            setHandler('search_results', function(search_result) {
                console.log(search_result)
                searchResults(search_result)
            })

            setHandler('playback_info', function(info) {
                mediaController.playUrl(info.url)
                currentPlayback(info.track)
                /*
                mediaPlayer.source = info.url
                mediaPlayer.play()
                */
                pythonApi.current_track_title = info.track.title
                pythonApi.current_track_artist = info.track.artist
                pythonApi.current_track_album = info.track.album
                pythonApi.current_track_image = info.track.image

                //searchResults(search_result)
            })

            importModule('tidal', function() {
                console.log("Tidal module imported successfully")
            })
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


    }

    onOAuthSuccess: {
            console.log(type, token, rtoken, date)
            authManager.updateTokens(type, token, rtoken, date)
            loginSuccess()
        }

        onLoginSuccess: {
            loginTrue = true
        }

        onLoginFailed: {
            loginTrue = false
            if (authManager) {
                authManager.clearTokens()
            }
        }


    // Login Funktionen
    function getOAuth() {
        console.log("Request new login")
        pythonTidal.call('tidal.Tidaler.initialize', [quality])
        pythonTidal.call('tidal.Tidaler.request_oauth', [])
    }

    function loginIn(tokenType, accessToken, refreshToken, expiryTime) {
        console.log(accessToken)
        pythonTidal.call('tidal.Tidaler.initialize', [quality])
        pythonTidal.call('tidal.Tidaler.login',
            [tokenType, accessToken, refreshToken, expiryTime])
    }

    // Search Funktionen
    function genericSearch(text) {
        console.log("generic search", text)
        pythonTidal.call("tidal.Tidaler.genericSearch", [text])
    }

    function search(searchText) {
        if(tracks) {
            pythonTidal.call('tidal.Tidaler.search_track', [searchText])
        }
        if(artists) {
            pythonTidal.call('tidal.Tidaler.search_artist', [searchText])
        }
        if(albums) {
            pythonTidal.call('tidal.Tidaler.search_album', [searchText])
        }
        if(playlists) {
            pythonTidal.call('tidal.Tidaler.search_playlist', [searchText])
        }
    }

    // Track Funktionen
    function playTrackId(id) {
        console.log(id)
        pythonTidal.call("tidal.Tidaler.getTrackUrl", [id], function(name) {
            console.log(name.url)
            if(typeof name === 'undefined')
                console.log(typeof name)
            else
                console.log(typeof name)
        })
    }

    function getTrackInfo(id) {
        if (typeof id === 'string') {
            id = id.split('/').pop()
            id = id.replace(/[^0-9]/g, '')
        }
        console.log("JavaScript id after:", id, typeof id)

        var returnValue = null
        var val = (pythonTidal.getTrackInfo(id))
        console.log(val.title)
        pythonTidal.call("tidal.Tidaler.getTrackInfo", [id], function(result) {
            if (result) {
                // Properties aktualisieren
                playlist_track = result.title
                playlist_artist = result.artist
                playlist_album = result.album
                // playlist_image = result.image
                // Return-Wert setzen
                returnValue = result
            }
        })
        console.log(returnValue)
        return returnValue
    }

    // Album Funktionen
    function getAlbumTracks(id) {
        pythonTidal.call("tidal.Tidaler.getAlbumTracks", [id])
    }

    function getAlbumInfo(id) {
        pythonTidal.call("tidal.Tidaler.getAlbumInfo", [id])
    }

    function playAlbumTracks(id) {
        pythonTidal.call("tidal.Tidaler.playAlbumTracks", [id])
    }

    function playAlbumFromTrack(id) {
        pythonTidal.call("tidal.Tidaler.playAlbumfromTrack", [id])
    }

    // Artist Funktionen
    function getArtistInfo(id) {
        pythonTidal.call("tidal.Tidaler.getArtistInfo", [id])
    }

    // Playlist Funktionen
    function getPersonalPlaylists() {
        pythonTidal.call('tidal.Tidaler.getPersonalPlaylists', [])
    }

    function getPlaylistTracks(id) {
        pythonTidal.call('tidal.Tidaler.get_playlist_tracks', [id])
    }

    function playPlaylist(id) {
        pythonTidal.call("tidal.Tidaler.playPlaylist", [id])
    }

    function getFavorites() {
        pythonTidal.call('tidal.Tidaler.get_favorite_tracks', [])
    }


}


