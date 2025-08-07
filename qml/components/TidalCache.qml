import QtQuick 2.0
import QtQuick.LocalStorage 2.0

Item {
id: root
    // PERFORMANCE: LRU Cache Implementation - prevents memory leaks
    property int maxCacheSize: 1000           // Max items per cache type
    property int maxCacheAge: 24 * 3600000    // Max age in milliseconds
    property int urlCacheAge: 10 * 60 * 1000  // URLs expire after 10 minutes
    
    // Cache objects with LRU tracking
    property var trackCache: ({})
    property var albumCache: ({})
    property var artistCache: ({})
    property var playlistCache: ({})
    property var mixCache: ({})
    
    // URL cache for fast track loading (without tokens)
    property var urlCache: ({})
    
    // LRU access order tracking (most recent first)
    property var trackAccessOrder: []
    property var albumAccessOrder: []
    property var artistAccessOrder: []
    property var playlistAccessOrder: []
    property var mixAccessOrder: []
    property var urlAccessOrder: []
    
    property var db
    
    // PERFORMANCE: Database batching properties
    property var pendingWrites: []
    property bool batchWriteInProgress: false
    property int batchSize: 50           // Process 50 writes per batch
    property int batchTimeout: 2000      // Batch timeout in milliseconds
    
    // PERFORMANCE: Incremental cleanup properties
    property bool cleanupInProgress: false
    property int cleanupBatchSize: 25    // Clean 25 entries per batch
    property var cleanupQueue: []        // Queue of cleanup operations

    // PERFORMANCE: LRU Cache Management Functions
    function addToLRU(cache, accessOrder, key, value) {
        // Remove from current position if exists
        var index = accessOrder.indexOf(key)
        if (index > -1) {
            accessOrder.splice(index, 1)
        }
        
        // Add to front (most recent)
        accessOrder.unshift(key)
        cache[key] = value
        
        // Enforce size limit
        while (accessOrder.length > maxCacheSize) {
            var oldestKey = accessOrder.pop()
            delete cache[oldestKey]
            console.log("LRU: Evicted cache entry:", oldestKey)
        }
    }
    
    function touchLRU(accessOrder, key) {
        // Move accessed item to front
        var index = accessOrder.indexOf(key)
        if (index > -1) {
            accessOrder.splice(index, 1)
            accessOrder.unshift(key)
        }
    }
    

    // PERFORMANCE: Cache stats logging timer
    Timer {
        interval: 300000  // 5 minutes
        running: true
        repeat: true
        onTriggered: {
            var stats = getCacheStats()
            console.log("Cache stats:", JSON.stringify(stats))
            
            // PERFORMANCE: Trigger incremental cleanup if cache gets large
            if (stats.total > maxCacheSize * 3) {
                console.log("Cache getting large, starting incremental cleanup...")
                startIncrementalCleanup()
            }
        }
    }
    
    // PERFORMANCE: Database batch write timer
    Timer {
        id: batchWriteTimer
        interval: batchTimeout
        running: false
        repeat: false
        onTriggered: {
            if (pendingWrites.length > 0) {
                processBatchWrites()
            }
        }
    }
    
    // PERFORMANCE: Incremental cleanup timer
    Timer {
        id: incrementalCleanupTimer
        interval: 100  // 100ms between cleanup batches
        running: false
        repeat: true
        onTriggered: {
            if (cleanupQueue.length === 0) {
                running = false
                cleanupInProgress = false
                console.log("PERFORMANCE: Incremental cleanup completed")
                return
            }
            
            processCleanupBatch()
        }
    }

    // PERFORMANCE: Database batch processing functions
    function queueWrite(table, data) {
        pendingWrites.push({
            table: table,
            data: data,
            timestamp: Date.now()
        })
        
        // Start batch timer if not running
        if (!batchWriteTimer.running) {
            batchWriteTimer.start()
        }
        
        // Process immediately if batch is full
        if (pendingWrites.length >= batchSize) {
            batchWriteTimer.stop()
            processBatchWrites()
        }
    }
    
    function processBatchWrites() {
        if (batchWriteInProgress || pendingWrites.length === 0) return
        
        batchWriteInProgress = true
        var writesToProcess = pendingWrites.splice(0, batchSize)
        
        console.log("PERFORMANCE: Processing", writesToProcess.length, "database writes in batch")
        
        db.transaction(function(tx) {
            for (var i = 0; i < writesToProcess.length; i++) {
                var write = writesToProcess[i]
                try {
                    // Extract correct ID field based on table
                    var id = write.data.trackid || write.data.albumid || write.data.artistid || 
                             write.data.playlistid || write.data.mixid || write.data.trackId
                    tx.executeSql('INSERT OR REPLACE INTO ' + write.table + '(id, data, timestamp) VALUES(?, ?, ?)',
                        [id, JSON.stringify(write.data), write.timestamp])
                } catch (e) {
                    console.error("Batch write error:", e, "for table:", write.table)
                }
            }
        })
        
        batchWriteInProgress = false
        
        // Process remaining writes if any
        if (pendingWrites.length > 0) {
            batchWriteTimer.start()
        }
    }
    
    // PERFORMANCE: Incremental cleanup functions
    function startIncrementalCleanup() {
        if (cleanupInProgress) {
            console.log("PERFORMANCE: Cleanup already in progress, skipping")
            return
        }
        
        console.log("PERFORMANCE: Starting incremental cache cleanup")
        cleanupInProgress = true
        cleanupQueue = []
        
        // Queue all cache types for cleanup
        var cacheTypes = [
            {name: 'tracks', cache: trackCache, accessOrder: trackAccessOrder},
            {name: 'albums', cache: albumCache, accessOrder: albumAccessOrder},
            {name: 'artists', cache: artistCache, accessOrder: artistAccessOrder},
            {name: 'playlists', cache: playlistCache, accessOrder: playlistAccessOrder},
            {name: 'mixes', cache: mixCache, accessOrder: mixAccessOrder},
            {name: 'urls', cache: urlCache, accessOrder: urlAccessOrder}
        ]
        
        for (var i = 0; i < cacheTypes.length; i++) {
            var cacheType = cacheTypes[i]
            var keys = Object.keys(cacheType.cache)
            
            // Split keys into batches
            for (var j = 0; j < keys.length; j += cleanupBatchSize) {
                var batch = keys.slice(j, j + cleanupBatchSize)
                cleanupQueue.push({
                    type: cacheType.name,
                    cache: cacheType.cache,
                    accessOrder: cacheType.accessOrder,
                    keys: batch
                })
            }
        }
        
        incrementalCleanupTimer.start()
    }
    
    function processCleanupBatch() {
        if (cleanupQueue.length === 0) return
        
        var batch = cleanupQueue.shift()
        var now = Date.now()
        var expiredKeys = []
        
        // Check which keys are expired
        for (var i = 0; i < batch.keys.length; i++) {
            var key = batch.keys[i]
            var item = batch.cache[key]
            if (item && (now - item.timestamp) > maxCacheAge) {
                expiredKeys.push(key)
            }
        }
        
        if (expiredKeys.length > 0) {
            console.log("PERFORMANCE: Cleaning", expiredKeys.length, "expired", batch.type, "entries")
            
            // Remove from cache and access order
            for (var j = 0; j < expiredKeys.length; j++) {
                var expiredKey = expiredKeys[j]
                delete batch.cache[expiredKey]
                
                var orderIndex = batch.accessOrder.indexOf(expiredKey)
                if (orderIndex > -1) {
                    batch.accessOrder.splice(orderIndex, 1)
                }
            }
            
            // Queue database cleanup
            queueDatabaseCleanup(batch.type, expiredKeys)
        }
    }
    
    function queueDatabaseCleanup(tableName, expiredKeys) {
        // Use batch write system for database cleanup
        for (var i = 0; i < expiredKeys.length; i++) {
            queueWrite(tableName + '_delete', {
                id: expiredKeys[i],
                operation: 'DELETE'
            })
        }
    }

    Component.onCompleted: {
        initDatabase()
        loadCache()
        
        // Log initial cache stats
        console.log("TidalCache initialized with LRU + DB batching, max size per type:", maxCacheSize)
    }

    // Verbindungen zu den Python-Signalen
 Connections {
        target: tidalApi
        // Neue Connections für Suchergebnisse

        onCacheTrack: {
            //track_info
            if (track_info == undefined) {
                console.error("track_info is undefined. skipping save")
                return;
            }            
            saveTrackToCache({
                trackid: track_info.trackid,
                title: track_info.title,
                artist: track_info.artist,
                artistid:track_info.artistid,
                album: track_info.album,
                albumid: track_info.albumid,
                duration: track_info.duration,
                image: track_info.image,
                track_num : track_info.track_num,
                timestamp: Date.now(),
                fromSearch: true  // Optional: markiert Einträge aus der Suche
            })
        }

        onCacheArtist: {
            //artist_info
            if (artist_info == undefined) {
                console.error("artist_info is undefined. skipping save")
                return;
            }            
            saveArtistToCache({
                artistid: artist_info.artistid,
                name: artist_info.name,
                image: artist_info.image,
                bio: artist_info.bio,
                timestamp: Date.now(),
                fromSearch: true  // Optional: markiert Einträge aus der Suche
            })
        }

        onCacheAlbum: {
            //album_info
            if (album_info == undefined) {
                console.error("album_info is undefined. skipping save")
                return;
            } 
            saveAlbumToCache({
                albumid: album_info.albumid,
                title: album_info.title,
                artist: album_info.artist,
                artistid: album_info.artistid,
                image: album_info.image,
                duration: album_info.duration,
                num_tracks : album_info.num_tracks,
                year : album_info.year,
                timestamp: Date.now(),
                fromSearch: true  // Optional: markiert Einträge aus der Suche
            })
        }

        onCachePlaylist: {
            //playlist_info
            if (playlist_info == undefined) {
                console.error("playlist_info is undefined. skipping save")
                return;
            }            
            savePlaylistToCache({
                playlistid: playlist_info.playlistid,
                title: playlist_info.title,
                image: playlist_info.image,
                duration: playlist_info.duration,
                timestamp: Date.now(),
                fromSearch: true  // Optional: markiert Einträge aus der Suche
            })
        }

        onCacheMix: {
            //mix_info
            if (mix_info == undefined) {
                console.error("mix_info is undefined. skipping save")
                return;
            }            
            saveMixToCache({
                mixid: mix_info.mixid,
                title: mix_info.title,
                artist: mix_info.artist,
                artistid:mix_info.artistid,
                album: mix_info.album,
                albumid: mix_info.albumid,
                duration: mix_info.duration,
                image: mix_info.image,
                track_num : mix_info.track_num,
                timestamp: Date.now(),
                fromSearch: true  // Optional: markiert Einträge aus der Suche
            })
        }
        
    }

    // Optional: Erweiterte Such-spezifische Funktionen
    property var searchResults: ({
        tracks: [],
        albums: [],
        artists: [],
        playlists: [],
        mixes: []
    })

    // Suchergebnisse zwischenspeichern
    function clearSearchResults() {
        searchResults.tracks = []
        searchResults.albums = []
        searchResults.artists = []
        searchResults.playlists = []
        searchResults.mixes = []
    }

    function addSearchTrack(id) {
        if (!searchResults.tracks.includes(id)) {
            searchResults.tracks.push(id)
        }
    }

    function addSearchAlbum(id) {
        if (!searchResults.albums.includes(id)) {
            searchResults.albums.push(id)
        }
    }

    function addSearchArtist(id) {
        if (!searchResults.artists.includes(id)) {
            searchResults.artists.push(id)
        }
    }

    // Getter für Suchergebnisse
    function getSearchTracks() {
        return searchResults.tracks.map(function(id) {
            return getTrack(id);
        }).filter(function(t) {
            return t !== null;
        });
    }

    function getSearchAlbums() {
        return searchResults.albums.map(function(id) {
            return getAlbum(id);
        }).filter(function(a) {
            return a !== null;
        });
    }

    function getSearchArtists() {
        return searchResults.artists.map(function(id) {
            return getArtist(id);
        }).filter(function(a) {
            return a !== null;
        });
    }

    // Track-Info abrufen (entweder aus Cache oder von Python)
    function getTrackInfo(id) {
        // Erst im Cache nachsehen
        var cachedTrack = getTrack(id)
        if (cachedTrack) {
            if (Date.now() - cachedTrack.timestamp < maxCacheAge) {
                return cachedTrack
            } else {
                console.log("Cache entry too old, refreshing...")
            }
        }

        // Wenn nicht im Cache oder zu alt, von Python holen

        var result = tidalApi.getTrackInfo(id)
        if (result) {
            var trackData = {
                trackid: id,
                albumid: result.albumid,
                artistid: result.artistid,
                title: result.title,
                artist: result.artist,
                album: result.album,
                duration: result.duration,
                timestamp: Date.now()
            }

            saveTrackToCache(trackData)
            return trackData
        }

        return null
    }

    function getAlbumInfo(id) {
        // Erst im Cache nachsehen
        var cachedTrack = getAlbum(id)
        if (cachedTrack) {
            if (Date.now() - cachedTrack.timestamp < maxCacheAge) {
                return cachedTrack
            } else {
                console.log("Cache entry too old, refreshing...")
            }
        }

        // Wenn nicht im Cache oder zu alt, von Python holen

        var result = tidalApi.getAlbumInfo(id)
        if (result) {
            var albumData = {
                albumid: result.albumid,
                title: result.title,
                artist: result.artist,
                artistid: result.artistid,
                image: result.image,
                duration: result.duration,
                num_tracks : result.num_tracks,
                year : result.year,
                timestamp: Date.now()
            }
            console.log("album not in cache, adding to cache ... (i think this causes the nulls, as it should be synchr.) ", result)
            saveAlbumToCache(albumData)
            return albumData
        }

        return null
    }

    function getArtistInfo(id) {
        // Erst im Cache nachsehen
        var cachedTrack = getArtist(id)
        if (cachedTrack) {
            if (Date.now() - cachedTrack.timestamp < maxCacheAge) {
                return cachedTrack
            } else {
                console.log("Cache entry too old, refreshing...")
            }
        }

        // Wenn nicht im Cache oder zu alt, von Python holen

        var result = tidalApi.getArtistInfo(id)
        if (result) {
            var artistData = {
                artistid: result.artistid,
                name: result.name,
                image: result.image,
                bio: result.bio,
                timestamp: Date.now(),
            }
            console.log("Adding to cache ...")

            saveArtistToCache(artistData)
            return artistData
        }

        return null
    }

    function getPlaylistInfo(id) {
        // Erst im Cache nachsehen
        var cachedTrack = getPlaylist(id)
        if (cachedTrack) {
            if (Date.now() - cachedTrack.timestamp < maxCacheAge) {
                return cachedTrack
            } else {
                console.log("Cache entry too old, refreshing...")
            }
        }

        // Wenn nicht im Cache oder zu alt, von Python holen

        var result = tidalApi.getPlaylistInfo(id)
        if (result) {
            var playlistData = {
                playlistid: result.playlistid,
                title: result.title,
                image: result.image,
                duration: result.duration,
                timestamp: Date.now()
            }
            console.log("Adding to cache ...")

            savePlaylistToCache(playlistData)
            return playlistData
        }

        return null
    }

    function getMixInfo(id) {
        // Erst im Cache nachsehen
        var cachedTrack = getMix(id)
        if (cachedTrack) {
            if (Date.now() - cachedTrack.timestamp < maxCacheAge) {
                return cachedTrack
            } else {
                console.log("Cache entry too old, refreshing...")
            }
        }

        // Wenn nicht im Cache oder zu alt, von Python holen

        var result = tidalApi.getMixInfo(id)
        if (result) {
            var mixData = {
                mixid: result.mixid,
                title: result.title,
                artist: result.artist,
                artistid: result.artistid,
                album: result.album,
                albumid: result.albumid,
                duration: result.duration,
                timestamp: Date.now()
            }
            console.log("Adding to cache ...")

            saveMixToCache(mixData)
            return mixData
        }

        return null
    }

    // Datenbank initialisieren
    function initDatabase() {
        db = LocalStorage.openDatabaseSync("TidalCache", "1.2", "Cache for Tidal data", 1000000)
        db.transaction(function(tx) {
            // Tracks Tabelle
            tx.executeSql('CREATE TABLE IF NOT EXISTS tracks(id TEXT PRIMARY KEY, data TEXT, timestamp INTEGER)')
            tx.executeSql('CREATE INDEX IF NOT EXISTS tracks_timestamp_idx ON tracks(timestamp)')


            tx.executeSql('CREATE TABLE IF NOT EXISTS albums(id TEXT PRIMARY KEY, data TEXT, timestamp INTEGER)')
            tx.executeSql('CREATE INDEX IF NOT EXISTS albums_timestamp_idx ON albums(timestamp)')

            // Artists Tabelle
            tx.executeSql('CREATE TABLE IF NOT EXISTS artists(id TEXT PRIMARY KEY, data TEXT, timestamp INTEGER)')
            tx.executeSql('CREATE INDEX IF NOT EXISTS artists_timestamp_idx ON artists(timestamp)')
        
            // Playlists Tabelle
            tx.executeSql('CREATE TABLE IF NOT EXISTS playlists(id TEXT PRIMARY KEY, data TEXT, timestamp INTEGER)') 
            tx.executeSql('CREATE INDEX IF NOT EXISTS playlists_timestamp_idx ON playlists(timestamp)')
            
            // Mixes Tabelle
            tx.executeSql('CREATE TABLE IF NOT EXISTS mixes(id TEXT PRIMARY KEY, data TEXT, timestamp INTEGER)')
            tx.executeSql('CREATE INDEX IF NOT EXISTS mixes_timestamp_idx ON mixes(timestamp)')
            
            // URLs Tabelle (for caching clean URLs without tokens)
            tx.executeSql('CREATE TABLE IF NOT EXISTS urls(id TEXT PRIMARY KEY, data TEXT, timestamp INTEGER)')
            tx.executeSql('CREATE INDEX IF NOT EXISTS urls_timestamp_idx ON urls(timestamp)')
            
        })
    }

    // Cache aus DB laden
    function loadCache() {
        db.transaction(function(tx) {
            // Tracks laden
            var rs = tx.executeSql('SELECT * FROM tracks')
            for(var i = 0; i < rs.rows.length; i++) {
                try {
                    trackCache[rs.rows.item(i).id] = JSON.parse(rs.rows.item(i).data)
                } catch(e) {
                    console.error("Error parsing track data:", e)
                }
            }

            // Albums laden
            rs = tx.executeSql('SELECT * FROM albums')
            for(i = 0; i < rs.rows.length; i++) {
                try {
                    albumCache[rs.rows.item(i).id] = JSON.parse(rs.rows.item(i).data)
                } catch(e) {
                    console.error("Error parsing album data:", e)
                }
            }

            // Artists laden
            rs = tx.executeSql('SELECT * FROM artists')
            for(i = 0; i < rs.rows.length; i++) {
                try {
                    artistCache[rs.rows.item(i).id] = JSON.parse(rs.rows.item(i).data)
                    //console.log(artistCache[rs.rows.item(i).id].artistid, artistCache[rs.rows.item(i).id].name)
                } catch(e) {
                    console.error("Error parsing artist data:", e)
                }
            }
            
            // URLs laden
            rs = tx.executeSql('SELECT * FROM urls')
            for(i = 0; i < rs.rows.length; i++) {
                try {
                    urlCache[rs.rows.item(i).id] = JSON.parse(rs.rows.item(i).data)
                } catch(e) {
                    console.error("Error parsing URL data:", e)
                }
            }
        })
        cleanOldCache()
    }

    // Cache-Speicherfunktionen - Now with Database Batching
    function saveTrackToCache(trackData) {
        // PERFORMANCE: Use LRU cache instead of unlimited growth
        addToLRU(trackCache, trackAccessOrder, trackData.trackid, trackData)
        
        // PERFORMANCE: Queue write instead of immediate transaction
        queueWrite('tracks', trackData)
    }

    function saveAlbumToCache(albumData) {
        // PERFORMANCE: Use LRU cache
        addToLRU(albumCache, albumAccessOrder, albumData.albumid, albumData)
        
        // PERFORMANCE: Queue write instead of immediate transaction
        queueWrite('albums', albumData)
    }

    function saveArtistToCache(artistData) {
        // PERFORMANCE: Use LRU cache
        addToLRU(artistCache, artistAccessOrder, artistData.artistid, artistData)
        
        // PERFORMANCE: Queue write instead of immediate transaction
        queueWrite('artists', artistData)
    }

    function savePlaylistToCache(playlistData) {
        // PERFORMANCE: Use LRU cache
        addToLRU(playlistCache, playlistAccessOrder, playlistData.playlistid, playlistData)
        
        // PERFORMANCE: Queue write instead of immediate transaction
        queueWrite('playlists', playlistData)
    }

    function saveMixToCache(mixData) {
        // PERFORMANCE: Use LRU cache
        addToLRU(mixCache, mixAccessOrder, mixData.mixid, mixData)
        
        // PERFORMANCE: Queue write instead of immediate transaction
        queueWrite('mixes', mixData)
    }

    // Getter-Funktionen with LRU touch
    function getTrack(id) {
        var track = trackCache[id] || null
        if (track) {
            // PERFORMANCE: Update LRU access order
            touchLRU(trackAccessOrder, id)
            
            // Debug: Check what URL is stored
            if (applicationWindow.settings.debugLevel >= 2 && track.url) {
                console.log("TidalCache: getTrack", id, "returning URL:", track.url.substring(0, 80) + "...")
                console.log("TidalCache: getTrack URL has token:", track.url.indexOf('token') !== -1 ? "YES" : "NO")
            }
        }
        return track
    }

    function getAlbum(id) {
        var album = albumCache[id] || null
        if (album) {
            touchLRU(albumAccessOrder, id)
        }
        return album
    }

    function getArtist(id) {
        var artist = artistCache[id] || null
        if (artist) {
            touchLRU(artistAccessOrder, id)
        }
        return artist
    }

    function getPlaylist(id) {
        var playlist = playlistCache[id] || null
        if (playlist) {
            touchLRU(playlistAccessOrder, id)
        }
        return playlist
    }

    function getMix(id) {
        var mix = mixCache[id] || null
        if (mix) {
            touchLRU(mixAccessOrder, id)
        }
        return mix
    }
    
    // URL parsing and caching functions
    function stripTokenFromUrl(url) {
        if (!url) return url
        
        // Remove everything after the first '?' (including token parameters)
        var questionIndex = url.indexOf('?')
        if (questionIndex !== -1) {
            return url.substring(0, questionIndex)
        }
        
        return url
    }
    
    function cacheUrl(trackId, fullUrl) {
        if (!trackId || !fullUrl) return
        
        // Cache FULL URL for short-term use (10 minutes)
        // Don't strip tokens - we need the working URL
        var urlData = {
            trackId: trackId,
            url: fullUrl,  // Full URL with token
            timestamp: Date.now()
        }
        
        // Use LRU cache for URLs (in-memory only, don't persist tokens to disk)
        addToLRU(urlCache, urlAccessOrder, trackId, urlData)
        
        // DO NOT write to database - URLs with tokens should not be persisted
        
        if (applicationWindow.settings.debugLevel >= 2) {
            console.log("TidalCache: Full URL cached for track", trackId, "(10min TTL)")
        }
    }
    
    function getCachedUrl(trackId) {
        var urlData = urlCache[trackId]
        if (urlData && (Date.now() - urlData.timestamp) < urlCacheAge) {
            // Touch LRU
            touchLRU(urlAccessOrder, trackId)
            if (applicationWindow.settings.debugLevel >= 2) {
                var ageMinutes = ((Date.now() - urlData.timestamp) / 60000).toFixed(1)
                console.log("TidalCache: Using cached URL for track", trackId, "age:", ageMinutes + "min")
            }
            return urlData.url
        }
        
        if (urlData && applicationWindow.settings.debugLevel >= 1) {
            var ageMinutes = ((Date.now() - urlData.timestamp) / 60000).toFixed(1)
            console.log("TidalCache: URL expired for track", trackId, "age:", ageMinutes + "min")
        }
        return null
    }
    
    function getCachedUrlWithToken(trackId, token) {
        // Now we cache full URLs, so token parameter is ignored
        return getCachedUrl(trackId)
    }
    
    // Public function to be called when a track URL is received
    function cacheTrackUrl(trackId, fullUrl) {
        if (trackId && fullUrl) {
            // Cache full URL for short-term use
            cacheUrl(trackId, fullUrl)
            
            // Update track metadata cache - DON'T strip token from stored URL
            var trackInfo = getTrack(trackId)
            if (trackInfo) {
                // Store the full URL with token for playback
                trackInfo.url = fullUrl
                // Store clean URL separately for display if needed
                trackInfo.displayUrl = stripTokenFromUrl(fullUrl)
                trackInfo.timestamp = Date.now()
                saveTrackToCache(trackInfo)
            }
            
            if (applicationWindow.settings.debugLevel >= 2) {
                console.log("TidalCache: Track URL cached for track", trackId)
            }
        }
    }
    
    function clearExpiredUrl(trackId) {
        if (urlCache[trackId]) {
            delete urlCache[trackId]
            var index = urlAccessOrder.indexOf(trackId)
            if (index > -1) {
                urlAccessOrder.splice(index, 1)
            }
            if (applicationWindow.settings.debugLevel >= 1) {
                console.log("TidalCache: Cleared expired URL for track", trackId)
            }
        }
    }

    // PERFORMANCE: Non-blocking cache cleanup - triggers incremental cleanup
    function cleanOldCache() {
        console.log("PERFORMANCE: Triggering incremental cache cleanup instead of blocking cleanup")
        startIncrementalCleanup()
    }

    // Cache-Statistiken
    function getCacheStats() {
        var stats = {
            tracks: { count: 0, oldest: null, newest: null },
            albums: { count: 0, oldest: null, newest: null },
            artists: { count: 0, oldest: null, newest: null },
            playlists: { count: 0, oldest: null, newest: null },
            mixes: { count: 0, oldest: null, newest: null }
        }

        db.transaction(function(tx) {
            var rs = tx.executeSql('SELECT COUNT(*) as count, MIN(timestamp) as oldest, MAX(timestamp) as newest FROM tracks')
            stats.tracks = {
                count: rs.rows.item(0).count,
                oldest: new Date(rs.rows.item(0).oldest),
                newest: new Date(rs.rows.item(0).newest)
            }

            rs = tx.executeSql('SELECT COUNT(*) as count, MIN(timestamp) as oldest, MAX(timestamp) as newest FROM albums')
            stats.albums = {
                count: rs.rows.item(0).count,
                oldest: new Date(rs.rows.item(0).oldest),
                newest: new Date(rs.rows.item(0).newest)
            }

            rs = tx.executeSql('SELECT COUNT(*) as count, MIN(timestamp) as oldest, MAX(timestamp) as newest FROM artists')
            stats.artists = {
                count: rs.rows.item(0).count,
                oldest: new Date(rs.rows.item(0).oldest),
                newest: new Date(rs.rows.item(0).newest)
            }

            rs = tx.executeSql('SELECT COUNT(*) as count, MIN(timestamp) as oldest, MAX(timestamp) as newest FROM playlists')
            stats.playlists = {
                count: rs.rows.item(0).count,
                oldest: new Date(rs.rows.item(0).oldest),
                newest: new Date(rs.rows.item(0).newest)
            }

            rs = tx.executeSql('SELECT COUNT(*) as count, MIN(timestamp) as oldest, MAX(timestamp) as newest FROM mixes')
            stats.mixes = {
                count: rs.rows.item(0).count,
                oldest: new Date(rs.rows.item(0).oldest),
                newest: new Date(rs.rows.item(0).newest)
            }
        })

        return stats
    }

    // Cache leeren
    function clearCache() {
        console.log("clearing cache.")
        db.transaction(function(tx) {
            tx.executeSql('DELETE FROM tracks')
            tx.executeSql('DELETE FROM albums')
            tx.executeSql('DELETE FROM artists')
            tx.executeSql('DELETE FROM playlists')
            tx.executeSql('DELETE FROM mixes')
            tx.executeSql('DELETE FROM urls')
        })
        trackCache = ({})
        albumCache = ({})
        artistCache = ({})
        playlistCache = ({})
        mixCache = ({})
        urlCache = ({})
    }
}
