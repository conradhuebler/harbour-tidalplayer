import QtQuick 2.0
import Sailfish.Silica 1.0

Rectangle {
    id: notificationBanner
    
    property string title: ""
    property string message: ""
    property int displayDuration: 3000  // 3 seconds
    
    width: parent.width
    height: Math.max(Theme.itemSizeSmall, content.height + 2 * Theme.paddingMedium)
    color: Theme.rgba(Theme.highlightBackgroundColor, 0.95)
    border.color: Theme.highlightColor
    border.width: 1
    radius: Theme.paddingSmall
    z: 1000  // High z-order to appear above other elements
    
    // Initially hidden at top
    y: -height
    opacity: 0
    
    // Content
    Column {
        id: content
        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
            margins: Theme.horizontalPageMargin
        }
        spacing: Theme.paddingSmall
        
        Label {
            width: parent.width
            text: notificationBanner.title
            font.pixelSize: Theme.fontSizeSmall
            font.weight: Font.Bold
            color: Theme.primaryColor
            wrapMode: Text.Wrap
            visible: text.length > 0
        }
        
        Label {
            width: parent.width
            text: notificationBanner.message
            font.pixelSize: Theme.fontSizeExtraSmall
            color: Theme.secondaryColor
            wrapMode: Text.Wrap
        }
    }
    
    // Show animation
    ParallelAnimation {
        id: showAnimation
        NumberAnimation {
            target: notificationBanner
            property: "y"
            to: 0
            duration: 300
            easing.type: Easing.OutQuad
        }
        NumberAnimation {
            target: notificationBanner
            property: "opacity"
            to: 1.0
            duration: 300
        }
    }
    
    // Hide animation
    SequentialAnimation {
        id: hideAnimation
        PauseAnimation { duration: displayDuration }
        ParallelAnimation {
            NumberAnimation {
                target: notificationBanner
                property: "y"
                to: -notificationBanner.height
                duration: 300
                easing.type: Easing.InQuad
            }
            NumberAnimation {
                target: notificationBanner
                property: "opacity"
                to: 0.0
                duration: 300
            }
        }
        ScriptAction {
            script: notificationBanner.destroy()
        }
    }
    
    // Click to dismiss
    MouseArea {
        anchors.fill: parent
        onClicked: {
            hideAnimation.stop()
            var quickHide = Qt.createQmlObject('
                import QtQuick 2.0;
                ParallelAnimation {
                    NumberAnimation { target: notificationBanner; property: "y"; 
                                     to: -notificationBanner.height; duration: 200 }
                    NumberAnimation { target: notificationBanner; property: "opacity"; 
                                     to: 0.0; duration: 200 }
                    onFinished: notificationBanner.destroy()
                }', notificationBanner)
            quickHide.start()
        }
    }
    
    // Public function to show the banner
    function show() {
        showAnimation.start()
        hideAnimation.start()
    }
    
    Component.onCompleted: {
        // Ensure we're parented to the application window
        if (parent && typeof parent.contentItem !== 'undefined') {
            parent = parent.contentItem
        }
    }
}