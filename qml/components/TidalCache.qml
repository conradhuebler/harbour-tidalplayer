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
            
            // Optional: Cleanup if total cache gets too large
            if (stats.total > maxCacheSize * 4) {
                console.log("Cache getting large, considering cleanup...")
            }
        }
    }

    Component.onCompleted: {
        initDatabase()
        loadCache()
        
        // Log initial cache stats
        console.log("TidalCache initialized with LRU, max size per type:", maxCacheSize)
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
        })
        cleanOldCache()
    }

    // Cache-Speicherfunktionen
    function saveTrackToCache(trackData) {
        // PERFORMANCE: Use LRU cache instead of unlimited growth
        addToLRU(trackCache, trackAccessOrder, trackData.trackid, trackData)
        
        db.transaction(function(tx) {
            tx.executeSql('INSERT OR REPLACE INTO tracks(id, data, timestamp) VALUES(?, ?, ?)',
                [trackData.trackid, JSON.stringify(trackData), trackData.timestamp])
        })
    }

    function saveAlbumToCache(albumData) {
        // PERFORMANCE: Use LRU cache
        addToLRU(albumCache, albumAccessOrder, albumData.albumid, albumData)
        
        db.transaction(function(tx) {
            tx.executeSql('INSERT OR REPLACE INTO albums(id, data, timestamp) VALUES(?, ?, ?)',
                [albumData.albumid, JSON.stringify(albumData), albumData.timestamp])
        })
    }

    function saveArtistToCache(artistData) {
        // PERFORMANCE: Use LRU cache
        addToLRU(artistCache, artistAccessOrder, artistData.artistid, artistData)
        
        db.transaction(function(tx) {
            tx.executeSql('INSERT OR REPLACE INTO artists(id, data, timestamp) VALUES(?, ?, ?)',
                [artistData.artistid, JSON.stringify(artistData), artistData.timestamp])
        })
    }

    function savePlaylistToCache(playlistData) {
        // PERFORMANCE: Use LRU cache
        addToLRU(playlistCache, playlistAccessOrder, playlistData.playlistid, playlistData)
        
        db.transaction(function(tx) {
            tx.executeSql('INSERT OR REPLACE INTO playlists(id, data, timestamp) VALUES(?, ?, ?)',
                [playlistData.playlistid, JSON.stringify(playlistData), playlistData.timestamp])
        })
    }

    function saveMixToCache(mixData) {
        // PERFORMANCE: Use LRU cache
        addToLRU(mixCache, mixAccessOrder, mixData.mixid, mixData)
        
        db.transaction(function(tx) {
            tx.executeSql('INSERT OR REPLACE INTO mixes(id, data, timestamp) VALUES(?, ?, ?)',
                [mixData.mixid, JSON.stringify(mixData), mixData.timestamp])
        })
    }

    // Getter-Funktionen with LRU touch
    function getTrack(id) {
        var track = trackCache[id] || null
        if (track) {
            // PERFORMANCE: Update LRU access order
            touchLRU(trackAccessOrder, id)
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

    // Cache bereinigen
    function cleanOldCache() {
        var now = Date.now()
        db.transaction(function(tx) {
            // Alte Einträge aus allen Tabellen löschen
            tx.executeSql('DELETE FROM tracks WHERE timestamp < ?', [now - maxCacheAge])
            tx.executeSql('DELETE FROM albums WHERE timestamp < ?', [now - maxCacheAge])
            tx.executeSql('DELETE FROM artists WHERE timestamp < ?', [now - maxCacheAge])
            tx.executeSql('DELETE FROM playlists WHERE timestamp < ?', [now - maxCacheAge])
            tx.executeSql('DELETE FROM mixes WHERE timestamp < ?', [now - maxCacheAge])

            // Cache-Objekte aktualisieren
            var rs = tx.executeSql('SELECT * FROM tracks')
            trackCache = ({})
            for(var i = 0; i < rs.rows.length; i++) {
                trackCache[rs.rows.item(i).id] = JSON.parse(rs.rows.item(i).data)
            }

            rs = tx.executeSql('SELECT * FROM albums')
            albumCache = ({})
            for(i = 0; i < rs.rows.length; i++) {
                albumCache[rs.rows.item(i).id] = JSON.parse(rs.rows.item(i).data)
            }

            rs = tx.executeSql('SELECT * FROM artists')
            artistCache = ({})
            for(i = 0; i < rs.rows.length; i++) {
                artistCache[rs.rows.item(i).id] = JSON.parse(rs.rows.item(i).data)
            }

            rs = tx.executeSql('SELECT * FROM playlists')
            playlistCache = ({})
            for(i = 0; i < rs.rows.length; i++) {
                playlistCache[rs.rows.item(i).id] = JSON.parse(rs.rows.item(i).data)
            }

            rs = tx.executeSql('SELECT * FROM mixes')
            mixCache = ({})
            for(i = 0; i < rs.rows.length; i++) {
                mixCache[rs.rows.item(i).id] = JSON.parse(rs.rows.item(i).data)
            }    
        })
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
        })
        trackCache = ({})
        albumCache = ({})
        artistCache = ({})
        playlistCache = ({})
        mixCache = ({})
    }
}
