import pyotherside

class PlaylistManager:
    def __init__(self):
        self.current_index = -1
        self.playlist = []
        self._notify_playlist_state()

    def _notify_playlist_state(self):
        """Benachrichtigt über den aktuellen Playlist-Status"""
        is_last_track = self.current_index >= len(self.playlist) - 1
        pyotherside.send("playlistSize", len(self.playlist))

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

    def InsertTrack(self, track_id):
        """Fügt einen Track nach dem aktuellen Track ein"""
        if track_id:
            insert_pos = max(0, self.current_index + 1)
            self.playlist.insert(insert_pos, track_id)
            self._notify_playlist_state()
            self._notify_current_track()

    def PlayTrack(self, track_id):
        """Spielt einen bestimmten Track sofort"""
        if track_id:
            insert_pos = max(0, self.current_index + 1)
            self.playlist.insert(insert_pos, track_id)
            self.current_index = insert_pos
            self._notify_playlist_state()
            self._notify_current_track()

    def NextTrack(self):
        """Wechselt zum nächsten Track"""
        if self.current_index < len(self.playlist) - 1:
            self.current_index += 1
            self._notify_current_track()
        self._notify_playlist_state()

    def PreviousTrack(self):
        """Wechselt zum vorherigen Track"""
        if self.current_index > 0:
            self.current_index -= 1
            self._notify_current_track()
        self._notify_playlist_state()

    def PlayPosition(self, position):
        """Spielt einen Track an einer bestimmten Position"""
        if 0 <= position < len(self.playlist):
            self.current_index = position
            self._notify_current_track()
            self._notify_playlist_state()

    def RestartTrack(self):
        """Startet den aktuellen Track neu"""
        self._notify_current_track()

    def GenerateList(self):
        """Generiert die komplette Playlist"""
        pyotherside.send("clearList")
        for track_id in self.playlist:
            pyotherside.send("containsTrack", track_id)

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
        pyotherside.send("clearList")

PL = PlaylistManager()
