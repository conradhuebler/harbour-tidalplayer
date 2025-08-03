import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Configuration 1.0

Item {
    id: homescreenManager

    // HOMESCREEN PERSONALIZATION: Central coordinator for configurable sections
    
    // Section configuration and state
    property var sectionConfigs: ({
        "recent": { 
            enabled: true, 
            order: 0, 
            priority: "high",
            maxItems: 15,  // Mehr Einträge
            refreshInterval: 300000,  // 5min
            title: qsTr("Recently played"),
            type: "recent"
        },
        "popular": { 
            enabled: true, 
            order: 1, 
            priority: "medium",
            maxItems: 12,  // Mehr Einträge
            refreshInterval: 600000,  // 10min
            title: qsTr("Popular playlists"),
            type: "foryou"
        },
        "topArtists": { 
            enabled: true, 
            order: 2, 
            priority: "medium",
            maxItems: 12,  // Mehr Einträge
            refreshInterval: 900000,  // 15min
            title: qsTr("Top Artists"),
            type: "topArtists"
        },
        "topAlbums": { 
            enabled: true, 
            order: 3, 
            priority: "low",
            maxItems: 12,  // Mehr Einträge
            refreshInterval: 900000,  // 15min
            title: qsTr("Top Albums"),
            type: "topAlbums"
        },
        "topTracks": { 
            enabled: true, 
            order: 4, 
            priority: "low",
            maxItems: 12,  // Mehr Einträge
            refreshInterval: 900000,  // 15min
            title: qsTr("Top Tracks"),
            type: "topTracks"
        },
        "personalPlaylists": { 
            enabled: true, 
            order: 5, 
            priority: "medium",
            maxItems: 15,  // Mehr Einträge
            refreshInterval: 1800000,  // 30min
            title: qsTr("Personal Playlists"),
            type: "personalPlaylists"
        },
        "dailyMixes": { 
            enabled: true, 
            order: 6, 
            priority: "medium",
            maxItems: 10,  // Mehr Einträge
            refreshInterval: 3600000,  // 1hour
            title: qsTr("Custom Mixes"),
            type: "dailyMixes"
        },
        "radioMixes": { 
            enabled: true, 
            order: 7, 
            priority: "low",
            maxItems: 10,  // Mehr Einträge
            refreshInterval: 3600000,  // 1hour
            title: qsTr("Personal Radio Stations"),
            type: "radioMixes"
        }
    })
    
    // Runtime state
    property var loadingStates: ({})
    property var lastRefreshTimes: ({})
    property bool backgroundRefreshActive: false
    property var loadingQueue: []
    
    // Configuration storage
    ConfigurationValue {
        id: sectionOrderConfig
        key: "/homescreen/sectionOrder"
        defaultValue: ["recent", "popular", "topArtists", "topAlbums", "topTracks", "personalPlaylists", "dailyMixes", "radioMixes"]
    }
    
    ConfigurationValue {
        id: sectionVisibilityConfig
        key: "/homescreen/sectionVisibility"
        defaultValue: ({
            "recent": true,
            "popular": true,
            "topArtists": true,
            "topAlbums": true,
            "topTracks": true,
            "personalPlaylists": true,
            "dailyMixes": true,
            "radioMixes": true
        })
    }
    
    ConfigurationValue {
        id: refreshIntervalsConfig
        key: "/homescreen/refreshIntervals"
        defaultValue: ({})
    }

    // Signals for section updates
    signal sectionContentUpdated(string sectionId, var content)
    signal sectionOrderChanged(var newOrder)
    signal sectionVisibilityChanged(string sectionId, bool visible)
    signal cacheMiss(string sectionId)
    signal cacheHit(string sectionId)

    // CORE FUNCTIONS

    // Initialize homescreen with cache-first loading
    function initialize() {
        console.log("HomescreenManager: Initializing with cache-first loading")
        
        // Load configuration
        loadConfiguration()
        
        // 1. Load cached content immediately (0ms)
        loadCachedContent()
        
        // 2. Start background refresh after delay
        delayedRefreshTimer.start()
    }
    
    // Load user configuration
    function loadConfiguration() {
        var savedOrder = sectionOrderConfig.value
        var savedVisibility = sectionVisibilityConfig.value
        var savedIntervals = refreshIntervalsConfig.value
        
        // Apply saved section order
        if (savedOrder && Array.isArray(savedOrder)) {
            for (var i = 0; i < savedOrder.length; i++) {
                var sectionId = savedOrder[i]
                if (sectionConfigs[sectionId]) {
                    sectionConfigs[sectionId].order = i
                }
            }
        }
        
        // Apply saved visibility settings
        if (savedVisibility) {
            for (var sectionId in savedVisibility) {
                if (sectionConfigs[sectionId]) {
                    sectionConfigs[sectionId].enabled = savedVisibility[sectionId]
                }
            }
        }
        
        // Apply saved refresh intervals
        if (savedIntervals) {
            for (var sectionId in savedIntervals) {
                if (sectionConfigs[sectionId]) {
                    sectionConfigs[sectionId].refreshInterval = savedIntervals[sectionId]
                }
            }
        }
        
        console.log("HomescreenManager: Configuration loaded")
    }
    
    // Load cached content for immediate display
    function loadCachedContent() {
        console.log("HomescreenManager: Loading cached content for instant display")
        
        var enabledSections = getEnabledSectionsInOrder()
        
        for (var i = 0; i < enabledSections.length; i++) {
            var sectionId = enabledSections[i]
            var cachedData = sectionCache.loadSection(sectionId)
            
            if (cachedData) {
                console.log("Cache HIT for section:", sectionId)
                cacheHit(sectionId)
                sectionContentUpdated(sectionId, cachedData)
            } else {
                console.log("Cache MISS for section:", sectionId)
                cacheMiss(sectionId)
            }
        }
    }
    
    // Start progressive background refresh
    function startBackgroundRefresh() {
        if (backgroundRefreshActive) {
            console.log("HomescreenManager: Background refresh already active")
            return
        }
        
        console.log("HomescreenManager: Starting progressive background refresh")
        backgroundRefreshActive = true
        
        // Build priority-based loading queue
        buildLoadingQueue()
        
        // Start progressive loader
        progressiveLoader.start()
    }
    
    // Build loading queue based on priority and cache status
    function buildLoadingQueue() {
        loadingQueue = []
        var sections = getEnabledSectionsInOrder()
        
        // Sort by priority: high -> medium -> low
        var priorityOrder = { "high": 0, "medium": 1, "low": 2 }
        sections.sort(function(a, b) {
            var priorityA = priorityOrder[sectionConfigs[a].priority] || 999
            var priorityB = priorityOrder[sectionConfigs[b].priority] || 999
            return priorityA - priorityB
        })
        
        for (var i = 0; i < sections.length; i++) {
            var sectionId = sections[i]
            var config = sectionConfigs[sectionId]
            var needsRefresh = shouldRefreshSection(sectionId)
            
            if (needsRefresh) {
                loadingQueue.push({
                    sectionId: sectionId,
                    priority: config.priority,
                    type: config.type
                })
            }
        }
        
        console.log("HomescreenManager: Built loading queue with", loadingQueue.length, "items")
    }
    
    // Check if section needs refresh based on interval
    function shouldRefreshSection(sectionId) {
        var config = sectionConfigs[sectionId]
        var lastRefresh = lastRefreshTimes[sectionId] || 0
        var now = Date.now()
        var timeSinceRefresh = now - lastRefresh
        
        return timeSinceRefresh >= config.refreshInterval
    }
    
    // Get enabled sections in configured order
    function getEnabledSectionsInOrder() {
        var allSections = Object.keys(sectionConfigs)
        var enabledSections = allSections.filter(function(sectionId) {
            return sectionConfigs[sectionId].enabled
        })
        
        // Sort by order
        enabledSections.sort(function(a, b) {
            return sectionConfigs[a].order - sectionConfigs[b].order
        })
        
        return enabledSections
    }
    
    // SECTION MANAGEMENT
    
    // Reorder sections (drag & drop support)
    function reorderSections(fromIndex, toIndex) {
        console.log("HomescreenManager: Reordering section from", fromIndex, "to", toIndex)
        
        var sections = getEnabledSectionsInOrder()
        if (fromIndex < 0 || fromIndex >= sections.length || toIndex < 0 || toIndex >= sections.length) {
            console.warn("Invalid reorder indices:", fromIndex, toIndex)
            return false
        }
        
        // Update order values
        var movedSection = sections[fromIndex]
        
        if (fromIndex < toIndex) {
            // Moving down: shift items up
            for (var i = fromIndex + 1; i <= toIndex; i++) {
                sectionConfigs[sections[i]].order = i - 1
            }
        } else {
            // Moving up: shift items down
            for (var i = toIndex; i < fromIndex; i++) {
                sectionConfigs[sections[i]].order = i + 1
            }
        }
        
        sectionConfigs[movedSection].order = toIndex
        
        // Save new order
        saveConfiguration()
        
        // Emit signal
        sectionOrderChanged(getEnabledSectionsInOrder())
        
        return true
    }
    
    // Toggle section visibility
    function toggleSection(sectionId, enabled) {
        if (!sectionConfigs[sectionId]) {
            console.warn("Unknown section:", sectionId)
            return false
        }
        
        console.log("HomescreenManager: Toggle section", sectionId, "to", enabled)
        sectionConfigs[sectionId].enabled = enabled
        
        // Save configuration
        saveConfiguration()
        
        // Emit signal
        sectionVisibilityChanged(sectionId, enabled)
        
        return true
    }
    
    // Update section refresh interval
    function updateRefreshInterval(sectionId, intervalMs) {
        if (!sectionConfigs[sectionId]) {
            console.warn("Unknown section:", sectionId)
            return false
        }
        
        console.log("HomescreenManager: Update refresh interval for", sectionId, "to", intervalMs, "ms")
        sectionConfigs[sectionId].refreshInterval = intervalMs
        
        // Save configuration
        saveConfiguration()
        
        return true
    }
    
    // CONFIGURATION PERSISTENCE
    
    // Save current configuration
    function saveConfiguration() {
        // Save section order
        var currentOrder = getEnabledSectionsInOrder()
        var allSectionsOrder = Object.keys(sectionConfigs).sort(function(a, b) {
            return sectionConfigs[a].order - sectionConfigs[b].order
        })
        sectionOrderConfig.value = allSectionsOrder
        
        // Save visibility settings
        var visibility = {}
        for (var sectionId in sectionConfigs) {
            visibility[sectionId] = sectionConfigs[sectionId].enabled
        }
        sectionVisibilityConfig.value = visibility
        
        // Save refresh intervals
        var intervals = {}
        for (var sectionId in sectionConfigs) {
            intervals[sectionId] = sectionConfigs[sectionId].refreshInterval
        }
        refreshIntervalsConfig.value = intervals
        
        console.log("HomescreenManager: Configuration saved")
    }
    
    // SECTION LOADING
    
    // Load specific section content
    function loadSection(sectionId) {
        if (loadingStates[sectionId]) {
            console.log("Section already loading:", sectionId)
            return
        }
        
        console.log("HomescreenManager: Loading section", sectionId)
        loadingStates[sectionId] = true
        lastRefreshTimes[sectionId] = Date.now()
        
        var config = sectionConfigs[sectionId]
        
        // Trigger appropriate API call based on section type
        switch (config.type) {
            case "recent":
            case "foryou":
                console.log("HomescreenManager: Loading homepage for recent/foryou")
                tidalApi.getHomepage() // loads recent, for you
                break
            case "topArtists":
                console.log("HomescreenManager: Loading top artists")
                tidalApi.getTopArtists()
                break
            case "topAlbums":
            case "topTracks":
                console.log("HomescreenManager: Loading favorites")
                tidalApi.getFavorits() // This loads favorite albums and tracks
                break
            case "personalPlaylists":
                console.log("HomescreenManager: Loading personal playlists")
                tidalApi.getPersonalPlaylists()
                break
            case "dailyMixes":
                console.log("HomescreenManager: Loading daily mixes")
                tidalApi.getDailyMixes()
                break
            case "radioMixes":
                console.log("HomescreenManager: Loading radio mixes")
                tidalApi.getRadioMixes()
                break
        }
    }
    
    // Mark section as loaded and cache content
    function markSectionLoaded(sectionId, content) {
        loadingStates[sectionId] = false
        
        // Cache the content
        if (content && content.length > 0) {
            console.log("HomescreenManager: Caching", content.length, "items for section", sectionId)
            sectionCache.storeSection(sectionId, content)
            
            // Emit signal for immediate UI update
            sectionContentUpdated(sectionId, content)
        } else {
            console.log("HomescreenManager: No content to cache for section", sectionId)
        }
        
        console.log("HomescreenManager: Section loaded", sectionId)
    }
    
    // Delayed refresh timer for initialization
    Timer {
        id: delayedRefreshTimer
        interval: 100
        repeat: false
        running: false
        onTriggered: startBackgroundRefresh()
    }
    
    // Progressive loading timer
    Timer {
        id: progressiveLoader
        interval: 200  // 200ms between section loads
        repeat: true
        running: false
        
        onTriggered: {
            if (loadingQueue.length === 0) {
                stop()
                backgroundRefreshActive = false
                console.log("HomescreenManager: Background refresh completed")
                return
            }
            
            var next = loadingQueue.shift()
            loadSection(next.sectionId)
        }
    }
    
    // Reference to section cache
    property alias sectionCache: sectionCache
    
    SectionCache {
        id: sectionCache
    }
    
    // PUBLIC API
    
    // Get section configuration
    function getSectionConfig(sectionId) {
        return sectionConfigs[sectionId] || null
    }
    
    // Get all section configurations
    function getAllSectionConfigs() {
        return sectionConfigs
    }
    
    // Check if section is loading
    function isSectionLoading(sectionId) {
        return loadingStates[sectionId] || false
    }
    
    // Force refresh specific section
    function forceRefreshSection(sectionId) {
        if (!sectionConfigs[sectionId]) {
            return false
        }
        
        lastRefreshTimes[sectionId] = 0  // Force refresh
        loadSection(sectionId)
        return true
    }
    
    // Force refresh all sections
    function forceRefreshAll() {
        console.log("HomescreenManager: Force refresh all sections")
        for (var sectionId in sectionConfigs) {
            if (sectionConfigs[sectionId].enabled) {
                lastRefreshTimes[sectionId] = 0
            }
        }
        startBackgroundRefresh()
    }
    
    Component.onCompleted: {
        console.log("HomescreenManager: Component completed, initializing...")
        initialize()
    }
}
