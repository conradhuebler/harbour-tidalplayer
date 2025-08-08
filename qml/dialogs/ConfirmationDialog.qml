import QtQuick 2.0
import Sailfish.Silica 1.0

// Claude Generated - Generic confirmation dialog
Dialog {
    id: confirmationDialog
    
    // Properties to be set from the calling component
    property string title: ""
    property string message: ""
    property string acceptText: qsTr("Accept")
    property string cancelText: qsTr("Cancel")
    
    Column {
        width: parent.width
        spacing: Theme.paddingLarge
        
        DialogHeader {
            title: confirmationDialog.title
            acceptText: confirmationDialog.acceptText
            cancelText: confirmationDialog.cancelText
        }
        
        Label {
            width: parent.width - 2 * Theme.horizontalPageMargin
            anchors.horizontalCenter: parent.horizontalCenter
            text: confirmationDialog.message
            wrapMode: Text.WordWrap
            color: Theme.primaryColor
        }
    }
}