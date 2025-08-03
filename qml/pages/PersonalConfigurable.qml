import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components/homescreen"

Item {
    id: personalConfigurablePage
    
    // HOMESCREEN PERSONALIZATION: New configurable personal page
    
    property bool editMode: false
    property bool initialLoadComplete: false
    
    // Temporary data collectors for building section content
    property var recentItems: []
    property var foryouItems: []
    property var personalPlaylistItems: []
    property var topArtistItems: []
    property var topAlbumItems: []
    property var topTrackItems: []
    property var dailyMixItems: []
    property var radioMixItems: []
    
    SilicaFlickable {
        id: flickable
        anchors.fill: parent
        anchors.bottomMargin: miniPlayerPanel.height
        contentHeight: contentColumn.height
        
        // Control buttons row
        Item {
            width: parent.width
            height: Theme.itemSizeSmall + Theme.paddingMedium
            
            Row {
                anchors.centerIn: parent
                spacing: Theme.paddingMedium
                
                IconButton {
                    icon.source: editMode ? "image://theme/icon-m-accept" : "image://theme/icon-m-edit"
                    onClicked: {
                        editMode = !editMode
                        if (editMode) {
                            homescreenManager.sectionCache.clearAll()
                        }
                    }
                }
                
                IconButton {
                    icon.source: "image://theme/icon-m-refresh"
                    onClicked: {
                        homescreenManager.forceRefreshAll()
                    }
                }
                
                IconButton {
                    icon.source: "image://theme/icon-m-developer-mode"
                    onClicked: {
                        // Hier könnten wir später Settings öffnen
                        console.log("Settings: Würde HomescreenSettings.qml öffnen")
                    }
                }
            }
        }
        
        Column {
            id: contentColumn
            width: parent.width
            spacing: 0
            
            
            // Page header
            PageHeader {
                title: editMode ? qsTr("Edit Personal Page") : qsTr("Personal Collection")
                
                // Edit mode indicator
                Rectangle {
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.paddingLarge
                    anchors.verticalCenter: parent.verticalCenter
                    width: editModeLabel.width + 2 * Theme.paddingSmall
                    height: editModeLabel.height + Theme.paddingSmall
                    color: Theme.rgba(Theme.highlightColor, 0.2)
                    radius: 4
                    visible: editMode
                    
                    Label {
                        id: editModeLabel
                        text: qsTr("EDIT")
                        font.pixelSize: Theme.fontSizeExtraSmall
                        font.bold: true
                        color: Theme.highlightColor
                        anchors.centerIn: parent
                    }
                }
            }
            
            // Edit mode instructions
            Item {
                width: parent.width
                height: editMode ? editInstructions.height + 2 * Theme.paddingMedium : 0
                clip: true
                
                Behavior on height {
                    NumberAnimation { duration: 300; easing.type: Easing.InOutQuad }
                }
                
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: Theme.paddingMedium
                    color: Theme.rgba(Theme.highlightBackgroundColor, 0.1)
                    radius: Theme.paddingSmall
                    
                    Label {
                        id: editInstructions
                        anchors.centerIn: parent
                        width: parent.width - 2 * Theme.paddingMedium
                        text: qsTr("• Drag sections to reorder\n• Use switches to show/hide sections\n• Tap settings to configure each section")
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.secondaryColor
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignLeft
                    }
                }
            }
            
            // Dynamic sections container
            Column {
                id: sectionsContainer
                width: parent.width
                spacing: Theme.paddingSmall
                
                // Test element to verify container is working
                Rectangle {
                    width: parent.width
                    height: 50
                    color: Theme.rgba(Theme.highlightColor, 0.3)
                    visible: sectionsContainer.children.length <= 1 // Only show if no sections created
                    
                    Label {
                        anchors.centerIn: parent
                        text: "TEST: Container is working - " + sectionsContainer.children.length + " children"
                        color: Theme.primaryColor
                        font.pixelSize: Theme.fontSizeSmall
                    }
                }
                
                // Sections will be created dynamically here
            }
            
            // Loading indicator for initial load
            Item {
                width: parent.width
                height: !initialLoadComplete && sectionsContainer.children.length === 0 ? 200 : 0
                
                Behavior on height {
                    NumberAnimation { duration: 300 }
                }
                
                BusyIndicator {
                    anchors.centerIn: parent
                    running: !initialLoadComplete
                    size: BusyIndicatorSize.Large
                }
                
                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.verticalCenter
                    anchors.topMargin: Theme.paddingLarge * 2
                    text: qsTr("Loading personal content...")
                    color: Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeSmall
                }
            }
        }
        
        VerticalScrollDecorator {}
    }
    
    // Homescreen Manager - the core of the new system
    HomescreenManager {
        id: homescreenManager
        
        // Handle section content updates
        onSectionContentUpdated: {
            updateSection(sectionId, content)
        }
        
        // Handle section order changes
        onSectionOrderChanged: {
            refreshSectionOrder()
        }
        
        // Handle section visibility changes
        onSectionVisibilityChanged: {
            updateSectionVisibility(sectionId, visible)
        }
        
        // Handle cache events
        onCacheHit: {
            console.log("PersonalConfigurable: Cache hit for", sectionId)
        }
        
        onCacheMiss: {
            console.log("PersonalConfigurable: Cache miss for", sectionId)
            // Create section with empty content for cache misses
            updateSection(sectionId, [])
        }
    }
    
    // Connections to TidalApi for data updates
    Connections {
        target: tidalApi
        
        // Recent content handlers - collect individual items
        onRecentAlbum: {
            console.log("PersonalConfigurable: Recent album received:", album_info.title)
            recentItems.push({type: "album", data: album_info})
            updateAndCacheSection("recent", recentItems)
        }
        
        onRecentMix: {
            console.log("PersonalConfigurable: Recent mix received:", mix_info.title)
            recentItems.push({type: "mix", data: mix_info})
            updateAndCacheSection("recent", recentItems)
        }
        
        onRecentArtist: {
            console.log("PersonalConfigurable: Recent artist received:", artist_info.name)
            recentItems.push({type: "artist", data: artist_info})
            updateAndCacheSection("recent", recentItems)
        }
        
        onRecentPlaylist: {
            console.log("PersonalConfigurable: Recent playlist received:", playlist_info.title)
            recentItems.push({type: "playlist", data: playlist_info})
            updateAndCacheSection("recent", recentItems)
        }
        
        onRecentTrack: {
            console.log("PersonalConfigurable: Recent track received:", track_info.title)
            recentItems.push({type: "track", data: track_info})
            updateAndCacheSection("recent", recentItems)
        }
        
        // For you content handlers
        onForyouAlbum: {
            console.log("PersonalConfigurable: Foryou album received:", album_info.title)
            foryouItems.push({type: "album", data: album_info})
            updateSection("popular", foryouItems.slice())
        }
        
        onForyouArtist: {
            console.log("PersonalConfigurable: Foryou artist received:", artist_info.name)
            foryouItems.push({type: "artist", data: artist_info})
            updateSection("popular", foryouItems.slice())
        }
        
        onForyouPlaylist: {
            console.log("PersonalConfigurable: Foryou playlist received:", playlist_info.title)
            foryouItems.push({type: "playlist", data: playlist_info})
            updateSection("popular", foryouItems.slice())
        }
        
        onForyouMix: {
            console.log("PersonalConfigurable: Foryou mix received:", mix_info.title)
            foryouItems.push({type: "mix", data: mix_info})
            updateSection("popular", foryouItems.slice())
        }
        
        // Personal content handlers
        onPersonalPlaylistAdded: {
            console.log("PersonalConfigurable: Personal playlist received:", playlist_info.title)
            personalPlaylistItems.push({type: "playlist", data: playlist_info})
            updateSection("personalPlaylists", personalPlaylistItems.slice())
        }
        
        // Favorites handlers
        onFavArtists: {
            console.log("PersonalConfigurable: Fav artist received:", artist_info.name)
            topArtistItems.push({type: "artist", data: artist_info})
            updateSection("topArtists", topArtistItems.slice())
        }
        
        onFavAlbums: {
            console.log("PersonalConfigurable: Fav album received:", album_info.title)
            topAlbumItems.push({type: "album", data: album_info})
            updateSection("topAlbums", topAlbumItems.slice())
        }
        
        onFavTracks: {
            console.log("PersonalConfigurable: Fav track received:", track_info.title)
            topTrackItems.push({type: "track", data: track_info})
            updateSection("topTracks", topTrackItems.slice())
        }
        
        // Custom mixes handlers
        onCustomMix: {
            console.log("PersonalConfigurable: Custom mix received:", mix_info.title, "type:", mixType)
            if (mixType === "dailyMix") {
                dailyMixItems.push({type: "mix", data: mix_info})
                updateSection("dailyMixes", dailyMixItems.slice())
            } else if (mixType === "radioMix") {
                radioMixItems.push({type: "mix", data: mix_info})
                updateSection("radioMixes", radioMixItems.slice())
            }
        }
        
        // Top artists handler
        onTopArtist: {
            console.log("PersonalConfigurable: Top artist received:", artist_info.name)
            topArtistItems.push({type: "artist", data: artist_info})
            updateSection("topArtists", topArtistItems.slice())
        }
        
        // Login handler - trigger initial load
        onLoginSuccess: {
            console.log("PersonalConfigurable: Login successful, starting content load")
            initialLoadComplete = false
            homescreenManager.initialize()
        }
    }
    
    // HELPER FUNCTIONS
    
    // Helper to update section and cache content
    function updateAndCacheSection(sectionId, items) {
        var itemsCopy = items.slice()
        updateSection(sectionId, itemsCopy)
        homescreenManager.markSectionLoaded(sectionId, itemsCopy)
    }
    
    // SECTION MANAGEMENT FUNCTIONS
    
    // Create or update a section
    function updateSection(sectionId, content) {
        console.log("PersonalConfigurable: updateSection called for", sectionId, "with content length:", content ? content.length : 0)
        
        var section = findSection(sectionId)
        var config = homescreenManager.getSectionConfig(sectionId)
        
        if (!config) {
            console.warn("No config found for section:", sectionId)
            return
        }
        
        console.log("PersonalConfigurable: Section config found:", config.title, "enabled:", config.enabled)
        
        if (!section) {
            // Create new section
            console.log("PersonalConfigurable: Creating new section for", sectionId)
            section = createSection(sectionId, config)
            console.log("PersonalConfigurable: Section created:", section ? "SUCCESS" : "FAILED")
        }
        
        if (section) {
            console.log("PersonalConfigurable: Updating section content and setting loading false")
            section.updateContent(content)
            section.setLoading(false)
        }
        
        console.log("PersonalConfigurable: sectionsContainer now has", sectionsContainer.children.length, "children")
        
        // Mark initial load as complete when we have content
        if (!initialLoadComplete && sectionsContainer.children.length > 0) {
            initialLoadComplete = true
            console.log("PersonalConfigurable: Initial load marked as complete")
        }
    }
    
    // Create a new section component
    function createSection(sectionId, config) {
        console.log("PersonalConfigurable: Creating component for", sectionId)
        var component = Qt.createComponent("../components/homescreen/ConfigurableSection.qml")
        console.log("PersonalConfigurable: Component status:", component.status, "Ready =", Component.Ready)
        
        if (component.status !== Component.Ready) {
            console.error("Failed to create ConfigurableSection:", component.errorString())
            return null
        }
        
        console.log("PersonalConfigurable: Creating object with config:", config.title, config.type)
        var section = component.createObject(sectionsContainer, {
            sectionId: sectionId,
            sectionTitle: config.title,
            sectionType: config.type,
            sectionEnabled: config.enabled,
            maxItems: config.maxItems,
            sectionOrder: config.order,
            dragEnabled: editMode
        })
        
        if (!section) {
            console.error("Failed to instantiate ConfigurableSection")
            return null
        }
        
        console.log("PersonalConfigurable: Object created successfully, connecting signals")
        
        // Connect section signals
        connectSectionSignals(section)
        
        console.log("PersonalConfigurable: Created section", sectionId, "parent:", section.parent)
        return section
    }
    
    // Connect signals from a section to parent handlers
    function connectSectionSignals(section) {
        // Store callback functions as properties on the section
        section.onSectionRefreshRequested = function(sectionId) {
            homescreenManager.forceRefreshSection(sectionId)
        }
        section.onSectionVisibilityChanged = function(sectionId, visible) {
            homescreenManager.toggleSection(sectionId, visible)
            updateSectionVisibility(sectionId, visible)
        }
        section.onSectionConfigChanged = function(sectionId, config) {
            if (config.maxItems !== undefined) {
                homescreenManager.getSectionConfig(sectionId).maxItems = config.maxItems
            }
        }
        section.onSectionCacheCleared = function(sectionId) {
            homescreenManager.sectionCache.clearSection(sectionId)
        }
        section.onSectionDragged = function(sectionObj, offset) {
            handleSectionDrag(sectionObj, offset)
        }
        section.onSectionDragEnded = function(sectionObj, offset) {
            handleSectionDragEnd(sectionObj, offset)
        }
    }
    
    // Find existing section by ID
    function findSection(sectionId) {
        for (var i = 0; i < sectionsContainer.children.length; i++) {
            var child = sectionsContainer.children[i]
            if (child.sectionId === sectionId) {
                return child
            }
        }
        return null
    }
    
    // Update section visibility
    function updateSectionVisibility(sectionId, visible) {
        var section = findSection(sectionId)
        if (section) {
            section.sectionEnabled = visible
        }
    }
    
    // Refresh section order after reordering
    function refreshSectionOrder() {
        var enabledSections = homescreenManager.getEnabledSectionsInOrder()
        var existingSections = []
        
        // Collect existing sections
        for (var i = 0; i < sectionsContainer.children.length; i++) {
            existingSections.push(sectionsContainer.children[i])
        }
        
        // Remove all sections temporarily
        for (var j = 0; j < existingSections.length; j++) {
            existingSections[j].parent = null
        }
        
        // Re-add in correct order
        for (var k = 0; k < enabledSections.length; k++) {
            var sectionId = enabledSections[k]
            var section = findSectionInArray(existingSections, sectionId)
            if (section) {
                section.parent = sectionsContainer
                section.sectionOrder = k
            }
        }
    }
    
    // Helper to find section in array
    function findSectionInArray(sections, sectionId) {
        for (var i = 0; i < sections.length; i++) {
            if (sections[i].sectionId === sectionId) {
                return sections[i]
            }
        }
        return null
    }
    
    // DRAG & DROP HANDLERS
    
    function handleSectionDrag(section, offset) {
        // Visual feedback during drag
        section.y += offset
        
        // Show drop indicators on other sections
        for (var i = 0; i < sectionsContainer.children.length; i++) {
            var otherSection = sectionsContainer.children[i]
            if (otherSection !== section) {
                var showIndicator = Math.abs(section.y - otherSection.y) < otherSection.height / 2
                otherSection.showDropIndicator(showIndicator)
            }
        }
    }
    
    function handleSectionDragEnd(section, offset) {
        // Hide all drop indicators
        for (var i = 0; i < sectionsContainer.children.length; i++) {
            sectionsContainer.children[i].showDropIndicator(false)
        }
        
        // Calculate new position
        var targetIndex = calculateDropIndex(section, offset)
        var currentIndex = findSectionIndex(section.sectionId)
        
        if (targetIndex !== currentIndex && targetIndex >= 0) {
            homescreenManager.reorderSections(currentIndex, targetIndex)
        }
        
        // Reset position
        section.y = 0
    }
    
    function calculateDropIndex(draggedSection, offset) {
        var draggedCenter = draggedSection.y + draggedSection.height / 2
        
        for (var i = 0; i < sectionsContainer.children.length; i++) {
            var section = sectionsContainer.children[i]
            if (section !== draggedSection) {
                var sectionTop = section.y
                var sectionBottom = section.y + section.height
                
                if (draggedCenter >= sectionTop && draggedCenter <= sectionBottom) {
                    return i
                }
            }
        }
        
        return -1
    }
    
    function findSectionIndex(sectionId) {
        for (var i = 0; i < sectionsContainer.children.length; i++) {
            if (sectionsContainer.children[i].sectionId === sectionId) {
                return i
            }
        }
        return -1
    }
    
    // CONTENT AGGREGATION FUNCTIONS (from existing data)
    
    function getCombinedRecentContent() {
        // Combine all recent content into single array
        // This would aggregate from existing HorizontalList data
        return []
    }
    
    function getCombinedForyouContent() {
        // Combine all for-you content into single array
        return []
    }
    
    function getPersonalPlaylistsContent() {
        return []
    }
    
    function getTopArtistsContent() {
        return []
    }
    
    function getTopAlbumsContent() {
        return []
    }
    
    function getTopTracksContent() {
        return []
    }
    
    function getDailyMixesContent() {
        return []
    }
    
    function getRadioMixesContent() {
        return []
    }
    
    // EDIT MODE MANAGEMENT
    
    onEditModeChanged: {
        // Update drag enabled state for all sections
        for (var i = 0; i < sectionsContainer.children.length; i++) {
            var section = sectionsContainer.children[i]
            if (section.hasOwnProperty('dragEnabled')) {
                section.dragEnabled = editMode
            }
        }
    }
    
    // PAGE LIFECYCLE
    
    Component.onCompleted: {
        console.log("PersonalConfigurable: Component completed")
        
        // Initialize homescreen if user is already logged in
        if (applicationWindow.isLoggedIn) {
            homescreenManager.initialize()
        }
    }
    
    // Remove PageStatus since we're now an Item, not a Page
}
