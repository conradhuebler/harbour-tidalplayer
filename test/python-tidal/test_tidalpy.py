from __future__ import print_function

import datetime

import dateutil.tz
import pytest

import tidalapi
from tidalapi.page import PageItem, PageLink
from tidalapi.mix import Mix

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

def test_get_user_recently_played(session):
    tidaler = Tidal()
    tidaler.session = session
    recent_page = tidaler.getPageContinueListen()
    for item in recent_page:
        tidaler.getRecently(item)

def test_get_fav_artist(session):
    assert isinstance(session.user.favorites, tidalapi.Favorites)
    for artist in session.user.favorites.artists():
        assert isinstance(artist, tidalapi.artist.Artist)
        print(artist.name)
        print(artist.id)