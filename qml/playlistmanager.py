# This Python file uses the following encoding: utf-8

# if __name__ == "__main__":
#     pass


import pyotherside

testlist = [161699365, 5190513]

class PlaylistManager:
    def __init__(self):
        print("init")
        self.currentTrackIndex = -1
        self.playlist = []

    def AppendTrack(self, id):
        self.playlist.append(id)
        pyotherside.send("playlistSize", len(self.playlist))
        if self.currentTrackIndex  == len(self.playlist) - 1:
            pyotherside.send("playlistFinished")
        else:
            pyotherside.send("playlistUnFinished")

    def InsertTrack(self, id):
        self.playlist.insert(self.currentTrackIndex + 1, id)
        pyotherside.send("playlistSize", len(self.playlist))
        if self.currentTrackIndex  == len(self.playlist) - 1:
            pyotherside.send("playlistFinished")
        else:
            pyotherside.send("playlistUnFinished")
        pyotherside.send("currentTrack", self.playlist[self.currentTrackIndex], self.currentTrackIndex)

    def PreviousTrack(self):
        self.currentTrackIndex =  self.currentTrackIndex - 1
        pyotherside.send("currentTrack", self.playlist[self.currentTrackIndex])
        if self.currentTrackIndex  == len(self.playlist) - 1:
            pyotherside.send("playlistFinished")
        else:
            pyotherside.send("playlistUnFinished")

    def RestartTrack(self):
        pyotherside.send("currentTrack", self.playlist[self.currentTrackIndex])

    def PlayTrack(self, id):
        self.playlist.insert(self.currentTrackIndex + 1, id)
        self.currentTrackIndex =  self.currentTrackIndex + 1
        pyotherside.send("playlistSize", len(self.playlist))
        pyotherside.send("currentTrack", self.playlist[self.currentTrackIndex], self.currentTrackIndex)


        if self.currentTrackIndex  == len(self.playlist) - 1:
            pyotherside.send("playlistFinished")
        else:
            pyotherside.send("playlistUnFinished")

    def PlayPosition(self, position):
        self.currentTrackIndex = position
        pyotherside.send("currentTrack", self.playlist[self.currentTrackIndex], self.currentTrackIndex)

        if self.currentTrackIndex  == len(self.playlist) - 1:
            pyotherside.send("playlistFinished")
        else:
            pyotherside.send("playlistUnFinished")

    def NextTrack(self):
        if self.currentTrackIndex == len(self.playlist)  - 1:
            pyotherside.send("playlistFinished")
        else:
            self.currentTrackIndex =  self.currentTrackIndex + 1
            pyotherside.send("currentTrack", self.playlist[self.currentTrackIndex], self.currentTrackIndex)
            pyotherside.send("playlistUnFinished")

    def GenerateList(self):
        pyotherside.send("clearList")
        for i in self.playlist:
            pyotherside.send("containsTrack", i)

    def clear(self):
        self.currentTrackIndex = -1
        self.playlist = testlist #[]
        pyotherside.send("clearList")

    def clearList(self):
        self.currentTrackIndex = -1
        self.playlist = []

PL = PlaylistManager()
