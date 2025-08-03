// Zeige nur die geänderten Handler für TidalApi.qml
// Diese Handler müssen in der bestehenden TidalApi.qml ersetzt werden

            // UPDATED: Direkte QML Playlist Integration ohne Python
            setHandler('fillStarted', function() {
                // In QML Implementation: start playing next track immediately
                if (playlistManager.size > 0) {
                    playlistManager.nextTrack()
                }
            })

            // UPDATED: Direkte QML Playlist Integration 
            setHandler('fillFinished', function(autoPlay) {
                var auto = false
                if (autoPlay !== undefined) auto = autoPlay
                
                // Generate list display
                playlistManager.generateList()
                
                // Auto-play if requested
                if (auto && playlistManager.size > 0) {
                    playlistManager.nextTrack()
                }
            })

            // UPDATED: Direkte QML Playlist Integration
            setHandler('addTracktoPL', function(id) {
                console.log("appended to PL", id)
                playlistManager.appendTrack(id)
            })

            // OPTIONAL: Add new handlers for more granular control
            setHandler('addTrackToPLSilent', function(id) {
                console.log("appended to PL (silent)", id)
                playlistManager.appendTrackSilent(id)
            })

            setHandler('insertTrackToPL', function(id) {
                console.log("inserted to PL", id)
                playlistManager.insertTrack(id)
            })

            setHandler('removeTrackFromPL', function(id) {
                console.log("removed from PL", id)
                playlistManager.removeTrack(id)
            })

            setHandler('clearPlaylist', function() {
                console.log("clearing playlist")
                playlistManager.clearPlayList()
            })