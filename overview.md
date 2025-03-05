# General
tidal.py is the python implementation
TidalApi.qml is the qml proxy, so to say. It uses pythonotherside to call methods in tidal.py and defines the handlers for python signals.
tidal.py sends signals via pythonotherside, TidalApi handles them and sends qt signals


# Class diagrams
the class diagrams are simplified. Tidal Service represents the Tidal service incl. python-tidal client.
TidalApi.qml is ignored.
Tidal represents class Tidal as defined in tidal.py 

```mermaid
classDiagram
    class Tidal {

        +playTrack(trackId: String): void
        +playAlbum(albumId: String, autoPlay: Boolean): void
        +playPlaylist(playlistId: String, autoPlay: Boolean): void
        +playPlayArtistTracks(playlistId: String, autoPlay: Boolean): void

        %% cache signals
        +signal cacheTrack(track_info)
        +signal cacheAlbum(album_info)
        +signal cacheArtist(artist_info)

        +signal filStarted()
        +signal fillFinished(autoplay)

        %% signals to indicate (turning wheels) a loading progress %%
        +signal loadingStarted()
        +signal loadingFinished()

        

        %% signals on add %%
        +signal playlistTrackAdded()
        +signal addTracktoPL()
        +signal albumTrackAdded()

        %% signals for artist page details %%
        +signal AlbumofArtist()
        +signal TopTrackofArtist()
        +signal SimilarArtist()

        %% personal page signals %%
        +signal FavAlbums()
        +signal FavTracks()
        +signal FavArtist()          

        %% Favorite Handling %%
        +setAlbumFavInfo(id: String, status Boolean)
        +setArtistFavInfo(id: String, status Boolean)
        +setPlaylistInfo(id: String, status Boolean)
        +setTrackFavInfo(id: String, status: Boolean)

        %% Signals %%
        +signal UpdateFavorite(id: String, status: Boolean)

        %% Common Signal %%
        +signal error(message: String)

    }

    class Album {
        +id: String
        +title: String
        +artist: Artist
        +tracks: List~Track~
    }

    class Artist {
        +id: String
        +name: String
        +albums: List~Album~
    }

    class Track {
        +id: String
        +title: String
        +artist: Artist
        +album: Album
    }

    class Playlist {
        +id: String
        +title: String
        +tracks: List~Track~
    }

    class Session {
    }

    class User {

    }


    Tidal --> Album
    Tidal --> Artist
    Tidal --> Track
    Tidal --> Playlist
    Album --> Artist
    Album --> Track
    Artist --> Album
    Track --> Artist
    Track --> Album
    Playlist --> Track
    Tidal --> Session
    Session --> User

```
# Sequence diagrams
Sequence diagrams are simplified. They do not show the pythonotherside layer with signal-handlers.

## playArtistTracks sequence diagram
id: artistID

autoPlay: start playing after load

applicable to:
- playAlbumTracks
- playAlbumfromTrack
- playArtistTracks

```mermaid
sequenceDiagram
    participant UI as QML UI
    participant Player as PlaylistPlayer
    participant Cache as TidalCache 
    participant API as Tidal
    participant Tidal as Tidal Service

    UI-)API: playArtistTracks(id, autoPlay)
    API->>Tidal: get_top_tracks()
    Tidal->>API: returning
    %%API->>UI: loadingStarted
    
    loop For each track
        API->>API: handleTrack(track)
        API->>Cache: cacheTrack(track_info)
        API->>Player: addTracktoPL(track_id)
    end
    
    API->>API: fillFinished(autoPlay)
    API->>Player: generateList()
    Note over API: If autoPlay true,<br/>starts playback
    alt (autoPlay)
    API->>Player: nextTrack()
    end

```
## playPlaylist sequence diagram
```mermaid
sequenceDiagram
    participant UI as QML UI
    participant Player as PlaylistPlayer
    participant Cache as TidalCache 
    participant API as Tidal
    participant Tidal as Tidal Service

    UI->>API: playPlaylist(playlistId)
    API->>UI: loadingStarted
    API->>Tidal: session.playlist(playlistId)
    
    loop For each track in playlist
        API->API: handleTrack(track)
        API->>Cache: cacheTrack(track_info)
        API->>Player: addTracktoPL(track_id)
    end
    
    API->>API: fillFinished(autoPlay)
    API->>Player: generateList()
    Note over API: If autoPlay true,<br/>starts playback
    alt (autoPlay)
    API->>Player: nextTrack()
    end
    API->>UI: loadingFinished

    Note over UI: Turning wheel goes away
```
https://sidharthv96.github.io/mermaid/syntax/sequenceDiagram.html