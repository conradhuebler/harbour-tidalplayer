import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: homescreenSettingsPage

    // HOMESCREEN PERSONALIZATION: Modern Configuration UI with Section Reordering

    property var homescreenManager
    property var sectionConfigs: homescreenManager ? homescreenManager.getAllSectionConfigs() : ({})
    property bool hasUnsavedChanges: false
    property string draggedSectionId: ""
    property int draggedFromIndex: -1
    property bool isDragging: false

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: contentColumn.height

        // Pull-down menu
        PullDownMenu {
            MenuItem {
                text: qsTr("Help")
                onClicked: {
                    showHelpDialog()
                }
            }

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
                title: qsTr("Homescreen Layout")
                description: qsTr("Customize your personal page sections")
            }

            // Instructions panel
            Rectangle {
                width: parent.width - 2 * Theme.paddingLarge
                anchors.horizontalCenter: parent.horizontalCenter
                height: instructionsColumn.height + 2 * Theme.paddingMedium
                color: Theme.rgba(Theme.highlightBackgroundColor, 0.08)
                radius: Theme.paddingSmall

                Column {
                    id: instructionsColumn
                    anchors.centerIn: parent
                    width: parent.width - 2 * Theme.paddingMedium
                    spacing: Theme.paddingSmall

                    Label {
                        text: qsTr("How to reorder sections:")
                        font.pixelSize: Theme.fontSizeSmall
                        font.bold: true
                        color: Theme.highlightColor
                    }

                    Label {
                        text: qsTr("• Press and hold a section to start dragging")
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: Theme.secondaryColor
                        width: parent.width
                        wrapMode: Text.WordWrap
                    }

                    Label {
                        text: qsTr("• Drag up or down to change position")
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: Theme.secondaryColor
                        width: parent.width
                        wrapMode: Text.WordWrap
                    }

                    Label {
                        text: qsTr("• Release to drop in new position")
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: Theme.secondaryColor
                        width: parent.width
                        wrapMode: Text.WordWrap
                    }
                }
            }

            // Section reordering list
            SectionHeader {
                text: qsTr("Section Order & Settings")
            }

            Column {
                id: sectionsList
                width: parent.width
                spacing: Theme.paddingSmall

                Repeater {
                    id: sectionsRepeater
                    model: getSortedSectionIds()

                    delegate: Item {
                        id: sectionDelegate
                        width: parent.width
                        height: sectionRect.height + spacing

                        property string sectionId: modelData
                        property var sectionConfig: sectionConfigs[sectionId] || {}
                        property bool beingDragged: sectionId === draggedSectionId
                        property real targetY: y
                        property int spacing: Theme.paddingSmall

                        // Visual feedback for drag target
                        Rectangle {
                            id: dropIndicator
                            width: parent.width - 2 * Theme.paddingLarge
                            height: 3
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.top
                            anchors.topMargin: -1.5
                            color: Theme.highlightColor
                            radius: 1.5
                            opacity: 0.0

                            states: [
                                State {
                                    name: "dropTarget"
                                    when: isDragging && !beingDragged && canDropHere(index)
                                    PropertyChanges { target: dropIndicator; opacity: 1.0 }
                                }
                            ]

                            transitions: [
                                Transition {
                                    NumberAnimation { property: "opacity"; duration: 200 }
                                }
                            ]
                        }

                        Rectangle {
                            id: sectionRect
                            width: parent.width - 2 * Theme.paddingLarge
                            anchors.horizontalCenter: parent.horizontalCenter
                            height: sectionContent.height + 2 * Theme.paddingMedium
                            color: sectionConfig.enabled ?
                                   Theme.rgba(Theme.highlightBackgroundColor, beingDragged ? 0.2 : 0.1) :
                                   Theme.rgba(Theme.secondaryColor, 0.1)
                            radius: Theme.paddingSmall
                            border.color: beingDragged ? Theme.highlightColor : "transparent"
                            border.width: beingDragged ? 2 : 0

                            // Drag & Drop functionality
                            MouseArea {
                                id: dragArea
                                anchors.fill: parent

                                property bool held: false
                                property point startPos
                                property real startY: 0

                                onPressAndHold: {
                                    held = true
                                    startPos = Qt.point(mouse.x, mouse.y)
                                    startY = sectionDelegate.y
                                    sectionDelegate.targetY = sectionDelegate.y
                                    startDrag(sectionId, index)
                                }

                                onReleased: {
                                    if (held) {
                                        endDrag()
                                        held = false
                                        // Reset position after drag
                                        sectionDelegate.y = sectionDelegate.targetY
                                    }
                                }

                                onPositionChanged: {
                                    if (held && isDragging) {
                                        var deltaY = mouse.y - startPos.y
                                        updateDragPosition(deltaY)
                                    }
                                }

                                onClicked: {
                                    if (!held) {
                                        // Toggle section expanded state or show settings
                                        sectionContent.expanded = !sectionContent.expanded
                                    }
                                }
                            }

                            Column {
                                id: sectionContent
                                anchors.centerIn: parent
                                width: parent.width - 2 * Theme.paddingMedium
                                spacing: Theme.paddingMedium

                                property bool expanded: false

                                // Section header
                                Row {
                                    width: parent.width
                                    spacing: Theme.paddingMedium

                                    // Drag handle
                                    Rectangle {
                                        width: 8
                                        height: 24
                                        color: Theme.secondaryColor
                                        radius: 4
                                        anchors.verticalCenter: parent.verticalCenter
                                        opacity: 0.7

                                        Column {
                                            anchors.centerIn: parent
                                            spacing: 2
                                            Repeater {
                                                model: 4
                                                Rectangle {
                                                    width: 4
                                                    height: 1
                                                    color: Theme.primaryColor
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                }
                                            }
                                        }
                                    }

                                    // Section order number
                                    Rectangle {
                                        width: 28
                                        height: 28
                                        radius: 14
                                        color: Theme.rgba(Theme.highlightColor, 0.2)
                                        anchors.verticalCenter: parent.verticalCenter

                                        Label {
                                            text: (index + 1).toString()
                                            anchors.centerIn: parent
                                            font.pixelSize: Theme.fontSizeSmall
                                            font.bold: true
                                            color: Theme.highlightColor
                                        }
                                    }

                                    // Section info
                                    Column {
                                        width: parent.width - 120 - 2 * Theme.paddingMedium
                                        anchors.verticalCenter: parent.verticalCenter

                                        Label {
                                            text: sectionConfig.title || sectionId
                                            font.pixelSize: Theme.fontSizeMedium
                                            color: sectionConfig.enabled ? Theme.primaryColor : Theme.secondaryColor
                                            truncationMode: TruncationMode.Fade
                                            width: parent.width
                                        }

                                        Label {
                                            text: qsTr("%1 items • %2")
                                                  .arg(sectionConfig.maxItems || 8)
                                                  .arg(getPriorityText(sectionConfig.priority))
                                            font.pixelSize: Theme.fontSizeExtraSmall
                                            color: Theme.secondaryColor
                                            truncationMode: TruncationMode.Fade
                                            width: parent.width
                                        }
                                    }

                                    // Enable/disable switch
                                    Switch {
                                        anchors.verticalCenter: parent.verticalCenter
                                        checked: sectionConfig.enabled || false
                                        automaticCheck: false
                                        onClicked: {
                                            toggleSection(sectionId)
                                        }
                                    }
                                }

                                // Expandable settings (when section is expanded)
                                Column {
                                    width: parent.width
                                    spacing: Theme.paddingMedium
                                    opacity: sectionConfig.enabled ? 1.0 : 0.3
                                    height: sectionContent.expanded ? implicitHeight : 0
                                    clip: true

                                    Behavior on height {
                                        NumberAnimation { duration: 300; easing.type: Easing.InOutQuad }
                                    }

                                    // Separator
                                    Rectangle {
                                        width: parent.width
                                        height: 1
                                        color: Theme.secondaryColor
                                        opacity: 0.3
                                    }

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
                                            width: parent.width - 140
                                            minimumValue: 4
                                            maximumValue: 20
                                            stepSize: 2
                                            value: sectionConfig.maxItems || 8
                                            enabled: sectionConfig.enabled
                                            onValueChanged: {
                                                if (value !== (sectionConfig.maxItems || 8)) {
                                                    updateSectionMaxItems(sectionId, value)
                                                }
                                            }
                                        }

                                        Label {
                                            text: (sectionConfig.maxItems || 8).toString()
                                            font.pixelSize: Theme.fontSizeSmall
                                            color: Theme.primaryColor
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: 40
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
                                            width: parent.width - 100
                                            enabled: sectionConfig.enabled

                                            menu: ContextMenu {
                                                MenuItem { text: qsTr("5 minutes"); property int value: 300000 }
                                                MenuItem { text: qsTr("10 minutes"); property int value: 600000 }
                                                MenuItem { text: qsTr("15 minutes"); property int value: 900000 }
                                                MenuItem { text: qsTr("30 minutes"); property int value: 1800000 }
                                                MenuItem { text: qsTr("1 hour"); property int value: 3600000 }
                                                MenuItem { text: qsTr("2 hours"); property int value: 7200000 }
                                            }

                                            currentIndex: getRefreshIntervalIndex(sectionConfig.refreshInterval)

                                            onCurrentItemChanged: {
                                                if (currentItem) {
                                                    updateSectionRefreshInterval(sectionId, currentItem.value)
                                                }
                                            }
                                        }
                                    }

                                    // Quick actions
                                    Flow {
                                        width: parent.width
                                        spacing: Theme.paddingSmall

                                        Button {
                                            text: qsTr("Clear Cache")
                                            preferredWidth: Theme.buttonWidthExtraSmall
                                            onClicked: {
                                                clearSectionCache(sectionId)
                                            }
                                        }

                                        Button {
                                            text: qsTr("Refresh Now")
                                            preferredWidth: Theme.buttonWidthExtraSmall
                                            enabled: sectionConfig.enabled
                                            onClicked: {
                                                refreshSection(sectionId)
                                            }
                                        }

                                        Button {
                                            text: qsTr("Reset")
                                            preferredWidth: Theme.buttonWidthExtraSmall
                                            onClicked: {
                                                resetSection(sectionId)
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Smooth position animations
                        Behavior on y {
                            enabled: !beingDragged && !isDragging
                            NumberAnimation {
                                duration: 300
                                easing.type: Easing.InOutQuad
                            }
                        }

                        states: [
                            State {
                                name: "dragging"
                                when: beingDragged
                                PropertyChanges {
                                    target: sectionDelegate
                                    z: 10
                                    scale: 1.02
                                }
                            }
                        ]

                        transitions: [
                            Transition {
                                NumberAnimation { properties: "scale"; duration: 200 }
                                NumberAnimation { properties: "opacity"; duration: 200 }
                            }
                        ]
                    }
                }
            }

            // Global cache settings
            SectionHeader {
                text: qsTr("Cache Settings")
            }

            Column {
                width: parent.width - 2 * Theme.paddingLarge
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.paddingMedium

                // Cache size setting
                Row {
                    width: parent.width
                    spacing: Theme.paddingMedium

                    Label {
                        text: qsTr("Cache size:")
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.highlightColor
                        anchors.verticalCenter: parent.verticalCenter
                        width: 100
                    }

                    Slider {
                        width: parent.width - 180
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

                    Label {
                        text: homescreenManager ? homescreenManager.sectionCache.maxSections + " sections" : "20 sections"
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.primaryColor
                        anchors.verticalCenter: parent.verticalCenter
                        width: 60
                    }
                }

                // Cache age setting
                Row {
                    width: parent.width
                    spacing: Theme.paddingMedium

                    Label {
                        text: qsTr("Cache age:")
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.highlightColor
                        anchors.verticalCenter: parent.verticalCenter
                        width: 100
                    }

                    Slider {
                        width: parent.width - 180
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

                    Label {
                        text: homescreenManager ? Math.round(homescreenManager.sectionCache.maxAge / 60000) + " min" : "60 min"
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.primaryColor
                        anchors.verticalCenter: parent.verticalCenter
                        width: 60
                    }
                }

                // Cache statistics
                Rectangle {
                    width: parent.width
                    height: cacheStatsColumn.height + 2 * Theme.paddingMedium
                    color: Theme.rgba(Theme.highlightBackgroundColor, 0.08)
                    radius: Theme.paddingSmall

                    Column {
                        id: cacheStatsColumn
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
                    }
                }
            }
        }

        VerticalScrollDecorator {}
    }

    // FEEDBACK NOTIFICATIONS

    // Success notification
    Rectangle {
        id: successNotification
        width: parent.width - 2 * Theme.paddingLarge
        height: successLabel.height + 2 * Theme.paddingMedium
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.paddingExtraLarge
        color: Theme.rgba(Theme.highlightColor, 0.9)
        radius: Theme.paddingMedium
        opacity: 0.0
        z: 100

        property bool isVisible: false

        function show(message) {
            successLabel.text = message
            isVisible = true
            showAnimation.start()
        }

        Label {
            id: successLabel
            anchors.centerIn: parent
            color: Theme.primaryColor
            font.pixelSize: Theme.fontSizeSmall
            font.bold: true
        }

        SequentialAnimation {
            id: showAnimation
            NumberAnimation { target: successNotification; property: "opacity"; to: 1.0; duration: 200 }
            PauseAnimation { duration: 1500 }
            NumberAnimation { target: successNotification; property: "opacity"; to: 0.0; duration: 300 }
            ScriptAction { script: successNotification.isVisible = false }
        }
    }

    // Error notification
    Rectangle {
        id: errorNotification
        width: parent.width - 2 * Theme.paddingLarge
        height: errorLabel.height + 2 * Theme.paddingMedium
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.paddingExtraLarge
        color: Theme.rgba(Theme.errorColor, 0.9)
        radius: Theme.paddingMedium
        opacity: 0.0
        z: 100

        property bool isVisible: false

        function show(message) {
            errorLabel.text = message
            isVisible = true
            errorShowAnimation.start()
        }

        Label {
            id: errorLabel
            anchors.centerIn: parent
            color: Theme.primaryColor
            font.pixelSize: Theme.fontSizeSmall
            font.bold: true
        }

        SequentialAnimation {
            id: errorShowAnimation
            NumberAnimation { target: errorNotification; property: "opacity"; to: 1.0; duration: 200 }
            PauseAnimation { duration: 2000 }
            NumberAnimation { target: errorNotification; property: "opacity"; to: 0.0; duration: 300 }
            ScriptAction { script: errorNotification.isVisible = false }
        }
    }

    // DRAG AND DROP FUNCTIONS

    function startDrag(sectionId, fromIndex) {
        console.log("HomescreenSettings: Starting drag for section", sectionId, "from index", fromIndex)
        draggedSectionId = sectionId
        draggedFromIndex = fromIndex
        isDragging = true
    }

    function updateDragPosition(deltaY) {
        if (!isDragging || draggedFromIndex === -1) {
            return
        }

        // Update the position of the dragged item
        var draggedDelegate = sectionsRepeater.itemAt(draggedFromIndex)
        if (draggedDelegate) {
            draggedDelegate.y = draggedDelegate.targetY + deltaY

            // Update drop indicators for all sections
            for (var i = 0; i < sectionsRepeater.count; i++) {
                var delegate = sectionsRepeater.itemAt(i)
                if (delegate && i !== draggedFromIndex) {
                    // Check if we're hovering over this section
                    var draggedCenterY = draggedDelegate.y + draggedDelegate.height / 2
                    var delegateCenterY = delegate.y + delegate.height / 2
                    var distance = Math.abs(draggedCenterY - delegateCenterY)

                    // Show drop indicator if we're close enough
                    if (delegate.children.length > 0 && delegate.children[0].opacity !== undefined) {
                        delegate.children[0].opacity = (distance < 50) ? 1.0 : 0.0
                    }
                }
            }
        }
    }

    function endDrag() {
        if (!isDragging || draggedFromIndex === -1) {
            return
        }

        console.log("HomescreenSettings: Ending drag for section", draggedSectionId)

        // Find the drop target based on current drag position
        var dropIndex = findDropIndex()

        if (dropIndex !== -1 && dropIndex !== draggedFromIndex) {
            console.log("HomescreenSettings: Moving section from", draggedFromIndex, "to", dropIndex)
            reorderSection(draggedFromIndex, dropIndex)
        }

        // Reset all drop indicators
        for (var i = 0; i < sectionsRepeater.count; i++) {
            var delegate = sectionsRepeater.itemAt(i)
            if (delegate && delegate.children.length > 0 && delegate.children[0].opacity !== undefined) {
                delegate.children[0].opacity = 0.0
            }
        }

        // Reset drag state
        draggedSectionId = ""
        draggedFromIndex = -1
        isDragging = false
    }

    function findDropIndex() {
        if (!isDragging || draggedFromIndex === -1) {
            return -1
        }

        // Get the dragged section delegate
        var draggedDelegate = sectionsRepeater.itemAt(draggedFromIndex)
        if (!draggedDelegate) {
            return draggedFromIndex
        }

        // Calculate the center Y position of the dragged item
        var draggedCenterY = draggedDelegate.y + draggedDelegate.height / 2

        // Find the best drop position by comparing with other sections
        var bestIndex = draggedFromIndex
        var minDistance = Number.MAX_VALUE

        for (var i = 0; i < sectionsRepeater.count; i++) {
            if (i === draggedFromIndex) continue

            var delegate = sectionsRepeater.itemAt(i)
            if (!delegate) continue

            var delegateCenterY = delegate.y + delegate.height / 2
            var distance = Math.abs(draggedCenterY - delegateCenterY)

            if (distance < minDistance) {
                minDistance = distance
                bestIndex = i
            }
        }

        // Only return a new index if we're close enough to another section
        if (minDistance < 50) { // 50px threshold
            return bestIndex
        }

        return draggedFromIndex // No change if not close to any other section
    }

    function canDropHere(index) {
        return isDragging && index !== draggedFromIndex
    }

    function reorderSection(fromIndex, toIndex) {
        if (!homescreenManager) return

        console.log("HomescreenSettings: Reordering section from", fromIndex, "to", toIndex)

        var success = homescreenManager.reorderSections(fromIndex, toIndex)
        if (success) {
            hasUnsavedChanges = true

            // Show brief success feedback
            successNotification.show(qsTr("Section reordered successfully"))

            // Refresh the view
            sectionConfigs = homescreenManager.getAllSectionConfigs()
            sectionsRepeater.model = getSortedSectionIds()
        } else {
            // Show error feedback
            errorNotification.show(qsTr("Failed to reorder section"))
        }
    }

    // HELPER FUNCTIONS

    function getSortedSectionIds() {
        if (!sectionConfigs) return []

        return Object.keys(sectionConfigs).sort(function(a, b) {
            var orderA = sectionConfigs[a].order || 0
            var orderB = sectionConfigs[b].order || 0
            return orderA - orderB
        })
    }

    function getPriorityText(priority) {
        switch (priority) {
            case "high": return qsTr("High Priority")
            case "medium": return qsTr("Medium Priority")
            case "low": return qsTr("Low Priority")
            default: return qsTr("Unknown")
        }
    }

    function getRefreshIntervalIndex(interval) {
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

    function getSectionTitle(sectionId) {
        if (sectionConfigs && sectionConfigs[sectionId]) {
            return sectionConfigs[sectionId].title || sectionId
        }
        return sectionId
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
            successNotification.show(qsTr("Cache cleared for %1").arg(getSectionTitle(sectionId)))
        }
    }

    function refreshSection(sectionId) {
        if (homescreenManager) {
            homescreenManager.forceRefreshSection(sectionId)
            console.log("Refreshing section:", sectionId)
            successNotification.show(qsTr("Refreshing %1...").arg(getSectionTitle(sectionId)))
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

    function showHelpDialog() {
        var dialog = pageStack.push(Qt.resolvedUrl("../dialogs/HomescreenHelpDialog.qml"))
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