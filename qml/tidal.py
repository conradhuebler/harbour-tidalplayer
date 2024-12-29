# This Python file uses the following encoding: utf-8

import sys
sys.path.append('/usr/share/harbour-tidalplayer/python/')

import socket
import requests
import json
import tidalapi
import pyotherside

class Tidal:
    def __init__(self):
        self.session = None
        self.config = None

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

    def login(self, token_type, access_token, refresh_token, expiry_time):
        if access_token == token_type:
            pyotherside.send("oauth_login_failed")
        else:
            self.session.load_oauth_session(token_type, access_token)
            if self.session.check_login() == True:
                pyotherside.send("oauth_login_success")
            if access_token == refresh_token:
                self.session.load_oauth_session(token_type, refresh_token)
                pyotherside.send("oauth_updated", self.session.token_type, self.session.access_token, self.session.refresh_token,  self.session.expiry_time)

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

    def handle_track(self, track):
        try:
            return {
                "id": str(track.id),
                "title": str(track.name),
                "artist": str(track.artist.name),
                "album": str(track.album.name),
                "duration": int(track.duration),
                "image": track.album.image(320) if hasattr(track.album, 'image') else "",
                "track_num" : track.track_num,
                "type": "track"
            }
        except AttributeError as e:
            print(f"Error handling track: {e}")
            return None

    def handle_artist(self, artist):
        try:
            return {
                "id": str(artist.id),
                "name": str(artist.name),
                "image": artist.image(320) if hasattr(artist, 'image') else "",
                "type": "artist"
            }
        except AttributeError as e:
            print(f"Error handling artist: {e}")
            return None

    def handle_album(self, album):
        try:
            return {
                "id": str(album.id),
                "title": str(album.name),
                "artist": str(album.artist.name),
                "image": album.image(320) if hasattr(album, 'image') else "",
                "duration": int(album.duration) if hasattr(album, 'duration') else 0,
                "type": "album"
            }
        except AttributeError as e:
            print(f"Error handling album: {e}")
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
                "id": str(playlist.id),
                "name": str(playlist.name),
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
        result = self.session.search(text)
        search_results = {
            "tracks": [],
            "artists": [],
            "albums": [],
            "playlists": []
        }

        # Tracks verarbeiten
        for track in result["tracks"]:
            if track_info := self.handle_track(track):
                search_results["tracks"].append(track_info)
                self.send_object("cacheTrack", track_info)

        # Artists verarbeiten
        for artist in result["artists"]:
            if artist_info := self.handle_artist(artist):
                search_results["artists"].append(artist_info)
                self.send_object("artist_data", artist_info)

        # Albums verarbeiten
        for album in result["albums"]:
            if album_info := self.handle_album(album):
                search_results["albums"].append(album_info)
                self.send_object("album_data", album_info)

        # Playlists verarbeiten
        for playlist in result["playlists"]:
            if playlist_info := self.handle_playlist(playlist):
                search_results["playlists"].append(playlist_info)
                self.send_object("playlist_data", playlist_info)

        # Gesamtergebnis senden
        self.send_object("search_results", search_results)

    def getAlbumInfo(self, id):
        try:
            album = self.session.album(int(id))
            album_info = self.handle_album(album)
            if album_info:
                self.send_object("album_data", album_info)

                # Album tracks auch gleich mitschicken
                tracks = []
                for track in album.tracks():
                    if track_info := self.handle_track(track):
                        tracks.append(track_info)

                self.send_object("album_tracks", {
                    "album_id": id,
                    "tracks": tracks
                })

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
                self.send_object("artist_data", artist_info)

                # Top Tracks gleich mitschicken
                top_tracks = []
                for track in artist.get_top_tracks(20):
                    if track_info := self.handle_track(track):
                        top_tracks.append(track_info)

                self.send_object("artist_top_tracks", {
                    "artist_id": id,
                    "tracks": top_tracks
                })

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


    def playAlbumTracks(self, id):
        album = self.session.album(int(id))
        for track in album.tracks():
            track_info = self.handle_track(track)
            if track_info:
                pyotherside.send("cacheTrack", track_info)
                pyotherside.send("addTracktoPL", track_info['id'])
        pyotherside.send("fillFinished")

    def playAlbumfromTrack(self, id):
        for track in self.session.track(int(id)).album.tracks():
            track_info = self.handle_track(track)
            if track_info:
                pyotherside.send("cacheTrack", track_info)
                pyotherside.send("addTracktoPL", track_info['id'])
        pyotherside.send("fillFinished")

    def getTopTracks(self, id, max):
        toptracks = self.session.artist(int(id)).get_top_tracks(max)
        for track in toptracks:
            track_info = self.handle_track(track)
            if track_info:
                pyotherside.send("cacheTrack", track_info)
                pyotherside.send("addTrack",
                    track_info['id'],
                    track_info['title'],
                    track_info['album'],
                    track_info['artist'],
                    track_info['image'],
                    track_info['duration'])

    def getPersonalPlaylists(self):
        playlists = self.session.user.playlists()
        for i in playlists:
            try:
                pyotherside.send("addPersonalPlaylist", i.id, i.name, i.image(320), i.num_tracks, i.description, i.duration)
            except AttributeError:
                pyotherside.send("addPersonalPlaylist", i.id, i.name, "", i.num_tracks, i.description, i.duration)

    def getPersonalPlaylist(self, id):
        playlist = self.session.playlist(int(id))
        try:
            pyotherside.send("setPlaylist", i.id, i.name, i.image(320), i.num_tracks, i.description, i.duration)
        except AttributeError:
            pyotherside.send("setPlaylist", i.id, i.name, "", i.num_tracks, i.description, i.duration)

        for ti in playlist.tracks():
            i = self.handle_track(ti)
            pyotherside.send("cacheTrack", i)
            #pyotherside.send("cacheTrack", i.id, i.name, i.album.name, i.artist.name, i.album, i.duration)

    def playPlaylist(self, id):
        playlist = self.session.playlist(id)
        first_track = playlist.tracks()[0]
        pyotherside.send("insertTrack", first_track.id)
        pyotherside.send("printConsole", f" insert Track: {first_track.id}")

        for i, track in enumerate(playlist.tracks()):
            track_info = self.handle_track(track)
            if track_info:
                pyotherside.send("cacheTrack", track_info)
                pyotherside.send("addTracktoPL", track_info['id'])

            if i == 0:
                pyotherside.send("fillStarted")

        pyotherside.send("fillFinished")

Tidaler = Tidal()
