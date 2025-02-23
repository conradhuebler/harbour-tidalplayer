# This Python file uses the following encoding: utf-8

import sys
sys.path.append('/usr/share/harbour-tidalplayer/python/')

import socket
import requests
import json
import tidalapi
import pyotherside

from tidalapi.page import PageItem, PageLink
from tidalapi.mix import Mix

from requests.exceptions import HTTPError


class Tidal:
    def __init__(self):
        self.session = None
        self.config = None
        self.top_tracks = 20
        self.album_search = 20
        self.track_search = 20
        self.artist_search = 20

        pyotherside.send('loadingStarted')

    def initialize(self, quality="HIGH"):
        pyotherside.send("printConsole", "Initialise tidal api")

        if quality == "LOW":
            selected_quality = tidalapi.Quality.low
        elif quality == "HIGH":
            selected_quality = tidalapi.Quality.high
        elif quality == "LOSSLESS":
            selected_quality = tidalapi.Quality.lossless
        else:
            # Fallback auf HIGH wenn unbekannte Qualität
            selected_quality = tidalapi.Quality.high

        self.config = tidalapi.Config(quality=selected_quality, video_quality=tidalapi.VideoQuality.low)
        self.session = tidalapi.Session(self.config)

    def setconfig(self, top_tracks, album_search, track_search, artist_search):
        self.top_tracks = top_tracks
        self.album_search = album_search
        self.track_search = track_search
        self.artist_search = artist_search

    def login(self, token_type, access_token, refresh_token, expiry_time):
        if access_token == token_type:
            pyotherside.send("oauth_login_failed")
        else:
            if access_token == refresh_token:
                pyotherside.send("printConsole", "Getting new token")
                self.session.token_refresh(refresh_token)
                self.session.load_oauth_session(token_type, self.session.access_token)

                if self.session.check_login() == True:
                    pyotherside.send("printConsole", "New token", self.session.access_token)
                    pyotherside.send("oauth_refresh", self.session.access_token)
                    pyotherside.send("oauth_login_success")
                    pyotherside.send("printConsole", "Login success")

            else:
                pyotherside.send("printConsole", "Login with old token")
                self.session.load_oauth_session(token_type, access_token)
                if self.session.check_login() == True:
                    pyotherside.send("oauth_login_success")
                    pyotherside.send("printConsole", "Login success")



    def request_oauth(self):
        pyotherside.send("printConsole", "Start new session")
        self.login, self.future = self.session.login_oauth()
        pyotherside.send("printConsole", "getting url")

        pyotherside.send("get_url", self.login.verification_uri_complete)
        pyotherside.send("printConsole", "waiting for done")

        self.future.result()
        pyotherside.send("printConsole", "Done", self.session.token_type, self.session.access_token)

        if self.session.check_login() == True:
            pyotherside.send("get_token", self.session.token_type, self.session.access_token, self.session.refresh_token,  self.session.expiry_time)
        else:
            pyotherside.send("oauth_failed")

        pyotherside.send('loadingFinished')

    def handle_track(self, track):
        try:
            return {
                "trackid": str(track.id),
                "title": str(track.name),
                "artist": str(track.artist.name),
                "artistid": str(track.artist.id),
                "album": str(track.album.name),
                "albumid": int(track.album.id),
                "duration": int(track.duration),
                "image": track.album.image(320) if hasattr(track.album, 'image') else "",
                "track_num" : track.track_num,
                "type": "track",
                "albumid": track.album.id
            }
        except AttributeError as e:
            print(f"Error handling track: {e}")
            return None

    def handle_artist(self, artist):
        try:
            return {
                "artistid": str(artist.id),
                "name": str(artist.name),
                "image": artist.image(320) if hasattr(artist, 'image') else "",
                "type": "artist",
                "bio" : str(artist.get_bio())
            }
        except AttributeError as e:
            print(f"Error handling artist: {e}")
            return None

        except HTTPError as e:
            if e.response.status_code == 404:
                return {
                    "artistid": str(artist.id),
                    "name": str(artist.name),
                    "image": artist.image(320) if hasattr(artist, 'image') else "",
                    "type": "artist",
                    "bio" : ""
                }
            else:
                return f"Error fetching biography: {str(e)}"

    def handle_album(self, album):
        try:
            return {
                "albumid": int(album.id),
                "title": str(album.name),
                "artist": str(album.artist.name),
                "artistid" : str(album.artist.id),
                "image": album.image(320) if hasattr(album, 'image') else "",
                "duration": int(album.duration) if hasattr(album, 'duration') else 0,
                "num_tracks": int(album.num_tracks),
                "year": int(album.year),
                "type": "album"
            }
        except AttributeError as e:
            print(f"Error handling album: {e}")
            return None

    def handle_video(self, video):
        try:
            return {
                "videoid": str(video.id),
                "title": str(video.name),
                "artist": str(video.artist.name),
                "artistid": str(video.artist.id),
                "album": str(video.album.name),
                "albumid": int(video.album.id),
                "duration": int(video.duration),
                "image": video.album.image(320) if hasattr(video.album, 'image') else "",
                "track_num" : video.track_num,
                "type": "video",
                "albumid": video.album.id
            }
        except AttributeError as e:
            print(f"Error handling video: {e}")
            return None

    def send_object(self, signal_name, data):
        """Helper-Funktion zum Senden von Objekten"""
        try:
            pyotherside.send(signal_name, data)
        except Exception as e:
            print(f"Error sending object: {e}")

    def handle_playlist(self, playlist):
        """Handler für Playlist-Informationen"""
        try:
            return {
                "playlistid": str(playlist.id),
                "title": str(playlist.name),
                "image": playlist.image(320) if hasattr(playlist, 'image') else "",
                "duration": int(playlist.duration) if hasattr(playlist, 'duration') else 0,
                "num_tracks": playlist.num_tracks if hasattr(playlist, 'num_tracks') else 0,
                "description": playlist.description if hasattr(playlist, 'description') else "",
                "type": "playlist"
            }
        except AttributeError as e:
            print(f"Error handling playlist: {e}")
            return None

    def genericSearch(self, text):
        pyotherside.send('loadingStarted')
        result = self.session.search(text)

        # Tracks verarbeiten
        for track in result["tracks"]:
            if track_info := self.handle_track(track):
                #search_results["tracks"].append(track_info)
                self.send_object("cacheTrack", track_info)
                self.send_object("foundTrack", track_info)

        # Artists verarbeiten
        for artist in result["artists"]:
            if artist_info := self.handle_artist(artist):
                #search_results["artists"].append(artist_info)
                self.send_object("cacheArtist", artist_info)
                self.send_object("foundArtist", artist_info)

        # Albums verarbeiten
        for album in result["albums"]:
            if album_info := self.handle_album(album):
                #search_results["albums"].append(album_info)
                self.send_object("cacheAlbum", album_info)
                self.send_object("foundAlbum", album_info)

        # Playlists verarbeiten
        for playlist in result["playlists"]:
            if playlist_info := self.handle_playlist(playlist):
                #search_results["playlists"].append(playlist_info)
                self.send_object("foundPlaylist", playlist_info)

        for video in result["videos"]:
            if video_info := self.handle_video(video):
                #search_results["videos"].append(video_info)
                self.send_object("foundVideo", video_info)

        # Gesamtergebnis senden
        #self.send_object("search_results", search_results)
        pyotherside.send('loadingFinished')

    def getAlbumInfo(self, id):
        try:
            album = self.session.album(int(id))
            album_info = self.handle_album(album)
            if album_info:
                self.send_object("cacheAlbum", album_info)
                return album_info
            return None
        except Exception as e:
            self.send_object("error", {"message": str(e)})
            return None

    def getArtistInfo(self, id):
        try:
            artist = self.session.artist(int(id))
            artist_info = self.handle_artist(artist)
            if artist_info:
                self.send_object("cacheArtist", artist_info)
                return artist_info
            return None
        except Exception as e:
            self.send_object("error", {"message": str(e)})
            return None

    def getTrackInfo(self, id):
        try:
            track = self.session.track(int(id))
            track_info = self.handle_track(track)
            if track_info:
                self.send_object("cacheTrack", track_info)
                return track_info
            return None
        except Exception as e:
            self.send_object("error", {"message": str(e)})
            return None

    def getTrackUrl(self, id):
        try:
            track = self.session.track(int(id))
            url = track.get_url()
            track_info = self.handle_track(track)

            if track_info and url:
                self.send_object("playback_info", {
                    "track": track_info,
                    "url": url
                })
                return track_info
            return None
        except Exception as e:
            self.send_object("error", {"message": str(e)})
        return None

