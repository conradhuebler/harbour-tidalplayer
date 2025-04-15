# -*- coding: utf-8 -*-
#
# Copyright (C) 2023- The Tidalapi Developers
# Copyright (C) 2019-2022 morguldir
# Copyright (C) 2014 Thomas Amland
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

import datetime

import dateutil.tz
import pytest

import tidalapi
from tidalapi.page import PageItem, PageLink
from tidalapi.mix import Mix


def test_get_fav_artist(session):
    assert isinstance(session.user.favorites, tidalapi.Favorites)
    for artist in session.user.favorites.artists():
        assert isinstance(artist, tidalapi.artist.Artist)
        print(artist.name)
        print(artist.id)

def test_get_fav_albums(session):
    assert isinstance(session.user.favorites, tidalapi.Favorites)
    for album in session.user.favorites.albums():
        assert isinstance(album, tidalapi.album.Album)
        print(album.name)
        print(album.id)      

def test_get_fav_tracks(session):
    assert isinstance(session.user.favorites, tidalapi.Favorites)
    for track in session.user.favorites.tracks():
        assert isinstance(track, tidalapi.Track)
        print(track.name)
        print(track.id) 

@pytest.mark.skip(reason="no way of currently testing this")
def test_playaround_with_home(session):
    home = session.home()
    assert home
    home.categories.extend(session.for_you().categories)
    #home.categories.extend(session.explore().categories)
    #home.categories.extend(session.genres().categories)
    #home.categories.extend(session.moods().categories)
    #home.categories.extend(session.mixes().categories)
    #home.categories.extend(session.recent().categories)
    home.categories.extend(session.page.get("pages/CONTINUE_LISTEN_TO/view-all"))
    

    print('home page content \n')
    for category in home.categories:
        assert category is not None
        print(category.title)

    for category in home.categories:
        print("type:" + category.title)
        #print(category.type)
        items = []
        for item in category.items:
            if isinstance(item, tidalapi.album.Album):
                if item and item.type is not None:
                    items.append("\talbum:" + item.name + "\t" + item.type)
                    # Call item.get() on this one, for example on click 
                else:
                    items.append("\talbum-none:" + item.name)
            elif isinstance(item, tidalapi.artist.Artist):
                items.append("\tartist:" + item.name)
                # Call item.get() on this one, for example on click 
            elif isinstance(item, PageItem):
                items.append("\tpageItem:" + item.short_header)
                items.append("\t" + item.short_sub_header[0:50])
                # Call item.get() on this one, for example on click
            elif isinstance(item, PageLink):
                items.append("\tpageLink:" + item.title)
                # Call item.get() on this one, for example on click
            elif isinstance(item, Mix):
                items.append("\tmix:" + item.title)
                # You can optionally call item.get() to request the items() first, but it does it for you if you don't
            else:
                items.append("\telse:" + item.name)
                # An album could be handled by session.album(item.id) for example,
                # to get full details. Usually the relevant info is there already however
        [print(x) for x in sorted(items)]
