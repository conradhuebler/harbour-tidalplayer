// Claude Generated
import QtQuick 2.0
import Sailfish.Silica 1.0
import "../modules/Opal/Delegates" 1.0 as Del
import "../modules/Opal/DragDrop" 1.0 as Drag

Page {
    id: page

    readonly property var defaultOrder: ["recent", "foryou", "topartist", "topalbum",
                                         "toptrack", "personalPlaylist", "dailyMixes",
                                         "radioMixes", "favArtists"]

    readonly property var titles: ({
        "recent":           qsTr("Recently played"),
        "foryou":           qsTr("Popular playlists"),
        "topartist":        qsTr("Top Artists"),
        "topalbum":         qsTr("Top Albums"),
        "toptrack":         qsTr("Top Tracks"),
        "personalPlaylist": qsTr("Personal Playlists"),
        "dailyMixes":       qsTr("Custom Mixes"),
        "radioMixes":       qsTr("Personal Radio Stations"),
        "favArtists":       qsTr("Favorite Artists")
    })

    readonly property var visibilityKeys: ({
        "recent":           "recentList",
        "foryou":           "yourList",
        "topartist":        "topartistList",
        "topalbum":         "topalbumsList",
        "toptrack":         "toptrackList",
        "personalPlaylist": "personalPlaylistList",
        "dailyMixes":       "dailyMixesList",
        "radioMixes":       "radioMixesList",
        "favArtists":       "topArtistsList"
    })

    function loadFromSettings() {
        sectionsModel.clear()
        var order = applicationWindow.settings.homescreenSectionOrder
        if (!order || order.length === 0) order = defaultOrder.slice()
        // Make sure every known id appears exactly once (defensive against
        // settings that were written by older builds with a different set).
        var seen = {}
        for (var i = 0; i < order.length; i++) {
            var id = order[i]
            if (!titles[id] || seen[id]) continue
            seen[id] = true
            sectionsModel.append({
                "sectionId": id,
                "title": titles[id],
                "sectionVisible": !!applicationWindow.settings[visibilityKeys[id]]
            })
        }
        for (var k = 0; k < defaultOrder.length; k++) {
            var did = defaultOrder[k]
            if (seen[did]) continue
            sectionsModel.append({
                "sectionId": did,
                "title": titles[did],
                "sectionVisible": !!applicationWindow.settings[visibilityKeys[did]]
            })
        }
    }

    function saveToSettings() {
        var order = []
        for (var i = 0; i < sectionsModel.count; i++) {
            var item = sectionsModel.get(i)
            order.push(item.sectionId)
            applicationWindow.settings[visibilityKeys[item.sectionId]] = item.sectionVisible
        }
        applicationWindow.settings.homescreenSectionOrder = order
    }

    function resetDefaults() {
        for (var i = 0; i < defaultOrder.length; i++) {
            applicationWindow.settings[visibilityKeys[defaultOrder[i]]] = true
        }
        applicationWindow.settings.homescreenSectionOrder = defaultOrder.slice()
        loadFromSettings()
    }

    SilicaListView {
        id: layoutView
        anchors.fill: parent
        header: PageHeader { title: qsTr("Homescreen Layout") }

        PullDownMenu {
            MenuItem {
                text: qsTr("Reset to defaults")
                onClicked: resetDefaults()
            }
        }

        Drag.ViewDragHandler {
            id: viewDragHandler
            listView: layoutView
            active: true
            handleMove: true
            onItemDropped: function(originalIndex, currentIndex, finalIndex) {
                if (originalIndex !== finalIndex) saveToSettings()
            }
        }

        model: ListModel { id: sectionsModel }

        delegate: Del.OneLineDelegate {
            id: row
            text: model.title
            dragHandler: viewDragHandler
            enableDefaultGrabHandle: true
            interactive: false

            leftItem: Switch {
                checked: model.sectionVisible
                automaticCheck: false
                onClicked: {
                    var newValue = !model.sectionVisible
                    sectionsModel.setProperty(row._modelIndex, "sectionVisible", newValue)
                    applicationWindow.settings[visibilityKeys[model.sectionId]] = newValue
                    if (newValue && tidalApi.loginTrue && applicationWindow.personalPage) {
                        applicationWindow.personalPage.loadSectionData(model.sectionId)
                    }
                }
            }
        }
    }

    Component.onCompleted: loadFromSettings()
}
