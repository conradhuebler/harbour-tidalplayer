import pyotherside
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



class PlaylistManager:
    def __init__(self):
        self.current_index = -1
        self.playlist = []
        #self._notify_playlist_state()
        pyotherside.send("playlistManagerLoaded")

    def _notify_playlist_state(self):
        """Benachrichtigt über den aktuellen Playlist-Status"""
        is_last_track = self.current_index >= len(self.playlist) - 1
        pyotherside.send("playlistSize", len(self.playlist))
        pyotherside.send("currentIndex", self.current_index)

        if is_last_track:
            pyotherside.send("playlistFinished")
        else:
            pyotherside.send("playlistUnFinished")

    def _notify_current_track(self):
        """Benachrichtigt über den aktuellen Track"""

        if 0 <= self.current_index < len(self.playlist):
            pyotherside.send("currentTrack",
                           self.playlist[self.current_index],
                           self.current_index)

    def AppendTrack(self, track_id):
        """Fügt einen Track am Ende der Playlist hinzu"""
        if track_id:
            self.playlist.append(track_id)
            self._notify_playlist_state()

    def AppendTrackSilent(self, track_id):
        """Fügt einen Track am Ende der Playlist hinzu"""
        if track_id:
            self.playlist.append(track_id)

    def InsertTrack(self, track_id):
        """Fügt einen Track nach dem aktuellen Track ein"""
        if track_id:
            insert_pos = max(0, self.current_index + 1)
            self.playlist.insert(insert_pos, track_id)
            self._notify_playlist_state()
            self._notify_current_track()
            #pyotherside.send("listChanged")

    def RemoveTrack(self, track_id):
        """Entfernt einen Track aus der Playlist"""
        if track_id:
            try:
                self.playlist.remove(track_id)
                self._notify_playlist_state()
            except ValueError:
                print(f"Track with id {track_id} not found in the playlist")

    def PlayTrack(self, track_id):
        """Spielt einen bestimmten Track sofort"""
        if track_id:
            insert_pos = max(0, self.current_index + 1)
            self.playlist.insert(insert_pos, track_id)
            self.current_index = insert_pos
            self._notify_playlist_state()
            self._notify_current_track()
            #pyotherside.send("listChanged")

    def NextTrack(self):
        """Wechselt zum nächsten Track"""
        if self.current_index < len(self.playlist) - 1:
            self.current_index += 1
            self._notify_current_track()
            #self._notify_playlist_state()

    def PreviousTrack(self):
        """Wechselt zum vorherigen Track"""
        if self.current_index > 0:
            self.current_index -= 1
            self._notify_current_track()
        #self._notify_playlist_state()

    def PlayPosition(self, position):
        """Spielt einen Track an einer bestimmten Position"""
        try:
            position = int(position)  # Konvertiere zu Integer
            if 0 <= position < len(self.playlist):
                self.current_index = position
                self._notify_current_track()
        except (ValueError, TypeError):
            print(f"Invalid position value: {position}")

    def RestartTrack(self):
        """Startet den aktuellen Track neu"""
        self._notify_current_track()

    def GenerateList(self):
        """Generiert die komplette Playlist"""
        pyotherside.send("clearList")
        for track_id in self.playlist:
            pyotherside.send("containsTrack", track_id)

        pyotherside.send("listChanged")

    def size(self):
        """Gibt die Größe der Playlist zurück"""
        return len(self.playlist)

    def TidalId(self, index):
        """Gibt die Tidal-ID für einen Index zurück"""
        try:
            index = int(index)
            if 0 <= index < len(self.playlist):
                return self.playlist[index]
        except (ValueError, TypeError):
            pass
        return 0

    def PlaylistIndex(self):
        """Gibt den aktuellen Index zurück"""
        return self.current_index

    def clearList(self):
        """Leert die komplette Playlist"""
        self.current_index = -1
        self.playlist = []
        self._notify_playlist_state()

PL = PlaylistManager()
