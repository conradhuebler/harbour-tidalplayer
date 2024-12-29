import QtQuick 2.0
import QtQuick.LocalStorage 2.0

Item {
id: root
    property var trackCache: ({})
    property var albumCache: ({})
    property var artistCache: ({})
    property var db
    property int maxCacheAge: 24 * 3600000

    Component.onCompleted: {
        initDatabase()
        loadCache()
    }

    // Verbindungen zu den Python-Signalen
 Connections {
        target: tidalApi

        // Bestehende Connections
        onTrackChanged: {
            // id, title, album, artist, image, duration
            saveTrackToCache({
                id: id,
                title: title,
                album: album,
                artist: artist,
                image: image,
                duration: duration,
                timestamp: Date.now()
            })
        }

        onAlbumChanged: {
            // id, title, artist, image
            saveAlbumToCache({
                id: id,
                title: title,
                artist: artist,
                image: image,
                timestamp: Date.now()
            })
        }

        onArtistChanged: {
            // id, name, img
            saveArtistToCache({
                id: id,
                name: name,
                image: img,
                timestamp: Date.now()
            })
        }

        // Neue Connections für Suchergebnisse

        onCacheTrack: {
            //track_info
            saveTrackToCache({
                id: track_info.id,
                title: track_info.title,
                album: track_info.album,
                artist: track_info.artist,
                image: track_info.image,
                duration: track_info.duration,
                albumid: track_info.albumid,
                timestamp: Date.now(),
                fromSearch: true  // Optional: markiert Einträge aus der Suche
            })
        }

        onCacheArtist: {
            //artist_info
            saveArtistToCache({
                id: artist_info.id,
                name: artist_info.name,
                bio: artist_info.bio,
                image: artist_info.image,
                timestamp: Date.now(),
                fromSearch: true  // Optional: markiert Einträge aus der Suche
            })
        }

        onCacheAlbum: {
            //album_info
            saveAlbumToCache({
                id: album_info.id,
                title: album_info.title,
                artist: album_info.artist,
                image: album_info.image,
                duration: album_info.duration,
                timestamp: Date.now(),
                fromSearch: true  // Optional: markiert Einträge aus der Suche
            })
        }
        onTrackAdded: {
            // id, title, album, artist, image, duration
            saveTrackToCache({
                id: id,
                title: title,
                album: album,
                artist: artist,
                image: image,
                duration: duration,
                timestamp: Date.now(),
                fromSearch: true  // Optional: markiert Einträge aus der Suche
            })
        }

        onAlbumAdded: {
            // id, title, artist, image, duration
            saveAlbumToCache({
                id: id,
                title: title,
                artist: artist,
                image: image,
                duration: duration,
                timestamp: Date.now(),
                fromSearch: true
            })
        }

        onArtistAdded: {
            // id, name, image
            saveArtistToCache({
                id: id,
                name: name,
                image: image,
                timestamp: Date.now(),
                fromSearch: true
            })
        }
    }

    // Optional: Erweiterte Such-spezifische Funktionen
    property var searchResults: ({
        tracks: [],
        albums: [],
        artists: []
    })

    // Suchergebnisse zwischenspeichern
    function clearSearchResults() {
        searchResults.tracks = []
        searchResults.albums = []
        searchResults.artists = []
    }

    function addSearchTrack(id) {
        if (!searchResults.tracks.includes(id)) {
            searchResults.tracks.push(id)
        }d, title, artist, image, duration
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
                id: id,
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

    // Datenbank initialisieren
    function initDatabase() {
        db = LocalStorage.openDatabaseSync("TidalCache", "1.1", "Cache for Tidal data", 1000000)
        db.transaction(function(tx) {
            // Tracks Tabelle
            tx.executeSql('CREATE TABLE IF NOT EXISTS tracks(id TEXT PRIMARY KEY, data TEXT, timestamp INTEGER)')
            tx.executeSql('CREATE INDEX IF NOT EXISTS tracks_timestamp_idx ON tracks(timestamp)')


            tx.executeSql('CREATE TABLE IF NOT EXISTS albums(id TEXT PRIMARY KEY, data TEXT, timestamp INTEGER)')
            tx.executeSql('CREATE INDEX IF NOT EXISTS albums_timestamp_idx ON albums(timestamp)')

            // Artists Tabelle
            tx.executeSql('CREATE TABLE IF NOT EXISTS artists(id TEXT PRIMARY KEY, data TEXT, timestamp INTEGER)')
            tx.executeSql('CREATE INDEX IF NOT EXISTS artists_timestamp_idx ON artists(timestamp)')
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
                } catch(e) {
                    console.error("Error parsing artist data:", e)
                }
            }
        })
        cleanOldCache()
    }

    // Cache-Speicherfunktionen
    function saveTrackToCache(trackData) {
        trackCache[trackData.id] = trackData
        db.transaction(function(tx) {
            tx.executeSql('INSERT OR REPLACE INTO tracks(id, data, timestamp) VALUES(?, ?, ?)',
                [trackData.id, JSON.stringify(trackData), trackData.timestamp])
        })
    }

    function saveAlbumToCache(albumData) {
        albumCache[albumData.id] = albumData
        db.transaction(function(tx) {
            tx.executeSql('INSERT OR REPLACE INTO albums(id, data, timestamp) VALUES(?, ?, ?)',
                [albumData.id, JSON.stringify(albumData), albumData.timestamp])
        })
    }

    function saveArtistToCache(artistData) {
        artistCache[artistData.id] = artistData
        db.transaction(function(tx) {
            tx.executeSql('INSERT OR REPLACE INTO artists(id, data, timestamp) VALUES(?, ?, ?)',
                [artistData.id, JSON.stringify(artistData), artistData.timestamp])
        })
    }

    // Getter-Funktionen
    function getTrack(id) {
        return trackCache[id] || null
    }

    function getAlbum(id) {
        return albumCache[id] || null
    }

    function getArtist(id) {
        return artistCache[id] || null
    }

    // Cache bereinigen
    function cleanOldCache() {
        var now = Date.now()
        db.transaction(function(tx) {
            // Alte Einträge aus allen Tabellen löschen
            tx.executeSql('DELETE FROM tracks WHERE timestamp < ?', [now - maxCacheAge])
            tx.executeSql('DELETE FROM albums WHERE timestamp < ?', [now - maxCacheAge])
            tx.executeSql('DELETE FROM artists WHERE timestamp < ?', [now - maxCacheAge])

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
        })
    }

    // Cache-Statistiken
    function getCacheStats() {
        var stats = {
            tracks: { count: 0, oldest: null, newest: null },
            albums: { count: 0, oldest: null, newest: null },
            artists: { count: 0, oldest: null, newest: null }
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
        })

        return stats
    }

    // Cache leeren
    function clearCache() {
        db.transaction(function(tx) {
            tx.executeSql('DELETE FROM tracks')
            tx.executeSql('DELETE FROM albums')
            tx.executeSql('DELETE FROM artists')
        })
        trackCache = ({})
        albumCache = ({})
        artistCache = ({})
    }
}