#  not sure if this method is used at all
    def playPlaylist(self, id):
        try:
            playlist = self.session.playlist(id)
            playlist_info = self.handle_playlist(playlist)

            if playlist_info:
                tracks = []
                for track in playlist.tracks():
                    if track_info := self.handle_track(track):
                        tracks.append(track_info)

                self.send_object("playlist_replace", {
                    "playlist": playlist_info,
                    "tracks": tracks
                })

                # Ersten Track zur Wiedergabe markieren
                if tracks:
                    self.send_object("play_track", tracks[0])

                return playlist_info
        except Exception as e:
            self.send_object("error", {"message": str(e)})
            return None

    def getAlbumTracks(self, id):
        album = self.session.album(int(id))
        for track in album.tracks():
            track_info = self.handle_track(track)
            if track_info:
                pyotherside.send("cacheTrack", track_info)
                pyotherside.send("albumTrackAdded",track_info)

    def playAlbumTracks(self, id, autoPlay=False):
        album = self.session.album(int(id))
        for track in album.tracks():
            track_info = self.handle_track(track)
            if track_info:
                pyotherside.send("cacheTrack", track_info)
                pyotherside.send("addTracktoPL", track_info['trackid'])
        pyotherside.send("fillFinished", autoPlay)

    def playAlbumfromTrack(self, id):
        for track in self.session.track(int(id)).album.tracks():
            track_info = self.handle_track(track)
            if track_info:
                pyotherside.send("cacheTrack", track_info)
                pyotherside.send("addTracktoPL", track_info['trackid'])
        pyotherside.send("fillFinished")

    def getTopTracks(self, id, max):
        toptracks = self.session.artist(int(id)).get_top_tracks(max)
        for track in toptracks:
            track_info = self.handle_track(track)
            if track_info:
                pyotherside.send("cacheTrack", track_info)
                pyotherside.send("addTrack",
                    track_info['trackid'],
                    track_info['title'],
                    track_info['album'],
                    track_info['artist'],
                    track_info['image'],
                    track_info['duration'])

    def getPersonalPlaylists(self):
        pyotherside.send('loadingStarted')
        playlists = self.session.user.playlists()
        for i in playlists:
            try:
                pyotherside.send("addPersonalPlaylist", i.id, i.name, i.image(320), i.num_tracks, i.description, i.duration)
            except AttributeError:
                pyotherside.send("addPersonalPlaylist", i.id, i.name, "", i.num_tracks, i.description, i.duration)

        pyotherside.send('loadingFinished')

    def getPersonalPlaylist(self, id):
        pyotherside.send('loadingStarted')
        playlist = self.session.playlist(int(id))
        try:
            pyotherside.send("setPlaylist", i.id, i.name, i.image(320), i.num_tracks, i.description, i.duration)
        except AttributeError:
            pyotherside.send("setPlaylist", i.id, i.name, "", i.num_tracks, i.description, i.duration)

        for ti in playlist.tracks():
            i = self.handle_track(ti)
            pyotherside.send("cacheTrack", i)
            #pyotherside.send("cacheTrack", i.id, i.name, i.album.name, i.artist.name, i.album, i.duration)
        pyotherside.send('loadingFinished')

    def playPlaylist(self, id, autoPlay=False):
        pyotherside.send('loadingStarted')
        playlist = self.session.playlist(id)
        first_track = playlist.tracks()[0]
        #pyotherside.send("insertTrack", first_track.id)
        pyotherside.send("printConsole", f" insert Track: {first_track.id}")

        for i, track in enumerate(playlist.tracks()):
            track_info = self.handle_track(track)
            if track_info:
                pyotherside.send("cacheTrack", track_info)
                pyotherside.send("addTracktoPL", track_info['trackid']) #maybe silent ?

            #if i == 0:
        
        # playlist = self.session.playlist(id)
        #playlist_info = self.handle_playlist(playlist)    
        # #    pyotherside.send("fillStarted")

        pyotherside.send("fillFinished", autoPlay)
        pyotherside.send('loadingFinished')
        #return playlist_info

    def getPlaylistTracks(self, playlist_id):
        pyotherside.send('loadingStarted')
        try:
            playlist = self.session.playlist(playlist_id)

            for ti in playlist.tracks():
                i = self.handle_track(ti)
                pyotherside.send("cacheTrack", i)
                pyotherside.send('playlistTrackAdded',i)
        finally:
            pyotherside.send('loadingFinished')

    def getAlbumsofArtist(self, id):
        pyotherside.send('loadingStarted')
        albums = self.session.artist(int(id)).get_albums()
        for ti in albums:
            i = self.handle_album(ti)
            pyotherside.send("cacheAlbum", i)
            pyotherside.send("AlbumofArtist", i)

        pyotherside.send('loadingFinished')

    def getTopTracksofArtist(self, id):
        pyotherside.send('loadingStarted')
        tracks = self.session.artist(int(id)).get_top_tracks(self.top_tracks)
        for ti in tracks:
            i = self.handle_track(ti)
            pyotherside.send("cacheTrack", i)
            pyotherside.send("TopTrackofArtist", i)

        pyotherside.send('loadingFinished')

    def getSimiliarArtist(self, id):
        pyotherside.send('loadingStarted')
        try:
            artists = self.session.artist(int(id)).get_similar()
            if artists:  # Wenn Artists zurückgegeben wurden
                for ti in artists:
                    i = self.handle_artist(ti)
                    #pyotherside.send("cacheArtist", i)
                    pyotherside.send("SimilarArtist", i)
            else:
                pyotherside.send("noSimilarArtists")  # Signal wenn keine ähnlichen Künstler gefunden
        except requests.exceptions.HTTPError as e:
            if e.response.status_code == 404:
                print(f"Keine ähnlichen Künstler gefunden für ID: {id}")
                pyotherside.send("noSimilarArtists")
            else:
                print(f"HTTP Fehler beim Abrufen ähnlicher Künstler: {e}")
                pyotherside.send("apiError", str(e))
        except Exception as e:
            print(f"Allgemeiner Fehler beim Abrufen ähnlicher Künstler: {e}")
            pyotherside.send("apiError", str(e))
        finally:
            pyotherside.send('loadingFinished')

    def getFavorits(self, id):
        pyotherside.send('loadingStarted')
        albums = self.session.user.favorites.albums()
        for ti in albums:
            i = self.handle_album(ti)
            pyotherside.send("cacheAlbum", i)
            pyotherside.send("FavAlbums", i)

        tracks = self.session.user.favorites.tracks()
        for ti in tracks:
            i = self.handle_track(ti)
            pyotherside.send("cacheTrack", i)
            pyotherside.send("FavTracks", i)

        artists = self.session.user.favorites.artists()
        for ti in artists:
            i = self.handle_artist(ti)
            pyotherside.send("cacheArtist", i)
            pyotherside.send("FavArtist", i)

        pyotherside.send('loadingFinished')

    def homepage(self):
        self.home = self.session.home()
        self.home.categories.extend(self.session.explore().categories)
        self.home.categories.extend(self.session.videos().categories)

        for category in self.home.categories:
            print(category.title)

        for category in self.home.categories:
            print(category.title)
            self.items = []
            for item in category.items:
                if isinstance(item, PageItem):
                    self.items.append("\t" + item.short_header)
                    self.items.append("\t" + item.short_sub_header[0:50])
                    # Call item.get() on this one, for example on click
                elif isinstance(item, PageLink):
                    self.items.append("\t" + item.title)
                    # Call item.get() on this one, for example on click
                elif isinstance(item, Mix):
                    self.items.append("\t" + item.title)
                    # You can optionally call item.get() to request the items() first, but it does it for you if you don't
                else:
                    self.items.append("\t" + item.name)
                    # An album could be handled by session.album(item.id) for example,
                    # to get full details. Usually the relevant info is there already however
                print()
            #[print(x) for x in sorted(items)]

    def getUser(self):
        return self.session.get_user(self.session.user.id)
    
    def setAlbumFavInfo(self,id,status):
        result = False
        if status:
            result = self.getUser().favorites.add_album(id)
        else:
            result = self.getUser().favorites.remove_album(id)
        if result:
            pyotherside.send('updateFavorite', id, status)
    
    def setArtistFavInfo(self,id,status):
        user = self.session.get_user(self.session.user.id)
        result = False
        if status:
            result = user.favorites.add_artist(id)
        else:
            result = user.favorites.remove_artist(id)
        if result:
            pyotherside.send('updateFavorite', id, status)

    def setTrackFavInfo(self,id,status):
        result = False
        if status:
            result = self.getUser().favorites.add_track(id)
        else:
            result = self.getUser().favorites.remove_track(id)
        if result:
            pyotherside.send('updateFavorite', id, status)

    def setPlaylistFavInfo(self,id,status):
        result = False
        if status:
            result = self.getUser().favorites.add_playlist(id)
        else:
            result = self.getUser().favorites.remove_playlist(id)
        if result:
            pyotherside.send('updateFavorite', id, status)

Tidaler = Tidal()
