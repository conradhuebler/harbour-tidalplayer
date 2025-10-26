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

    // Edit mode state (simplified - no drag-n-drop)
    property bool showingSettingsHint: false

    SilicaFlickable {
        id: flickable
        anchors.fill: parent
        anchors.bottomMargin: applicationWindow.miniPlayerPanel.height
        contentHeight: contentColumn.height

        PullDownMenu {
            MenuItem {
                text: editMode ? qsTr("Save Changes") : qsTr("Edit Sections")
                onClicked: {
                    editMode = !editMode
                }
            }

            MenuItem {
                text: qsTr("Refresh All")
                onClicked: {
                    homescreenManager.forceRefreshAll()
                }
            }
        }

        Column {
            id: contentColumn
            width: parent.width
            spacing: 0

            // Page header with integrated controls
            PageHeader {
                title: editMode ? qsTr("Edit Personal Page") : qsTr("Personal Collection")

                // Action buttons row
                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.horizontalPageMargin
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.paddingSmall

                    // Edit mode indicator
                    Rectangle {
                        width: editModeLabel.width + 2 * Theme.paddingSmall
                        height: editModeLabel.height + Theme.paddingSmall
                        color: Theme.rgba(Theme.highlightColor, 0.2)
                        radius: Theme.paddingSmall
                        visible: editMode
                        anchors.verticalCenter: parent.verticalCenter

                        Label {
                            id: editModeLabel
                            text: qsTr("EDIT")
                            font.pixelSize: Theme.fontSizeExtraSmall
                            font.bold: true
                            color: Theme.highlightColor
                            anchors.centerIn: parent
                        }
                    }

                    // Control buttons
                    IconButton {
                        icon.source: editMode ? "image://theme/icon-m-accept" : "image://theme/icon-m-edit"
                        icon.width: Theme.iconSizeSmall
                        icon.height: Theme.iconSizeSmall
                        onClicked: {
                            editMode = !editMode
                        }
                    }

                    IconButton {
                        icon.source: "image://theme/icon-m-refresh"
                        icon.width: Theme.iconSizeSmall
                        icon.height: Theme.iconSizeSmall
                        onClicked: {
                            homescreenManager.forceRefreshAll()
                        }
                    }

                    IconButton {
                        icon.source: "image://theme/icon-m-developer-mode"
                        icon.width: Theme.iconSizeSmall
                        icon.height: Theme.iconSizeSmall
                        onClicked: {
                            pageStack.push(Qt.resolvedUrl("HomescreenSettings.qml"), {
                                homescreenManager: homescreenManager
                            })
                        }
                    }
                }
            }

            // Edit mode instructions with improved styling
            Item {
                width: parent.width
                height: editMode ? editInstructionsContainer.height + 2 * Theme.paddingMedium : 0
                clip: true
                opacity: editMode ? 1.0 : 0.0

                Behavior on height {
                    NumberAnimation { duration: 300; easing.type: Easing.InOutQuad }
                }

                Behavior on opacity {
                    FadeAnimation { duration: 200 }
                }

                Rectangle {
                    id: editInstructionsContainer
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Theme.horizontalPageMargin
                    height: editInstructions.height + 2 * Theme.paddingLarge
                    color: Theme.rgba(Theme.highlightBackgroundColor, 0.08)
                    radius: Theme.paddingMedium
                    border.width: 1
                    border.color: Theme.rgba(Theme.highlightColor, 0.2)

                    Column {
                        id: editInstructions
                        anchors.centerIn: parent
                        width: parent.width - 2 * Theme.paddingLarge
                        spacing: Theme.paddingSmall

                        Label {
                            width: parent.width
                            text: qsTr("Configure Mode Active")
                            font.pixelSize: Theme.fontSizeSmall
                            font.bold: true
                            color: Theme.highlightColor
                            horizontalAlignment: Text.AlignCenter
                        }

                        Label {
                            width: parent.width
                            text: qsTr("• Tap the settings icon to configure sections\n• Reorder sections in the Settings page\n• Enable/disable sections as needed")
                            font.pixelSize: Theme.fontSizeExtraSmall
                            color: Theme.secondaryColor
                            wrapMode: Text.WordWrap
                            horizontalAlignment: Text.AlignLeft
                        }
                    }
                }
            }

            // Dynamic sections container with improved spacing
            Column {
                id: sectionsContainer
                width: parent.width
                spacing: editMode ? Theme.paddingMedium : Theme.paddingSmall

                Behavior on spacing {
                    NumberAnimation {
                        duration: 300
                        easing.type: Easing.OutCubic
                    }
                }

                // Add subtle background pulse in edit mode
                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    border.width: editMode ? 1 : 0
                    border.color: Theme.rgba(Theme.highlightColor, 0.3)
                    radius: Theme.paddingMedium
                    opacity: editMode ? 0.5 : 0.0

                    Behavior on opacity {
                        FadeAnimation { duration: 400 }
                    }

                    Behavior on border.width {
                        NumberAnimation { duration: 300 }
                    }

                    // Subtle pulsing animation in edit mode
                    SequentialAnimation {
                        running: editMode
                        loops: Animation.Infinite

                        NumberAnimation {
                            target: parent
                            property: "border.color"
                            to: Theme.rgba(Theme.highlightColor, 0.6)
                            duration: 2000
                            easing.type: Easing.InOutSine
                        }
                        NumberAnimation {
                            target: parent
                            property: "border.color"
                            to: Theme.rgba(Theme.highlightColor, 0.2)
                            duration: 2000
                            easing.type: Easing.InOutSine
                        }
                    }
                }

                // Debug info (only visible in debug mode and when no sections loaded)
                Rectangle {
                    width: parent.width
                    height: 50
                    color: Theme.rgba(Theme.highlightColor, 0.1)
                    radius: Theme.paddingSmall
                    visible: (applicationWindow.settings.debugLevel >= 2) && (sectionsContainer.children.length <= 1) && !initialLoadComplete

                    Label {
                        anchors.centerIn: parent
                        text: qsTr("Debug: Section container ready (%1 sections)").arg(sectionsContainer.children.length)
                        color: Theme.secondaryColor
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }
                }

                // Sections will be created dynamically here
            }

            // Loading indicator for initial load
            Column {
                width: parent.width
                height: !initialLoadComplete && sectionsContainer.children.length === 0 ? implicitHeight : 0
                spacing: Theme.paddingLarge
                visible: height > 0

                Behavior on height {
                    NumberAnimation { duration: 300; easing.type: Easing.InOutQuad }
                }

                Item {
                    width: parent.width
                    height: Theme.paddingLarge * 4
                }

                BusyIndicator {
                    anchors.horizontalCenter: parent.horizontalCenter
                    running: !initialLoadComplete
                    size: BusyIndicatorSize.Large
                }

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: qsTr("Loading personal content...")
                    color: Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeSmall
                }

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: qsTr("This may take a moment")
                    color: Theme.secondaryHighlightColor
                    font.pixelSize: Theme.fontSizeExtraSmall
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
            if (applicationWindow.settings.debugLevel >= 2) {
                console.log("PersonalConfigurable: Section content updated:", sectionId, "items:", content ? content.length : 0)
            }
            updateSection(sectionId, content)
        }

        // Handle section order changes
        onSectionOrderChanged: {
            if (applicationWindow.settings.debugLevel >= 1) {
                console.log("PersonalConfigurable: Section order changed")
            }
            refreshSectionOrder()
        }

        // Handle section visibility changes
        onSectionVisibilityChanged: {
            if (applicationWindow.settings.debugLevel >= 2) {
                console.log("PersonalConfigurable: Section visibility changed:", sectionId, "visible:", visible)
            }
            updateSectionVisibility(sectionId, visible)
        }

        // Handle cache events with debug logging
        onCacheHit: {
            if (applicationWindow.settings.debugLevel >= 2) {
                console.log("PersonalConfigurable: Cache hit for", sectionId)
            }
        }

        onCacheMiss: {
            if (applicationWindow.settings.debugLevel >= 1) {
                console.log("PersonalConfigurable: Cache miss for", sectionId)
            }
            // Create section with empty content for cache misses
            updateSection(sectionId, [])
        }
    }

    // Connections to TidalApi for data updates with improved error handling
    Connections {
        target: tidalApi
        ignoreUnknownSignals: true

        // Recent content handlers - collect individual items
        onRecentAlbum: {
            if (!album_info || !album_info.title) {
                console.warn("PersonalConfigurable: Invalid album_info received")
                return
            }
            if (applicationWindow.settings.debugLevel >= 2) {
                console.log("PersonalConfigurable: Recent album received:", album_info.title)
            }
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
            if (applicationWindow.settings.debugLevel >= 1) {
                console.log("PersonalConfigurable: Login successful, starting content load")
            }
            initialLoadComplete = false

            // Reset data arrays
            recentItems = []
            foryouItems = []
            personalPlaylistItems = []
            topArtistItems = []
            topAlbumItems = []
            topTrackItems = []
            dailyMixItems = []
            radioMixItems = []

            // Initialize homescreen manager
            homescreenManager.initialize()
        }
    }

    // HELPER FUNCTIONS

    // Helper to update section and cache content with error handling
    function updateAndCacheSection(sectionId, items) {
        if (!sectionId || !items) {
            console.warn("PersonalConfigurable: Invalid parameters for updateAndCacheSection")
            return
        }

        try {
            var itemsCopy = items.slice()
            updateSection(sectionId, itemsCopy)
            if (homescreenManager && homescreenManager.markSectionLoaded) {
                homescreenManager.markSectionLoaded(sectionId, itemsCopy)
            }
        } catch (error) {
            console.error("PersonalConfigurable: Error in updateAndCacheSection:", error)
        }
    }

    // SECTION MANAGEMENT FUNCTIONS (Simplified - no drag-n-drop)

    // Create or update a section with improved error handling
    function updateSection(sectionId, content) {
        if (applicationWindow.settings.debugLevel >= 2) {
            console.log("PersonalConfigurable: updateSection called for", sectionId, "with content length:", content ? content.length : 0)
        }

        if (!sectionId) {
            console.warn("PersonalConfigurable: Invalid sectionId provided")
            return
        }

        try {
            var section = findSection(sectionId)
            var config = homescreenManager ? homescreenManager.getSectionConfig(sectionId) : null

            if (!config) {
                console.warn("PersonalConfigurable: No config found for section:", sectionId)
                return
            }

            if (applicationWindow.settings.debugLevel >= 2) {
                console.log("PersonalConfigurable: Section config found:", config.title, "enabled:", config.enabled)
            }

            if (!section) {
                // Create new section
                if (applicationWindow.settings.debugLevel >= 1) {
                    console.log("PersonalConfigurable: Creating new section for", sectionId)
                }
                section = createSection(sectionId, config)
                if (applicationWindow.settings.debugLevel >= 1) {
                    console.log("PersonalConfigurable: Section created:", section ? "SUCCESS" : "FAILED")
                }
            }

            if (section && section.updateContent && section.setLoading) {
                if (applicationWindow.settings.debugLevel >= 2) {
                    console.log("PersonalConfigurable: Updating section content and setting loading false")
                }
                section.updateContent(content || [])
                section.setLoading(false)
            } else if (!section) {
                console.warn("PersonalConfigurable: Failed to create or find section:", sectionId)
            }

            if (applicationWindow.settings.debugLevel >= 2) {
                console.log("PersonalConfigurable: sectionsContainer now has", sectionsContainer.children.length, "children")
            }

            // Mark initial load as complete when we have content
            if (!initialLoadComplete && sectionsContainer.children.length > 0) {
                initialLoadComplete = true
                if (applicationWindow.settings.debugLevel >= 1) {
                    console.log("PersonalConfigurable: Initial load marked as complete")
                }
            }
        } catch (error) {
            console.error("PersonalConfigurable: Error in updateSection:", error)
        }
    }

    // Create a new section component with improved error handling
    function createSection(sectionId, config) {
        if (applicationWindow.settings.debugLevel >= 2) {
            console.log("PersonalConfigurable: Creating component for", sectionId)
        }

        var component = Qt.createComponent("../components/homescreen/ConfigurableSection.qml")

        // Wait for component to be ready if still loading
        if (component.status === Component.Loading) {
            component.statusChanged.connect(function() {
                if (component.status === Component.Ready) {
                    createSectionObject(component, sectionId, config)
                } else if (component.status === Component.Error) {
                    console.error("PersonalConfigurable: Component loading failed:", component.errorString())
                }
            })
            return null
        }

        if (component.status !== Component.Ready) {
            console.error("PersonalConfigurable: Failed to create ConfigurableSection:", component.errorString())
            return null
        }

        return createSectionObject(component, sectionId, config)
    }

    // Helper function to create section object
    function createSectionObject(component, sectionId, config) {
        if (applicationWindow.settings.debugLevel >= 2) {
            console.log("PersonalConfigurable: Creating object with config:", config.title, config.type)
        }

        var section = component.createObject(sectionsContainer, {
            sectionId: sectionId,
            sectionTitle: config.title,
            sectionType: config.type,
            sectionEnabled: config.enabled,
            maxItems: config.maxItems,
            sectionOrder: config.order,
            dragEnabled: false  // Drag disabled - use Settings for reordering
        })

        if (!section) {
            console.error("PersonalConfigurable: Failed to instantiate ConfigurableSection for", sectionId)
            return null
        }

        // Create signal connections component for this section
        createSectionConnections(section)

        if (applicationWindow.settings.debugLevel >= 1) {
            console.log("PersonalConfigurable: Created section", sectionId, "successfully")
        }

        return section
    }

    // Create proper Connections component for section signals (drag handlers removed)
    function createSectionConnections(section) {
        if (!section) {
            return
        }

        try {
            var connectionsComponent = Qt.createQmlObject(`
                import QtQuick 2.0
                Connections {
                    id: sectionConnections
                    target: section
                    ignoreUnknownSignals: true

                    function onSectionRefreshRequested(sectionId) {
                        if (homescreenManager && homescreenManager.forceRefreshSection) {
                            homescreenManager.forceRefreshSection(sectionId)
                        }
                    }

                    function onSectionVisibilityChanged(sectionId, visible) {
                        if (homescreenManager && homescreenManager.toggleSection) {
                            homescreenManager.toggleSection(sectionId, visible)
                        }
                        updateSectionVisibility(sectionId, visible)
                    }

                    function onSectionConfigChanged(sectionId, config) {
                        if (config && config.maxItems !== undefined && homescreenManager) {
                            var sectionConfig = homescreenManager.getSectionConfig(sectionId)
                            if (sectionConfig) {
                                sectionConfig.maxItems = config.maxItems
                            }
                        }
                    }

                    function onSectionCacheCleared(sectionId) {
                        if (homescreenManager && homescreenManager.sectionCache && homescreenManager.sectionCache.clearSection) {
                            homescreenManager.sectionCache.clearSection(sectionId)
                        }
                    }

                    // Drag handlers removed - configuration now handled in Settings
                }
            `, personalConfigurablePage)

            if (connectionsComponent) {
                // Store reference for cleanup
                section.sectionConnections = connectionsComponent
            }
        } catch (error) {
            console.error("PersonalConfigurable: Failed to create section connections:", error)
            // Fallback to old method
            connectSectionSignalsLegacy(section)
        }
    }

    // Legacy signal connection method (fallback)
    function connectSectionSignalsLegacy(section) {
        if (applicationWindow.settings.debugLevel >= 1) {
            console.warn("PersonalConfigurable: Using legacy signal connections for", section.sectionId)
        }

        section.onSectionRefreshRequested = function(sectionId) {
            if (homescreenManager && homescreenManager.forceRefreshSection) {
                homescreenManager.forceRefreshSection(sectionId)
            }
        }
        section.onSectionVisibilityChanged = function(sectionId, visible) {
            if (homescreenManager && homescreenManager.toggleSection) {
                homescreenManager.toggleSection(sectionId, visible)
            }
            updateSectionVisibility(sectionId, visible)
        }
        section.onSectionConfigChanged = function(sectionId, config) {
            if (config && config.maxItems !== undefined && homescreenManager) {
                var sectionConfig = homescreenManager.getSectionConfig(sectionId)
                if (sectionConfig) {
                    sectionConfig.maxItems = config.maxItems
                }
            }
        }
        section.onSectionCacheCleared = function(sectionId) {
            if (homescreenManager && homescreenManager.sectionCache && homescreenManager.sectionCache.clearSection) {
                homescreenManager.sectionCache.clearSection(sectionId)
            }
        }
        // Drag handlers removed - configuration now handled in Settings
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

    // Refresh section order after reordering (simplified - no animations)
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

    // EDIT MODE MANAGEMENT (Simplified)

    onEditModeChanged: {
        // Update drag enabled state for all sections (disabled)
        for (var i = 0; i < sectionsContainer.children.length; i++) {
            var section = sectionsContainer.children[i]
            if (section.hasOwnProperty('dragEnabled')) {
                section.dragEnabled = false  // Always disabled
            }
        }
    }

    // PAGE LIFECYCLE

    Component.onCompleted: {
        if (applicationWindow.settings.debugLevel >= 1) {
            console.log("PersonalConfigurable: Component completed")
        }

        // Initialize homescreen if user is already logged in
        if (tidalApi && tidalApi.loginTrue) {
            if (applicationWindow.settings.debugLevel >= 1) {
                console.log("PersonalConfigurable: User already logged in, initializing")
            }
            homescreenManager.initialize()
        } else {
            if (applicationWindow.settings.debugLevel >= 2) {
                console.log("PersonalConfigurable: User not logged in, waiting for login")
            }
        }
    }

    Component.onDestruction: {
        if (applicationWindow.settings.debugLevel >= 2) {
            console.log("PersonalConfigurable: Component being destroyed")
        }

        // Clean up all section connections
        cleanupAllSectionConnections()
    }

    // Clean up all section connection components
    function cleanupAllSectionConnections() {
        try {
            for (var i = 0; i < sectionsContainer.children.length; i++) {
                var section = sectionsContainer.children[i]
                if (section && section.sectionConnections) {
                    if (applicationWindow.settings.debugLevel >= 2) {
                        console.log("PersonalConfigurable: Cleaning up connections for", section.sectionId)
                    }
                    section.sectionConnections.destroy()
                    section.sectionConnections = null
                }
            }
        } catch (error) {
            console.error("PersonalConfigurable: Error during connection cleanup:", error)
        }
    }

    // Clean up connections for a specific section
    function cleanupSectionConnections(section) {
        if (section && section.sectionConnections) {
            try {
                section.sectionConnections.destroy()
                section.sectionConnections = null
            } catch (error) {
                console.error("PersonalConfigurable: Error cleaning up section connections:", error)
            }
        }
    }
}