// Claude Generated
import QtQuick 2.0
import Sailfish.Silica 1.0
import "../personalLists"

Column {
    id: section
    width: parent ? parent.width : 0
    spacing: Theme.paddingMedium

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
            if (mixType === "dailyMix") {
                dailyMixesList.addMix(mix_info)
                applicationWindow.personalPage.cacheItem("dailyMixes", "mix", mix_info)
            }
        }
    }

    Component.onCompleted: applicationWindow.personalPage.loadSectionItems("dailyMixes", dailyMixesList)
}
