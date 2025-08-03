import QtQuick 2.0
import QtQuick.LocalStorage 2.0

Item {
    id: sectionCache

    // HOMESCREEN PERSONALIZATION: Intelligent section content caching
    
    // Cache configuration
    property int maxAge: 3600000        // 1 hour default max age
    property int maxSections: 20        // Maximum cached sections
    property int maxItemsPerSection: 50 // Maximum items per section
    
    // Runtime cache (in-memory for performance)
    property var memoryCache: ({})
    property var cacheMetadata: ({})
    property var accessOrder: []        // LRU tracking
    
    // Database for persistent storage
    property var db
    
    // Cache statistics
    property int hitCount: 0
    property int missCount: 0
    property int totalRequests: 0
    
    // CORE FUNCTIONS
    
    // Store section content in cache
    function storeSection(sectionId, content) {
        if (!sectionId || !content) {
            console.warn("SectionCache: Invalid parameters for storeSection")
            return false
        }
        
        var timestamp = Date.now()
        var cacheEntry = {
            sectionId: sectionId,
            content: content,
            timestamp: timestamp,
            size: calculateContentSize(content)
        }
        
        console.log("SectionCache: Storing section", sectionId, "with", 
                   Array.isArray(content) ? content.length : "unknown", "items")
        
        // Store in memory cache
        memoryCache[sectionId] = cacheEntry
        cacheMetadata[sectionId] = {
            timestamp: timestamp,
            accessCount: 1,
            lastAccess: timestamp
        }
        
        // Update LRU order
        updateAccessOrder(sectionId)
        
        // Store in persistent database
        storeSectionInDatabase(cacheEntry)
        
        // Enforce cache limits
        enforceCacheLimits()
        
        return true
    }
    
    // Load section content from cache
    function loadSection(sectionId) {
        if (!sectionId) {
            return null
        }
        
        totalRequests++
        
        // Check memory cache first
        var cacheEntry = memoryCache[sectionId]
        if (cacheEntry && !isExpired(sectionId)) {
            hitCount++
            console.log("SectionCache: Memory cache HIT for", sectionId)
            
            // Update access tracking
            updateAccessTracking(sectionId)
            
            return cacheEntry.content
        }
        
        // Check persistent database
        var dbContent = loadSectionFromDatabase(sectionId)
        if (dbContent && !isExpired(sectionId)) {
            hitCount++
            console.log("SectionCache: Database cache HIT for", sectionId)
            
            // Load into memory cache
            memoryCache[sectionId] = {
                sectionId: sectionId,
                content: dbContent,
                timestamp: cacheMetadata[sectionId].timestamp || Date.now(),
                size: calculateContentSize(dbContent)
            }
            
            updateAccessTracking(sectionId)
            return dbContent
        }
        
        // Cache miss
        missCount++
        console.log("SectionCache: Cache MISS for", sectionId)
        return null
    }
    
    // Check if cached content is expired
    function isExpired(sectionId) {
        var metadata = cacheMetadata[sectionId]
        if (!metadata) {
            return true
        }
        
        var age = Date.now() - metadata.timestamp
        return age > maxAge
    }
    
    // Update access order for LRU
    function updateAccessOrder(sectionId) {
        // Remove from current position
        var index = accessOrder.indexOf(sectionId)
        if (index > -1) {
            accessOrder.splice(index, 1)
        }
        
        // Add to front (most recent)
        accessOrder.unshift(sectionId)
    }
    
    // Update access tracking
    function updateAccessTracking(sectionId) {
        if (!cacheMetadata[sectionId]) {
            cacheMetadata[sectionId] = {
                timestamp: Date.now(),
                accessCount: 0,
                lastAccess: 0
            }
        }
        
        cacheMetadata[sectionId].accessCount++
        cacheMetadata[sectionId].lastAccess = Date.now()
        updateAccessOrder(sectionId)
    }
    
    // Calculate content size (approximate)
    function calculateContentSize(content) {
        if (Array.isArray(content)) {
            return content.length
        } else if (typeof content === 'object') {
            return Object.keys(content).length
        }
        return 1
    }
    
    // Enforce cache size limits
    function enforceCacheLimits() {
        // Remove expired entries first
        cleanExpiredEntries()
        
        // If still over limit, remove least recently used
        while (accessOrder.length > maxSections) {
            var lruSectionId = accessOrder.pop()
            console.log("SectionCache: Evicting LRU section", lruSectionId)
            
            delete memoryCache[lruSectionId]
            delete cacheMetadata[lruSectionId]
            removeSectionFromDatabase(lruSectionId)
        }
    }
    
    // Clean expired cache entries
    function cleanExpiredEntries() {
        var now = Date.now()
        var expiredSections = []
        
        for (var sectionId in cacheMetadata) {
            var age = now - cacheMetadata[sectionId].timestamp
            if (age > maxAge) {
                expiredSections.push(sectionId)
            }
        }
        
        for (var i = 0; i < expiredSections.length; i++) {
            var expiredId = expiredSections[i]
            console.log("SectionCache: Removing expired section", expiredId)
            
            delete memoryCache[expiredId]
            delete cacheMetadata[expiredId]
            
            var orderIndex = accessOrder.indexOf(expiredId)
            if (orderIndex > -1) {
                accessOrder.splice(orderIndex, 1)
            }
            
            removeSectionFromDatabase(expiredId)
        }
    }
    
    // DATABASE OPERATIONS
    
    // Initialize database
    function initDatabase() {
        db = LocalStorage.openDatabaseSync("HomescreenCache", "1.0", "Homescreen Section Cache", 5000000)
        
        db.transaction(function(tx) {
            // Main cache table
            tx.executeSql('CREATE TABLE IF NOT EXISTS section_cache(' +
                         'section_id TEXT PRIMARY KEY, ' +
                         'content TEXT, ' +
                         'timestamp INTEGER, ' +
                         'size INTEGER)')
            
            // Create index for faster queries
            tx.executeSql('CREATE INDEX IF NOT EXISTS idx_section_timestamp ON section_cache(timestamp)')
            
            console.log("SectionCache: Database initialized")
        })
    }
    
    // Store section in database
    function storeSectionInDatabase(cacheEntry) {
        if (!db) return
        
        db.transaction(function(tx) {
            try {
                var contentJson = JSON.stringify(cacheEntry.content)
                tx.executeSql('INSERT OR REPLACE INTO section_cache(section_id, content, timestamp, size) VALUES(?, ?, ?, ?)',
                             [cacheEntry.sectionId, contentJson, cacheEntry.timestamp, cacheEntry.size])
            } catch (e) {
                console.error("SectionCache: Database store error:", e)
            }
        })
    }
    
    // Load section from database
    function loadSectionFromDatabase(sectionId) {
        if (!db) return null
        
        var result = null
        db.transaction(function(tx) {
            try {
                var rs = tx.executeSql('SELECT content, timestamp FROM section_cache WHERE section_id = ?', [sectionId])
                if (rs.rows.length > 0) {
                    var row = rs.rows.item(0)
                    result = JSON.parse(row.content)
                    
                    // Update metadata if not in memory
                    if (!cacheMetadata[sectionId]) {
                        cacheMetadata[sectionId] = {
                            timestamp: row.timestamp,
                            accessCount: 0,
                            lastAccess: Date.now()
                        }
                    }
                }
            } catch (e) {
                console.error("SectionCache: Database load error:", e)
            }
        })
        
        return result
    }
    
    // Remove section from database
    function removeSectionFromDatabase(sectionId) {
        if (!db) return
        
        db.transaction(function(tx) {
            try {
                tx.executeSql('DELETE FROM section_cache WHERE section_id = ?', [sectionId])
            } catch (e) {
                console.error("SectionCache: Database remove error:", e)
            }
        })
    }
    
    // Load cache metadata from database
    function loadCacheFromDatabase() {
        if (!db) return
        
        console.log("SectionCache: Loading cache metadata from database")
        
        db.transaction(function(tx) {
            try {
                var rs = tx.executeSql('SELECT section_id, timestamp FROM section_cache ORDER BY timestamp DESC')
                
                for (var i = 0; i < rs.rows.length; i++) {
                    var row = rs.rows.item(i)
                    var sectionId = row.section_id
                    
                    cacheMetadata[sectionId] = {
                        timestamp: row.timestamp,
                        accessCount: 0,
                        lastAccess: row.timestamp
                    }
                    
                    accessOrder.push(sectionId)
                }
                
                console.log("SectionCache: Loaded metadata for", accessOrder.length, "cached sections")
                
            } catch (e) {
                console.error("SectionCache: Database metadata load error:", e)
            }
        })
    }
    
    // CACHE MANAGEMENT
    
    // Clear all cache
    function clearAll() {
        console.log("SectionCache: Clearing all cache")
        
        memoryCache = {}
        cacheMetadata = {}
        accessOrder = []
        
        if (db) {
            db.transaction(function(tx) {
                tx.executeSql('DELETE FROM section_cache')
            })
        }
        
        hitCount = 0
        missCount = 0
        totalRequests = 0
    }
    
    // Clear specific section
    function clearSection(sectionId) {
        console.log("SectionCache: Clearing section", sectionId)
        
        delete memoryCache[sectionId]
        delete cacheMetadata[sectionId]
        
        var index = accessOrder.indexOf(sectionId)
        if (index > -1) {
            accessOrder.splice(index, 1)
        }
        
        removeSectionFromDatabase(sectionId)
    }
    
    // Get cache statistics
    function getCacheStats() {
        var memorySize = Object.keys(memoryCache).length
        var totalSize = Object.keys(cacheMetadata).length
        var hitRate = totalRequests > 0 ? (hitCount / totalRequests * 100).toFixed(1) : 0
        
        return {
            memorySize: memorySize,
            totalSize: totalSize,
            hitCount: hitCount,
            missCount: missCount,
            totalRequests: totalRequests,
            hitRate: hitRate,
            maxAge: maxAge,
            maxSections: maxSections
        }
    }
    
    // Update cache configuration
    function updateConfig(newMaxAge, newMaxSections) {
        if (newMaxAge !== undefined) {
            maxAge = newMaxAge
            console.log("SectionCache: Updated maxAge to", maxAge)
        }
        
        if (newMaxSections !== undefined) {
            maxSections = newMaxSections
            console.log("SectionCache: Updated maxSections to", maxSections)
            enforceCacheLimits()
        }
    }
    
    // Preload sections (for predictive caching)
    function preloadSections(sectionIds) {
        console.log("SectionCache: Preloading sections", sectionIds)
        
        for (var i = 0; i < sectionIds.length; i++) {
            var sectionId = sectionIds[i]
            if (!memoryCache[sectionId]) {
                // Try to load from database to memory
                loadSectionFromDatabase(sectionId)
            }
        }
    }
    
    // AUTOMATIC CLEANUP
    
    // Periodic cleanup timer
    Timer {
        interval: 300000  // 5 minutes
        running: true
        repeat: true
        onTriggered: {
            console.log("SectionCache: Running periodic cleanup")
            cleanExpiredEntries()
            
            var stats = getCacheStats()
            console.log("SectionCache: Stats - Memory:", stats.memorySize, 
                       "Total:", stats.totalSize, "Hit Rate:", stats.hitRate + "%")
        }
    }
    
    // COMPONENT LIFECYCLE
    
    Component.onCompleted: {
        console.log("SectionCache: Initializing cache system")
        initDatabase()
        loadCacheFromDatabase()
        console.log("SectionCache: Cache system ready")
    }
    
    Component.onDestruction: {
        console.log("SectionCache: Cache cleanup on destruction")
        // Final cleanup is automatic with LocalStorage
    }
}
