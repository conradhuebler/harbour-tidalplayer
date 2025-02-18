import QtQuick 2.0
import Sailfish.Silica 1.0

Switch {
    property string icon: ""

    width: Theme.iconSizeMedium + 2 * Theme.paddingMedium
    height: Theme.iconSizeMedium + Theme.paddingMedium

    Image {
        anchors.centerIn: parent
        source: icon
        width: Theme.iconSizeMedium
        height: Theme.iconSizeMedium
    }
}
