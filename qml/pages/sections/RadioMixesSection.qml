// Claude Generated
import QtQuick 2.0
import Sailfish.Silica 1.0
import "../personalLists"

Column {
    id: section
    width: parent ? parent.width : 0
    spacing: Theme.paddingMedium

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
            if (mixType === "radioMix") {
                radioMixesList.addMix(mix_info)
                applicationWindow.personalPage.cacheItem("radioMixes", "mix", mix_info)
            }
        }
    }

    Component.onCompleted: applicationWindow.personalPage.loadSectionItems("radioMixes", radioMixesList)
}
