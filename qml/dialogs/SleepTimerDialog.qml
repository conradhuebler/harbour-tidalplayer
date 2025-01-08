// SleepTimerDialog.qml

import QtQuick 2.0
import Sailfish.Silica 1.0

Dialog {
    id: dialog

    property int selectedMinutes: 0

    canAccept: selectedMinutes > 0

    Column {
        width: parent.width
        spacing: Theme.paddingLarge

        DialogHeader {
            title: qsTr("Set Sleep Timer")
        }

        ComboBox {
            id: durationCombo
            width: parent.width
            label: qsTr("Duration")

            menu: ContextMenu {
                MenuItem { text: qsTr("15 minutes"); onClicked: selectedMinutes = 15 }
                MenuItem { text: qsTr("30 minutes"); onClicked: selectedMinutes = 30 }
                MenuItem { text: qsTr("45 minutes"); onClicked: selectedMinutes = 45 }
                MenuItem { text: qsTr("1 hour"); onClicked: selectedMinutes = 60 }
                MenuItem { text: qsTr("1.5 hours"); onClicked: selectedMinutes = 90 }
                MenuItem { text: qsTr("2 hours"); onClicked: selectedMinutes = 120 }
                MenuItem { text: qsTr("Custom..."); onClicked: openCustomDialog() }
            }
        }

        Label {
            x: Theme.horizontalPageMargin
            width: parent.width - 2*x
            text: selectedMinutes > 0
                  ? qsTr("Playback will stop in %1").arg(Format.formatDuration(selectedMinutes * 60, Formatter.DurationLong))
                  : qsTr("Select duration")
            wrapMode: Text.Wrap
            color: Theme.highlightColor
        }
    }

    function openCustomDialog() {
        pageStack.push(Qt.resolvedUrl("CustomDurationDialog.qml"), {},
            PageStackAction.Animated, function(dialog) {
                dialog.accepted.connect(function() {
                    selectedMinutes = dialog.minutes
            })
        }
    )
}
}
