import QtQuick 2.0
import QtQuick.LocalStorage 2.0

Item {
    id: root
    property string playlistTitle: "_current"

    // Signale für Playlist-Events
    signal playlistSaved(string name, var trackIds)
    signal playlistLoaded(string name, var trackIds, int position)
    signal playlistsChanged()
    signal playlistDeleted(string name)

    // Initialisiere Datenbank
    function getDatabase() {
        return LocalStorage.openDatabaseSync(
            "TidalPlayerDB",
            "1.0",
            "Tidal Player Playlist Storage",
            1000000
        );
    }

    // Erstelle Tabellen
    function initDatabase() {
        var db = getDatabase();
        db.transaction(function(tx) {
            // Erweiterte Tabelle mit Position und Timestamp
            tx.executeSql('CREATE TABLE IF NOT EXISTS playlists(
                name TEXT PRIMARY KEY,
                tracks TEXT,
                position INTEGER DEFAULT 0,
                last_played TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )');
        });
    }

    // Speichere Playlist mit Position
    function savePlaylist(name, trackIds, position) {
        var db = getDatabase();
        var tracksJson = JSON.stringify(trackIds);

        db.transaction(function(tx) {
            tx.executeSql('INSERT OR REPLACE INTO playlists (name, tracks, position, last_played) VALUES(?, ?, ?, CURRENT_TIMESTAMP)',
                         [name, tracksJson, position]);
        });

        playlistSaved(name, trackIds);
        playlistsChanged();
    }

    // Lade Playlist mit Position
    function loadPlaylist(name) {
    playlistTitle = name
        var db = getDatabase();
        var result;

        db.transaction(function(tx) {
            result = tx.executeSql('SELECT tracks, position FROM playlists WHERE name = ?', [name]);
            if (result.rows.length > 0) {
                var trackIds = JSON.parse(result.rows.item(0).tracks);
                var position = result.rows.item(0).position;

                // Aktualisiere last_played
                tx.executeSql('UPDATE playlists SET last_played = CURRENT_TIMESTAMP WHERE name = ?', [name]);

                playlistLoaded(name, trackIds, position);
            }
        });
    }

    // Update Position einer Playlist
    function updatePosition(name, position) {
        var db = getDatabase();

        db.transaction(function(tx) {
            tx.executeSql('UPDATE playlists SET position = ?, last_played = CURRENT_TIMESTAMP WHERE name = ?',
                         [position, name]);
        });
    }

    // Lösche Playlist
    function deletePlaylist(name) {
        var db = getDatabase();

        db.transaction(function(tx) {
            tx.executeSql('DELETE FROM playlists WHERE name = ?', [name]);
        });

        playlistDeleted(name);
        playlistsChanged();
    }

    // Hole alle Playlist-Namen mit Zusatzinformationen
    function getPlaylistInfo() {
        var db = getDatabase();
        var playlists = [];

        db.transaction(function(tx) {
            var result = tx.executeSql('SELECT name, position, tracks, last_played FROM playlists ORDER BY last_played DESC');
            for (var i = 0; i < result.rows.length; i++) {
                var item = result.rows.item(i);
                var tracks = JSON.parse(item.tracks);
                playlists.push({
                    name: item.name,
                    position: item.position,
                    trackCount: tracks.length,
                    lastPlayed: item.last_played
                });
            }
        });

        return playlists;
    }

    // In PlaylistManager.qml oder wo der PlaylistStorage verwendet wird
    function saveCurrentPlaylistState() {
        var trackIds = []
        for(var i = 0; i < playlistManager.size; i++) {
            var id = playlistManager.requestPlaylistItem(i)
            trackIds.push(id)
        }
        // Speichere als spezielle Playlist "_current"
        playlistStorage.savePlaylist("_current", trackIds, playlistManager.currentIndex)
    }

    // Beim Laden
    function loadCurrentPlaylistState() {
        var currentPlaylist = playlistStorage.loadPlaylist("_current")
        if (currentPlaylist && currentPlaylist.tracks.length > 0) {
            playlistManager.clearPlayList()
            for (var i = 0; i < currentPlaylist.tracks.length; i++) {
                playlistManager.appendTrack(currentPlaylist.tracks[i])
            }
            // Position wiederherstellen
            if (currentPlaylist.position >= 0) {
                playlistManager.playPosition(currentPlaylist.position)
            }
        }
    }
    Component.onCompleted: {
        initDatabase();
        loadCurrentPlaylistState()
    }
    // Bei App-Beendigung
    Component.onDestruction: {
        saveCurrentPlaylistState()
    }

    // Optional: Bei wichtigen Playlist-Änderungen
    Connections {
        target: playlistManager
        onListChanged: {
            saveCurrentPlaylistState()
        }
        onCurrentIndexChanged: {
            saveCurrentPlaylistState()
        }
    }
}
