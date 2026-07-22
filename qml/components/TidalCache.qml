import QtQuick 2.0
import QtQuick.LocalStorage 2.0

Item {
id: root
    // PERFORMANCE: LRU Cache Implementation - prevents memory leaks
    property int maxCacheSize: 1000           // Max items per cache type
    property int maxCacheAge: 24 * 3600000    // Max age in milliseconds
    
    // Cache objects with LRU tracking
    property var trackCache: ({})
    property var albumCache: ({})
    property var artistCache: ({})
    property var playlistCache: ({})
    property var mixCache: ({})

    // LRU access order tracking (most recent first)
    property var trackAccessOrder: []
    property var albumAccessOrder: []
    property var artistAccessOrder: []
    property var playlistAccessOrder: []
    property var mixAccessOrder: []
    
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
            if (applicationWindow.settings && applicationWindow.settings.debugLevel >= 2)
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
    // Only runs when debugging - LRU eviction in addToLRU already bounds size,
    // so this is purely a diagnostic; keeping it off avoids a periodic idle
    // CPU wakeup every 5 minutes. - Claude Generated
    Timer {
        interval: 300000  // 5 minutes
        running: applicationWindow.settings && applicationWindow.settings.debugLevel >= 1
        repeat: true
        onTriggered: {
            var stats = getCacheStats()
            if (applicationWindow.settings && applicationWindow.settings.debugLevel >= 1)
                console.log("Cache stats:", JSON.stringify(stats))

            // PERFORMANCE: Trigger incremental cleanup if cache gets large
            if (stats.total > maxCacheSize * 3) {
                if (applicationWindow.settings && applicationWindow.settings.debugLevel >= 1)
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
    
    // Deferred startup prune: deletes expired rows via the timestamp index
    // without loading them into memory. - Claude Generated
    Timer {
        id: dbPruneTimer
        interval: 5000
        running: false
        repeat: false
        onTriggered: pruneExpiredDb()
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
                if (applicationWindow.settings && applicationWindow.settings.debugLevel >= 1)
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
        
        if (settings.debugLevel >= 2) {
            console.log("CACHE: Processing", writesToProcess.length, "database writes in batch")
        }
        
        db.transaction(function(tx) {
            for (var i = 0; i < writesToProcess.length; i++) {
                var write = writesToProcess[i]
                try {
                    // Convert table to string to handle potential objects
                    var tableName = String(write.table)
                    
                    // Handle DELETE operations differently
                    if (tableName.indexOf('_delete') !== -1 || (write.data && write.data.operation === 'DELETE')) {
                        var actualTable = tableName.replace('_delete', '')
                        var deleteId = write.data.id || write.data.trackid || write.data.albumid || write.data.artistid || 
                                      write.data.playlistid || write.data.mixid || write.data.trackId
                        tx.executeSql('DELETE FROM ' + actualTable + ' WHERE id = ?', [deleteId])
                    } else {
                        // Handle INSERT/REPLACE operations
                        var id = write.data.trackid || write.data.albumid || write.data.artistid || 
                                 write.data.playlistid || write.data.mixid || write.data.trackId
                        tx.executeSql('INSERT OR REPLACE INTO ' + tableName + '(id, data, timestamp) VALUES(?, ?, ?)',
                            [id, JSON.stringify(write.data), write.timestamp])
                    }
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
            if (applicationWindow.settings && applicationWindow.settings.debugLevel >= 1)
                console.log("PERFORMANCE: Cleanup already in progress, skipping")
            return
        }
        
        if (settings.debugLevel >= 2) {
            console.log("CACHE: Starting incremental cleanup")
        }
        cleanupInProgress = true
        cleanupQueue = []
        
        // Queue all cache types for cleanup
        var cacheTypes = [
            {name: 'tracks', cache: trackCache, accessOrder: trackAccessOrder},
            {name: 'albums', cache: albumCache, accessOrder: albumAccessOrder},
            {name: 'artists', cache: artistCache, accessOrder: artistAccessOrder},
            {name: 'playlists', cache: playlistCache, accessOrder: playlistAccessOrder},
            {name: 'mixes', cache: mixCache, accessOrder: mixAccessOrder}
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
            if (settings.debugLevel >= 2) {
                console.log("CACHE: Cleaning", expiredKeys.length, "expired", batch.type, "entries")
            }
            
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
        // Entries are loaded lazily per id (see loadFromDb); expired rows are
        // pruned in SQL after startup instead of scanning every row into memory.
        dbPruneTimer.start()

        // Log initial cache stats
        if (applicationWindow.settings && applicationWindow.settings.debugLevel >= 1)
            console.log("TidalCache initialized with lazy DB loading + LRU, max size per type:", maxCacheSize)
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

    // Info-Getter: reine Cache/DB-Lookups, blockieren nie den UI-Thread.
    // Bei Miss wird asynchron nachgeladen (Ergebnis kommt als cache*-Signal
    // zurueck und wird ueber die Connections unten gespeichert); ein
    // abgelaufener Eintrag wird sofort geliefert und im Hintergrund
    // aufgefrischt. - Claude Generated
    function getTrackInfo(id) {
        var cached = getTrack(id)
        if (!cached || Date.now() - cached.timestamp >= maxCacheAge)
            tidalApi.requestTrackInfo(id)
        return cached
    }

    function getAlbumInfo(id) {
        var cached = getAlbum(id)
        if (!cached || Date.now() - cached.timestamp >= maxCacheAge)
            tidalApi.requestAlbumInfo(id)
        return cached
    }

    function getArtistInfo(id) {
        var cached = getArtist(id)
        if (!cached || Date.now() - cached.timestamp >= maxCacheAge)
            tidalApi.requestArtistInfo(id)
        return cached
    }

    function getPlaylistInfo(id) {
        var cached = getPlaylist(id)
        if (!cached || Date.now() - cached.timestamp >= maxCacheAge)
            tidalApi.requestPlaylistInfo(id)
        return cached
    }

    function getMixInfo(id) {
        var cached = getMix(id)
        if (!cached || Date.now() - cached.timestamp >= maxCacheAge)
            tidalApi.requestMixInfo(id)
        return cached
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

            // Migration: Drop unused urls table if it exists
            tx.executeSql('DROP TABLE IF EXISTS urls')
        })
    }

    // Einzelnen Eintrag lazy aus der DB in den LRU-Cache laden - Claude Generated
    function loadFromDb(table, cache, accessOrder, id) {
        if (!db || id === undefined || id === null)
            return null
        var item = null
        db.readTransaction(function(tx) {
            var rs = tx.executeSql('SELECT data FROM ' + table + ' WHERE id = ?', [String(id)])
            if (rs.rows.length > 0) {
                try {
                    item = JSON.parse(rs.rows.item(0).data)
                } catch(e) {
                    console.error("Error parsing", table, "data:", e)
                }
            }
        })
        if (item)
            addToLRU(cache, accessOrder, id, item)
        return item
    }

    // Abgelaufene Einträge direkt in SQL löschen (nutzt timestamp-Index) - Claude Generated
    function pruneExpiredDb() {
        if (!db)
            return
        var cutoff = Date.now() - maxCacheAge
        db.transaction(function(tx) {
            tx.executeSql('DELETE FROM tracks WHERE timestamp < ?', [cutoff])
            tx.executeSql('DELETE FROM albums WHERE timestamp < ?', [cutoff])
            tx.executeSql('DELETE FROM artists WHERE timestamp < ?', [cutoff])
            tx.executeSql('DELETE FROM playlists WHERE timestamp < ?', [cutoff])
            tx.executeSql('DELETE FROM mixes WHERE timestamp < ?', [cutoff])
        })
        if (applicationWindow.settings && applicationWindow.settings.debugLevel >= 2)
            console.log("CACHE: Pruned expired DB entries older than", new Date(cutoff))
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

    // Getter-Funktionen: erst LRU-Speicher, dann lazy aus der DB
    function getTrack(id) {
        var track = trackCache[id] || null
        if (track) {
            // PERFORMANCE: Update LRU access order
            touchLRU(trackAccessOrder, id)
            return track
        }
        return loadFromDb('tracks', trackCache, trackAccessOrder, id)
    }

    function getAlbum(id) {
        var album = albumCache[id] || null
        if (album) {
            touchLRU(albumAccessOrder, id)
            return album
        }
        return loadFromDb('albums', albumCache, albumAccessOrder, id)
    }

    function getArtist(id) {
        var artist = artistCache[id] || null
        if (artist) {
            touchLRU(artistAccessOrder, id)
            return artist
        }
        return loadFromDb('artists', artistCache, artistAccessOrder, id)
    }

    function getPlaylist(id) {
        var playlist = playlistCache[id] || null
        if (playlist) {
            touchLRU(playlistAccessOrder, id)
            return playlist
        }
        return loadFromDb('playlists', playlistCache, playlistAccessOrder, id)
    }

    function getMix(id) {
        var mix = mixCache[id] || null
        if (mix) {
            touchLRU(mixAccessOrder, id)
            return mix
        }
        return loadFromDb('mixes', mixCache, mixAccessOrder, id)
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
        if (applicationWindow.settings && applicationWindow.settings.debugLevel >= 1)
            console.log("clearing cache.")
        db.transaction(function(tx) {
            tx.executeSql('DELETE FROM tracks')
            tx.executeSql('DELETE FROM albums')
            tx.executeSql('DELETE FROM artists')
            tx.executeSql('DELETE FROM playlists')
            tx.executeSql('DELETE FROM mixes')
        })
        trackCache = ({})
        albumCache = ({})
        artistCache = ({})
        playlistCache = ({})
        mixCache = ({})
        trackAccessOrder = []
        albumAccessOrder = []
        artistAccessOrder = []
        playlistAccessOrder = []
        mixAccessOrder = []
    }
}
