// Claude Generated
import QtQuick 2.0
import Sailfish.Silica 1.0
import "../personalLists"

Column {
    id: section
    width: parent.width
    spacing: Theme.paddingMedium
    visible: applicationWindow.settings.dailyMixesList

    SectionHeader {
        text: qsTr("Custom Mixes")
    }

    HorizontalList {
        id: dailyMixesList
        width: parent.width
    }

    Connections {
        target: tidalApi
        onCustomMix: {
            if (mixType === "dailyMix") dailyMixesList.addMix(mix_info)
        }
    }
}
