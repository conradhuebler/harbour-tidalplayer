from __future__ import print_function

import datetime

import dateutil.tz
import pytest

import tidalapi
from tidalapi.page import PageItem, PageLink
from tidalapi.mix import Mix
from tidalapi import VideoQuality
import sys
sys.path.append( './../..' )

import sys

from unittest.mock import MagicMock

# Create a mock that prints debug messages
class DebugMock:
    def __init__(self):
        self.messages = []    
    def send(self, type, message=None):
        if type == 'debug':
            print(f"DEBUG: {message}", file=sys.stderr, flush=True)
            return True
            
    #def send(self, message):
    #        print(f"DEBUG: {message}", file=sys.stderr, flush=True)
    #        return True
          
# Create singleton instance
debug_mock = DebugMock()
sys.modules['pyotherside'] = debug_mock

from qml.tidal import Tidal

# should go into setup
def test_genericSearch(session):
    tidal = Tidal()
    tidal.session = session
    tidal.initialize("TEST") # it does not work to use the enum
    tidal.config = tidalapi.Config(quality=tidalapi.Quality.high_lossless, video_quality=tidalapi.VideoQuality.low)
    tidal.session = session
    result = tidal.genericSearch("Def Leppard")
    for playlist in result["playlists"]:
        if playlist_info := tidal.handle_playlist(playlist):
            print("debug",playlist_info)

def test_getPageContinueListen(session):
    tidal = Tidal()
    tidal.session = session
    page = tidal.getPageContinueListen()
    assert page is not None
    assert page.categories
    for item in page.categories:
         print(item.title)

def test_getPageDailyMixes(session):
    tidal = Tidal()
    tidal.session = session
    page = tidal.getPageDailyMixes()
    assert page is not None
    assert page.categories
    for item in page.categories:
         print(item.title)

def test_getPageFavoriteArtists(session):
    tidal = Tidal()
    tidal.session = session
    page = tidal.getPageFavoriteArtists()
    assert page is not None
    assert page.categories
    for item in page.categories:
         print(item.title)

def test_getPageListeningHistorypage(session):
    tidal = Tidal()
    tidal.session = session
    page = tidal.getPageListeningHistorypage()
    assert page is not None
    assert page.categories
    for item in page.categories:
         print(item.title)

def test_getPagePopularPlaylists(session):
    tidal = Tidal()
    tidal.session = session
    page = tidal.getPagePopularPlaylists()
    assert page is not None
    assert page.categories
    for item in page.categories:
         print(item.title)         

def test_getPageDecades(session):
    tidal = Tidal()
    tidal.session = session
    page = tidal.getPageDecades()
    assert page is not None
    assert page.categories
    for item in page.categories:
         print(item.title)      

def test_get_user_recently_played(session):
    tidaler = Tidal()
    tidaler.initialize("TEST") # it does not work to use the enum
    tidaler.config = tidalapi.Config(quality=tidalapi.Quality.high_lossless, video_quality=tidalapi.VideoQuality.low)
    tidaler.session = session
    page = tidaler.getPageContinueListen()
    assert page is not None
    for item in page:
        tidaler.getRecently(item)


def test_get_fav_artist(session):
    assert isinstance(session.user.favorites, tidalapi.Favorites)
    for artist in session.user.favorites.artists():
        assert isinstance(artist, tidalapi.artist.Artist)
        print(artist.name)
        print(artist.id)