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
        anchors.bottomMargin: miniPlayerPanel.height * 0.4
        // highlightFollowsCurrentItem: true //introduced by Pawel for removing of tracks

        // Add smooth scrolling properties
        highlightRangeMode: ListView.ApplyRange
        highlightMoveDuration: 1000  // Duration of the scroll animation in milliseconds
        highlightMoveVelocity: -1   // -1 means use duration instead of velocity
        preferredHighlightBegin: height * 0.1
        preferredHighlightEnd: height * 0.9
        
        header: PageHeader {
            title: root.title
        }
        height: parent.height - minPlayerPanel.margin
        contentHeight: parent.height - minPlayerPanel.margin
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
                if (type === "current") {
                    playlistManager.playPosition(Math.floor(model.index))  // Stelle sicher, dass es ein Integer ist
                } else {
                    playlistManager.playTrack(model.trackid)
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
            if (type === "current") {
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
                listModel.clear()
                updateTimer.start()
            }
        }
    }
}
