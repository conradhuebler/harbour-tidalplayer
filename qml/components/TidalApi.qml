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
    
    // Claude Generated: Preload and crossfade signals
    signal preloadUrlReady(string trackId, string url)
    signal crossfadeUrlReady(string trackId, string url)
    

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

        onError: {
            // Handle PyOtherSide errors and show them in UI
            console.log("PyOtherSide Error:", traceback)
            
            // Convert traceback to string for parsing
            var errorStr = String(traceback || "")
            
            // Parse common error types and show user-friendly messages
            // Only show critical errors that require user action
            if (errorStr.indexOf("Not a callable: tidal.Tidaler.login") !== -1) {
                applicationWindow.showErrorNotification(
                    qsTr("Session Error"), 
                    qsTr("Please restart the app and log in again")
                )
            } else if (errorStr.indexOf("HTTPError: 401") !== -1) {
                applicationWindow.showErrorNotification(
                    qsTr("Authentication Error"), 
                    qsTr("Please log in again")
                )
                // Trigger logout
                authManager.clearTokens()
            } else if (errorStr.indexOf("HTTPError: 403") !== -1) {
                applicationWindow.showErrorNotification(
                    qsTr("Access Denied"), 
                    qsTr("This content is not available in your region or subscription")
                )
            } else if (errorStr.indexOf("requests.exceptions.ConnectionError") !== -1) {
                applicationWindow.showErrorNotification(
                    qsTr("Connection Error"), 
                    qsTr("Unable to connect to Tidal. Check your internet connection.")
                )
            } else if (errorStr.indexOf("HTTPError: 400 Client Error") !== -1) {
                // 400 errors can be temporary during session setup, so be less intrusive
                if (applicationWindow.settings.debugLevel >= 2) {
                    console.log("DEBUG: 400 API Error detected, but may be temporary during session setup")
                }
                // Only show if it's NOT during the critical session initialization period
                if (!sessionReinitTimer.running && loginTrue) {
                    applicationWindow.showErrorNotification(
                        qsTr("API Error"), 
                        qsTr("Tidal API request failed. This may be temporary - try again later.")
                    )
                }
            } else {
                // Generic errors - only show in debug mode and not during session setup
                if (applicationWindow.settings.debugLevel >= 2 && !sessionReinitTimer.running) {
                    console.log("DEBUG: Generic PyOtherSide error - may be harmless during session setup")
                }
            }
        }

        Component.onCompleted: {
            // DEBUG: TidalAPI initialization
            if (applicationWindow.settings.debugLevel >= 1) {
                console.log("TIDAL: Starting Python backend initialization...")
                console.log("TIDAL: Adding import path:", Qt.resolvedUrl('../'))
            }
            
            addImportPath(Qt.resolvedUrl('../'))
            
            // DEBUG: Module loading with error handling
            if (applicationWindow.settings.debugLevel >= 2) {
                console.log("TIDAL: Attempting to import tidal.py and dependencies...")
            }

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
                if (settings.debugLevel >= 3) {
                    console.log("AUTH: Got new token from session - type:", type, "token:", token, "rtoken:", rtoken, "expiry:", date)
                } else if (settings.debugLevel >= 1) {
                    console.log("AUTH: Got new token from session")
                }
                tidalApi.oAuthSuccess(type, token, rtoken, date)
            })

            setHandler('oauth_refresh', function(token, rtoken, expiry) {
                if (settings.debugLevel >= 3) {
                    console.log("AUTH: Got refreshed token - token:", token, "rtoken:", rtoken, "expiry:", expiry)
                } else if (settings.debugLevel >= 1) {
                    console.log("AUTH: Got refreshed token from session")
                }
                tidalApi.oAuthRefresh(token)
                // Update AuthManager with all token info
                authManager.refreshTokens(token, rtoken, expiry)
                
                // Note: Session reinitialization after token refresh may not be necessary
                // The existing session should continue working with the refreshed tokens
            })

            // Enhanced Debug Handlers - synchronized with Python debug levels
            setHandler('printConsole', function(string) {
                if (settings.debugLevel >= 2) {
                    console.log("TIDAL: " + string)
                }
            })
            
            // Python debug level handlers
            setHandler('pythonDebugNormal', function(message) {
                if (applicationWindow.settings.debugLevel >= 1) {
                    console.log(message)
                }
            })
            
            setHandler('pythonDebugInfo', function(message) {
                if (applicationWindow.settings.debugLevel >= 2) {
                    console.log(message)
                }
            })
            
            setHandler('pythonDebugVerbose', function(message) {
                if (applicationWindow.settings.debugLevel >= 3) {
                    console.log(message)
                }
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
                console.log("TidalApi: playback_info received - preload:", root.pendingPreloadId, "crossfade:", root.pendingCrossfadeId)
                if (applicationWindow.settings.debugLevel >= 1) {
                        if (info.url) {
                        var urlStr = String(info.url)
                        var hasToken = urlStr.indexOf('token') !== -1
                        var safeUrl = hasToken ? urlStr.split('?')[0] + "?token=***" : urlStr
                        console.log("TIDAL: URL received:", safeUrl.substring(0, 100) + "...")
                    } else {
                        console.log("TIDAL: URL received: NO URL")
                    }
                    console.log("TidalApi: Track info:", info.track ? JSON.stringify(info.track).substring(0, 200) + "..." : "NO TRACK")
                    
                    // Additional debug for 403 investigation
                    if (info.url) {
                        var urlStr = String(info.url)
                        var urlParts = urlStr.split('?')
                        console.log("TidalApi: Base URL:", urlParts[0])
                        if (urlParts.length > 1) {
                            var queryStr = String(urlParts[1])
                            console.log("TidalApi: Has query params:", queryStr.length > 0 ? "YES" : "NO")
                            // Check for token-like parameters
                            var hasToken = queryStr.indexOf('token') !== -1 || queryStr.indexOf('Token') !== -1 || queryStr.indexOf('TOKEN') !== -1
                            console.log("TidalApi: Has token param:", hasToken ? "YES" : "NO")
                            if (applicationWindow.settings.debugLevel >= 2) {
                                console.log("TidalApi: Query params:", queryStr.substring(0, 50) + "...")
                            }
                        }
                    }
                    
                    if (info.track) {
                        console.log("TidalApi: Track ID:", info.track.id || info.track.trackid || "UNKNOWN")
                        console.log("TidalApi: Track title:", info.track.title || "UNKNOWN")
                    }
                }
                
                // Get track ID (could be either .id or .trackid)
                var trackId = info.track.id || info.track.trackid
                
                // Check if this is a preload request
                if (root.pendingPreloadId && trackId && trackId.toString() === root.pendingPreloadId.toString()) {
                    console.log("TidalApi: Processing preload response for track", trackId)
                    
                    // Cache URL for preload too (only if enabled)
                    if (applicationWindow.settings.enableUrlCaching && trackId && info.url) {
                        cacheManager.cacheTrackUrl(trackId.toString(), info.url)
                    }
                    
                    // Emit preload signal instead of normal playback
                    preloadUrlReady(trackId.toString(), info.url)
                    root.pendingPreloadId = "" // Clear the flag
                    return
                }
                
                // Check if this is a crossfade request
                if (root.pendingCrossfadeId && trackId && trackId.toString() === root.pendingCrossfadeId.toString()) {
                    console.log("TidalApi: Processing crossfade response for track", trackId)
                    
                    // Cache URL for crossfade too (only if enabled)
                    if (applicationWindow.settings.enableUrlCaching && trackId && info.url) {
                        cacheManager.cacheTrackUrl(trackId.toString(), info.url)
                    }
                    
                    // Emit crossfade signal instead of normal playback
                    crossfadeUrlReady(trackId.toString(), info.url)
                    root.pendingCrossfadeId = "" // Clear the flag
                    return
                }
                
                // Normal playback handling
                if (applicationWindow.settings.debugLevel >= 1) {
                    console.log("TidalApi: Processing normal playback for track", trackId, "timestamp:", Date.now())
                }
                
                // Cache URL before playing (only if enabled)
                if (applicationWindow.settings.enableUrlCaching && trackId && info.url) {
                    cacheManager.cacheTrackUrl(trackId.toString(), info.url)
                }
                
                mediaController.playUrl(info.url)
                currentPlayback(info.track)
                tidalApi.current_track_title = info.track.title
                tidalApi.current_track_artist = info.track.artist
                tidalApi.current_track_album = info.track.album
                tidalApi.current_track_image = info.track.image
                
                // Reset deduplication flag when track successfully starts
                tidalApi.trackPlayInProgress = false
                trackPlayTimeoutTimer.stop()
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
                if (settings.debugLevel >= 3) {
                    console.log("TIDAL: topArtist data:", artist_info)
                } else if (settings.debugLevel >= 2) {
                    console.log("TIDAL: topArtist received:", artist_info ? "data" : "no data")
                }
                root.topArtist(artist_info)
            })

            // Import Python module with detailed error handling  
            if (applicationWindow.settings.debugLevel >= 1) {
                console.log("TIDAL: Importing tidal.py module...")
                console.log("TIDAL: Debug level synchronization:", applicationWindow.settings.debugLevel)
            }
            
            importModule('tidal', function() {
                if (applicationWindow.settings.debugLevel >= 1) {
                    console.log("TIDAL: ✓ Python module 'tidal' imported successfully")
                    console.log("TIDAL: Python backend is ready for API calls")
                    console.log("TIDAL: Python debug output should now be filtered by QML debug level")
                }
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
        if (applicationWindow.settings.debugLevel >= 3) {
            console.log("OAuth Success - type:", type, "token:", token, "rtoken:", rtoken, "date:", date)
        } else if (applicationWindow.settings.debugLevel >= 1) {
            console.log("OAuth Success - type:", type, "token length:", token.length, "rtoken length:", rtoken.length, "date:", date)
        }
        authManager.updateTokens(type, token, rtoken, date)
        loginSuccess()
    }

    onLoginSuccess: {
        loginTrue = true
        
        // Add current email to history
        if (applicationWindow.settings.mail && applicationWindow.settings.mail !== "") {
            applicationWindow.settings.addEmailToHistory(applicationWindow.settings.mail)
        }
        
        // CRITICAL: Ensure Python session is ready after successful login
        if (applicationWindow.settings.debugLevel >= 1) {
            console.log("LOGIN: Forcing Python session reinitialization after successful login")
        }
        // Force full reinitialization to ensure session works properly
        sessionReinitTimer.start()
        
        // Show login success notification and switch to main page
        applicationWindow.showSuccessNotification(qsTr("Login Successful"), qsTr("Successfully logged in to Tidal"))
        applicationWindow.switchToMainPage()
    }

    onLoginFailed: {
        loginTrue = false
        if (authManager) {
            authManager.clearTokens()
        }
        
        // Show login failure notification
        applicationWindow.showErrorNotification(qsTr("Login Failed"), qsTr("Unable to authenticate with Tidal. Please check your credentials."))
    }


    // Login Funktionen
    function getOAuth() {
        console.log("Request new login")
        pythonTidal.call('tidal.Tidaler.initialize', [quality])
        pythonTidal.call('tidal.Tidaler.request_oauth', [])
    }

    function loginIn(tokenType, accessToken, refreshToken, expiryTime) {
        if (settings.debugLevel >= 3) {
            console.log("AUTH: loginIn token (VERBOSE):", accessToken)
        } else if (settings.debugLevel >= 1) {
            console.log("AUTH: loginIn with token (length:", accessToken.length, "chars)")
        }
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
                // Use timer to call callback asynchronously (Qt.callLater not available in older Qt versions)
                var callbackTimer = Qt.createQmlObject(
                    "import QtQuick 2.0; Timer { interval: 1; repeat: false }",
                    tidalApi, "callbackTimer"
                )
                callbackTimer.triggered.connect(function() {
                    callback(cachedResult)
                    callbackTimer.destroy()
                })
                callbackTimer.start()
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
        // Check authentication before allowing search
        if (!isAuthenticated()) {
            if (applicationWindow.settings.debugLevel >= 1) {
                console.log("TidalApi: Cannot search - not authenticated")
            }
            applicationWindow.showWarningNotification(qsTr("Login Required"), qsTr("Please log in to search music"))
            return false
        }
        
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
        return true
    }

    // WORKAROUND: Track play deduplication 
    // TODO: Find root cause of duplicate playTrackId() calls
    // Symptoms: Same track ID called twice in rapid succession, causing:
    // - Double API requests to Python backend
    // - Double URL loading and MediaHandler calls  
    // - Slower track loading performance
    property string lastPlayedTrackId: ""
    property bool trackPlayInProgress: false
    
    // Check if user is authenticated for API operations
    function isAuthenticated() {
        return applicationWindow.settings.access_token && 
               applicationWindow.settings.refresh_token &&
               applicationWindow.settings.access_token !== "" &&
               applicationWindow.settings.refresh_token !== "" &&
               loginTrue
    }
    
    // Fallback timer to reset deduplication flag
    Timer {
        id: trackPlayTimeoutTimer
        interval: 5000  // 5 seconds
        repeat: false
        onTriggered: {
            console.log("TidalApi: Resetting trackPlayInProgress flag (timeout)")
            trackPlayInProgress = false
        }
    }
    
    // Timer for delayed session reinitialization after login
    Timer {
        id: sessionReinitTimer
        interval: 2000  // Wait 2 seconds for login to fully settle
        repeat: false
        onTriggered: {
            if (applicationWindow.settings.debugLevel >= 1) {
                console.log("LOGIN: Executing forced Python session reinitialization")
            }
            // Force full reinitialization to ensure session works properly
            pythonTidal.call('tidal.Tidaler.initialize', [applicationWindow.settings.audio_quality], function() {
                if (applicationWindow.settings.debugLevel >= 1) {
                    console.log("LOGIN: Session reinitialization completed")
                }
            })
        }
    }
    
    // Track Funktionen
    function playTrackId(id) {
        if (applicationWindow.settings.debugLevel >= 1) {
            console.log("TidalApi.playTrackId called with:", id)
        }
        
        // Check authentication before allowing track playback
        if (!isAuthenticated()) {
            if (applicationWindow.settings.debugLevel >= 1) {
                console.log("TidalApi: Cannot play track - not authenticated")
            }
            applicationWindow.showWarningNotification(qsTr("Login Required"), qsTr("Please log in to play music"))
            return false
        }
        
        // WORKAROUND: Prevent duplicate plays for same track
        // TODO: This shouldn't be necessary - find why playTrackId is called twice
        if (id === lastPlayedTrackId && trackPlayInProgress) {
            if (applicationWindow.settings.debugLevel >= 1) {
                console.log("TidalApi: WORKAROUND - Ignoring duplicate playTrackId call for", id, "(already in progress)")
            }
            return false
        }
        
        // Check for cached URL first - fast path! (only if enabled)
        if (applicationWindow.settings.enableUrlCaching) {
            var cachedUrl = cacheManager.getCachedUrlWithToken(id.toString(), applicationWindow.settings.access_token)
            if (cachedUrl) {
                if (applicationWindow.settings.debugLevel >= 1) {
                    console.log("TidalApi: Using cached URL for track", id, "- skipping API call!")
                }
                
                // Get track info from cache
                var trackInfo = cacheManager.getTrackInfo(id)
                if (trackInfo) {
                    // Play directly from cache
                    mediaController.playUrl(cachedUrl)
                    currentPlayback(trackInfo)
                    tidalApi.current_track_title = trackInfo.title || ""
                    tidalApi.current_track_artist = trackInfo.artist || ""
                    tidalApi.current_track_album = trackInfo.album || ""
                    tidalApi.current_track_image = trackInfo.image || ""
                    
                    lastPlayedTrackId = id
                    trackPlayInProgress = false
                    return
                }
            }
        }
        
        // Fallback to API if not cached
        if (applicationWindow.settings.debugLevel >= 1) {
            console.log("TidalApi: No cached URL found, requesting from API")
        }
        lastPlayedTrackId = id
        trackPlayInProgress = true
        
        // Fallback: Reset flag after 5 seconds if no playback_info received
        trackPlayTimeoutTimer.restart()
        
        if (applicationWindow.settings.debugLevel >= 1) {
            console.log("TidalApi: Calling Python backend for track URL:", id)
        }
        
        pythonTidal.call("tidal.Tidaler.getTrackUrl", [id], function(name) {
            if (applicationWindow.settings.debugLevel >= 2) {
                console.log("TidalApi: Python callback received for track", id, "result type:", typeof name)
            }
        })
    }

    // Claude Generated: Track URL fetching for preloading
    function getTrackUrlForPreload(id) {
        console.log("TidalApi.getTrackUrlForPreload called with:", id)
        
        // Set a flag to indicate this is a preload request
        root.pendingPreloadId = id.toString()
        console.log("TidalApi: Set pendingPreloadId to:", root.pendingPreloadId)
        
        pythonTidal.call("tidal.Tidaler.getTrackUrl", [id], function(result) {
            console.log("TidalApi: Preload URL received for track", id)
        })
    }
    
    // Claude Generated: Track URL fetching for crossfade
    function getTrackUrlForCrossfade(id) {
        console.log("TidalApi.getTrackUrlForCrossfade called with:", id)
        
        // Set a flag to indicate this is a crossfade request
        root.pendingCrossfadeId = id.toString()
        console.log("TidalApi: Set pendingCrossfadeId to:", root.pendingCrossfadeId)
        
        pythonTidal.call("tidal.Tidaler.getTrackUrl", [id], function(result) {
            console.log("TidalApi: Crossfade URL received for track", id)
        })
    }
    
    // Claude Generated: Track request tracking
    property string pendingPreloadId: ""
    property string pendingCrossfadeId: ""

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

    // Album Funktionen - Back to simple approach
    function getAlbumTracks(id) {
        console.log("Get album tracks", id)
        pythonTidal.call("tidal.Tidaler.getAlbumTracks", [id])
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


