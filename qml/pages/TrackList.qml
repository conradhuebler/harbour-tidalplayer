import QtQuick 2.0
import Sailfish.Silica 1.0

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
    
    // Search state - Claude Generated
    property bool searchVisible: false
    property int filteredCount: 0
    
    // Auto-scroll to current track - Claude Generated
    onCurrentIndexChanged: {
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
            if (targetIndex >= 0 && targetIndex < listModel.count) {
                if (applicationWindow.settings.debugLevel >= 2) {
                    console.log("TRACKLIST: Smooth scrolling to track", targetIndex)
                }
                // Enable animation temporarily, then use positionViewAtIndex
                tracks.animateScrolling = true
                tracks.positionViewAtIndex(targetIndex, ListView.Center)
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
        listModel.clear()
        
        if (type === "current") {
            var searchText = ""
            var hasFilter = false
            
            // Check if search field exists and has content
            if (typeof searchField !== 'undefined' && searchField && searchField.visible) {
                searchText = searchField.text.toLowerCase()
                hasFilter = searchText.length > 0
                
                if (applicationWindow.settings.debugLevel >= 2) {
                    console.log("SEARCH: Field found - text:", searchField.text, "searchText:", searchText, "hasFilter:", hasFilter)
                }
            } else {
                if (applicationWindow.settings.debugLevel >= 2) {
                    console.log("SEARCH: Field not found or not visible - type:", type, "totalTracks:", root.totalTracks)
                }
            }
            
            if (applicationWindow.settings.debugLevel >= 1) {
                console.log("TRACKLIST: Filtering with search:", searchText, "hasFilter:", hasFilter, "playlistSize:", playlistManager.size)
            }
            
            var filteredCount = 0
            for (var i = 0; i < playlistManager.size; ++i) {
                var id = playlistManager.requestPlaylistItem(i)
                var track = cacheManager.getTrackInfo(id)
                
                if (track) {
                    var matchesFilter = !hasFilter || 
                        track.title.toLowerCase().indexOf(searchText) >= 0 ||
                        track.artist.toLowerCase().indexOf(searchText) >= 0 ||
                        track.album.toLowerCase().indexOf(searchText) >= 0
                    
                    if (matchesFilter) {
                        listModel.append({
                            "title": track.title,
                            "artist": track.artist,
                            "album": track.album,
                            "id": track.id,
                            "trackid": track.id,
                            "duration": track.duration,
                            "image": track.image,
                            "index": i  // Keep original index for playback
                        })
                        filteredCount++
                    } else if (applicationWindow.settings.debugLevel >= 2) {
                        console.log("SEARCH: Filtered out:", track.title, "by", track.artist)
                    }
                }
            }
            
            root.filteredCount = filteredCount
            
            if (applicationWindow.settings.debugLevel >= 1) {
                console.log("TRACKLIST: Filter result:", filteredCount, "of", playlistManager.size, "tracks shown")
            }
        } else {
            // Original logic for non-current playlists
            updateTimer.start()
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

    SilicaListView {
        id: tracks
        anchors.fill: parent
        // highlightFollowsCurrentItem: true //introduced by Pawel for removing of tracks

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
        
        header: PageHeader {
            title: root.title
        }
        height: parent.height
        contentHeight: height
        clip: true  // Verhindert Überläufe

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

        delegate: ListItem {
            id: listEntry
            width: parent.width
            contentHeight: isItemSelected(model.index) ? root.selectedItemHeight : root.normalItemHeight
            highlighted: isItemSelected(model.index)

            Rectangle {
                visible: listEntry.highlighted
                anchors.fill: parent
                color: Theme.rgba(Theme.highlightBackgroundColor, highlightOpacity)
                z: -1
            }

            Row {
                id: contentRow
                anchors {
                    left: parent.left
                    right: parent.right
                    margins: Theme.horizontalPageMargin
                    verticalCenter: parent.verticalCenter
                }
                spacing: Theme.paddingMedium

                Label {
                    visible: listEntry.highlighted
                    text: "▶"
                    color: selectedTextColor
                    font.pixelSize: root.selectedFontSize
                    width: visible ? implicitWidth : 0
                    verticalAlignment: Text.AlignVCenter
                    height: coverImage.height
                }

                Image {
                    id: coverImage
                    width: listEntry.highlighted ? Theme.itemSizeLarge : Theme.itemSizeMedium
                    height: width
                    fillMode: Image.PreserveAspectCrop
                    source: model.image || ""
                    asynchronous: true
                    
                    Behavior on width { NumberAnimation { duration: 150 } }
                }

                Column {
                    width: parent.width - coverImage.width - parent.spacing
                    spacing: listEntry.highlighted ? Theme.paddingMedium : Theme.paddingSmall

                    Label {
                        width: parent.width
                        text: model.title
                        color: listEntry.highlighted ? selectedTextColor : normalTextColor
                        font.pixelSize: listEntry.highlighted ? root.selectedFontSize : root.normalFontSize
                        font.bold: listEntry.highlighted
                        truncationMode: TruncationMode.Elide
                    }

                    Row {
                        width: parent.width
                        spacing: Theme.paddingSmall

                        Label {
                            text: model.artist
                            color: listEntry.highlighted ? selectedSecondaryColor : normalSecondaryColor
                            font.pixelSize: listEntry.highlighted ? root.normalFontSize : Theme.fontSizeSmall
                            font.bold: listEntry.highlighted
                        }

                        Label {
                            text: " • "
                            color: listEntry.highlighted ? selectedSecondaryColor : normalSecondaryColor
                            font.pixelSize: listEntry.highlighted ? root.normalFontSize : Theme.fontSizeSmall
                        }

                        Label {
                            property string dur: (model.duration > 3599)
                                ? Format.formatDuration(model.duration, Formatter.DurationLong)
                                : Format.formatDuration(model.duration, Formatter.DurationShort)
                            text: dur
                            color: listEntry.highlighted ? selectedSecondaryColor : normalSecondaryColor
                            font.pixelSize: listEntry.highlighted ? root.normalFontSize : Theme.fontSizeSmall
                        }
                    }
                }
            }

            onClicked: {
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
        anchors.margins: Theme.paddingLarge
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
            if (type === "current") {
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
