import QtQuick 2.0
import io.thp.pyotherside 1.5


Item {
    id: root

    Timer {
        id: updateTimer
        interval: 1000  // 100ms Verzögerung
        repeat: false
        onTriggered: {

                //playlistStorage.loadCurrentPlaylistState()
        }
    }
    property var favoritesCache: ({})  // Object to store id -> boolean mappings

    signal updateFavorite(var id, var status)  // signal that an fav status was updated

    Python {
        id: favoritesPython


        property bool initialised : false

        Component.onCompleted: {

            addImportPath(Qt.resolvedUrl('.'))
        
            // Response Loading finished
            setHandler('updateFavorite', function(id,status) {
                addFavoriteInfo(id, status)
                root.updateFavorite(id, status)
            })

            initialised = true;
        }

        // Python-Funktionen
 
        function setArtistFavoriteInfo(id, status) {
            console.log("setArtistFavoriteInfo", id, status)
            if(initialised)  call('tidal.Tidaler.setArtistFavInfo', [id, status], {})
        }

        function setAlbumFavoriteInfo(id, status) {
           if(initialised)  call('tidal.Tidaler.setAlbumFavInfo', [id, status], {})
        }

        function setTrackFavoriteInfo(id, status) {
           if(initialised)  call('tidal.Tidaler.setTrackFavInfo', [id, status], {})
        }

        function setPlaylistFavoriteInfo(id, status) {
           if(initialised)  call('tidal.Tidaler.setPlaylistFavInfo', [id, status], {})
        }

    }


    // public function to check if item is favorite
    function isFavorite(id) {
        console.log("isFavorite check for:", id)
        if (id in favoritesCache) {
            console.log("Cache hit for:", id, "Status:", favoritesCache[id])
            return favoritesCache[id]
        }
        // Not in cache, need to load from Tidal
        // I doubt i need this, as all changes in the session
        // can be managed by favoritesManager
        // favoritesPython.isFavorite(id)
        return false  // Return false while loading
    }

    function setArtistFavoriteInfo(id, status) {
        console.log("setArtistFavoriteInfo", id, status)
        favoritesPython.setArtistFavoriteInfo(id, status)
    }

    function setAlbumFavoriteInfo(id, status) {
        console.log("setAlbumFavoriteInfo", id, status)
        favoritesPython.setAlbumFavoriteInfo(id, status)
    }

    function setTrackFavoriteInfo(id, status) {
        console.log("setTrackFavoriteInfo", id, status)
        favoritesPython.setTrackFavoriteInfo(id, status)
    }

    function setPlaylistFavoriteInfo(id, status) {
        console.log("setPlaylistFavoriteInfo", id, status)
        // this should happen only on success !!
        // favoritesCache[id] = status
        favoritesPython.setPlaylistFavoriteInfo(id, status)
    }

    // internal function to add favorite
    function addFavorite(id) {
        favoritesCache[id] = true
    }

    // internal function to add favorite
    function addFavoriteInfo(id, status) {
        favoritesCache[id] = status
    }

    Connections {
        target: tidalApi
        onFavArtists: {
            if (artist_info == undefined) {
                 console.error("artist_info is undefined. skip append to model")
                 return;
            }
            addFavorite(artist_info.artistid)
        }
        onFavAlbums: {
            if (album_info == undefined) {
                 console.error("album_info is undefined. skip append to model")
                 return;
            }            
            addFavorite(album_info.albumid)
        }
        onFavTracks: {
            if (track_info == undefined) {
                 console.error("track_info is undefined. skip append to model")
                 return;
            }            
            addFavorite(track_info.trackid)
        }
    }

}
