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
            if access_token == refresh_token:
                self.session.load_oauth_session(token_type, refresh_token)
                pyotherside.send("oauth_updated", self.session.token_type, self.session.access_token, self.session.refresh_token,  self.session.expiry_time)

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
        try:
            #//pyotherside.send("trackInfo", i.id, i.name, i.album.name, i.artist.name, i.album.image(320), i.duration)
            return i.id, i.name, i.album.name, i.artist.name, i.album.image(320), i.duration
        except AttributeError:
            #//pyotherside.send("trackInfo", i.id, i.name, i.album.name, i.artist.name, "", i.duration)
            return i.id, i.name, i.album.name, i.artist.name, "", i.duration


    def getAlbumInfo(self, id):
        i = self.session.album(int(id))
        try:
            pyotherside.send("albumInfo", i.id, i.name, i.artist.name, i.image(320))
        except AttributeError:
            pyotherside.send("albumInfo", i.id, i.name, i.artist.name, "")
        self.getAlbumTracks(int(id))

    def getArtistInfo(self, id):
        i = self.session.artist(int(id))
        try:
            pyotherside.send("artistInfo", i.id, i.name, i.image(320))
        except AttributeError:
            pyotherside.send("artistInfo", i.id, i.name, "")

        self.getTopTracks(id, 20)

    def genericSearch(self, text):
        result = self.session.search(text)

        self.tracks = result["tracks"]
        for i in self.tracks:
            try:
                pyotherside.send("addTrack", i.id, i.name, i.album.name, i.artist.name, i.album.image(80), i.duration)
                print(i.name)
            except Exception as e:
                pyotherside.send("addTrack", i.id, i.name, i.album.name, i.artist.name, "", i.duration)
                logging.error(traceback.format_exc())

        self.artists = result["artists"]
        for i in self.artists:
            try:
                pyotherside.send("addArtist", i.id, i.name, i.image(80))
            except AttributeError:
                pyotherside.send("addArtist", i.id, i.name, "")
            except ValueError:
                pyotherside.send("addArtist", i.id, i.name, "")

        self.albums = result["albums"]
        for i in self.albums:
            try:
                pyotherside.send("addAlbum", i.id, i.name, i.artist.name, i.image(80), i.duration)
            except AttributeError:
                pyotherside.send("addAlbum", i.id, i.name, i.artist.name, "", i.duration)

        self.playlists = result["playlists"]
        for i in self.playlists:
            pyotherside.send("addPlaylist", i.id, i.name, "", i.duration, i.id)


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
        try:
            pyotherside.send("currentTrackInfo", t.name, t.track_num, t.album.name, t.artist.name, t.duration, t.album.image(320), t.artist.image(320))
        except AttributeError:
            pyotherside.send("currentTrackInfo", t.name, t.track_num, t.album.name, t.artist.name, t.duration, "", "")
        return t.name, t.track_num

    def getAlbumTracks(self, id):
        album = self.session.album(int(id))
        for i in album.tracks():
            try:
                pyotherside.send("addTrack", i.id, i.name, i.album.name, i.artist.name, i.album.image(320), i.duration)
            except AttributeError:
                pyotherside.send("addTrack", i.id, i.name, i.album.name, i.artist.name, "", i.duration)
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

        for i in playlist.tracks():
            try:
                pyotherside.send("addTrack", i.id, i.name, i.album.name, i.artist.name, i.album.image(320), i.duration)
            except AttributeError:
                pyotherside.send("addTrack", i.id, i.name, i.album.name, i.artist.name, "", i.duration)

    def playPlaylist(self, id):
        playlist = self.session.playlist(id)
        pyotherside.send("insertTrack", playlist.tracks()[0].id)
        pyotherside.send("printConsole", " insert Track: " + str(playlist.tracks()[0].id))

        for i, item in enumerate(playlist.tracks()):
                pyotherside.send("addTracktoPL", item.id)
                if i == 0:
                    pyotherside.send("fillStarted")

        pyotherside.send("fillFinished")

Tidaler = Tidal()
