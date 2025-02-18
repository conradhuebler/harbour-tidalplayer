import QtQuick 2.0
import Sailfish.Silica 1.0

Dialog {
    id: customDialog

    property int minutes: timePicker.hour * 60 + timePicker.minute

    canAccept: minutes > 0

    Column {
        width: parent.width
        spacing: Theme.paddingLarge

        DialogHeader {
            title: qsTr("Custom Duration")
        }

        TimePicker {
            id: timePicker
            anchors.horizontalCenter: parent.horizontalCenter
            hour: 0
            minute: 0
            hourMode: DateTime.Hours24

            // Optional: Labels anpassen
            //hourText: qsTr("Hours")
            //minuteText: qsTr("Minutes")
        }

        Label {
            x: Theme.horizontalPageMargin
            width: parent.width - 2*x
            text: minutes > 0
                  ? qsTr("Timer will run for %1").arg(Format.formatDuration(minutes * 60, Formatter.DurationLong))
                  : qsTr("Select duration")
            wrapMode: Text.Wrap
            color: Theme.highlightColor
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
