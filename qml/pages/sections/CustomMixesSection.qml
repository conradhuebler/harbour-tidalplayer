// Claude Generated
import QtQuick 2.0
import Sailfish.Silica 1.0

HomeSection {
    id: section
    title: qsTr("Custom Mixes")
    cacheKey: "dailyMixes"
    filterPlaceholder: qsTr("Filter mixes")

    Connections {
        target: tidalApi
        onCustomMix: if (mixType === "dailyMix") section.addItem("mix", mix_info)
    }
}
