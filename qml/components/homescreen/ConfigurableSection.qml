import QtQuick 2.0
import Sailfish.Silica 1.0
import "../../pages/personalLists"

Item {
    id: configurableSection

    // HOMESCREEN PERSONALIZATION: Reusable configurable section component
    
    // Section configuration
    property string sectionId: ""
    property string sectionTitle: ""
    property string sectionType: ""
    property var sectionContent: []
    property bool sectionEnabled: true
    property bool isLoading: false
    property int maxItems: 8
    property int sectionOrder: 0
    
    // Drag & drop properties (disabled in carousel)
    property bool dragEnabled: false
    property bool dragging: false
    property int dragStartY: 0
    property real dragOffset: 0
    
    // Visual state
    property bool expanded: true
    property bool showSettings: false
    property color backgroundColor: "transparent"
    property real contentOpacity: 1.0
    
    // Callback functions (set by parent)
    property var onSectionRefreshRequested: null
    property var onSectionVisibilityChanged: null
    property var onSectionConfigChanged: null
    property var onSectionCacheCleared: null
    property var onSectionDragged: null
    property var onSectionDragEnded: null
    
    // Sizing
    property int headerHeight: 70
    property int listHeight: 250  // Noch größer für bessere Sichtbarkeit
    property int collapsedHeight: headerHeight
    property int expandedHeight: headerHeight + listHeight
    
    height: Math.max(collapsedHeight, expanded ? expandedHeight : collapsedHeight)
    width: parent.width
    
    // Subtle background
    Rectangle {
        anchors.fill: parent
        color: Theme.rgba(Theme.highlightBackgroundColor, 0.02)
        radius: Theme.paddingSmall
    }
    
    // Visual feedback during drag
    Rectangle {
        id: dragBackground
        anchors.fill: parent
        color: Theme.rgba(Theme.highlightBackgroundColor, 0.1)
        radius: Theme.paddingSmall
        opacity: dragging ? 0.8 : 0.0
        
        Behavior on opacity {
            FadeAnimation { duration: 200 }
        }
    }
    
    // Drop target indicator
    Rectangle {
        id: dropIndicator
        width: parent.width
        height: 2
        color: Theme.highlightColor
        opacity: 0.0
        anchors.top: parent.top
        anchors.topMargin: -1
        
        Behavior on opacity {
            FadeAnimation { duration: 150 }
        }
    }
    
    Column {
        id: sectionColumn
        width: parent.width
        opacity: contentOpacity
        
        // Section header with controls
        Item {
            id: sectionHeader
            width: parent.width
            height: headerHeight
            
            // Drag handle (disabled in carousel)
            Item {
                id: dragHandle
                width: 0
                height: 0
                anchors.left: parent.left
                anchors.leftMargin: 0
                visible: false
            }
            
            // Section title and controls
            Row {
                anchors.left: parent.left
                anchors.leftMargin: Theme.paddingMedium
                anchors.right: headerControls.left
                anchors.rightMargin: Theme.paddingMedium
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.paddingMedium
                
                // Expand/collapse indicator
                Icon {
                    id: expandIcon
                    source: expanded ? "image://theme/icon-m-up" : "image://theme/icon-m-down"
                    width: Theme.iconSizeSmall
                    height: Theme.iconSizeSmall
                    anchors.verticalCenter: parent.verticalCenter
                    
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -Theme.paddingMedium
                        onClicked: {
                            expanded = !expanded
                        }
                    }
                }
                
                // Section title
                Label {
                    text: sectionTitle
                    font.pixelSize: Theme.fontSizeMedium
                    color: sectionEnabled ? Theme.primaryColor : Theme.secondaryColor
                    anchors.verticalCenter: parent.verticalCenter
                    truncationMode: TruncationMode.Fade
                    width: Math.max(0, parent.width - expandIcon.width - parent.spacing)
                }
            }
            
            // Header controls (simplified)
            Row {
                id: headerControls
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingMedium
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.paddingSmall
                
                // Loading indicator
                BusyIndicator {
                    size: BusyIndicatorSize.ExtraSmall
                    running: isLoading
                    anchors.verticalCenter: parent.verticalCenter
                    opacity: isLoading ? 1.0 : 0.0
                }
                
                // Visibility toggle (only visible in edit mode)
                Switch {
                    checked: sectionEnabled
                    anchors.verticalCenter: parent.verticalCenter
                    automaticCheck: false
                    visible: dragEnabled
                    onClicked: {
                        toggleSectionVisibility()
                    }
                }
            }
            
            // Separator line
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: Theme.secondaryColor
                opacity: 0.2
            }
        }
        
        // Section settings (collapsible)
        Item {
            width: parent.width
            height: showSettings ? settingsContent.height : 0
            clip: true
            
            Behavior on height {
                NumberAnimation { duration: 300; easing.type: Easing.InOutQuad }
            }
            
            Column {
                id: settingsContent
                width: parent.width
                spacing: Theme.paddingSmall
                
                Rectangle {
                    width: parent.width
                    height: settingsColumn.height + 2 * Theme.paddingMedium
                    color: Theme.rgba(Theme.highlightBackgroundColor, 0.1)
                    radius: Theme.paddingSmall
                    
                    Column {
                        id: settingsColumn
                        width: parent.width - 2 * Theme.paddingMedium
                        anchors.centerIn: parent
                        spacing: Theme.paddingMedium
                        
                        // Max items slider
                        Item {
                            width: parent.width
                            height: maxItemsSlider.height + maxItemsLabel.height + Theme.paddingSmall
                            
                            Label {
                                id: maxItemsLabel
                                text: qsTr("Max items: %1").arg(maxItems)
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.secondaryColor
                            }
                            
                            Slider {
                                id: maxItemsSlider
                                anchors.top: maxItemsLabel.bottom
                                anchors.topMargin: Theme.paddingSmall
                                width: parent.width
                                minimumValue: 4
                                maximumValue: 20
                                stepSize: 2
                                value: maxItems
                                onValueChanged: {
                                    if (value !== maxItems) {
                                        maxItems = value
                                        updateSectionConfig()
                                    }
                                }
                            }
                        }
                        
                        // Quick actions
                        Row {
                            spacing: Theme.paddingMedium
                            
                            Button {
                                text: qsTr("Clear Cache")
                                preferredWidth: Theme.buttonWidthSmall
                                onClicked: {
                                    clearSectionCache()
                                }
                            }
                            
                            Button {
                                text: qsTr("Reset")
                                preferredWidth: Theme.buttonWidthSmall
                                onClicked: {
                                    resetSectionSettings()
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // Section content
        Item {
            width: parent.width
            height: expanded ? listHeight : 0
            clip: true
            
            Behavior on height {
                NumberAnimation { duration: 300; easing.type: Easing.InOutQuad }
            }
            
            // Content loader based on section type
            Loader {
                id: contentLoader
                anchors.fill: parent
                active: expanded && sectionEnabled
                
                sourceComponent: {
                    switch (sectionType) {
                        case "recent":
                        case "foryou":
                        case "topArtists":
                        case "topAlbums":
                        case "topTracks":
                        case "personalPlaylists":
                        case "dailyMixes":
                        case "radioMixes":
                            return horizontalListComponent
                        default:
                            return emptyComponent
                    }
                }
                
                onLoaded: {
                    if (item && sectionContent) {
                        populateContent()
                    }
                }
            }
            
            // Empty state
            Item {
                anchors.fill: parent
                visible: !isLoading && (!sectionContent || sectionContent.length === 0) && expanded
                
                Column {
                    anchors.centerIn: parent
                    spacing: Theme.paddingMedium
                    
                    Icon {
                        source: "image://theme/icon-l-music"
                        anchors.horizontalCenter: parent.horizontalCenter
                        opacity: 0.3
                    }
                    
                    Label {
                        text: qsTr("No content available")
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.secondaryColor
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
        }
    }
    
    // COMPONENTS
    
    // Horizontal list component (reuses existing HorizontalList)
    Component {
        id: horizontalListComponent
        
        HorizontalList {
            id: horizontalList
            anchors.fill: parent
            
            // Connect to content updates
            Component.onCompleted: {
                configurableSection.populateContent()
            }
        }
    }
    
    // Empty component for unknown section types
    Component {
        id: emptyComponent
        
        Item {
            Label {
                anchors.centerIn: parent
                text: qsTr("Unknown section type: %1").arg(sectionType)
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
            }
        }
    }
    
    // DRAG & DROP SUPPORT
    
    MouseArea {
        id: dragArea
        anchors.fill: parent
        anchors.topMargin: 0
        anchors.bottomMargin: parent.height - headerHeight
        enabled: dragEnabled
        
        drag.target: configurableSection
        drag.axis: Drag.YAxis
        drag.minimumY: 0
        drag.maximumY: parent ? parent.height - configurableSection.height : 0
        
        onPressed: {
            dragStartY = mouse.y
            dragging = true
            dragOffset = 0
        }
        
        onPositionChanged: {
            if (dragging) {
                dragOffset = mouse.y - dragStartY
                // Signal drag position change to parent
                if (configurableSection.parent && configurableSection.parent.onSectionDragged) {
                    configurableSection.parent.onSectionDragged(configurableSection, dragOffset)
                }
            }
        }
        
        onReleased: {
            dragging = false
            // Signal drag end to parent
            if (configurableSection.parent && configurableSection.parent.onSectionDragEnded) {
                configurableSection.parent.onSectionDragEnded(configurableSection, dragOffset)
            }
            dragOffset = 0
        }
    }
    
    // SECTION MANAGEMENT FUNCTIONS
    
    // Populate content based on section type
    function populateContent() {
        if (!contentLoader.item || !sectionContent) {
            return
        }
        
        var list = contentLoader.item
        
        // Clear existing content
        if (list.clearAll) {
            list.clearAll()
        }
        
        // Add content based on type
        var itemsAdded = 0
        console.log("ConfigurableSection: Populating", sectionId, "with", sectionContent.length, "items")
        
        for (var i = 0; i < sectionContent.length && itemsAdded < maxItems; i++) {
            var wrappedItem = sectionContent[i]
            var item = wrappedItem.data || wrappedItem  // Handle both wrapped and direct data
            var itemType = wrappedItem.type || "unknown"
            
            console.log("ConfigurableSection: Processing item", i, "type:", itemType, "title:", item.title || item.name)
            
            switch (sectionType) {
                case "recent":
                case "foryou":
                    if (itemType === "album" && list.addAlbum) {
                        list.addAlbum(item)
                        itemsAdded++
                    } else if (itemType === "artist" && list.addArtist) {
                        list.addArtist(item)
                        itemsAdded++
                    } else if (itemType === "playlist" && list.addPlaylist) {
                        list.addPlaylist(item)
                        itemsAdded++
                    } else if (itemType === "mix" && list.addMix) {
                        list.addMix(item)
                        itemsAdded++
                    } else if (itemType === "track" && list.addTrack) {
                        list.addTrack(item)
                        itemsAdded++
                    }
                    break
                case "topArtists":
                    if (itemType === "artist" && list.addArtist) {
                        list.addArtist(item)
                        itemsAdded++
                    }
                    break
                case "topAlbums":
                    if (itemType === "album" && list.addAlbum) {
                        list.addAlbum(item)
                        itemsAdded++
                    }
                    break
                case "topTracks":
                    if (itemType === "track" && list.addTrack) {
                        list.addTrack(item)
                        itemsAdded++
                    }
                    break
                case "personalPlaylists":
                    if (itemType === "playlist" && list.addPlaylist) {
                        list.addPlaylist(item)
                        itemsAdded++
                    }
                    break
                case "dailyMixes":
                case "radioMixes":
                    if (itemType === "mix" && list.addMix) {
                        list.addMix(item)
                        itemsAdded++
                    }
                    break
            }
        }
        
        console.log("ConfigurableSection: Populated", sectionId, "with", itemsAdded, "items")
    }
    
    // Refresh section content
    function refreshSection() {
        if (isLoading) return
        
        console.log("ConfigurableSection: Refreshing section", sectionId)
        
        // Call callback function if available
        if (onSectionRefreshRequested) {
            onSectionRefreshRequested(sectionId)
        }
    }
    
    // Toggle section visibility
    function toggleSectionVisibility() {
        var newEnabled = !sectionEnabled
        console.log("ConfigurableSection: Toggle visibility for", sectionId, "to", newEnabled)
        
        // Call callback function if available
        if (onSectionVisibilityChanged) {
            onSectionVisibilityChanged(sectionId, newEnabled)
        }
    }
    
    // Update section configuration
    function updateSectionConfig() {
        console.log("ConfigurableSection: Update config for", sectionId)
        
        // Call callback function if available
        if (onSectionConfigChanged) {
            onSectionConfigChanged(sectionId, {
                maxItems: maxItems,
                enabled: sectionEnabled
            })
        }
    }
    
    // Clear section cache
    function clearSectionCache() {
        console.log("ConfigurableSection: Clear cache for", sectionId)
        
        // Call callback function if available
        if (onSectionCacheCleared) {
            onSectionCacheCleared(sectionId)
        }
    }
    
    // Reset section settings
    function resetSectionSettings() {
        console.log("ConfigurableSection: Reset settings for", sectionId)
        
        // Reset to defaults
        maxItems = 8
        expanded = true
        showSettings = false
        
        updateSectionConfig()
    }
    
    // Update content from external source
    function updateContent(newContent) {
        if (!newContent || !Array.isArray(newContent)) {
            sectionContent = []
            return
        }
        
        sectionContent = newContent.slice(0, maxItems)
        
        // Refresh display if loaded
        if (contentLoader.item) {
            populateContent()
        }
    }
    
    // Set loading state
    function setLoading(loading) {
        isLoading = loading
    }
    
    // Show drop indicator
    function showDropIndicator(show) {
        dropIndicator.opacity = show ? 1.0 : 0.0
    }
    
    // Get section info for drag operations
    function getSectionInfo() {
        return {
            sectionId: sectionId,
            sectionOrder: sectionOrder,
            sectionTitle: sectionTitle,
            height: height
        }
    }
    
    // VISUAL TRANSITIONS
    
    Behavior on height {
        NumberAnimation { 
            duration: 300
            easing.type: Easing.InOutQuad 
        }
    }
    
    Behavior on contentOpacity {
        FadeAnimation { duration: 200 }
    }
    
    // COMPONENT LIFECYCLE
    
    Component.onCompleted: {
        console.log("ConfigurableSection: Initialized section", sectionId, "type:", sectionType)
    }
}