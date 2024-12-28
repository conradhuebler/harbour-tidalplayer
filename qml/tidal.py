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

    def getAlbumInfo(self, id):
        album_info = self.handle_album(self.session.album(int(id)))
        if album_info:
            pyotherside.send("cacheAlbum",
                album_info['id'],
                album_info['title'],
                album_info['artist'],
                album_info['image'])
            self.getAlbumTracks(int(id))

    def getArtistInfo(self, id):
        artist_info = self.handle_artist(self.session.artist(int(id)))
        if artist_info:
            pyotherside.send("cacheArtist",
                artist_info['id'],
                artist_info['name'],
                artist_info['image'])
            self.getTopTracks(id, 20)

    def genericSearch(self, text):
        result = self.session.search(text)

        for track in result["tracks"]:
            track_info = self.handle_track(track)
            if track_info:
                pyotherside.send("cacheTrack",
                    track_info['id'],
                    track_info['title'],
                    track_info['album'],
                    track_info['artist'],
                    track_info['image'],
                    track_info['duration'])

        for artist in result["artists"]:
            artist_info = self.handle_artist(artist)
            if artist_info:
                pyotherside.send("cacheArtist",
                    artist_info['id'],
                    artist_info['name'],
                    artist_info['image'])

        for album in result["albums"]:
            album_info = self.handle_album(album)
            if album_info:
                pyotherside.send("cacheAlbum",
                    album_info['id'],
                    album_info['title'],
                    album_info['artist'],
                    album_info['image'])

        for playlist in result["playlists"]:
            pyotherside.send("addPlaylist",
                playlist.id,
                playlist.name,
                "",
                playlist.duration,
                playlist.id)

    def getTrackUrl(self, id):
        track = self.session.track(int(id))
        track_info = self.handle_track(track)
        if track_info:
            pyotherside.send("cacheTrack",
                track_info['id'],
                track_info['title'],
                track_info['album'],
                track_info['artist'],
                track_info['image'],
                track_info['duration'])

        url = track.get_url()
        pyotherside.send("playUrl", url)
        try:
            pyotherside.send("currentTrackInfo",
                track.name,
                track.track_num,
                track.album.name,
                track.artist.name,
                track.duration,
                track.album.image(320),
                track.artist.image(320))
        except AttributeError:
            pyotherside.send("currentTrackInfo",
                track.name,
                track.track_num,
                track.album.name,
                track.artist.name,
                track.duration,
                "",
                "")
        return track.name, track.track_num

    def getAlbumTracks(self, id):
        album = self.session.album(int(id))
        for track in album.tracks():
            track_info = self.handle_track(track)
            if track_info:
                pyotherside.send("cacheTrack",
                    track_info['id'],
                    track_info['title'],
                    track_info['album'],
                    track_info['artist'],
                    track_info['image'],
                    track_info['duration'])

    def playAlbumTracks(self, id):
        album = self.session.album(int(id))
        for track in album.tracks():
            track_info = self.handle_track(track)
            if track_info:
                pyotherside.send("cacheTrack",
                    track_info['id'],
                    track_info['title'],
                    track_info['album'],
                    track_info['artist'],
                    track_info['image'],
                    track_info['duration'])
                pyotherside.send("addTracktoPL", track_info['id'])
        pyotherside.send("fillFinished")

    def playAlbumfromTrack(self, id):
        for track in self.session.track(int(id)).album.tracks():
            track_info = self.handle_track(track)
            if track_info:
                pyotherside.send("cacheTrack",
                    track_info['id'],
                    track_info['title'],
                    track_info['album'],
                    track_info['artist'],
                    track_info['image'],
                    track_info['duration'])
                pyotherside.send("addTracktoPL", track_info['id'])
        pyotherside.send("fillFinished")

    def getTopTracks(self, id, max):
        toptracks = self.session.artist(int(id)).get_top_tracks(max)
        for track in toptracks:
            track_info = self.handle_track(track)
            if track_info:
                pyotherside.send("cacheTrack",
                    track_info['id'],
                    track_info['title'],
                    track_info['album'],
                    track_info['artist'],
                    track_info['image'],
                    track_info['duration'])
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
            pyotherside.send("cacheTrack", i.id, i.name, i.album.name, i.artist.name, i.album, i.duration)

    def playPlaylist(self, id):
        playlist = self.session.playlist(id)
        first_track = playlist.tracks()[0]
        pyotherside.send("insertTrack", first_track.id)
        pyotherside.send("printConsole", f" insert Track: {first_track.id}")

        for i, track in enumerate(playlist.tracks()):
            track_info = self.handle_track(track)
            if track_info:
                pyotherside.send("cacheTrack",
                    track_info['id'],
                    track_info['title'],
                    track_info['album'],
                    track_info['artist'],
                    track_info['image'],
                    track_info['duration'])
                pyotherside.send("addTracktoPL", track_info['id'])

            if i == 0:
                pyotherside.send("fillStarted")

        pyotherside.send("fillFinished")

Tidaler = Tidal()
