# This Python file uses the following encoding: utf-8

# if __name__ == "__main__":
#     pass

import sys;
sys.path.append('/usr/share/harbour-tidalplayer/python/')

import socket
import requests
import json

import tidalapi
import pyotherside


class Tidal:
    def __init__(self):
        self.session = tidalapi.Session()

    def login(self, token_type, access_token, refresh_token, expiry_time):
        if access_token == token_type:
            pyotherside.send("oauth_login_failed")
        else:
            self.session.load_oauth_session(token_type, access_token)
            if self.session.check_login() == True:
                pyotherside.send("oauth_login_success")
            else:
                self.session.load_oauth_session(token_type, refresh_token)
                if self.session.check_login() == True:
                    pyotherside.send("oauth_login_success")
                    pyotherside.send("oauth_updated", self.session.token_type, self.session.access_token, self.session.refresh_token,  self.session.expiry_time)
                else:
                    pyotherside.send("oauth_login_failed")

    def request_oauth(self):
        self.login, self.future = self.session.login_oauth()
        pyotherside.send("get_url", self.login.verification_uri_complete)
        self.future.result()
        if self.session.check_login() == True:
            pyotherside.send("get_token", self.session.token_type, self.session.access_token, self.session.refresh_token,  self.session.expiry_time)
        else:
            pyotherside.send("oauth_failed")

    def getTrackInfo(self, id):
        i = self.session.track(int(id))
        pyotherside.send("trackInfo", i.id, i.name, i.album.name, i.artist.name, i.album.image(320), i.duration)

    def getAlbumInfo(self, id):
        i = self.session.album(int(id))
        pyotherside.send("albumInfo", i.id, i.name, i.artist.name, i.image(320))
        self.getAlbumTracks(int(id))

    def getArtistInfo(self, id):
        i = self.session.artist(int(id))
        pyotherside.send("artistInfo", i.id, i.name, i.image(320))
        self.getTopTracks(id, 20)

    def genericSearch(self, text):
        result = self.session.search(text)

        self.tracks = result["tracks"]
        for i in self.tracks:
            pyotherside.send("addTrack", i.id, i.name, i.album.name, i.artist.name, i.album.image(320), i.duration)

        self.artists = result["artists"]
        for i in self.artists:
            pyotherside.send("addArtist", i.id, i.name)

        self.albums = result["albums"]
        for i in self.albums:
            pyotherside.send("addAlbum", i.id, i.name, i.artist.name, i.image(320))

    def searchTracks(self, text, number):
        pyotherside.send("trackSearchFinished")

    def searchArtists(self, text, number):
        pyotherside.send("artistsSearchFinished")

    def searchAlbums(self,  text, number):
        pyotherside.send("albumsSearchFinished")

    def getTrackUrl(self, id):
        t = self.session.track(int(id))
        url = t.get_url()
        pyotherside.send("playUrl", url)
        pyotherside.send("currentTrackInfo", t.name, t.track_num, t.album.name, t.artist.name, t.duration, t.album.image(320), t.artist.image(320))

    def getAlbumTracks(self, id):
        album = self.session.album(int(id))
        for i in album.tracks():
            pyotherside.send("addTrack", i.id, i.name, i.album.name, i.artist.name, i.album.image(320), i.duration)

    def playAlbumTracks(self, id):
        album = self.session.album(int(id))
        for i in album.tracks():
            pyotherside.send("addTracktoPL", i.id)
        pyotherside.send("fillFinished")

    def playAlbumfromTrack(self, id):
        for i in self.session.track(int(id)).album.tracks():
             pyotherside.send("addTracktoPL", i.id)
        pyotherside.send("fillFinished")

    def getTopTracks(self, id, max):
        toptracks = self.session.artist(int(id)).get_top_tracks(max)
        for i in toptracks:
            pyotherside.send("addTrack", i.id, i.name, i.album.name, i.artist.name, i.album.image(320), i.duration)

    def getPersonalPlaylists(self):
        playlists = self.session.user.playlists()
        for i in playlists:
            pyotherside.send("addPersonalPlaylist", i.id, i.name, i.image(320), i.num_tracks, i.description, i.duration)

    def getPersonalPlaylist(self, id):
        playlist = self.session.playlist(int(id))
        pyotherside.send("setPlaylist", i.id, i.name, i.image(320), i.num_tracks, i.description, i.duration)
        for i in playlist.tracks():
            pyotherside.send("addTrack", i.id, i.name, i.album.name, i.artist.name, i.album.image(320), i.duration)

    def playPlaylist(self, id):
        playlist = self.session.playlist(id)
        for i in playlist.tracks():
            pyotherside.send("addTracktoPL", i.id)
        pyotherside.send("fillFinished")

Tidaler = Tidal()

