import QtQuick 2.0
import Sailfish.Silica 1.0
import io.thp.pyotherside 1.5
import QtMultimedia 5.6
import org.nemomobile.mpris 1.0
import Nemo.Configuration 1.0

import "components"
import "cover"
import "pages"
import "pages/widgets"


ApplicationWindow
{
    id: applicationWindow
    
    property FirstPage mainPage

    property bool loginTrue : false
    property var locale: Qt.locale()
    property date currentDate: new Date()
    property MiniPlayer minPlayerPanel : miniPlayerPanel
    property QtObject settings : QtObject
    {
        property string token_type : ""
        property string access_token : ""
        property string refresh_token : ""
        property int expiry_time : -1
        property string mail: ""
        property string audio_quality : ""
        property bool resume_playback : false
        property bool hide_player: false

        property bool recentList: true
        property bool yourList: true //shows currently popular playlists
        property bool topartistList: true // your favourite artists
        property bool topalbumsList: true // your favourite albums
        property bool toptrackList: true  // your favourite tracks
        property bool personalPlaylistList: true
        property bool dailyMixesList: true // custom mixes
        property bool radioMixesList: true // personal radio stations
        property bool topArtistsList: true // your top artists (most played)
    }

    // Configuration Storage
    ConfigurationValue {
        id: token_type
        key: "/token_type"
    }

    ConfigurationValue {
        id: access_token
        key: "/access_token"
        value: ""
    }

    ConfigurationValue {
        id: refresh_token
        key: "/refresh_token"
    }

    ConfigurationValue {
        id: expiry_time
        key: "/expiry_time"
    }

    ConfigurationValue {
        id: mail
        key: "/mail"
    }

    ConfigurationValue {
        id: audioQuality
        key: "/audioQuality"
        defaultValue: "HIGH"  // Standardwert
    }

    ConfigurationValue {
        id: resumePlayback
        key : "/resumePlayback"
        defaultValue: false
    }

    ConfigurationValue {
        id: hidePlayerOnFinished
        key : "/hidePlayerOnFinished"
        defaultValue: false
    }

    ConfigurationValue {
        id: recentListConfig
        key : "/recentList"
        defaultValue: true
    }

    ConfigurationValue {
        id: yourListConfig
        key : "/yourList"
        defaultValue: true
    }

    ConfigurationValue {
        id: topartistListConfig
        key : "/topartistList"
        defaultValue: true
    }

    ConfigurationValue {
        id: topalbumsListConfig
        key : "/topalbumsList"
        defaultValue: true
    }

    ConfigurationValue {
        id: toptrackListConfig
        key : "/toptrackList"
        defaultValue: true
    }

    ConfigurationValue {
        id: personalPlaylistListConfig
        key : "/personalPlaylistList"
        defaultValue: true
    }

    ConfigurationValue {
        id: dailyMixesListConfig
        key : "/dailyMixesList"
        defaultValue: true
    }
    
    ConfigurationValue {
        id: radioMixesListConfig
        key : "/radioMixesList"
        defaultValue: true
    }
    
    ConfigurationValue {
        id: topArtistsListConfig
        key : "/topArtistsList"
        defaultValue: true
    }

    property int remainingMinutes: 0

    property var sleepTimer: Timer {
        id: sleepTimer
        interval: 60000  // 1 Minute
        repeat: true
        onTriggered: {
            remainingMinutes--
            if (remainingMinutes <= 0) {
                stop()
                mediaController.pause()
                remainingMinutes = 0
            }
        }
    }

    // Funktion zum Starten des Timers
    function startSleepTimer(minutes) {
        console.log(minutes)
        if (minutes > 0) {
            remainingMinutes = minutes
            sleepTimer.start()
            // Optional: Benachrichtigung anzeigen
            //notification.notify(qsTr("Sleep timer set"),
            //    qsTr("Playback will stop in %1")
            //    .arg(Format.formatDuration(minutes * 60, Formatter.DurationLong)))
        }
    }

    // Funktion zum Abbrechen des Timers
    function cancelSleepTimer() {
        sleepTimer.stop()
        remainingMinutes = 0
    }



    TidalApi {
        id: tidalApi
        // its twice defined here in this file, the second time in connections
        /*onLoginFailed: {
            authManager.clearTokens()
            console.log("Login failed")
            pageStack.push(Qt.resolvedUrl("pages/Settings.qml"))
        }*/
    }


    PlaylistManager {
        id: playlistManager
        onCurrentTrackChanged: {
            if (track) {
                tidalApi.playTrackId(track)
            }
        }

    }

    FavoritesManager {
        id: favManager
    }

    TidalCache
    {
        id: cacheManager
    }

    PlaylistStorage {
        id: playlistStorage

        //property string currentPlaylistName: ""

        onPlaylistLoaded: {
            // Wenn eine Playlist geladen wird
            playlistTitle = name;
            playlistManager.forceClearPlayList();
            trackIds.forEach(function(trackId) {
                playlistManager.appendTrack(trackId);
            });
            // Setze die gespeicherte Position
            if (position >= 0) {
                playlistManager.playPosition(position);
            }
        }
    }


    MediaController
    {
        id: mediaController
    }

// MPRIS Player
    MprisPlayer {
        id: mprisPlayer

        // Bereits vorhandene Eigenschaften
        canControl: true
        canGoNext: true
        canGoPrevious: true
        canPause: true
        canPlay: true
        canSeek: true

        serviceName: "tidalplayer"
        identity: "Tidal Music Player"

        // Zusätzliche wichtige Eigenschaften
        canQuit: true
        canSetFullscreen: false
        canRaise: true
        hasTrackList: true
        loopStatus: Mpris.None
        shuffle: false
        volume: mediaController.volume
        position: mediaController.position * 1000 // MPRIS verwendet Mikrosekunden

        // Aktualisierte Metadaten-Funktion
        function updateTrack(track, artist, album) {
            var metadata = {}

            // Pflichtfelder
            metadata[Mpris.metadataToString(Mpris.Title)] = track
            metadata[Mpris.metadataToString(Mpris.Artist)] = [artist] // Array von Künstlern
            metadata[Mpris.metadataToString(Mpris.Album)] = album

            // Zusätzliche wichtige Metadaten
            metadata[Mpris.metadataToString(Mpris.Length)] = mediaController.current_track_duration * 1000000 // Mikrosekunden
            metadata[Mpris.metadataToString(Mpris.TrackNumber)] = playlistManager.currentIndex + 1

            if (mediaController.current_track_image !== "") {
                metadata[Mpris.metadataToString(Mpris.ArtUrl)] = mediaController.current_track_image
            }

            // Eindeutige ID für den Track
            metadata[Mpris.metadataToString(Mpris.TrackId)] = "/org/mpris/MediaPlayer2/track/" +
                playlistManager.currentIndex

            mprisPlayer.metadata = metadata
        }

        // Zusätzliche MPRIS-Signalhandler
        onRaiseRequested: {
            // App in den Vordergrund bringen
            window.raise()
        }

        onQuitRequested: {
            // App beenden
            Qt.quit()
        }

        onVolumeRequested: {
            // Lautstärke ändern
            mediaPlayer.volume = volume
        }

        onSeekRequested: {
            // Position ändern (offset ist in Mikrosekunden)
            var newPos = mediaPlayer.position + (offset / 1000000)
            if (newPos < 0) newPos = 0
            if (newPos > mediaPlayer.duration) newPos = mediaPlayer.duration
            mediaPlayer.seek(newPos)
        }

        onSetPositionRequested: {
            // Absolute Position setzen (position ist in Mikrosekunden)
            mediaPlayer.seek(position / 1000000)
        }
    }

    initialPage: Component {
        FirstPage {
            id: firstpage  // Diese ID wird nun über applicationWindow.firstPage verfügbar
            Component.onCompleted: {
                // Store reference to the page
                applicationWindow.mainPage = this
            }
        }
    }
    cover: CoverPage {
        application: applicationWindow
        //home : firstpage
    }
    allowedOrientations: defaultAllowedOrientations


    MiniPlayer {
        parent: pageStack
        id: miniPlayerPanel
        z:10
    }


    AuthManager {
            id: authManager
        }



    BusyIndicator {
        size: BusyIndicatorSize.Large
        anchors.centerIn: parent
        running: tidalApi.loading
    }

    Connections {
        target: tidalApi
        onOAuthSuccess: {
            authManager.updateTokens(type, token, rtoken, date)
        }
        onOAuthRefresh: {
            authManager.refreshTokens(token)
        }
        onLoginFailed: {
            authManager.clearTokens()
            console.log("Login failed")
            pageStack.push(Qt.resolvedUrl("pages/Settings.qml"))
        }
    }


    Connections
    {
        target: playlistManager
        onCurrentId:
        {
            tidalApi.playTrackId(id)
        }
    }


    Connections
    {
        target: mprisPlayer
        onPlayRequested :
        {
            mediaController.play()
        }

        onPauseRequested :
        {
            mediaController.pause()
        }

        onPlayPauseRequested :
        {
            if (mediaController.playbackState == 1)
            {
                mediaController.pause()
            }
            else if(mediaController.playbackState == 2){
                mediaController.play()
            }
        }

        onNextRequested :
        {
            mediaController.blockAutoNext = true
            playlistManager.nextTrackClicked()
        }

        onPreviousRequested :
        {
            playlistManager.previousTrackClicked()
        }
    }

    Connections
    {
    target: authManager
        onUpdateSettings:
        {
            token_type.value = applicationWindow.settings.token_type
            access_token.value = applicationWindow.settings.access_token
            refresh_token.value = applicationWindow.settings.refresh_token
            expiry_time.value = applicationWindow.settings.expiry_time
            mail.value = applicationWindow.settings.mail
            audioQuality.value = applicationWindow.settings.audio_quality
            resumePlayback.value = applicationWindow.settings.resume_playback
            hidePlayerOnFinished.value = applicationWindow.settings.hide_player

            recentListConfig.value = applicationWindow.settings.recentList
            yourListConfig.value = applicationWindow.settings.yourList
            topartistListConfig.value = applicationWindow.settings.topartistList
            topalbumsListConfig.value = applicationWindow.settings.topalbumsList
            toptrackListConfig.value = applicationWindow.settings.toptrackList
            personalPlaylistListConfig.value = applicationWindow.settings.personalPlaylistList
            dailyMixesListConfig.value = applicationWindow.settings.dailyMixesList
            radioMixesListConfig.value = applicationWindow.settings.radioMixesList
            topArtistsListConfig.value = applicationWindow.settings.topArtistsList
        }
    }

    Component.onCompleted:
    {
        applicationWindow.settings.token_type = token_type.value
        applicationWindow.settings.access_token = access_token.value
        applicationWindow.settings.refresh_token = refresh_token.value
        applicationWindow.settings.expiry_time = expiry_time.value
        applicationWindow.settings.mail = mail.value
        applicationWindow.settings.audio_quality = audioQuality.value
        applicationWindow.settings.resume_playback = resumePlayback.value
        applicationWindow.settings.hide_player = hidePlayerOnFinished.value
        tidalApi.quality = audioQuality.value

        applicationWindow.settings.recentList = recentListConfig.value
        applicationWindow.settings.yourList = yourListConfig.value
        applicationWindow.settings.topartistList = topartistListConfig.value
        applicationWindow.settings.topalbumsList = topalbumsListConfig.value
        applicationWindow.settings.toptrackList = toptrackListConfig.value
        applicationWindow.settings.personalPlaylistList = personalPlaylistListConfig.value

        applicationWindow.settings.dailyMixesList = dailyMixesListConfig.value
        applicationWindow.settings.radioMixesList = radioMixesListConfig.value
        applicationWindow.settings.topArtistsList = topArtistsListConfig.value

        authManager.checkAndLogin()
        mprisPlayer.setCanControl(true)
    }

    Component.onDestruction:
    {
        token_type.value = applicationWindow.settings.token_type
        access_token.value = applicationWindow.settings.access_token
        refresh_token.value = applicationWindow.settings.refresh_token
        expiry_time.value = applicationWindow.settings.expiry_time
        mail.value = applicationWindow.settings.mail
        audioQuality.value = applicationWindow.settings.audio_quality
        resumePlayback.value = applicationWindow.settings.resume_playback
        hidePlayerOnFinished.value = applicationWindow.settings.hide_player

        recentListConfig.value = applicationWindow.settings.recentList
        yourListConfig.value = applicationWindow.settings.yourList
        topartistListConfig.value = applicationWindow.settings.topartistList
        topalbumsListConfig.value = applicationWindow.settings.topalbumsList
        toptrackListConfig.value = applicationWindow.settings.toptrackList
        personalPlaylistListConfig.value = applicationWindow.settings.personalPlaylistList

        dailyMixesListConfig.value = applicationWindow.settings.dailyMixesList
        radioMixesListConfig.value = applicationWindow.settings.radioMixesList
        topArtistsListConfig.value = applicationWindow.settings.topArtistsList
    }

}
