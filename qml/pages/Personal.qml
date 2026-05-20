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

    // PERFORMANCE: Cache helper functions
    function loadCachedData() {
        if (!db) return

        if (applicationWindow.settings.debugLevel >= 1) {
            console.log("Personal: Loading cached data for instant display")
        }

        var sections = [
            {id: "recent", list: recentList, visible: true},
            {id: "foryou", list: foryouList, visible: true},
            {id: "artist", list: artistList, visible: applicationWindow.settings.topartistList},
            {id: "album",  list: albumsList, visible: applicationWindow.settings.topalbumsList},
            {id: "track",  list: tracksList, visible: applicationWindow.settings.toptrackList}
        ]

        try {
            db.readTransaction(function(tx) {
                for (var i = 0; i < sections.length; i++) {
                    var s = sections[i]
                    if (!s.visible || !s.list) continue
                    var rs = tx.executeSql(
                        "SELECT type, data FROM personal_cache WHERE section=? ORDER BY position",
                        [s.id])
                    for (var j = 0; j < rs.rows.length; j++) {
                        var row = rs.rows.item(j)
                        applyCachedItem(s.list, row.type, JSON.parse(row.data))
                    }
                }
            })
            if (applicationWindow.settings.debugLevel >= 1) {
                console.log("Personal: Cached data loaded successfully")
            }
        } catch (error) {
            console.error("Personal: Error loading cached data:", error)
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


        // todo: function to hide all search fields but current one
        // or one search field for all sections?
        Column {
            id: mainColumn
            width: parent.width
            spacing: Theme.paddingMedium
            property bool showFilterArtist : true

            PageHeader {
                title: "Personal Collection"
            }

            // Recently Played Section
            SectionHeader {
                text: qsTr("Recently played")
                visible: applicationWindow.settings.recentList
                //height: (filter.visible ? filter.height*2 : filter.height)
                MouseArea {
                  anchors.fill: parent
                  onClicked: filterRecentlyPlayed.visible = ! filterRecentlyPlayed.visible
                }
                // does not work as expected, it would also need to increase height of SessionHeader
                /*SearchField {
                    id: filterRecentlyPlayed
                    labelVisible: false
                    visible: false
                    anchors.margins: Theme.paddingMedium
                    anchors.top: sectionHeader.bottom
                }*/
            }
            SearchField {
                id: filterRecentlyPlayed
                labelVisible: false
                visible: false
                anchors.margins: Theme.paddingMedium
                onTextChanged: recentList.filterText = text
            }
            HorizontalList {
                id: recentList
                visible: applicationWindow.settings.recentList
            }

            // For you section
            SectionHeader {
                text: qsTr("Popular playlists")
                visible: applicationWindow.settings.yourList
                MouseArea {
                  anchors.fill: parent
                  onClicked: filterPopularPlaylists.visible = ! filterPopularPlaylists.visible
                }                
            }
            SearchField {
                id: filterPopularPlaylists
                labelVisible: false
                visible: false
                anchors.margins: Theme.paddingMedium
                onTextChanged: foryouList.filterText = text
            }
            HorizontalList {
                id: foryouList
                visible: applicationWindow.settings.yourList
            }

            // Top Artists Section
            SectionHeader {
                visible: applicationWindow.settings.topartistList
                text: qsTr("Top Artists")
                MouseArea {
                  anchors.fill: parent
                  onClicked:  {
                        filterTopArtists.visible = ! filterTopArtists.visible
                        if (filterTopArtists.visible) {
                            filterTopArtists.forceActiveFocus()
                        }
                    }
                }     
            }
            SearchField {
                id: filterTopArtists
                placeholderText: "Filter artists"
                visible: false
                anchors.margins: Theme.paddingMedium
                property int debounceInterval: 600
                Timer {
                    id: debounceTimer
                    interval: filterTopArtists.debounceInterval
                    repeat: false
                    onTriggered: {
                        console.log("Debounce timer triggered, applying filter: " + filterTopArtists.text)
                        artistList.filterText = filterTopArtists.text
                    }
                }
                onTextChanged: {
                    console.log("Debounce timer restart")
                    debounceTimer.restart()
                }
            }
            HorizontalList {
                visible: applicationWindow.settings.topartistList
                id: artistList
                //property string filterText: ""
            }

            // Top Albums Section
            SectionHeader {
                visible: applicationWindow.settings.topalbumsList
                text: qsTr("Top Albums")
                MouseArea {
                    anchors.fill: parent
                    onClicked:  {
                        filterAlbum.visible = ! filterAlbum.visible
                        if (filterAlbum.visible) {
                            filterAlbum.forceActiveFocus()
                        }
                    }
                }
            }
            SearchField {
                id: filterAlbum
                placeholderText: "Filter albums"
                visible: false
                anchors.margins: Theme.paddingMedium
                onTextChanged: albumsList.filterText = text
            }
            HorizontalList {
                visible: applicationWindow.settings.topalbumsList
                id: albumsList
            }

            // Top Titles Section
            SectionHeader {
                visible: applicationWindow.settings.toptrackList
                text: qsTr("Top Tracks")
                MouseArea {
                    anchors.fill: parent
                    onClicked: filterTracks.visible = ! filterTracks.visible
                }
            }
            SearchField {
                id: filterTracks
                placeholderText: "Filter tracks"
                visible: false
                anchors.margins: Theme.paddingMedium
                onTextChanged: tracksList.filterText = text
            }            
            HorizontalList {
                visible: applicationWindow.settings.toptrackList
                id: tracksList
            }

            // Playlists Section
            SectionHeader {
                visible: applicationWindow.settings.personalPlaylistList
                text: qsTr("Personal Playlists")
                MouseArea {
                    anchors.fill: parent
                    onClicked: filterPlaylists.visible = ! filterPlaylists.visible
                }                
            }
            SearchField {
                id: filterPlaylists
                placeholderText: "Filter playlists"
                visible: false
                anchors.margins: Theme.paddingMedium
                onTextChanged: playlistList.filterText = text
            }
            HorizontalList {
                visible: applicationWindow.settings.personalPlaylistList
                id: playlistList
            } 

            SectionHeader {
                visible: applicationWindow.settings.dailyMixesList
                text: qsTr("Custom Mixes")
            }

            HorizontalList {
                visible: applicationWindow.settings.dailyMixesList
                id: dailyMixesList
               // getPageDailyMixes
            }

            SectionHeader {
                visible: applicationWindow.settings.radioMixesList
                text: qsTr("Personal Radio Stations")
            }

            HorizontalList {
                visible: applicationWindow.settings.radioMixesList
                id: radioMixesList
                //def getPageSuggestedRadioMixes(self):
            }

            SectionHeader {
                visible: applicationWindow.settings.topArtistsList
                text: qsTr("Favorite Artists")
            }

            HorizontalList {
                visible: applicationWindow.settings.topArtistsList
                id: topArtistList
                //getPageFavoriteArtists // sorted by activity
            }

        }            

/*

    def getPageListeningHistorypage(self):
        return self.session.page.get("pages/HISTORY_MIXES/view-all?")
    
    def getPageSuggestedNewAlbumspage(self):
        return self.session.page.get("pages/NEW_ALBUM_SUGGESTIONS/view-all?")
    
    def getPageMoods(self):
        return self.session.page.get("pages/moods_page") */
        

        VerticalScrollDecorator {}
    }

    Connections {
        target: tidalApi


        onRecentAlbum:
        {
            recentList.addAlbum(album_info)
            cacheItem("recent", "album", album_info)
        }

        onRecentMix:
        {
            recentList.addMix(mix_info)
            cacheItem("recent", "mix", mix_info)
        }

        onRecentArtist:
        {
            recentList.addArtist(artist_info)
            cacheItem("recent", "artist", artist_info)
        }

        onRecentPlaylist:
        {
            recentList.addPlaylist(playlist_info)
            cacheItem("recent", "playlist", playlist_info)
        }

        onRecentTrack:
        {
            recentList.addTrack(track_info)
            cacheItem("recent", "track", track_info)
        }

        onForyouAlbum:
        {
            foryouList.addAlbum(album_info)
            cacheItem("foryou", "album", album_info)
        }

        onForyouArtist:
        {
            foryouList.addArtist(artist_info)
            cacheItem("foryou", "artist", artist_info)
        }

        onForyouPlaylist:
        {
            foryouList.addPlaylist(playlist_info)
            cacheItem("foryou", "playlist", playlist_info)
        }

        onForyouMix:
        {
            foryouList.addMix(mix_info)
            cacheItem("foryou", "mix", mix_info)
        }

        onPersonalPlaylistAdded: {
            playlistList.addPlaylist(playlist_info)
            cacheItem("playlist", "playlist", playlist_info)
        }

        onFavArtists: {
            artistList.addArtist(artist_info)
            cacheItem("artist", "artist", artist_info)
        }

        onFavAlbums: {
            albumsList.addAlbum(album_info)
            cacheItem("album", "album", album_info)
        }

        onFavTracks: {
            tracksList.addTrack(track_info)
            cacheItem("track", "track", track_info)
        }

        onCustomMix: {
            //if (mix_info.type == "dailyMix") {
            if (mixType == "dailyMix") {
                dailyMixesList.addMix(mix_info)
            } else if (mixType == "radioMix") {
                radioMixesList.addMix(mix_info)
            }
        }

        onTopArtist: {
            topArtistList.addArtist(artist_info)
        }

        onLoginSuccess: {
            if (applicationWindow.settings.debugLevel >= 1) {
                console.log("Personal: Login successful - Priority loading enabled")
            }

            // PERFORMANCE: Priority-based loading for faster startup
            // Phase 1: IMMEDIATE (0ms) - Critical content only
            tidalApi.getHomepage() // Loads recent + popular (most important)

            // Phase 2: 1 second delay - Favorites
            phaseTwoTimer.start()

            // Phase 3: 2 second delay - Secondary content (only if enabled)
            phaseThreeTimer.start()
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
            tidalApi.getFavorits() // Fav artists, albums, tracks
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

    // PERFORMANCE: Load cached data on component creation
    Component.onCompleted: {
        if (applicationWindow.settings.debugLevel >= 1) {
            console.log("Personal: Component completed - loading cache")
        }

        // Open DB first, then populate visible sections from the cache
        initDatabase()
        loadCachedData()

        if (applicationWindow.settings.debugLevel >= 1) {
            console.log("Personal: Cached content displayed, waiting for fresh data")
        }
    }

    // Flush any pending cache writes before destruction to avoid losing the last batch
    Component.onDestruction: {
        if (cacheFlushTimer.running) {
            cacheFlushTimer.stop()
            flushCache()
        }
    }
}
