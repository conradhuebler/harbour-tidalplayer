import QtQuick 2.0
import Sailfish.Silica 1.0

Dialog {
    id: sleepTimerDialog
    
    property int selectedMinutes: 0
    property string selectedAction: "pause"
    
    canAccept: selectedMinutes > 0
    
    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height
        
        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge
            
            DialogHeader {
                title: qsTr("Sleep Timer")
                acceptText: qsTr("Start")
                cancelText: qsTr("Cancel")
            }
            
            SectionHeader {
                text: qsTr("Quick Presets")
            }
            
            // Quick preset buttons
            Flow {
                anchors {
                    left: parent.left
                    right: parent.right
                    margins: Theme.horizontalPageMargin
                }
                spacing: Theme.paddingMedium
                
                Repeater {
                    model: [
                        { minutes: 5, text: "5m", color: Theme.primaryColor },
                        { minutes: 10, text: "10m", color: Theme.primaryColor },
                        { minutes: 15, text: "15m", color: Theme.secondaryHighlightColor },
                        { minutes: 30, text: "30m", color: Theme.secondaryHighlightColor },
                        { minutes: 45, text: "45m", color: Theme.highlightColor },
                        { minutes: 60, text: "1h", color: Theme.highlightColor },
                        { minutes: 90, text: "1.5h", color: Theme.highlightDimmerColor },
                        { minutes: 120, text: "2h", color: Theme.highlightDimmerColor }
                    ]
                    
                    BackgroundItem {
                        width: Theme.itemSizeSmall
                        height: Theme.itemSizeSmall
                        highlighted: selectedMinutes === modelData.minutes
                        
                        Rectangle {
                            anchors.fill: parent
                            radius: Theme.paddingSmall
                            color: parent.highlighted ? Theme.highlightBackgroundColor : "transparent"
                            border.color: modelData.color
                            border.width: 2
                            
                            Label {
                                anchors.centerIn: parent
                                text: modelData.text
                                color: parent.parent.highlighted ? Theme.highlightColor : modelData.color
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: parent.parent.highlighted ? Font.Bold : Font.Normal
                            }
                        }
                        
                        onClicked: {
                            selectedMinutes = modelData.minutes
                            updateTimeDisplay()
                        }
                    }
                }
            }
            
            SectionHeader {
                text: qsTr("Custom Time")
            }
            
            // Custom time picker
            TimePicker {
                id: timePicker
                anchors {
                    left: parent.left
                    right: parent.right
                    margins: Theme.horizontalPageMargin
                }
                hour: 0
                minute: selectedMinutes % 60
                hourMode: DateTime.TwentyFourHours
                
                onTimeChanged: {
                    selectedMinutes = hour * 60 + minute
                    updateTimeDisplay()
                }
            }
            
            // Display selected time
            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Selected: %1").arg(formatDuration(selectedMinutes))
                font.pixelSize: Theme.fontSizeLarge
                color: Theme.highlightColor
                visible: selectedMinutes > 0
            }
            
            SectionHeader {
                text: qsTr("Action")
            }
            
            // Action selection
            ComboBox {
                anchors {
                    left: parent.left
                    right: parent.right
                    margins: Theme.horizontalPageMargin
                }
                label: qsTr("When timer expires")
                
                menu: ContextMenu {
                    MenuItem { 
                        text: qsTr("Pause playback")
                        property string value: "pause"
                    }
                    MenuItem { 
                        text: qsTr("Stop playback")
                        property string value: "stop"
                    }
                    MenuItem { 
                        text: qsTr("Fade out and pause")
                        property string value: "fade"
                    }
                    MenuItem { 
                        text: qsTr("Close application")
                        property string value: "close"
                    }
                }
                
                currentIndex: {
                    switch (selectedAction) {
                        case "pause": return 0
                        case "stop": return 1
                        case "fade": return 2
                        case "close": return 3
                        default: return 0
                    }
                }
                
                onCurrentItemChanged: {
                    if (currentItem) {
                        selectedAction = currentItem.value
                    }
                }
            }
            
            // Current timer status (if running)
            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    margins: Theme.horizontalPageMargin
                }
                height: statusColumn.height + 2 * Theme.paddingLarge
                color: Theme.rgba(Theme.highlightBackgroundColor, 0.1)
                radius: Theme.paddingSmall
                visible: applicationWindow.remainingMinutes > 0
                
                Column {
                    id: statusColumn
                    anchors {
                        left: parent.left
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                        margins: Theme.paddingLarge
                    }
                    spacing: Theme.paddingMedium
                    
                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: qsTr("Timer Active")
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.secondaryColor
                    }
                    
                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: formatDuration(applicationWindow.remainingMinutes)
                        font.pixelSize: Theme.fontSizeExtraLarge
                        color: Theme.highlightColor
                        
                        // Live timer update
                        Timer {
                            interval: 60000  // Update every minute
                            running: applicationWindow.remainingMinutes > 0
                            repeat: true
                            onTriggered: parent.text = formatDuration(applicationWindow.remainingMinutes)
                        }
                    }
                    
                    // Action info
                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: {
                            switch(applicationWindow.timerAction) {
                                case "pause": return qsTr("Will pause playback")
                                case "stop": return qsTr("Will stop playback")
                                case "fade": return qsTr("Will fade out and pause")
                                case "close": return qsTr("Will close application")
                                default: return qsTr("Will pause playback")
                            }
                        }
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: Theme.secondaryColor
                    }
                    
                    Button {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: qsTr("Cancel Timer")
                        preferredWidth: Theme.buttonWidthMedium
                        onClicked: {
                            applicationWindow.cancelSleepTimer()
                            pageStack.pop()
                        }
                    }
                }
            }
        }
    }
    
    // Update time picker when preset is selected
    function updateTimeDisplay() {
        if (selectedMinutes > 0) {
            timePicker.hour = Math.floor(selectedMinutes / 60)
            timePicker.minute = selectedMinutes % 60
        }
    }
    
    // Format duration for display
    function formatDuration(minutes) {
        if (minutes < 60) {
            return qsTr("%1 min").arg(minutes)
        } else {
            var hours = Math.floor(minutes / 60)
            var mins = minutes % 60
            if (mins === 0) {
                return qsTr("%1 h").arg(hours)
            } else {
                return qsTr("%1 h %2 min").arg(hours).arg(mins)
            }
        }
    }
    
    onAccepted: {
        if (selectedMinutes > 0) {
            console.log("Starting sleep timer:", selectedMinutes, "minutes, action:", selectedAction)
            applicationWindow.startSleepTimer(selectedMinutes, selectedAction)
        }
    }
}
