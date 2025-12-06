import QtQuick 2.0
import Sailfish.Silica 1.0
// import Opal.Delegates 1.0 as D
import "../modules/Opal/Delegates" 1.0  as Del
import "../modules/Opal/DragDrop" 1.0 as Drag

Item {
    id: root

    // Properties für verschiedene Verwendungszwecke
    property string title: ""
    property string playlistId: ""
    property int albumId: -1
    property string type: "current"  // "playlist" oder "current" oder "album" oder "mix" ("tracklist")
    property int currentIndex: playlistManager.currentIndex
    property alias model: listModel
    property int totalTracks: playlistManager.totalTracks  // For search field visibility
    
    // Edit mode state
    property bool editMode: false
    // True while an item is being dragged/reordered
    property bool dragActive: false

    // Search state - Claude Generated
    property bool searchVisible: false
    property int filteredCount: 0
    
    // Auto-scroll to current track - Claude Generated
    onCurrentIndexChanged: {
        if (editMode) return
        if (type === "current" && currentIndex >= 0 && currentIndex < listModel.count) {
            // Use timer to ensure ListView is ready
            autoScrollTimer.targetIndex = currentIndex
            autoScrollTimer.restart()
        }
    }
    
    Timer {
        id: autoScrollTimer
        interval: 300  // Delay to ensure ListView is ready
        property int targetIndex: -1
        onTriggered: {
            // If a drag operation is in progress, postpone the auto-scroll
            if (dragActive) {
                if (applicationWindow.settings.debugLevel >= 2) {
                    console.log("TRACKLIST: Auto-scroll postponed because drag is active")
                }
                // Try again shortly after
                autoScrollTimer.restart()
                return
            }

            if (targetIndex >= 0 && targetIndex < listModel.count) {
                if (applicationWindow.settings.debugLevel >= 2) {
                    console.log("TRACKLIST: Smooth scrolling to track", targetIndex)
                }
                // Enable animation temporarily, then use positionViewAtIndex
                // if targetIndex near start, use Begin to avoid empty space above
                var useCenter = targetIndex > Math.floor(tracks.height / root.normalItemHeight / 2)
                tracks.animateScrolling = true
                tracks.positionViewAtIndex(targetIndex, useCenter ? ListView.Center : ListView.Contain)
                // Disable animation after scroll completes
                scrollAnimationTimer.start()
            }
        }
    }
    
    Timer {
        id: scrollAnimationTimer
        interval: 450  // Slightly longer than animation duration
        onTriggered: {
            tracks.animateScrolling = false
        }
    }
    
    // Filter timer and logic - Claude Generated
    Timer {
        id: filterTimer
        interval: 300  // Debounce search input
        onTriggered: {
            refreshList()
        }
    }
    
    Timer {
        id: clearScrollTimer
        interval: 500  // Wait for filter refresh to complete
        onTriggered: {
            if (type === "current" && root.currentIndex >= 0) {
                autoScrollTimer.targetIndex = root.currentIndex
                autoScrollTimer.restart()
                if (applicationWindow.settings.debugLevel >= 1) {
                    console.log("SEARCH: Auto-scrolling to current track after text clear:", root.currentIndex)
                }
            }
        }
    }
    
    Timer {
        id: autoClearTimer
        interval: 300  // Smooth delay after track selection
        onTriggered: {
            searchField.text = ""
            searchVisible = false
        }
    }
    
    // Store original playlist data for filtering
    property var originalPlaylistData: []
    
    function refreshList() {
        // Perform an in-place update of `listModel` so we don't clear/recreate
        // delegates. This preserves focus, selection and scroll position.
        if (type !== "current") {
            // Keep previous behavior for non-current lists
            updateTimer.start()
            return
        }

        var searchText = ""
        var hasFilter = false
        if (typeof searchField !== 'undefined' && searchField && searchField.visible) {
            searchText = searchField.text.toLowerCase()
            hasFilter = searchText.length > 0
        }

        if (applicationWindow.settings.debugLevel >= 1) {
            console.log("TRACKLIST: refreshList (in-place). filter=", hasFilter ? searchText : '<none>', "playlistSize=", playlistManager.size)
        }

        // Build new items array without touching the model yet
        var newItems = []
        for (var i = 0; i < playlistManager.size; ++i) {
            var id = playlistManager.requestPlaylistItem(i)
            var track = cacheManager.getTrackInfo(id)
            if (!track) continue

            var matchesFilter = !hasFilter ||
                track.title.toLowerCase().indexOf(searchText) >= 0 ||
                track.artist.toLowerCase().indexOf(searchText) >= 0 ||
                track.album.toLowerCase().indexOf(searchText) >= 0

            if (matchesFilter) {
                newItems.push({
                    "title": track.title,
                    "artist": track.artist,
                    "album": track.album,
                    "id": track.id,
                    "trackid": track.id,
                    "duration": track.duration,
                    "image": track.image,
                    "index": i
                })
            }
        }

        // Preserve scroll position and current active focus
        var savedContentY = tracks.contentY
        var savedAnimate = tracks.animateScrolling
        var savedHasFocus = (Qt.application.activeFocusItem !== null)
        var savedFocusItem = Qt.application.activeFocusItem

        // Temporarily disable animated scrolling while we adjust model
        tracks.animateScrolling = false

        // Update model in-place: set existing entries, remove extras, append new ones
        var common = Math.min(listModel.count, newItems.length)
        for (var j = 0; j < common; ++j) {
            listModel.set(j, newItems[j])
        }
        // Remove trailing items if any
        while (listModel.count > newItems.length) {
            listModel.remove(listModel.count - 1)
        }
        // Append additional items
        for (var k = common; k < newItems.length; ++k) {
            listModel.append(newItems[k])
        }

        // Update filteredCount and keep debug log
        root.filteredCount = newItems.length
        if (applicationWindow.settings.debugLevel >= 1) {
            console.log("TRACKLIST: refreshed in-place, items=", newItems.length)
        }

        // Restore scroll/focus
        tracks.contentY = savedContentY
        tracks.animateScrolling = savedAnimate
        if (savedHasFocus && savedFocusItem) {
            savedFocusItem.forceActiveFocus()
        }
    }

    // Add styling properties
    property real normalItemHeight: Theme.itemSizeMedium + Theme.paddingMedium
    property real selectedItemHeight: Theme.itemSizeMedium * 1.5 + Theme.paddingMedium
    property int normalFontSize: Theme.fontSizeMedium
    property int selectedFontSize: Theme.fontSizeLarge
    
    property color selectedTextColor: Theme.highlightColor
    property color normalTextColor: Theme.primaryColor
    property color selectedSecondaryColor: Theme.secondaryHighlightColor
    property color normalSecondaryColor: Theme.secondaryColor
    property real highlightOpacity: 0.2
    
    // Create a function to determine if item is selected
    function isItemSelected(index) {
        if (editMode) return false
        return type === "current" && index === root.currentIndex
    }

    Timer {
        id: updateTimer
        interval: 100  // 100ms Verzögerung
        repeat: false
        onTriggered: {
            console.log(playlistManager.size)
            for(var i = 0; i < playlistManager.size; ++i) {
                var id = playlistManager.requestPlaylistItem(i)
                var track = cacheManager.getTrackInfo(id)
                if (track) {
                    listModel.append({
                        "title": track.title,
                        "artist": track.artist,
                        "album": track.album,
                        "id": track.id,
                        "trackid": track.id,
                        "duration": track.duration,
                        "image": track.image,
                        "index": i
                    })
                } else {
                    console.log("No track data for index:", i)
                }
            }
        }
    }

    function enableEditMode(editMode) {
        if (editMode) {
            searchButton.visible = false
            searchVisible = false
            autoScrollTimer.stop()
            scrollAnimationTimer.stop()
            tracks.animateScrolling = false
            return
        }
        // disabled
        searchButton.visible = true
    }

    SilicaListView {
        id: tracks
        anchors.fill: parent

        // PERFORMANCE: Virtual scrolling optimizations
        cacheBuffer: Math.max(height * 2, 0)  // Cache 2 screens worth of content, never negative
        
        // Add smooth scrolling properties
        highlightRangeMode: ListView.ApplyRange
        highlightMoveDuration: 1000  // Duration of the scroll animation in milliseconds
        highlightMoveVelocity: -1   // -1 means use duration instead of velocity
        preferredHighlightBegin: height * 0.1
        preferredHighlightEnd: height * 0.9
        
        // Conditional smooth animated scrolling - Claude Generated
        property bool animateScrolling: false
        
        Behavior on contentY {
            enabled: tracks.animateScrolling
            NumberAnimation {
                duration: 400
                easing.type: Easing.OutCubic
            }
        }

        // Create a drag handler for the SilicaListView.
        Drag.ViewDragHandler {
            id: viewDragHandler1
            listView: parent
            active: (type==="current" && editMode )? true:false
            handleMove: false // We handle the move ourselves
            property int dragStartIndex : -1

            onItemMoved: function(from, to) {
                console.log("itemMoved - from " + from + " to " + to + ", dragStartIndex= " + dragStartIndex)
                if (dragStartIndex == -1) {
                    dragStartIndex = from
                    dragActive = true
                }
            }
            
            onItemDropped: function(from, curr, to) {
                console.log("Drag-drop operation: originalIndex=", from, "currentIndex=", curr, "finalIndex=", to, "stardIndex=",dragStartIndex)
                if (from !== to && type === "current") {
                    console.log("Calling moveTrack with from=", from, "to=", to)
                    // Call the moveTrack function in PlaylistManager
                    listModel.move(dragStartIndex, to, 1)
                    playlistManager.moveTrack(dragStartIndex, to, true)
                    root.refreshList()
                }

                // Clear drag state immediately
                dragStartIndex = -1
                dragActive = false
            }
        }
        
        header: root.title === "" ? null : headerComponent

        Component {
            id: headerComponent
            PageHeader {
                id: pageHeader
                title: root.title
            }
        }


        height: parent.height
        contentHeight: listModel.count * root.normalItemHeight
        bottomMargin: Theme.paddingLarge

        clip: true  // prevents visual overruns

        PullDownMenu {
            // this works only when parent does not define any other menues
            MenuItem {
                text: qsTr("Play All")
                onClicked: {
                    if (type === "playlist" ) {
                        playlistManager.clearPlayList()
                        tidalApi.playPlaylist(playlistId)
                    }
                }
                visible: type === "playlist"
            }
            visible: type === "playlist"
        }

        model: ListModel {
            id: listModel
        }

        delegate: Del.TwoLineDelegate { //ListItem {
            id: listEntry
            width: parent.width
            contentHeight: isItemSelected(model.index) ? root.selectedItemHeight : root.normalItemHeight
            highlighted: isItemSelected(model.index)

            // Register the drag handler in the delegate.
            dragHandler: viewDragHandler1
            // Ensure drag handle is visible and properly configured
            enableDefaultGrabHandle: type === "current" && editMode

            leftItem :
                Image {
                id: coverImage
                width: listEntry.highlighted ? Theme.itemSizeExtraLarge : Theme.itemSizeMedium
                height: width
                fillMode: Image.PreserveAspectCrop
                source: model.image || ""
                asynchronous: true

                Behavior on width { NumberAnimation { duration: 150 } }
                }

            rightItem: 
                   Label {
                    visible: listEntry.highlighted
                    text: "▶"
                    color: selectedTextColor
                    font.pixelSize: root.selectedFontSize
                    width: visible ? implicitWidth : 0
                    verticalAlignment: Text.AlignVCenter
                }

            textLabel.palette {
                // just as an example
                // primaryColor: normalColor
                // highlightedColor: highlightColor
            }
            textLabel.font.bold: isItemSelected(model.index)
            textLabel.highlighted: isItemSelected(model.index)

            text: model.title
            description: { model.artist + " • " +
                ((model.duration > 3599)
                         ? Format.formatDuration(model.duration, Formatter.DurationLong)
                         : Format.formatDuration(model.duration, Formatter.DurationShort))
            }

            onClicked: {
                // dont play in edit mode
                if (editMode) return

                // Play track first
                if (type === "current") {
                    playlistManager.playPosition(Math.floor(model.index))  // Stelle sicher, dass es ein Integer ist
                } else {
                    playlistManager.playTrack(model.trackid)
                }                
                // Auto-clear search with smooth delay if only one result - Claude Generated
                if (type === "current" && searchVisible && root.filteredCount === 1) {
                    if (applicationWindow.settings.debugLevel >= 1) {
                        console.log("SEARCH: Auto-clearing search - single result selected")
                    }
                    // Smooth delay to let track change be visible first
                    autoClearTimer.start()
                }
            }

            // Swipe-to-delete handler with remorse (only in editMode)
            Item {
                id: swipeDeleteContainer
                anchors.fill: parent
                property bool showDeleteButton: false
                property int timeLeft: 3000  // Countdown in milliseconds

                // Timer for remorse/undo
                Timer {
                    id: remorseTimer
                    interval: 100  // Update countdown every 100ms
                    repeat: true
                    onTriggered: {
                        swipeDeleteContainer.timeLeft -= interval
                        if (swipeDeleteContainer.timeLeft <= 0) {
                            // Actually remove the track after timeout
                            var trackId = playlistManager.requestPlaylistItem(model.index)
                            console.log("Remorse timeout: removing track", trackId)
                                // Remove silently (don't emit listChanged) and update view directly
                                playlistManager.removeTrack(trackId, true)
                                // Keep playlistManager.currentIndex in sync with view
                                root.currentIndex = playlistManager.currentIndex
                                // Remove visual item from ListModel
                                if (model && typeof model.index !== 'undefined') {
                                    listModel.remove(model.index)
                                }
                                root.filteredCount = Math.max(0, root.filteredCount - 1)
                                swipeDeleteContainer.showDeleteButton = false
                                stop()
                        }
                    }
                }

                // Remorse overlay with delete button (anchored to the right of cover image)
                Rectangle {
                    id: deleteButtonOverlay
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.leftMargin: listEntry.leftItem.Image.width
                    anchors.right: parent.right
                    color: Theme.rgba(Theme.highlightBackgroundColor, 0.9)
                    visible: swipeDeleteContainer.showDeleteButton
                    opacity: visible ? 1.0 : 0.0
                    z: 10

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.InOutQuad
                        }
                    }

                    Row {
                        anchors.fill: parent
                        anchors.margins: Theme.paddingMedium
                        spacing: Theme.paddingMedium
                        layoutDirection: Qt.RightToLeft

                        // Cancel button
                        Button {
                            anchors.verticalCenter: parent.verticalCenter
                            text: qsTr("Cancel")
                            preferredWidth: Theme.buttonWidthSmall
                            onClicked: {
                                console.log("Delete cancelled")
                                swipeDeleteContainer.showDeleteButton = false
                                remorseTimer.stop()
                                swipeDeleteContainer.timeLeft = 3000  // Reset timer
                            }
                        }

                        // Delete button
                        Button {
                            anchors.verticalCenter: parent.verticalCenter
                            text: qsTr("Delete")
                            preferredWidth: Theme.buttonWidthSmall
                            onClicked: {
                                var trackId = playlistManager.requestPlaylistItem(model.index)
                                console.log("Delete confirmed: removing track", trackId)
                                // Remove silently and update view without triggering full refresh
                                playlistManager.removeTrack(trackId, true)
                                root.currentIndex = playlistManager.currentIndex
                                if (model && typeof model.index !== 'undefined') {
                                    listModel.remove(model.index)
                                }
                                root.filteredCount = Math.max(0, root.filteredCount - 1)
                                swipeDeleteContainer.showDeleteButton = false
                                remorseTimer.stop()
                            }
                        }

                        Item { width: Theme.paddingMedium; height: 1 }  // Spacer

                        // Countdown timer display
                        Label {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Math.max(0, Math.ceil(swipeDeleteContainer.timeLeft / 1000)) + "s"
                            color: Theme.secondaryHighlightColor
                            font.pixelSize: Theme.fontSizeLarge
                            width: Theme.itemSizeExtraSmall
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }

                SilicaFlickable {
                    id: swipeFlick
                    anchors.fill: parent
                    flickableDirection: Flickable.HorizontalFlick
                    interactive: editMode && !dragActive

                    contentWidth: width * 2
                    contentHeight: height

                    onMovementEnded: {
                        if (contentX > width * 0.25) {
                            // Swiped to the left
                            console.log("LEFT SWIPE", model.index)
                            swipeDeleteContainer.timeLeft = 3000
                            swipeDeleteContainer.showDeleteButton = true
                            remorseTimer.restart()
                        }

                        // Reset position
                        contentX = 0
                    }
                }

            }

            menu: ContextMenu {
                MenuItem {
                    text: qsTr("Play Now")
                    onClicked: {
                        if (type === "current") {
                            playlistManager.playPosition(Math.floor(model.index))  // Stelle sicher, dass es ein Integer ist
                        } else {
                            playlistManager.playTrack(model.trackid)
                        }
                    }
                }
                MenuItem {
                    text: qsTr("Add to Queue")
                    onClicked: {
                        playlistManager.appendTrack(model.trackid)
                    }
                    visible: type !== "current"
                }
                MenuItem {
                    text: qsTr("Remove from Queue")
                    onClicked: {
                        var orgIndex = model.index
                        var orgTrackId = playlistManager.requestPlaylistItem(model.index)
                        var playingState = mediaController.isPlaying
                        var removingPrevTrack = orgIndex < currentIndex
                        var removingSelected = currentIndex === model.index
                        console.log("removingPrevTrack:",orgIndex)
                        playlistManager.removeTrack(orgTrackId)
                        if (type === "current") {
                            if (playlistManager.size === 0) {
                                playlistManager.playlistFinished()
                                return
                            }
                            if (removingSelected)
                            {   // intention: if user removes the currently played song
                                // then move next if possible, else stop playing
                                if (playingState) {
                                    playlistManager.playPosition(model.index)
                                } else {
                                    playlistManager.setTrack(orgIndex) }// to inform cover
                                return
                            }
                            if (removingPrevTrack ) {
                                // remove a track before selected
                                console.log("removePrevTrack:", orgIndex, currentIndex)
                                var newIndex = Math.max(0, currentIndex - 1)
                                if (playingState) {
                                    playlistManager.playPosition(newIndex)
                                 } else {
                                    model.index = newIndex
                                    currentIndex = newIndex
                                    playlistManager.setTrack(newIndex)  
                                }
                            }
                            // no action needed for removal after current track
                        }
                    }
                    visible: type === "current"
                }
                MenuItem {
                    // get artistInfo
                    text: qsTr("Artist Info")
                    onClicked: {
                        var trackId
                        if (type === "current") {
                            trackId = playlistManager.requestPlaylistItem(model.index)
                        }
                        else {
                            trackId = model.trackid
                        }                        
                        var trackInfo = cacheManager.getTrackInfo(trackId)
                        if (trackInfo && trackInfo.artistid) {
                            pageStack.push(Qt.resolvedUrl("./ArtistPage.qml"),
                                { artistId: trackInfo.artistid })
                        }
                    }
                }
                MenuItem {
                    // get albumInfo
                    text: qsTr("Album Info")
                    onClicked: {
                        var trackId
                        if (type === "current") {
                            trackId = playlistManager.requestPlaylistItem(model.index)
                        }
                        else {
                            trackId = model.trackid
                        }
                        var trackInfo = cacheManager.getTrackInfo(trackId)
                        if (trackInfo && trackInfo.albumid) {
                            pageStack.push(Qt.resolvedUrl("./AlbumPage.qml"),
                                { albumId: trackInfo.albumid })
                        }
                    }
                }
            }

        }

        ViewPlaceholder {
            enabled: listModel.count === 0
            text: qsTr("No Tracks")
            hintText: type === "playlist" ?
                     qsTr("This playlist is empty") :
                     qsTr("No tracks in queue")
        }

        VerticalScrollDecorator {}
    }

    
    // Floating search overlay for current playlist - Claude Generated
    Rectangle {
        id: searchOverlay
        anchors.left: parent.left
        anchors.right: parent.right
        height: searchField.height + Theme.paddingMedium * 2
        color: Theme.rgba(Theme.overlayBackgroundColor, 0.9)
        visible: type === "current" && root.totalTracks > 0
        z: 100  // Above ListView
        
        // Smooth slide animation from top
        y: searchVisible ? 0 : -height
        
        Behavior on y {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutQuad
            }
        }
        
        // Fade animation
        opacity: searchVisible ? 1.0 : 0.0
        
        Behavior on opacity {
            NumberAnimation {
                duration: 200
                easing.type: Easing.InOutQuad
            }
        }
        
        SearchField {
            id: searchField
            anchors.centerIn: parent
            anchors.rightMargin: Theme.paddingLarge * 2
            width: parent.width - Theme.paddingLarge * 4
            placeholderText: qsTr("Search in playlist...")
            
            onTextChanged: {
                if (applicationWindow.settings.debugLevel >= 2) {
                    console.log("SEARCH: Text changed to:", text)
                }
                filterTimer.restart()
                
                // Auto-scroll to current track when text is completely cleared - Claude Generated
                if (text === "" && type === "current" && root.currentIndex >= 0) {
                    // Delay scroll until after filter refresh
                    clearScrollTimer.restart()
                }
            }
        }

        
        // Close button
        IconButton {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: Theme.paddingMedium
            icon.source: "image://theme/icon-m-clear"
            onClicked: {
                searchField.text = ""
                searchVisible = false
                // Auto-scroll to current track when search is cleared - Claude Generated
                if (type === "current" && root.currentIndex >= 0) {
                    autoScrollTimer.targetIndex = root.currentIndex
                    autoScrollTimer.restart()
                    if (applicationWindow.settings.debugLevel >= 1) {
                        console.log("SEARCH: Auto-scrolling to current track after clear:", root.currentIndex)
                    }
                }
            }
        }
    }
    
    // Search toggle button - Claude Generated
    IconButton {
        id: searchButton
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.rightMargin: Theme.paddingLarge
        anchors.bottomMargin: Theme.paddingLarge * 3
        icon.source: "image://theme/icon-m-search"
        visible: type === "current" && root.totalTracks > 0
        z: 99
        
        // Smooth fade animation
        opacity: searchVisible ? 0.0 : 1.0
        enabled: !searchVisible
        
        Behavior on opacity {
            NumberAnimation {
                duration: 200
                easing.type: Easing.InOutQuad
            }
        }
        
        // Scale animation on press
        scale: pressed ? 0.9 : 1.0
        
        Behavior on scale {
            NumberAnimation {
                duration: 100
                easing.type: Easing.OutQuad
            }
        }
        
        onClicked: {
            searchVisible = true
            // Delay focus until animation starts
            focusTimer.start()
        }
    }
    
    IconButton {
        id: editButton
        anchors.top: searchButton.bottom
        anchors.right: parent.right
        anchors.rightMargin: editMode ? Theme.paddingLarge * 4 : Theme.paddingLarge
        anchors.bottomMargin: Theme.paddingLarge

        icon.source: editMode
            ? "image://theme/icon-m-file-audio"      // exit edit mode
            : "image://theme/icon-m-edit"      // enter edit mode

        visible: type === "current"
        z: 99

        // Simple fade-in/out, consistent with search button
        opacity: 1.0
        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
        }

        onClicked: {
            console.log("Toggling edit mode")
            editMode = !editMode
            enableEditMode(editMode)
        }
    }

    // Timer for delayed focus - Claude Generated
    Timer {
        id: focusTimer
        interval: 100  // Wait for slide animation to start
        onTriggered: {
            searchField.forceActiveFocus()
        }
    }

    Component.onCompleted: {
        if (type === "playlist") {
            console.log("getPlaylistTracks")
            tidalApi.getPlaylistTracks(playlistId)
        } else if (type == "album") {
            tidalApi.getAlbumTracks(albumId)
        } else if (type == "mix") {
            console.log("getMixTracks")
            tidalApi.getMixTracks(playlistId)
        } else {
            playlistManager.generateList()
        }
    }

    
    Connections {
        target: tidalApi
        onPlaylistTrackAdded: {
            if (type === "playlist") {
                listModel.append({
                    "title": track_info.title,
                    "artist": track_info.artist,
                    "album": track_info.album,
                    "trackid": track_info.trackid,
                    "duration": track_info.duration,
                    "image": track_info.image
                })
            }
        }

        onAlbumTrackAdded: {
            if (type === "album") {
                listModel.append({
                    "title": track_info.title,
                    "artist": track_info.artist,
                    "album": track_info.album,
                    "trackid": track_info.trackid,
                    "duration": track_info.duration,
                    "image": track_info.image
                })
            }
        }

        onMixTrackAdded: {
            //console.log("Mix track added")
            if (type === "mix") {
                listModel.append({
                    "title": track_info.title,
                    "artist": track_info.artist,
                    "album": track_info.album,
                    "trackid": track_info.trackid,
                    "duration": track_info.duration,
                    "image": track_info.image
                })
            }
        }        

        onTopTracksofArtist: {
            if (type === "tracklist") {
                listModel.append({
                    "title": track_info.title,
                    "artist": track_info.artist,
                    "album": track_info.album,
                    "trackid": track_info.trackid,
                    "duration": track_info.duration,
                    "image": track_info.image
                })
            }
        }
    }

    Connections {
        target: playlistManager
        onTrackInformation: {
            // For current playlist, this is handled by onListChanged -> refreshList() to avoid duplicates
            if (type !== "current") {
                listModel.append({
                    "title": title,
                    "artist": artist,
                    "album": album,
                    "trackid": id,
                    "duration": duration,
                    "image": image,
                    "index": index
                })
            }
        }

        onCurrentTrack: {
            // Avoid auto-scrolling while user is actively dragging/reordering
            if (type === "current") {
                if (dragActive) {
                    if (applicationWindow.settings.debugLevel >= 2) {
                        console.log("TRACKLIST: Skipping onCurrentTrack auto-scroll because drag is active")
                    }
                    return
                }
                tracks.positionViewAtIndex(position, ListView.Contain)
            }
        }

        onClearList: {
            console.log("Playlist must be cleared")
            if (type === "current") {
                listModel.clear()
            }
        }

        onListChanged: {
            console.log("update playlist")
            if (type === "current") {
                console.log("update current playlist")
                // Use refreshList() to maintain search/filter functionality
                refreshList()
            }
        }
    }
}
