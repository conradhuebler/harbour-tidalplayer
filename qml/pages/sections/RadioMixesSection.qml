// Claude Generated
import QtQuick 2.0
import Sailfish.Silica 1.0
import "../personalLists"

Column {
    id: section
    width: parent.width
    spacing: Theme.paddingMedium
    visible: applicationWindow.settings.radioMixesList

    SectionHeader {
        text: qsTr("Personal Radio Stations")
    }

    HorizontalList {
        id: radioMixesList
        width: parent.width
    }

    Connections {
        target: tidalApi
        onCustomMix: {
            if (mixType === "radioMix") radioMixesList.addMix(mix_info)
        }
    }
}
