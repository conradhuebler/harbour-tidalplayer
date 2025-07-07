# This Python file uses the following encoding: utf-8

import sys
(major, minor, micro, release, serial) = sys.version_info
sys.path.append("/usr/share/harbour-tidalplayer/lib/python" + str(major) + "." + str(minor) + "/site-packages/");

sys.path.append('/usr/share/harbour-tidalplayer/python/')
import socket
import requests
import json
import tidalapi
import pyotherside

from tidalapi.page import PageItem, PageLink
from tidalapi.mix import Mix
from tidalapi.media import Quality
from requests.exceptions import HTTPError, RequestException


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

        selected_quality = ""
        if quality == "LOW":
            selected_quality = Quality.low_96k
        elif quality == "HIGH":
            selected_quality = Quality.low_320k
        elif quality == "LOSSLESS":
            selected_quality = Quality.high_lossless
        elif quality == "TEST":
            selected_quality = Quality.low_96k
        else:
            # Fallback auf HIGH wenn unbekannte Qualität
            selected_quality = Quality.default
        #todo: add the other qualities too

        self.config = tidalapi.Config(quality=selected_quality, video_quality=tidalapi.VideoQuality.low)
        self.session = tidalapi.Session(self.config)

    def setconfig(self, top_tracks, album_search, track_search, artist_search):
        self.top_tracks = top_tracks
        self.album_search = album_search
        self.track_search = track_search
        self.artist_search = artist_search

    def login(self, token_type, access_token, refresh_token, expiry_time):
        try:
            if access_token == token_type:
                pyotherside.send("oauth_login_failed")
            else:
                if access_token == refresh_token:
                    pyotherside.send("printConsole", "Getting new token")

                    try:
                        self.session.token_refresh(refresh_token)
                        self.session.load_oauth_session(token_type, self.session.access_token)

                        if self.session.check_login() is True:
                            pyotherside.send("printConsole", "New token", self.session.access_token)
                            pyotherside.send("oauth_refresh", self.session.access_token)
                            pyotherside.send("oauth_login_success")
                            pyotherside.send("printConsole", "Login success")
                        else:
                            pyotherside.send("printConsole", "Token refresh failed - login check unsuccessful")
                            pyotherside.send("oauth_login_failed")

                    except HTTPError as http_err:
                        if http_err.response.status_code == 401:
                            pyotherside.send("printConsole", "Token refresh failed - 401 Unauthorized")
                            pyotherside.send("oauth_login_failed")
                        else:
                            pyotherside.send("printConsole", f"HTTP error during token refresh: {http_err}")
                            pyotherside.send("oauth_login_failed")

                    except RequestException as req_err:
                        pyotherside.send("printConsole", f"Network error during token refresh: {req_err}")
                        pyotherside.send("oauth_login_failed")

                    except Exception as e:
                        pyotherside.send("printConsole", f"Unexpected error during token refresh: {e}")
                        pyotherside.send("oauth_login_failed")

                else:
                    pyotherside.send("printConsole", "Login with old token")

                    try:
                        self.session.load_oauth_session(token_type, access_token)

                        if self.session.check_login() == True:
                            pyotherside.send("oauth_login_success")
                            pyotherside.send("printConsole", "Login success")
                        else:
                            pyotherside.send("printConsole", "Login check failed with old token")
                            pyotherside.send("oauth_login_failed")

                    except HTTPError as http_err:
                        if http_err.response.status_code == 401:
                            pyotherside.send("printConsole", "Login failed - 401 Unauthorized, please re-authenticate")
                            pyotherside.send("oauth_login_failed")
                        else:
                            pyotherside.send("printConsole", f"HTTP error during login: {http_err}")
                            pyotherside.send("oauth_login_failed")

                    except RequestException as req_err:
                        pyotherside.send("printConsole", f"Network error during login: {req_err}")
                        pyotherside.send("oauth_login_failed")

                    except Exception as e:
                        pyotherside.send("printConsole", f"Unexpected error during login: {e}")
                        pyotherside.send("oauth_login_failed")

        except Exception as outer_e:
            # Fallback für alle anderen unerwarteten Fehler
            pyotherside.send("printConsole", f"Critical error in login function: {outer_e}")
            pyotherside.send("oauth_login_failed")

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
            artisti = {
                "artistid": str(artist.id),
                "name": str(artist.name),
                "image": artist.image(320) if hasattr(artist, 'image') else "image://theme/icon-m-media-artists",
                "type": "artist",
                "bio" : ""
            }
        except AttributeError as e:
            print(f"Error handling artist: {e}")
            return None
        try:
            bio = str(artist.get_bio())
        except HTTPError as e:
            if e.response.status_code == 404:
                print(f"Error fetching biography: {e}")
                return artisti
            return artisti
        except tidalapi.exceptions.ObjectNotFound as e:
            return artisti
        artisti["bio"] = bio
        return artisti

    def handle_album(self, album):
        try:
            return {
                "albumid": int(album.id),
                "title": str(album.name),
                "artist": str(album.artist.name),
                "artistid" : str(album.artist.id),
                "image": album.image(320) if hasattr(album, 'image') else "image://theme/icon-m-media-albums",
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

    def send_object(self, signal_name, data, data2=None):
        """Helper-Funktion zum Senden von Objekten"""
        try:
            if (data2 is None):
                pyotherside.send(signal_name, data)
            else:
                pyotherside.send(signal_name, data, data2)
        except Exception as e:
            print(f"Error sending object: {e}")

    def handle_playlist(self, playlist):
        """Handler für Playlist-Informationen"""
        try:
            return {
                "playlistid": str(playlist.id),
                "title": str(playlist.name),
                "image": playlist.image(320) if hasattr(playlist, 'image') else "image://theme/icon-m-media-playlists",
                "duration": int(playlist.duration) if hasattr(playlist, 'duration') else 0,
                "num_tracks": playlist.num_tracks if hasattr(playlist, 'num_tracks') else 0,
                "description": playlist.description if hasattr(playlist, 'description') else "",
                "type": "playlist"
            }
        except AttributeError as e:
            pyotherside.send("printConsole", f"Error handling playlist: {e}")
            print(f"Error handling playlist: {e}")
            return None

    def handle_mix(self, mix):
        """Handler für Mix-Informationen, nicht fertig, """
        try:
            default_image = "image://theme/icon-m-media-playlists"
            image = default_image
            # image will not work with current tidalapi version
            if hasattr(mix, 'images'):
                if hasattr(mix.images, 'small'):
                    image = str(mix.images.small)
            return {
                "mixid": str(mix.id),
                "title": str(mix.title),
                "image": image,
                "duration": int(mix.duration) if hasattr(mix, 'duration') else 0,
                "num_tracks": mix.num_tracks if hasattr(mix, 'num_tracks') else 0,
                "description": mix.sub_title if hasattr(mix, 'sub_title') else "",
                "type": "mix"
            } # rather try to return items.count as num_tracks
        except AttributeError as e:
            print(f"Error handling mix: {e}")
            pyotherside.send("printConsole", f"trouble loading mix: f{e}")
            return None

    def genericSearch(self, text):
        pyotherside.send('loadingStarted')
        result = self.session.search(text)

        # Tracks verarbeiten
        if "tracks" in result:
            for track in result["tracks"]:
                if track_info := self.handle_track(track):
                    #search_results["tracks"].append(track_info)
                    self.send_object("cacheTrack", track_info)
                    self.send_object("foundTrack", track_info)

        # Artists verarbeiten
        if "artists" in result:
            for artist in result["artists"]:
                if artist_info := self.handle_artist(artist):
                    #search_results["artists"].append(artist_info)
                    self.send_object("cacheArtist", artist_info)
                    self.send_object("foundArtist", artist_info)

        # Albums verarbeiten
        if "albums" in result:
            for album in result["albums"]:
                if album_info := self.handle_album(album):
                    #search_results["albums"].append(album_info)
                    self.send_object("cacheAlbum", album_info)
                    self.send_object("foundAlbum", album_info)

        if "playlists" in result:
            for playlist in result["playlists"]:
                if playlist_info := self.handle_playlist(playlist):
                    #search_results["playlists"].append(playlist_info)
                    self.send_object("foundPlaylist", playlist_info)

        if "videos" in result:
            for video in result["videos"]:
                if video_info := self.handle_video(video):
                    #search_results["videos"].append(video_info)
                    self.send_object("foundVideo", video_info)

        if "mixes" in result:
            for mix in result["mixes"]:
                if mix_info := self.handle_mix(mix):
                    #search_results["videos"].append(video_info)
                    self.send_object("foundMix", mix_info)

        # Gesamtergebnis senden
        #self.send_object("search_results", search_results)
        pyotherside.send('loadingFinished')
        # mainly for testing, i do return ..
        return result

    def getMixInfo(self, id):
        try:
            mix = self.session.mix(id)
            mix_info = self.handle_mix(mix)
            if mix_info:
                self.send_object("cacheMix", mix_info)
                return mix_info
            return None
        except Exception as e:
            self.send_object("error", {"message": str(e)})
            return None

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

    def getMixTracks(self, id):
        pyotherside.send('loadingStarted')
        try:
            mix = self.session.mix(id)
            for track in mix.items():
                track_info = self.handle_track(track)
                if track_info:
                    pyotherside.send("cacheTrack", track_info)
                    pyotherside.send("mixTrackAdded",track_info)
            return mix # just for testing
        finally:
            pyotherside.send('loadingFinished')

    def playMix(self, id,autoPlay=False):
        pyotherside.send('loadingStarted')
        mix = self.session.mix(id)
        mix_info = self.handle_mix(mix)
        if mix_info:
            for track in mix.items(): #tracks():
                track_info = self.handle_track(track)
                if track_info:
                    pyotherside.send("cacheTrack", track_info)
                    pyotherside.send("addTracktoPL", track_info['trackid'])

        pyotherside.send("fillFinished", autoPlay)
        pyotherside.send('loadingFinished')

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
        pyotherside.send("fillFinished", False)

    def playArtistTracks(self, id, autoPlay=False):
        artist = self.session.artist(int(id))
        for track in artist.get_top_tracks(self.top_tracks):
            track_info = self.handle_track(track)
            if track_info:
                pyotherside.send("cacheTrack", track_info)
                pyotherside.send("addTracktoPL", track_info['trackid'])
        pyotherside.send("fillFinished", autoPlay)

    def playArtistRadio(self, id, autoPlay=False):
        artist = self.session.artist(int(id))
        for track in artist.get_radio():
            track_info = self.handle_track(track)
            if track_info:
                pyotherside.send("cacheTrack", track_info)
                pyotherside.send("addTracktoPL", track_info['trackid'])
        pyotherside.send("fillFinished", autoPlay)

    # this is kinda duplicate of getTopTracksofArtist
    #def getTopTracks(self, id, max):
    #    toptracks = self.session.artist(int(id)).get_top_tracks(max)
    #    for track in toptracks:
    #        track_info = self.handle_track(track)
    #        if track_info:
    #            pyotherside.send("cacheTrack", track_info)
    #            pyotherside.send("addTrack",
    #                track_info['trackid'],
    #                track_info['title'],
    #                track_info['album'],
    #                track_info['artist'],
    #                track_info['image'],
    #                track_info['duration'])
    
    def getArtistRadio(self, id): # -> Optional[List[Track]]:
        pyotherside.send('loadingStarted')
        tracks = self.session.artist(int(id)).get_radio()
        for ti in tracks:
            i = self.handle_track(ti)
            pyotherside.send("cacheTrack", i)
            pyotherside.send("RadioTrackofArtist", i)

        pyotherside.send('loadingFinished')
        return tracks  # just for testing
                
    def getPersonalPlaylists(self):
        pyotherside.send('loadingStarted')
        playlists = self.session.user.playlists()
        for i in playlists:
            playlist_info = self.handle_playlist(i)
            self.send_object("addPersonalPlaylist", playlist_info)
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
            return playlist # just for testing

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
        #self.home.categories.extend(self.session.explore().categories)
        #self.home.categories.extend(self.session.videos().categories)

        for item in self.home.categories[0].items:
            self.getForYou(item)

        recent_page = self.getPageContinueListen()
        for item in recent_page:
            self.getRecently(item)

    def getRadioMixes(self):
        page = self.getPageSuggestedRadioMixes()
        for item in page:
            self.getCustomMixes("radioMix",item)

    def getDailyMixes(self):
        page = self.getPageDailyMixes()
        for item in page:
            self.getCustomMixes("dailyMix",item)

    def getTopArtists(self): # should there be a switch on get-artist in the end ?
        page = self.getPageFavoriteArtists()
        for item in page:
            self.tryHandleArtist("topArtist", item)

    def getPageContinueListen(self):
        return self.session.page.get("pages/CONTINUE_LISTEN_TO/view-all")

    def getPagePopularPlaylists(self):
        return self.session.page.get("pages/POPULAR_PLAYLISTS/view-all")

    def getPageSuggestedRadioMixes(self):
        return self.session.page.get("pages/SUGGESTED_RADIOS_MIXES/view-all?")

    def getPageDailyMixes(self):
        return self.session.page.get("pages/DAILY_MIXES/view-all?")

    # sorted by activity
    def getPageFavoriteArtists(self):
        return self.session.page.get("pages/YOUR_FAVORITE_ARTISTS/view-all?")

    def getPageListeningHistorypage(self):
        return self.session.page.get("pages/HISTORY_MIXES/view-all?")

    def getPageSuggestedNewAlbumspage(self):
        return self.session.page.get("pages/NEW_ALBUM_SUGGESTIONS/view-all?")

    def getPageDecades(self):
        return self.session.page.get("pages/genre_decades")

    def getPageGenres(self):
        return self.session.page.get("pages/genre_page")

    def getPageMoods(self):
        return self.session.page.get("pages/moods_page")

    def tryHandleAlbum(self, signalName, item):
        if isinstance(item, tidalapi.album.Album):
            album_info = self.handle_album(item)
            if album_info:
                self.send_object("cacheAlbum", album_info)
                self.send_object(signalName, album_info)
            else:
                pyotherside.send("printConsole", "trouble loading album")
            return True
        return False

    def tryHandleArtist(self, signalName, item):
        if isinstance(item, tidalapi.artist.Artist):
            # ps: crashes here self.items.append("\t" + item.name)
            pyotherside.send("printConsole", item.name)
            artist_info = self.handle_artist(item)
            if artist_info:
                self.send_object("cacheArtist", artist_info)
                self.send_object(signalName, artist_info)
            else:
                pyotherside.send("printConsole", "trouble loading artist")
            return True
        return False

    def tryHandlePlaylist(self, signalName, item):
        if isinstance(item, tidalapi.playlist.Playlist):
            playlist_info = self.handle_playlist(item)
            if playlist_info:
                self.send_object("cachePlaylist", playlist_info)
                self.send_object(signalName, playlist_info)
            return True
        return False

    def tryHandleMix(self, signalName, item, sub=None):
        # sub is used for customMixes
        if isinstance(item, tidalapi.mix.Mix):
            mix_info = self.handle_mix(item)
            if mix_info:
                self.send_object("cacheMix", mix_info)
                self.send_object(signalName, mix_info,sub)
            return True
        return False

    def tryHandleTrack(self, signalName, item):
        if isinstance(item, tidalapi.Track):
            track_info = self.handle_track(item)
            if track_info:
                self.send_object(signalName, track_info)
            return True
        return False

    def getRecently(self, item):
        if self.tryHandleAlbum("recentAlbum", item):
            return
        if self.tryHandleArtist("recentArtist", item):
            return
        if self.tryHandlePlaylist("recentPlaylist", item):
            return
        if self.tryHandleMix("recentMix", item):
            return
        if self.tryHandleTrack("recentTrack", item):
            return
        pyotherside.send("printConsole", f"trouble handling object in getRecently: {type(item)}")

    def getForYou(self, item):
        if self.tryHandleAlbum("foryouAlbum", item):
            return
        if self.tryHandleArtist("foryouArtist",item):
            return
        if self.tryHandlePlaylist("foryouPlaylist", item):
            return
        if self.tryHandleMix("foryouMix", item):
            return
        if self.tryHandleTrack("foryouTrack", item):
            return
        pyotherside.send("printConsole", f"trouble handling object in getForYou: {type(item)}")

    def getCustomMixes(self, sub, item):
        if self.tryHandleMix("customMix",item,sub):
            return
        pyotherside.send("printConsole", f"trouble handling object in getCustomMixes: {type(item)}")

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
