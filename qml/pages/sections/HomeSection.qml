// Claude Generated
// Shared layout for a homescreen section: SectionHeader (with tap-to-toggle
// filter), optional SearchField (with optional debounce), HorizontalList of
// items, and the LocalStorage cache plumbing.
//
// A section file just sets `title` + `cacheKey` and declares its own
// Connections {} for the backend signals it cares about — calling
// section.addItem(type, data) routes the item to the right list method
// and writes it to the cache.
import QtQuick 2.0
import Sailfish.Silica 1.0
import "../personalLists"

Column {
    id: section
    width: parent ? parent.width : 0
    spacing: Theme.paddingMedium

    property string title
    // Persistent LocalStorage cache key. Empty disables caching for this section.
    property string cacheKey: ""
    // Empty placeholder => no SearchField rendered and the section header
    // does not tap-toggle a filter.
    property string filterPlaceholder: ""
    // 0 => filter updates synchronously on every keystroke. >0 => debounce.
    property int filterDebounceMs: 0

    readonly property alias list: theList
    readonly property bool hasFilter: filterPlaceholder !== ""

    // Default child slot - section files drop their Connections {} here.
    default property alias _content: extraContent.data

    SectionHeader {
        text: section.title
        MouseArea {
            anchors.fill: parent
            enabled: section.hasFilter
            onClicked: {
                filter.visible = !filter.visible
                if (filter.visible) filter.forceActiveFocus()
            }
        }
    }

    SearchField {
        id: filter
        visible: false
        labelVisible: false
        anchors.margins: Theme.paddingMedium
        placeholderText: section.filterPlaceholder

        Timer {
            id: filterDebounce
            interval: Math.max(0, section.filterDebounceMs)
            repeat: false
            onTriggered: theList.filterText = filter.text
        }

        onTextChanged: {
            if (section.filterDebounceMs > 0) filterDebounce.restart()
            else theList.filterText = text
        }
    }

    HorizontalList {
        id: theList
        width: parent.width
    }

    // Holds the Connections {} (and any other non-visual items) declared by
    // the section file — non-visual so it adds no layout.
    Item { id: extraContent; visible: false }

    // Append an item to the list and to the persistent cache. type ∈
    // {"album", "mix", "artist", "playlist", "track"}.
    function addItem(type, data) {
        if (type === "album")         theList.addAlbum(data)
        else if (type === "mix")      theList.addMix(data)
        else if (type === "artist")   theList.addArtist(data)
        else if (type === "playlist") theList.addPlaylist(data)
        else if (type === "track")    theList.addTrack(data)
        else {
            if (applicationWindow.settings && applicationWindow.settings.debugLevel >= 1)
                console.log("HomeSection: unknown item type", type)
            return
        }
        if (cacheKey !== "" && applicationWindow.personalPage) {
            applicationWindow.personalPage.cacheItem(cacheKey, type, data)
        }
    }

    Component.onCompleted: {
        if (cacheKey !== "" && applicationWindow.personalPage) {
            applicationWindow.personalPage.loadSectionItems(cacheKey, theList)
        }
    }
}
