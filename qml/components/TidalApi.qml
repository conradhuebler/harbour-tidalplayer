import QtQuick 2.0
import io.thp.pyotherside 1.5

Item {
    id: root

    // Wichtige Login/Auth Signale
    signal authUrl(string url)
    signal oAuthSuccess(string type, string token, string rtoken, string date)
    signal oAuthRefresh(string token)

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
    //signal personalPlaylistAdded(string id, string title, string image, int num_tracks, string description, int duration)
    signal personalPlaylistAdded(var playlist_info)
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
    signal cacheTrack(var track_info)
    signal cacheAlbum(var album_info)
    signal cacheArtist(var artist_info)
    signal cacheMix(var mix_info)
    signal cachePlaylist(var playlist_info)
    signal albumofArtist(var album_info)
    signal topTracksofArtist(var track_info)
    signal radioTrackofArtist(var track_info)
    signal similarArtist(var artist_info)

    // signals for search
    signal foundTrack(var track_info)
    signal foundPlaylist(var playlist_info)
    signal foundAlbum(var album_info)
    signal foundArtist(var artist_info)
    signal foundVideo(var video_info)
    
    // PERFORMANCE: Batch signals for improved search performance
    signal foundTracksBatch(var tracks_array)
    signal foundPlaylistsBatch(var playlists_array)
    signal foundAlbumsBatch(var albums_array)
    signal foundArtistsBatch(var artists_array)

    // signal for favorites
    signal favTracks(var track_info)
    signal favAlbums(var album_info)
    signal favArtists(var artist_info)

    // recent stuff
    signal recentAlbum(var album_info)
    signal recentArtist(var artist_info)
    signal recentPlaylist(var playlist_info)
    signal recentMix(var mix_info)
    signal recentTrack(var track_info)

    // for you 
    signal foryouAlbum(var album_info)
    signal foryouArtist(var artist_info)
    signal foryouPlaylist(var playlist_info)
    signal foryouMix(var mix_info)

    // dailyMix, radioMix
    signal customMix(var mix_info, var mixType) // mixType: dailyMix, radioMix, customMix

    // sorted items like
    signal topArtist(var artist_info) // artists sorted by my popularity

    signal noSimilarArtists()

    signal playlistTrackAdded(var track_info)
    signal albumTrackAdded(var track_info)
    signal mixTrackAdded(var track_info)

    // Properties für die Suche
    property string artistsResults
    property string albumsResults
    property string tracksResults

    property bool albums: true
    property bool artists: true
    
    // PERFORMANCE: Async-First API properties
    property bool loading: false
    property var pendingRequests: ({})  // Track pending requests by ID
    property int requestCounter: 0      // Generate unique request IDs
    
    // Request queue for batching
    property var requestQueue: []
    property bool processingQueue: false
    
    // PERFORMANCE: Request Deduplication
    property var activeRequests: ({})      // Track active requests by signature
    property var requestCache: ({})        // Cache recent request results
    property int cacheTimeout: 30000       // 30 seconds cache timeout
    property bool tracks: true
    property bool playlists: true

    property bool loginTrue: false
    
    // PERFORMANCE: Request processing timer
    Timer {
        id: requestProcessingTimer
        interval: 10  // 10ms between requests to prevent blocking
        repeat: false
        running: false
        onTriggered: {
            if (requestQueue.length > 0) {
                var request = requestQueue.shift()
                console.log("Processing async request:", request.method)
                pythonTidal.call(request.method, request.params)
                // Continue processing if more requests
                if (requestQueue.length > 0) {
                    start()
                }
            } else {
                processingQueue = false
                if (Object.keys(pendingRequests).length === 0) {
                    loading = false
                }
            }
        }
    }
  //  property bool loading: false

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
                tidalApi.authUrl(newvalue)
            })
            setHandler('oauth_success', function() {
                tidalApi.loginSuccess()
            })
            setHandler('oauth_login_success', function() {
                tidalApi.loginSuccess()
            })
            // we have both here
            //
            setHandler('oauth_failed', function() {
                tidalApi.loginFailed()
            })

            setHandler('oauth_login_failed', function() {
                tidalApi.loginFailed()
            })
            // lets remove soon one

            setHandler('get_token', function(type, token, rtoken, date) {
                console.log("Got new token from session")
                console.log(type, token, rtoken, date)
                tidalApi.oAuthSuccess(type, token, rtoken, date)
            })

            setHandler('oauth_refresh', function(token, rtoken, expiry) {
                console.log("Got refreshed token from session")
                console.log("token:", token, "rtoken:", rtoken, "expiry:", expiry)
                tidalApi.oAuthRefresh(token)
                // Update AuthManager with all token info
                authManager.refreshTokens(token, rtoken, expiry)
            })

            // Debug Handler
            setHandler('printConsole', function(string) {
                console.log("tidalApi::printConsole " + string)
            })


            setHandler('cacheTrack', function(track_info) {
                tidalApi.cacheTrack(track_info)
            })
            setHandler('cacheArtist', function(artist_info) {
                tidalApi.cacheArtist(artist_info)
            })
            setHandler('cacheAlbum', function(album_info) {
                tidalApi.cacheAlbum(album_info)
            })
            setHandler('cachePlaylist', function(playlist_info) {
                tidalApi.cachePlaylist(playlist_info)
            })
            setHandler('cacheMix', function(mix_info) {
                tidalApi.cacheMix(mix_info)
            })            

            setHandler('TopTrackofArtist', function(track_info) {
                tidalApi.topTracksofArtist(track_info)
            })

            setHandler('RadioTrackofArtist', function(track_info) {
                tidalApi.radioTrackofArtist(track_info)
            })            

            setHandler('AlbumofArtist', function(album_info) {
                tidalApi.albumofArtist(album_info)
            })

            setHandler('SimilarArtist', function(artist_info) {
                //cacheManager.saveArtistToCache(artist_info)
                tidalApi.cacheArtist(artist_info)
                tidalApi.similarArtist(artist_info)
            })

            setHandler('noSimilarArtists', function() {
                tidalApi.noSimilarArtists()
            })

            setHandler('foundTrack', function(track_info) {
                tidalApi.foundTrack(track_info)
            })

            setHandler('foundAlbum', function(album_info) {
                tidalApi.foundAlbum(album_info)
            })

            setHandler('foundArtist', function(artist_info) {
                tidalApi.foundArtist(artist_info)
            })


            setHandler('foundPlaylist', function(playlist_info) {
                tidalApi.foundPlaylist(playlist_info)
            })


            setHandler('foundVideo', function(video_info) {
                tidalApi.foundVideo(video_info)
            })

            // PERFORMANCE: Batch signal handlers - emit batch signals directly
            setHandler('foundTracksBatch', function(tracks_array) {
                console.log("Received tracks batch:", tracks_array.length, "tracks")
                tidalApi.foundTracksBatch(tracks_array)
            })

            setHandler('foundArtistsBatch', function(artists_array) {
                console.log("Received artists batch:", artists_array.length, "artists")
                tidalApi.foundArtistsBatch(artists_array)
            })

            setHandler('foundAlbumsBatch', function(albums_array) {
                console.log("Received albums batch:", albums_array.length, "albums")
                tidalApi.foundAlbumsBatch(albums_array)
            })

            setHandler('foundPlaylistsBatch', function(playlists_array) {
                console.log("Received playlists batch:", playlists_array.length, "playlists")
                tidalApi.foundPlaylistsBatch(playlists_array)
            })

            setHandler('foundVideosBatch', function(videos_array) {
                console.log("Received videos batch:", videos_array.length, "videos")
                for (var i = 0; i < videos_array.length; i++) {
                    tidalApi.foundVideo(videos_array[i])
                }
            })

            setHandler('foundMixesBatch', function(mixes_array) {
                console.log("Received mixes batch:", mixes_array.length, "mixes")
                for (var i = 0; i < mixes_array.length; i++) {
                    tidalApi.foundMix(mixes_array[i])
                }
            })


            setHandler('FavAlbums', function(album_info) {
                tidalApi.favAlbums(album_info)
            })

            setHandler('FavTracks', function(track_info) {
                tidalApi.favTracks(track_info)
            })

            setHandler('FavArtist', function(artist_info) {
                tidalApi.favArtists(artist_info)
            })

            setHandler('foundPlaylist', function(playlist_info) {
                tidalApi.foundPlaylist(playlist_info)
            })

            // Search Handler
            setHandler('addTrack', function(id, title, album, artist, image, duration) {
                tidalApi.trackAdded(id, title, album, artist, image, duration)
            })
            setHandler('addArtist', function(id, name, image) {
                tidalApi.artistAdded(id, name, image)
            })
            setHandler('addAlbum', function(id, title, artist, image, duration) {
                tidalApi.albumAdded(id, title, artist, image, duration)
            })
            setHandler('addPlaylist', function(id, name, image, duration, uid) {
                tidalApi.playlistSearchAdded(id, name, image, duration, uid)
            })


            // Search Finished Handler
            setHandler('trackSearchFinished', function() {
                tidalApi.trackSearchFinished()
            })
            setHandler('artistsSearchFinished', function() {
                tidalApi.artistSearchFinished()
            })
            setHandler('albumsSearchFinished', function() {
                tidalApi.albumSearchFinished()
            })

            setHandler('fillStarted', function()
            {
                playlistManager.nextTrack();
            });

            // adding tracks to playlist / album finished
            setHandler('fillFinished', function(autoPlay)
            {
                var auto=false
                if (autoPlay !== undefined) auto = autoPlay
                playlistManager.generateList()
                if(auto)
                    playlistManager.nextTrack();
            });

            // Info Handler
            setHandler('trackInfo', function(id, title, album, artist, image, duration) {
                tidalApi.trackChanged(id, title, album, artist, image, duration)
            })
            setHandler('albumInfo', function(id, title, artist, image) {
                tidalApi.albumChanged(id, title, artist, image)
            })
            setHandler('artistInfo', function(id, name, img) {
                tidalApi.artistChanged(id, name, img)
            })

            // Playlist Handler
            //setHandler('addPersonalPlaylist', function(id, name, image, num_tracks, description, duration) {
            //    tidalApi.personalPlaylistAdded(id, name, image, num_tracks, description, duration)
            //})

            setHandler('addPersonalPlaylist', function(playlist_info) {
                tidalApi.personalPlaylistAdded(playlist_info)
            })

            setHandler('setPlaylist', function(id, title, image, num_tracks, description, duration) {
                tidalApi.playlistAdded(id, title, image, num_tracks, description, duration)
            })
            setHandler('currentTrackInfo', function(title, track_num, album, artist, duration, album_image, artist_image) {
                tidalApi.currentTrackInfo(title, track_num, album, artist, duration, album_image, artist_image)
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
                tidalApi.current_track_title = info.track.title
                tidalApi.current_track_artist = info.track.artist
                tidalApi.current_track_album = info.track.album
                tidalApi.current_track_image = info.track.image

            })

            setHandler('playlist_replace', function(playlist) {
                playlistManager.clearPlayList()
                searchResults(playlist)
            })
            
            setHandler('mix_replace', function(mix_data) {
                console.log("Mix replace received, clearing playlist and adding", mix_data.tracks.length, "tracks")
                playlistManager.clearPlayList()
                // Add all tracks to playlist
                var trackIds = []
                for (var i = 0; i < mix_data.tracks.length; i++) {
                    trackIds.push(mix_data.tracks[i].trackid)
                }
                playlistManager.appendTracksBatch(trackIds)
                
                // Auto-start if needed - handled by play_track signal separately
            })

            // Response Loading started
            setHandler('loadingStarted', function() {
                root.loading = true
            })

            // Response Loading finished
            setHandler('loadingFinished', function() {
                root.loading = false
            })

            setHandler('apiError', function(error) {
                console.log("api-error: " + error)
            })

            setHandler('playlistTrackAdded', function(track_info) {
                root.playlistTrackAdded(track_info)
            })

            setHandler('albumTrackAdded', function(track_info) {
                root.albumTrackAdded(track_info)
            })

            setHandler('mixTrackAdded', function(track_info) {
                root.mixTrackAdded(track_info)
            })

            setHandler('recentAlbum', function(album_info)
            {
                root.recentAlbum(album_info)
            })

            setHandler('recentArtist', function(artist_info)
            {
                root.recentArtist(artist_info)
            })

            setHandler('recentPlaylist', function(playlist_info)
            {
                root.recentPlaylist(playlist_info)
            })

            setHandler('recentMix', function(mix_info)
            {
                root.recentMix(mix_info)
            })

            setHandler('recentTrack', function(track_info)
            {
                root.recentTrack(track_info)
            })

            setHandler('foryouAlbum', function(album_info)
            {
                root.foryouAlbum(album_info)
            })

            setHandler('foryouArtist', function(artist_info)
            {
                root.foryouArtist(artist_info)
            })

            setHandler('foryouPlaylist', function(playlist_info)
            {
                root.foryouPlaylist(playlist_info)
            })

            setHandler('foryouMix', function(mix_info)
            {
                root.foryouMix(mix_info)
            })

            setHandler('customMix', function(mix_info, mixType)
            {
                root.customMix(mix_info, mixType)
            })

            setHandler('topArtist', function(artist_info)
            {
                console.log("topArtist", artist_info)
                root.topArtist(artist_info)
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
        console.log("loginIn:", accessToken)
        pythonTidal.call('tidal.Tidaler.initialize', [quality])
        pythonTidal.call('tidal.Tidaler.login',
            [tokenType, accessToken, refreshToken, expiryTime])
    }

    // PERFORMANCE: Request Deduplication functions
    function generateRequestSignature(method, params) {
        return method + ":" + JSON.stringify(params || [])
    }
    
    function isRequestCached(signature) {
        var cached = requestCache[signature]
        if (cached && (Date.now() - cached.timestamp) < cacheTimeout) {
            return cached.result
        }
        return null
    }
    
    function cacheRequestResult(signature, result) {
        requestCache[signature] = {
            result: result,
            timestamp: Date.now()
        }
        
        // Clean old cache entries
        cleanRequestCache()
    }
    
    function cleanRequestCache() {
        var now = Date.now()
        for (var sig in requestCache) {
            if ((now - requestCache[sig].timestamp) > cacheTimeout) {
                delete requestCache[sig]
            }
        }
    }

    // PERFORMANCE: Async-First API Management
    function generateRequestId() {
        return ++requestCounter
    }
    
    function queueRequest(method, params, callback) {
        var signature = generateRequestSignature(method, params)
        
        // PERFORMANCE: Check if result is cached
        var cachedResult = isRequestCached(signature)
        if (cachedResult) {
            console.log("DEDUP: Using cached result for:", signature)
            if (callback) {
                // Use Qt.callLater to call callback asynchronously
                Qt.callLater(callback, cachedResult)
            }
            return -1  // Cached request ID
        }
        
        // PERFORMANCE: Check if request is already active
        if (activeRequests[signature]) {
            console.log("DEDUP: Request already active, attaching callback:", signature)
            if (callback) {
                activeRequests[signature].callbacks.push(callback)
            }
            return activeRequests[signature].id
        }
        
        // New request
        var requestId = generateRequestId()
        var request = {
            id: requestId,
            method: method,
            params: params || [],
            callback: callback,
            callbacks: callback ? [callback] : [],
            timestamp: Date.now(),
            signature: signature
        }
        
        // Mark as active
        activeRequests[signature] = request
        
        requestQueue.push(request)
        pendingRequests[requestId] = request
        
        // Process queue if not already processing
        if (!processingQueue) {
            processRequestQueue()
        }
        
        return requestId
    }
    
    function processRequestQueue() {
        if (processingQueue || requestQueue.length === 0) return
        
        processingQueue = true
        loading = true
        
        // Start the dedicated request processing timer
        requestProcessingTimer.start()
    }
    
    function completeRequest(requestId, result) {
        if (pendingRequests[requestId]) {
            var request = pendingRequests[requestId]
            
            // PERFORMANCE: Cache the result for deduplication
            if (request.signature) {
                cacheRequestResult(request.signature, result)
                
                // Remove from active requests
                delete activeRequests[request.signature]
                
                // Call all callbacks for deduplicated requests
                for (var i = 0; i < request.callbacks.length; i++) {
                    if (request.callbacks[i]) {
                        request.callbacks[i](result)
                    }
                }
            } else if (request.callback) {
                request.callback(result)
            }
            
            delete pendingRequests[requestId]
            
            // Check if all requests completed
            if (Object.keys(pendingRequests).length === 0) {
                loading = false
            }
        }
    }

    // Search Funktionen - Now Async-First
    function genericSearch(text) {
        console.log("ASYNC: generic search", text)
        // Clear previous results immediately for instant feedback
        searchResults({tracks: [], albums: [], artists: [], playlists: []})
        
        return queueRequest("tidal.Tidaler.genericSearch", [text], function(result) {
            console.log("Search completed for:", text)
        })
    }

    function reInit() {
        console.log("Re-initializing Tidal session")
        pythonTidal.call('tidal.Tidaler.initialize', [])
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
//            console.log(name.title)
// imho this returny onyl track-info (the signal contains track-info and url but retval not)
/*            if(typeof name === 'undefined')
                console.log(typeof name)
            else
                console.log(typeof name)*/
        })
    }

    function getTrackInfo(id) {
        if (typeof id === 'string') {
            id = id.split('/').pop()
            id = id.replace(/[^0-9]/g, '')
        }
        console.log("JavaScript id after:", id, typeof id)

        var returnValue = null

        pythonTidal.call_sync("tidal.Tidaler.getTrackInfo", [id], function(result) {
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

    // Album Funktionen - Now Async-First
    function getAlbumTracks(id) {
        console.log("ASYNC: Get album tracks", id)
        return queueRequest("tidal.Tidaler.getAlbumTracks", [id], function(result) {
            console.log("Album tracks loaded for:", id)
        })
    }

    function getAlbumInfo(id) {
        pythonTidal.call("tidal.Tidaler.getAlbumInfo", [id])
    }

    function playAlbumTracks(id, startPlay) {
        var shouldPlay = startPlay === undefined ? true : startPlay
        pythonTidal.call("tidal.Tidaler.playAlbumTracks", [id,shouldPlay])
    }

    function playAlbumFromTrack(id) {
        pythonTidal.call("tidal.Tidaler.playAlbumfromTrack", [id])
    }

    function playArtistTracks(id, startPlay) {
        var shouldPlay = startPlay === undefined ? true : startPlay
        pythonTidal.call("tidal.Tidaler.playArtistTracks", [id, startPlay])
    }

    function playArtistRadio(id, startPlay) {
        var shouldPlay = startPlay === undefined ? true : startPlay
        pythonTidal.call("tidal.Tidaler.playArtistRadio", [id, startPlay])
    }

    // Artist Funktionen
    function getArtistInfo(id) {
        pythonTidal.call("tidal.Tidaler.getArtistInfo", [id])
    }

    // Playlist Funktionen
    function getPersonalPlaylists() {
        pythonTidal.call('tidal.Tidaler.getPersonalPlaylists', [])
        //pythonTidal.call('tidal.Tidaler.homepage', [])
    }

    function getHomepage() {
        pythonTidal.call('tidal.Tidaler.homepage', [])
    }

    function getDailyMixes() {
        pythonTidal.call('tidal.Tidaler.getDailyMixes', [])
    }

    function getRadioMixes() {
        pythonTidal.call('tidal.Tidaler.getRadioMixes', [])
    }

    function getTopArtists() {
        pythonTidal.call('tidal.Tidaler.getTopArtists', [])
    }

    function getPlaylistTracks(id) {
        pythonTidal.call('tidal.Tidaler.getPlaylistTracks', [id])
    }

    function playPlaylist(id, startPlay) {
        var shouldPlay = startPlay === undefined ? true : startPlay
        console.log("playPlaylist", id, shouldPlay)
        pythonTidal.call("tidal.Tidaler.playPlaylist", [id, shouldPlay])
    }

    function getMixTracks(id) {
        pythonTidal.call('tidal.Tidaler.getMixTracks', [id])
    }
    function playMix(id, startPlay) {
        var shouldPlay = startPlay === undefined ? true : startPlay
        console.log("playMix", id, shouldPlay)
        pythonTidal.call("tidal.Tidaler.playMix", [id, shouldPlay])
    }

    function getFavorites() {
        pythonTidal.call('tidal.Tidaler.get_favorite_tracks', [])
    }

    function getAlbumsofArtist(artistid) {
        pythonTidal.call('tidal.Tidaler.getAlbumsofArtist', [artistid])
    }

    function getTopTracksofArtist(artistid) {
        pythonTidal.call('tidal.Tidaler.getTopTracksofArtist', [artistid])
    }

    function getArtistRadio(artistid) {
        pythonTidal.call('tidal.Tidaler.getArtistRadio', [artistid])
    }

    function getSimiliarArtist(artistid) {
        pythonTidal.call('tidal.Tidaler.getSimiliarArtist', [artistid])
    }

    function getFavorits(artistid) {
        pythonTidal.call('tidal.Tidaler.getFavorits', [artistid])
    }
}


