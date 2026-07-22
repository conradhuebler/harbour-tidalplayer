import QtQuick 2.0

// Session cache of favorite states. All Python communication goes through
// the single TidalApi bridge (updateFavorite handler + setXFavorite calls);
// the former dedicated Python instance here is gone. - Claude Generated
Item {
    id: root

    property var favoritesCache: ({})  // Object to store id -> boolean mappings

    signal updateFavorite(var id, var status)  // signal that a fav status was updated

    // public function to check if item is favorite
    function isFavorite(id) {
        if (id in favoritesCache) {
            if (applicationWindow.settings && applicationWindow.settings.debugLevel >= 2)
                console.log("FavoritesManager: cache hit for", id, "status:", favoritesCache[id])
            return favoritesCache[id]
        }
        return false
    }

    function setArtistFavoriteInfo(id, status) {
        if (applicationWindow.settings && applicationWindow.settings.debugLevel >= 1)
            console.log("setArtistFavoriteInfo", id, status)
        tidalApi.setArtistFavorite(id, status)
    }

    function setAlbumFavoriteInfo(id, status) {
        if (applicationWindow.settings && applicationWindow.settings.debugLevel >= 1)
            console.log("setAlbumFavoriteInfo", id, status)
        tidalApi.setAlbumFavorite(id, status)
    }

    function setTrackFavoriteInfo(id, status) {
        if (applicationWindow.settings && applicationWindow.settings.debugLevel >= 1)
            console.log("setTrackFavoriteInfo", id, status)
        tidalApi.setTrackFavorite(id, status)
    }

    function setPlaylistFavoriteInfo(id, status) {
        if (applicationWindow.settings && applicationWindow.settings.debugLevel >= 1)
            console.log("setPlaylistFavoriteInfo", id, status)
        tidalApi.setPlaylistFavorite(id, status)
    }

    // internal function to add favorite
    function addFavorite(id) {
        favoritesCache[id] = true
    }

    // internal function to store a favorite status (signal emission is done
    // by the updateFavorite handler in TidalApi)
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
