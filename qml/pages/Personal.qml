import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0
import "widgets"

import "personalLists"

Item {
    id: personalPage
    anchors.fill: parent

    // Persistent section cache (LocalStorage) for instant display on startup
    property var db

    function initDatabase() {
        db = LocalStorage.openDatabaseSync("PersonalCache", "1.0",
                                           "Personal page section cache", 200000)
        db.transaction(function(tx) {
            tx.executeSql('CREATE TABLE IF NOT EXISTS personal_cache (' +
                          'section TEXT NOT NULL, ' +
                          'position INTEGER NOT NULL, ' +
                          'type TEXT, ' +
                          'data TEXT, ' +
                          'PRIMARY KEY (section, position))')
        })
    }

    // Section file lookup for the Repeater in mainColumn - Claude Generated
    function sectionSourceFor(id) {
        switch (id) {
            case "recent":           return "sections/RecentSection.qml"
            case "foryou":           return "sections/ForYouSection.qml"
            case "topartist":        return "sections/TopArtistsSection.qml"
            case "topalbum":         return "sections/TopAlbumsSection.qml"
            case "toptrack":         return "sections/TopTracksSection.qml"
            case "personalPlaylist": return "sections/PersonalPlaylistsSection.qml"
            case "dailyMixes":       return "sections/CustomMixesSection.qml"
            case "radioMixes":       return "sections/RadioMixesSection.qml"
            case "favArtists":       return "sections/FavoriteArtistsSection.qml"
            default: return ""
        }
    }

    // Called by individual section components on Component.onCompleted to
    // populate themselves from the persistent cache. - Claude Generated
    function loadSectionItems(cacheKey, list) {
        if (!db || !list) return
        try {
            db.readTransaction(function(tx) {
                var rs = tx.executeSql(
                    "SELECT type, data FROM personal_cache WHERE section=? ORDER BY position",
                    [cacheKey])
                for (var j = 0; j < rs.rows.length; j++) {
                    var row = rs.rows.item(j)
                    applyCachedItem(list, row.type, JSON.parse(row.data))
                }
            })
        } catch (error) {
            console.error("Personal: Error loading cached data for", cacheKey, ":", error)
        }
    }

    // Trigger the Tidal API call that backs a given section. Called by the
    // HomescreenLayout switch on activation, so a newly enabled section is
    // populated live instead of waiting for the next app restart. - Claude Generated
    function loadSectionData(sectionId) {
        switch (sectionId) {
            case "recent":           tidalApi.getRecentPage();      break
            case "foryou":           tidalApi.getForYouPage();      break
            case "topartist":        tidalApi.getFavoriteArtists(); break
            case "topalbum":         tidalApi.getFavoriteAlbums();  break
            case "toptrack":         tidalApi.getFavoriteTracks();  break
            case "personalPlaylist": tidalApi.getPersonalPlaylists(); break
            case "dailyMixes":       tidalApi.getDailyMixes();      break
            case "radioMixes":       tidalApi.getRadioMixes();      break
            case "favArtists":       tidalApi.getTopArtists();      break
        }
    }

    function applyCachedItem(list, type, data) {
        if (type === "album") list.addAlbum(data)
        else if (type === "mix") list.addMix(data)
        else if (type === "artist") list.addArtist(data)
        else if (type === "playlist") list.addPlaylist(data)
        else if (type === "track") list.addTrack(data)
    }

    // Pending writes buffer for debounced disk writes
    property var pendingCacheWrites: ({})

    // Debounce timer - coalesce many cacheItem() calls into one Settings write
    Timer {
        id: cacheFlushTimer
        interval: 500
        repeat: false
        onTriggered: flushCache()
    }

    function cacheItem(listId, type, data) {
        if (!pendingCacheWrites[listId]) pendingCacheWrites[listId] = []
        pendingCacheWrites[listId].push({type: type, data: data})
        cacheFlushTimer.restart()
    }

    function flushCache() {
        if (!db) return

        var sectionIds = Object.keys(pendingCacheWrites)
        if (sectionIds.length === 0) return

        try {
            db.transaction(function(tx) {
                for (var i = 0; i < sectionIds.length; i++) {
                    var section = sectionIds[i]
                    var rs = tx.executeSql(
                        "SELECT type, data FROM personal_cache WHERE section=? ORDER BY position",
                        [section])
                    var current = []
                    for (var j = 0; j < rs.rows.length; j++) {
                        var row = rs.rows.item(j)
                        current.push({type: row.type, data: JSON.parse(row.data)})
                    }
                    var pending = pendingCacheWrites[section]
                    for (var k = 0; k < pending.length; k++) {
                        current.push(pending[k])
                    }
                    while (current.length > 20) current.shift()
                    tx.executeSql("DELETE FROM personal_cache WHERE section=?", [section])
                    for (var m = 0; m < current.length; m++) {
                        tx.executeSql(
                            "INSERT INTO personal_cache (section, position, type, data) VALUES (?, ?, ?, ?)",
                            [section, m, current[m].type, JSON.stringify(current[m].data)])
                    }
                }
            })
        } catch (error) {
            console.error("Personal: Error flushing cache:", error)
        }
        pendingCacheWrites = ({})
    }

    SilicaFlickable {
        id: flick
        anchors.fill: parent
        contentHeight: mainColumn.height

        Column {
            id: mainColumn
            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader {
                title: qsTr("Personal Collection")
            }

            // Configurable section order driven by homescreenSectionOrder - Claude Generated
            // active is a reactive property binding so that toggling a section's
            // visibility in HomescreenLayout instantiates / destroys the loader
            // without a page reload. Disabled sections are never built, skipping
            // their cache read, Connections and HorizontalList render at startup.
            Repeater {
                model: applicationWindow.settings.homescreenSectionOrder
                delegate: Loader {
                    width: mainColumn.width
                    asynchronous: true
                    active: {
                        switch (modelData) {
                            case "recent":           return applicationWindow.settings.recentList
                            case "foryou":           return applicationWindow.settings.yourList
                            case "topartist":        return applicationWindow.settings.topartistList
                            case "topalbum":         return applicationWindow.settings.topalbumsList
                            case "toptrack":         return applicationWindow.settings.toptrackList
                            case "personalPlaylist": return applicationWindow.settings.personalPlaylistList
                            case "dailyMixes":       return applicationWindow.settings.dailyMixesList
                            case "radioMixes":       return applicationWindow.settings.radioMixesList
                            case "favArtists":       return applicationWindow.settings.topArtistsList
                            default: return false
                        }
                    }
                    source: active ? personalPage.sectionSourceFor(modelData) : ""
                }
            }
        }

        VerticalScrollDecorator {}
    }

    Connections {
        target: tidalApi

        onLoginSuccess: {
            if (applicationWindow.settings.debugLevel >= 1) {
                console.log("Personal: Login successful - selective phase loading")
            }

            // If we auto-resume a track, hold homescreen API calls back so the
            // single Python worker can finish MediaHandler's stream-URL lookup
            // first. Otherwise Phase 1's session.home() blocks the queue and
            // audio starts late / stutters. - Claude Generated
            var resuming = applicationWindow.settings.resume_playback
                        && applicationWindow.settings.last_track_id !== ""
            var base = resuming ? 2500 : 0
            phaseOneTimer.interval   = base
            phaseTwoTimer.interval   = base + 1000
            phaseThreeTimer.interval = base + 2000
            phaseOneTimer.start()
            phaseTwoTimer.start()
            phaseThreeTimer.start()
        }
    }

    // PERFORMANCE: Phase 1 - recent + foryou
    Timer {
        id: phaseOneTimer
        interval: 0
        repeat: false
        onTriggered: {
            if (applicationWindow.settings.recentList) tidalApi.getRecentPage()
            if (applicationWindow.settings.yourList)   tidalApi.getForYouPage()
        }
    }

    // PERFORMANCE: Timer for delayed loading (Phase 2)
    Timer {
        id: phaseTwoTimer
        interval: 1000
        repeat: false
        onTriggered: {
            if (applicationWindow.settings.debugLevel >= 1) {
                console.log("Personal: Loading favorites (Phase 2)")
            }
            if (applicationWindow.settings.topalbumsList) tidalApi.getFavoriteAlbums()
            if (applicationWindow.settings.toptrackList)  tidalApi.getFavoriteTracks()
            if (applicationWindow.settings.topartistList) tidalApi.getFavoriteArtists()
        }
    }

    // PERFORMANCE: Timer for delayed loading (Phase 3)
    Timer {
        id: phaseThreeTimer
        interval: 2000
        repeat: false
        onTriggered: {
            if (applicationWindow.settings.debugLevel >= 1) {
                console.log("Personal: Loading secondary content (Phase 3)")
            }

            if (applicationWindow.settings.personalPlaylistList) {
                tidalApi.getPersonalPlaylists()
            }
            if (applicationWindow.settings.dailyMixesList) {
                tidalApi.getDailyMixes()
            }
            if (applicationWindow.settings.radioMixesList) {
                tidalApi.getRadioMixes()
            }
            if (applicationWindow.settings.topArtistsList) {
                tidalApi.getTopArtists()
            }
        }
    }

    Component.onCompleted: {
        if (applicationWindow.settings.debugLevel >= 1) {
            console.log("Personal: Component completed - loading cache")
        }

        // Expose this page so section components can reach the cache API
        applicationWindow.personalPage = personalPage

        // Open DB; individual sections pull their own cached rows in their
        // Component.onCompleted via loadSectionItems().
        initDatabase()
    }

    // Flush any pending cache writes before destruction to avoid losing the last batch
    Component.onDestruction: {
        if (cacheFlushTimer.running) {
            cacheFlushTimer.stop()
            flushCache()
        }
    }
}
