import QtQuick 2.0
import Sailfish.Silica 1.0
import QtMultimedia 5.6
import Amber.Mpris 1.0

Item {
    id: mediaHandler

    // Media properties
    property string media_source
    property string track_id
    property string track_name
    property string album_name
    property string artist_name
    property string artwork_url
    property int track_duration

    property alias audio_player: audioPlayer
    property alias playlist: playlistItem
    
    // Playback state
    property bool player_available: playlistItem.itemCount > 0
    property double player_volume: 1.0
    property double track_volume: 1.0
    property bool blockAutoNext: false
    
    // Compatibility properties for existing code
    property alias position: audioPlayer.position
    property alias duration: audioPlayer.duration
    property alias volume: audioPlayer.volume
    property alias playbackState: audioPlayer.playbackState
    property alias status: audioPlayer.status
    property alias source: audioPlayer.source
    property bool isPlaying: audioPlayer.playbackState === Audio.PlayingState
    
    // Current track info (compatibility) - separate properties to avoid binding conflicts
    property string current_track_title: ""
    property string current_track_artist: ""
    property string current_track_album: ""
    property string current_track_image: ""
    property int current_track_duration: 0

    // Audio player with playlist support
    Audio {
        id: audioPlayer
        
        playlist: Playlist {
            id: playlistItem
            playbackMode: Playlist.Sequential

            onCurrentItemSourceChanged: {
                console.log('MediaHandler: Track changed to:', currentItemSource)
                media_source = currentItemSource || ""
                
                // Get track info from playlist manager
                if (playlistManager.currentIndex >= 0) {
                    var trackId = playlistManager.requestPlaylistItem(playlistManager.currentIndex)
                    var trackInfo = cacheManager.getTrackInfo(trackId)
                    if (trackInfo) {
                        track_id = trackId
                        track_name = trackInfo.title || ""
                        album_name = trackInfo.album || ""
                        artist_name = trackInfo.artist || ""
                        artwork_url = trackInfo.image || ""
                        track_duration = trackInfo.duration || 0
                    }
                }
            }

            onItemInserted: function(start_index, end_index) {
                console.log('MediaHandler: Items inserted:', start_index, '-', end_index)
            }

            onItemRemoved: function(start_index, end_index) {
                if (itemCount === 0) {
                    track_id = ""
                    track_name = ""
                    album_name = ""
                    artist_name = ""
                    artwork_url = ""
                    track_duration = 0
                }
            }
        }

        // Playback state handlers
        onPlaying: {
            mprisPlayer.playbackStatus = Mpris.Playing
        }

        onPaused: {
            mprisPlayer.playbackStatus = Mpris.Paused
        }

        onStopped: {
            mprisPlayer.playbackStatus = Mpris.Stopped
            
            // Auto-advance to next track unless blocked
            if (!blockAutoNext && playlistManager.canNext) {
                console.log("MediaHandler: Auto-advancing to next track")
                playlistManager.nextTrack()
            } else if (!blockAutoNext) {
                console.log("MediaHandler: Playlist finished")
                playlistManager.playlistFinished()
            }
        }

        onError: {
            console.error("MediaHandler: Playback error:", error, errorString)
            mprisPlayer.playbackStatus = Mpris.Stopped
        }

        onDurationChanged: {
            if (duration > 0) {
                track_duration = duration
            }
        }
    }

    // MPRIS integration using Amber.Mpris
    MprisPlayer {
        id: mprisPlayer

        serviceName: "tidalplayer"
        identity: "Tidal Music Player"
        supportedUriSchemes: ["http", "https"]
        supportedMimeTypes: ["audio/mpeg", "audio/flac", "audio/x-vorbis+ogg"]

        canControl: true
        canGoNext: playlistManager.canNext
        canGoPrevious: playlistManager.canPrev
        canPause: player_available
        canPlay: player_available
        canSeek: audioPlayer.seekable
        canQuit: false
        canRaise: true
        hasTrackList: true
        playbackStatus: Mpris.Stopped
        loopStatus: Mpris.LoopNone
        shuffle: false
        volume: player_volume

        // MPRIS control handlers
        onPauseRequested: {
            audioPlayer.pause()
        }

        onPlayRequested: {
            audioPlayer.play()
        }

        onPlayPauseRequested: {
            if (audioPlayer.playbackState === Audio.PlayingState) {
                audioPlayer.pause() 
            } else {
                audioPlayer.play()
            }
        }

        onStopRequested: {
            audioPlayer.stop()
        }

        onNextRequested: {
            console.log('MPRIS: Next requested')
            blockAutoNext = true
            playlistManager.nextTrackClicked()
        }

        onPreviousRequested: {
            console.log('MPRIS: Previous requested')
            playlistManager.previousTrackClicked()
        }

        onSeekRequested: {
            var newPos = audioPlayer.position + (offset / 1000000)  // Convert microseconds
            if (newPos >= 0 && newPos <= audioPlayer.duration) {
                audioPlayer.seek(newPos)
            }
        }

        onSetPositionRequested: {
            var seekPos = position / 1000000  // Convert microseconds to milliseconds
            if (seekPos >= 0 && seekPos <= audioPlayer.duration) {
                audioPlayer.seek(seekPos)
            }
        }
    }

    // Update MPRIS metadata when track properties change
    onTrack_nameChanged: {
        mprisPlayer.metaData.title = track_name
    }

    onAlbum_nameChanged: {
        mprisPlayer.metaData.albumTitle = album_name
    }

    onArtist_nameChanged: {
        mprisPlayer.metaData.contributingArtist = artist_name
    }

    onArtwork_urlChanged: {
        mprisPlayer.metaData.artUrl = artwork_url
    }

    onTrack_durationChanged: {
        if (track_duration > 0) {
            mprisPlayer.metaData.length = track_duration * 1000000  // Convert to microseconds
        }
    }

    onPlayer_volumeChanged: {
        audioPlayer.volume = player_volume * track_volume
    }

    onTrack_volumeChanged: {
        audioPlayer.volume = player_volume * track_volume
    }

    // Public API functions
    function play() {
        audioPlayer.play()
    }

    function pause() {
        audioPlayer.pause()
    }

    function stop() {
        audioPlayer.stop()
    }

    function seek(position) {
        if (audioPlayer.seekable) {
            audioPlayer.seek(position)
        }
    }

    function setSource(url) {
        console.log("MediaHandler: Setting source:", url)
        media_source = url
        // Clear playlist and add single item
        playlistItem.clear()
        if (url) {
            playlistItem.addItem(url)
        }
    }

    function playUrl(url) {
        console.log("MediaHandler: Playing URL:", url)
        blockAutoNext = true
        setSource(url)
        play()
        blockAutoNext = false
    }

    // Playlist management
    function clearPlaylist() {
        playlistItem.clear()
    }

    function addToPlaylist(url) {
        playlistItem.addItem(url)
    }

    function replacePlaylist(urls) {
        playlistItem.clear()
        for (var i = 0; i < urls.length; i++) {
            playlistItem.addItem(urls[i])
        }
    }

    // Helper functions
    function seconds_to_minutes_seconds(total_seconds) {
        if (isNaN(total_seconds)) return "00:00"
        var minutes = Math.floor(total_seconds / 60)
        var seconds = Math.floor(total_seconds % 60)
        return minutes + ":" + ("00" + seconds).slice(-2)
    }

    Component.onCompleted: {
        console.log("MediaHandler: Initialized with Amber.Mpris")
        
        // Set up property bindings after component creation to avoid conflicts
        current_track_title = Qt.binding(function() { return track_name })
        current_track_artist = Qt.binding(function() { return artist_name })
        current_track_album = Qt.binding(function() { return album_name })
        current_track_image = Qt.binding(function() { return artwork_url })
        current_track_duration = Qt.binding(function() { return track_duration })
    }
}