import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: homescreenSettingsPage
    
    // HOMESCREEN PERSONALIZATION: Configuration UI
    
    property var homescreenManager
    property var sectionConfigs: homescreenManager ? homescreenManager.getAllSectionConfigs() : ({})
    property bool hasUnsavedChanges: false
    
    SilicaFlickable {
        anchors.fill: parent
        contentHeight: contentColumn.height
        
        // Pull-down menu
        PullDownMenu {
            MenuItem {
                text: qsTr("Reset to Defaults")
                onClicked: {
                    resetToDefaults()
                }
            }
            
            MenuItem {
                text: qsTr("Clear All Cache")
                onClicked: {
                    clearAllCache()
                }
            }
        }
        
        Column {
            id: contentColumn
            width: parent.width
            spacing: Theme.paddingMedium
            
            PageHeader {
                title: qsTr("Homescreen Settings")
                description: qsTr("Configure your personal page layout")
            }
            
            // Global settings section
            SectionHeader {
                text: qsTr("Global Settings")
            }
            
            // Cache settings
            Item {
                width: parent.width
                height: cacheSettingsColumn.height
                
                Column {
                    id: cacheSettingsColumn
                    width: parent.width - 2 * Theme.paddingLarge
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Theme.paddingMedium
                    
                    // Cache size setting
                    Item {
                        width: parent.width
                        height: cacheLabel.height + cacheSizeSlider.height + Theme.paddingSmall
                        
                        Label {
                            id: cacheLabel
                            text: qsTr("Cache size: %1 sections").arg(homescreenManager ? homescreenManager.sectionCache.maxSections : 20)
                            color: Theme.highlightColor
                        }
                        
                        Slider {
                            id: cacheSizeSlider
                            anchors.top: cacheLabel.bottom
                            anchors.topMargin: Theme.paddingSmall
                            width: parent.width
                            minimumValue: 10
                            maximumValue: 50
                            stepSize: 5
                            value: homescreenManager ? homescreenManager.sectionCache.maxSections : 20
                            onValueChanged: {
                                if (homescreenManager && value !== homescreenManager.sectionCache.maxSections) {
                                    homescreenManager.sectionCache.updateConfig(undefined, value)
                                    hasUnsavedChanges = true
                                }
                            }
                        }
                    }
                    
                    // Cache age setting
                    Item {
                        width: parent.width
                        height: cacheAgeLabel.height + cacheAgeSlider.height + Theme.paddingSmall
                        
                        Label {
                            id: cacheAgeLabel
                            text: qsTr("Cache age: %1 minutes").arg(homescreenManager ? Math.round(homescreenManager.sectionCache.maxAge / 60000) : 60)
                            color: Theme.highlightColor
                        }
                        
                        Slider {
                            id: cacheAgeSlider
                            anchors.top: cacheAgeLabel.bottom
                            anchors.topMargin: Theme.paddingSmall
                            width: parent.width
                            minimumValue: 15
                            maximumValue: 240
                            stepSize: 15
                            value: homescreenManager ? homescreenManager.sectionCache.maxAge / 60000 : 60
                            onValueChanged: {
                                if (homescreenManager && (value * 60000) !== homescreenManager.sectionCache.maxAge) {
                                    homescreenManager.sectionCache.updateConfig(value * 60000, undefined)
                                    hasUnsavedChanges = true
                                }
                            }
                        }
                    }
                    
                    // Cache statistics
                    Rectangle {
                        width: parent.width
                        height: statsColumn.height + 2 * Theme.paddingMedium
                        color: Theme.rgba(Theme.highlightBackgroundColor, 0.1)
                        radius: Theme.paddingSmall
                        
                        Column {
                            id: statsColumn
                            anchors.centerIn: parent
                            width: parent.width - 2 * Theme.paddingMedium
                            spacing: Theme.paddingSmall
                            
                            Label {
                                text: qsTr("Cache Statistics")
                                font.pixelSize: Theme.fontSizeSmall
                                font.bold: true
                                color: Theme.highlightColor
                            }
                            
                            Row {
                                width: parent.width
                                
                                Label {
                                    text: qsTr("Hit Rate:")
                                    font.pixelSize: Theme.fontSizeExtraSmall
                                    color: Theme.secondaryColor
                                    width: parent.width * 0.4
                                }
                                
                                Label {
                                    text: homescreenManager ? homescreenManager.sectionCache.getCacheStats().hitRate + "%" : "0%"
                                    font.pixelSize: Theme.fontSizeExtraSmall
                                    color: Theme.primaryColor
                                }
                            }
                            
                            Row {
                                width: parent.width
                                
                                Label {
                                    text: qsTr("Cached Sections:")
                                    font.pixelSize: Theme.fontSizeExtraSmall
                                    color: Theme.secondaryColor
                                    width: parent.width * 0.4
                                }
                                
                                Label {
                                    text: homescreenManager ? homescreenManager.sectionCache.getCacheStats().totalSize : "0"
                                    font.pixelSize: Theme.fontSizeExtraSmall
                                    color: Theme.primaryColor
                                }
                            }
                            
                            Row {
                                width: parent.width
                                
                                Label {
                                    text: qsTr("Total Requests:")
                                    font.pixelSize: Theme.fontSizeExtraSmall
                                    color: Theme.secondaryColor
                                    width: parent.width * 0.4
                                }
                                
                                Label {
                                    text: homescreenManager ? homescreenManager.sectionCache.getCacheStats().totalRequests : "0"
                                    font.pixelSize: Theme.fontSizeExtraSmall
                                    color: Theme.primaryColor
                                }
                            }
                        }
                    }
                }
            }
            
            // Section configuration
            SectionHeader {
                text: qsTr("Section Configuration")
            }
            
            // Section list
            Column {
                width: parent.width
                spacing: Theme.paddingSmall
                
                Repeater {
                    model: Object.keys(sectionConfigs).sort(function(a, b) {
                        return sectionConfigs[a].order - sectionConfigs[b].order
                    })
                    
                    delegate: Item {
                        width: parent.width
                        height: sectionItem.height
                        
                        Rectangle {
                            id: sectionItem
                            width: parent.width - 2 * Theme.paddingLarge
                            anchors.horizontalCenter: parent.horizontalCenter
                            height: sectionColumn.height + 2 * Theme.paddingMedium
                            color: sectionConfigs[modelData].enabled ? 
                                   Theme.rgba(Theme.highlightBackgroundColor, 0.1) :
                                   Theme.rgba(Theme.secondaryColor, 0.1)
                            radius: Theme.paddingSmall
                            
                            Column {
                                id: sectionColumn
                                anchors.centerIn: parent
                                width: parent.width - 2 * Theme.paddingMedium
                                spacing: Theme.paddingMedium
                                
                                // Section header
                                Row {
                                    width: parent.width
                                    spacing: Theme.paddingMedium
                                    
                                    // Drag handle
                                    Rectangle {
                                        width: 6
                                        height: 20
                                        color: Theme.secondaryColor
                                        radius: 3
                                        anchors.verticalCenter: parent.verticalCenter
                                        opacity: 0.6
                                        
                                        Column {
                                            anchors.centerIn: parent
                                            spacing: 1
                                            Repeater {
                                                model: 3
                                                Rectangle {
                                                    width: 4
                                                    height: 1
                                                    color: Theme.primaryColor
                                                }
                                            }
                                        }
                                    }
                                    
                                    // Section info
                                    Column {
                                        width: parent.width - 100 - Theme.paddingMedium
                                        
                                        Label {
                                            text: sectionConfigs[modelData].title
                                            font.pixelSize: Theme.fontSizeMedium
                                            color: sectionConfigs[modelData].enabled ? Theme.primaryColor : Theme.secondaryColor
                                            truncationMode: TruncationMode.Fade
                                            width: parent.width
                                        }
                                        
                                        Label {
                                            text: qsTr("Order: %1 • Priority: %2")
                                                  .arg(sectionConfigs[modelData].order)
                                                  .arg(sectionConfigs[modelData].priority)
                                            font.pixelSize: Theme.fontSizeExtraSmall
                                            color: Theme.secondaryColor
                                            truncationMode: TruncationMode.Fade
                                            width: parent.width
                                        }
                                    }
                                    
                                    // Enable/disable switch
                                    Switch {
                                        anchors.verticalCenter: parent.verticalCenter
                                        checked: sectionConfigs[modelData].enabled
                                        automaticCheck: false
                                        onClicked: {
                                            toggleSection(modelData)
                                        }
                                    }
                                }
                                
                                // Section settings (expandable)
                                Column {
                                    width: parent.width
                                    spacing: Theme.paddingSmall
                                    opacity: sectionConfigs[modelData].enabled ? 1.0 : 0.3
                                    
                                    // Max items setting
                                    Row {
                                        width: parent.width
                                        spacing: Theme.paddingMedium
                                        
                                        Label {
                                            text: qsTr("Max items:")
                                            font.pixelSize: Theme.fontSizeSmall
                                            color: Theme.secondaryColor
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: 80
                                        }
                                        
                                        Slider {
                                            width: parent.width - 120
                                            minimumValue: 4
                                            maximumValue: 20
                                            stepSize: 2
                                            value: sectionConfigs[modelData].maxItems
                                            enabled: sectionConfigs[modelData].enabled
                                            onValueChanged: {
                                                if (value !== sectionConfigs[modelData].maxItems) {
                                                    updateSectionMaxItems(modelData, value)
                                                }
                                            }
                                        }
                                        
                                        Label {
                                            text: sectionConfigs[modelData].maxItems.toString()
                                            font.pixelSize: Theme.fontSizeSmall
                                            color: Theme.primaryColor
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: 30
                                        }
                                    }
                                    
                                    // Refresh interval setting
                                    Row {
                                        width: parent.width
                                        spacing: Theme.paddingMedium
                                        
                                        Label {
                                            text: qsTr("Refresh:")
                                            font.pixelSize: Theme.fontSizeSmall
                                            color: Theme.secondaryColor
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: 80
                                        }
                                        
                                        ComboBox {
                                            width: parent.width - 120
                                            enabled: sectionConfigs[modelData].enabled
                                            
                                            menu: ContextMenu {
                                                MenuItem { text: qsTr("5 minutes"); property int value: 300000 }
                                                MenuItem { text: qsTr("10 minutes"); property int value: 600000 }
                                                MenuItem { text: qsTr("15 minutes"); property int value: 900000 }
                                                MenuItem { text: qsTr("30 minutes"); property int value: 1800000 }
                                                MenuItem { text: qsTr("1 hour"); property int value: 3600000 }
                                                MenuItem { text: qsTr("2 hours"); property int value: 7200000 }
                                            }
                                            
                                            currentIndex: {
                                                var interval = sectionConfigs[modelData].refreshInterval
                                                switch (interval) {
                                                    case 300000: return 0
                                                    case 600000: return 1
                                                    case 900000: return 2
                                                    case 1800000: return 3
                                                    case 3600000: return 4
                                                    case 7200000: return 5
                                                    default: return 1
                                                }
                                            }
                                            
                                            onCurrentItemChanged: {
                                                if (currentItem) {
                                                    updateSectionRefreshInterval(modelData, currentItem.value)
                                                }
                                            }
                                        }
                                    }
                                    
                                    // Quick actions
                                    Row {
                                        spacing: Theme.paddingSmall
                                        
                                        Button {
                                            text: qsTr("Clear Cache")
                                            preferredWidth: Theme.buttonWidthExtraSmall
                                            onClicked: {
                                                clearSectionCache(modelData)
                                            }
                                        }
                                        
                                        Button {
                                            text: qsTr("Refresh Now")
                                            preferredWidth: Theme.buttonWidthExtraSmall
                                            enabled: sectionConfigs[modelData].enabled
                                            onClicked: {
                                                refreshSection(modelData)
                                            }
                                        }
                                        
                                        Button {
                                            text: qsTr("Reset")
                                            preferredWidth: Theme.buttonWidthExtraSmall
                                            onClicked: {
                                                resetSection(modelData)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            // Advanced settings
            SectionHeader {
                text: qsTr("Advanced")
            }
            
            Column {
                width: parent.width - 2 * Theme.paddingLarge
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.paddingMedium
                
                // Background refresh toggle
                TextSwitch {
                    text: qsTr("Background refresh")
                    description: qsTr("Allow content refresh when app is in background")
                    checked: true
                    // onCheckedChanged: {} // Would be connected to background refresh setting
                }
                
                // Progressive loading toggle
                TextSwitch {
                    text: qsTr("Progressive loading")
                    description: qsTr("Load sections gradually by priority")
                    checked: true
                    // onCheckedChanged: {} // Would be connected to progressive loading setting
                }
                
                // Debug mode toggle
                TextSwitch {
                    text: qsTr("Debug mode")
                    description: qsTr("Show detailed logging information")
                    checked: false
                    // onCheckedChanged: {} // Would be connected to debug mode setting
                }
            }
            
            // Action buttons
            Column {
                width: parent.width
                spacing: Theme.paddingMedium
                
                Button {
                    text: qsTr("Export Configuration")
                    anchors.horizontalCenter: parent.horizontalCenter
                    onClicked: {
                        exportConfiguration()
                    }
                }
                
                Button {
                    text: qsTr("Import Configuration")
                    anchors.horizontalCenter: parent.horizontalCenter
                    onClicked: {
                        importConfiguration()
                    }
                }
            }
        }
        
        VerticalScrollDecorator {}
    }
    
    // CONFIGURATION FUNCTIONS
    
    function toggleSection(sectionId) {
        if (homescreenManager) {
            var config = sectionConfigs[sectionId]
            var newEnabled = !config.enabled
            homescreenManager.toggleSection(sectionId, newEnabled)
            hasUnsavedChanges = true
            
            // Refresh the view
            sectionConfigs = homescreenManager.getAllSectionConfigs()
        }
    }
    
    function updateSectionMaxItems(sectionId, maxItems) {
        if (homescreenManager) {
            sectionConfigs[sectionId].maxItems = maxItems
            hasUnsavedChanges = true
        }
    }
    
    function updateSectionRefreshInterval(sectionId, interval) {
        if (homescreenManager) {
            homescreenManager.updateRefreshInterval(sectionId, interval)
            hasUnsavedChanges = true
            
            // Refresh the view
            sectionConfigs = homescreenManager.getAllSectionConfigs()
        }
    }
    
    function clearSectionCache(sectionId) {
        if (homescreenManager) {
            homescreenManager.sectionCache.clearSection(sectionId)
            console.log("Cleared cache for section:", sectionId)
        }
    }
    
    function refreshSection(sectionId) {
        if (homescreenManager) {
            homescreenManager.forceRefreshSection(sectionId)
            console.log("Refreshing section:", sectionId)
        }
    }
    
    function resetSection(sectionId) {
        if (homescreenManager && sectionConfigs[sectionId]) {
            // Reset to default values
            var config = sectionConfigs[sectionId]
            config.maxItems = 8
            config.refreshInterval = 600000 // 10 minutes
            config.enabled = true
            
            hasUnsavedChanges = true
            sectionConfigs = homescreenManager.getAllSectionConfigs()
        }
    }
    
    function resetToDefaults() {
        var remorse = Remorse.popupAction(homescreenSettingsPage, qsTr("Resetting to defaults"), function() {
            if (homescreenManager) {
                // Reset all sections to defaults
                var sections = Object.keys(sectionConfigs)
                for (var i = 0; i < sections.length; i++) {
                    resetSection(sections[i])
                }
                
                // Reset cache settings
                homescreenManager.sectionCache.updateConfig(3600000, 20) // 1 hour, 20 sections
                
                console.log("Reset all settings to defaults")
            }
        })
    }
    
    function clearAllCache() {
        var remorse = Remorse.popupAction(homescreenSettingsPage, qsTr("Clearing all cache"), function() {
            if (homescreenManager) {
                homescreenManager.sectionCache.clearAll()
                console.log("Cleared all cache")
            }
        })
    }
    
    function exportConfiguration() {
        if (homescreenManager) {
            // This would export configuration to a file
            console.log("Export configuration not yet implemented")
        }
    }
    
    function importConfiguration() {
        if (homescreenManager) {
            // This would import configuration from a file
            console.log("Import configuration not yet implemented")
        }
    }
    
    // SAVE CHANGES ON EXIT
    
    onStatusChanged: {
        if (status === PageStatus.Deactivating && hasUnsavedChanges) {
            if (homescreenManager) {
                homescreenManager.saveConfiguration()
                console.log("HomescreenSettings: Saved configuration changes")
            }
        }
    }
    
    // COMPONENT LIFECYCLE
    
    Component.onCompleted: {
        console.log("HomescreenSettings: Component completed")
        if (homescreenManager) {
            sectionConfigs = homescreenManager.getAllSectionConfigs()
        }
    }
}