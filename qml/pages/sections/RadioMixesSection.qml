// Claude Generated
import QtQuick 2.0
import Sailfish.Silica 1.0

HomeSection {
    id: section
    title: qsTr("Personal Radio Stations")
    cacheKey: "radioMixes"
    filterPlaceholder: qsTr("Filter stations")

    Connections {
        target: tidalApi
        onCustomMix: if (mixType === "radioMix") section.addItem("mix", mix_info)
    }
}
