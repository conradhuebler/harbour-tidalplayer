import QtQuick 2.0
import io.thp.pyotherside 1.5

Item {
    id: root

    // Wichtige Login/Auth Signale
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
    signal playlistSearchAdded(int id, string name, string image, int duration, string uid)
    signal personalPlaylistAdded(string id, string title, string image, int num_tracks, string description, int duration)
    signal playlistAdded(string id, string title, string image, int num_tracks, string description, int duration)

    // Properties für die Suche
    property bool albums: true
    property bool artists: true
    property bool tracks: true
    property bool playlists: true

    Python {
        id: pythonTidal

        Component.onCompleted: {
            addImportPath(Qt.resolvedUrl('../'))

            // Login Handler
            setHandler('oauth_success', function() {
                root.loginSuccess()
            })
            setHandler('oauth_login_success', function() {
                root.loginSuccess()
            })
            setHandler('oauth_login_failed', function() {
                root.loginFailed()
            })
            setHandler('get_token', function(type, token, rtoken, date) {
                root.oAuthSuccess(type, token, rtoken, date)
            })

            // Debug Handler
            setHandler('printConsole', function(string) {
                console.log("TidalApi::printConsole " + string)
            })

            // Search Handler
            setHandler('addTrack', function(id, title, album, artist, image, duration) {
                root.trackAdded(id, title, album, artist, image, duration)
            })
            setHandler('addArtist', function(id, name, image) {
                root.artistAdded(id, name, image)
            })
            setHandler('addAlbum', function(id, title, artist, image, duration) {
                root.albumAdded(id, title, artist, image, duration)
            })
            setHandler('addPlaylist', function(id, name, image, duration, uid) {
                root.playlistSearchAdded(id, name, image, duration, uid)
            })

            // Search Finished Handler
            setHandler('trackSearchFinished', function() {
                root.trackSearchFinished()
            })
            setHandler('artistsSearchFinished', function() {
                root.artistSearchFinished()
            })
            setHandler('albumsSearchFinished', function() {
                root.albumSearchFinished()
            })

            // Playlist Handler
            setHandler('addPersonalPlaylist', function(id, name, image, num_tracks, description, duration) {
                root.personalPlaylistAdded(id, name, image, num_tracks, description, duration)
            })
            setHandler('setPlaylist', function(id, title, image, num_tracks, description, duration) {
                root.playlistAdded(id, title, image, num_tracks, description, duration)
            })

            importModule('tidal', function() {
                        console.log("Tidal module imported successfully")
                    })
        }
    }

    // Login Funktionen
    function getOAuth() {
        pythonTidal.call('tidal.Tidaler.request_oauth', [])
    }

    function loginIn(tokenType, accessToken, refreshToken, expiryTime) {
        pythonTidal.call('tidal.Tidaler.login',
            [tokenType, accessToken, refreshToken, expiryTime])
    }

    // Search Funktionen
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

    // Playlist Funktionen
    function playTrackId(id) {
        pythonTidal.call('tidal.Tidaler.play_track_id', [id])
    }

    function getPersonalPlaylists() {
        pythonTidal.call('tidal.Tidaler.get_user_playlists', [])
    }

    function getPlaylistTracks(id) {
        pythonTidal.call('tidal.Tidaler.get_playlist_tracks', [id])
    }

    function getFavorites() {
        pythonTidal.call('tidal.Tidaler.get_favorite_tracks', [])
    }
}
