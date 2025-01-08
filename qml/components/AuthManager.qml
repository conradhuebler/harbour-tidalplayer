// AuthManager.qml
import QtQuick 2.0
import Nemo.Configuration 1.0

Item {
    id: root

    // Properties
    property date currentDate: new Date()
    signal updateSettings()

    // Funktionen zum Token-Management
    function updateTokens(type, token, rtoken, expiry) {
        console.log("Update tokens")
        var currentUnixTime = Math.floor(new Date().getTime() / 1000)
        var oneWeekLater = currentUnixTime + 604800

        applicationWindow.settings.token_type = type
        applicationWindow.settings.access_token = token
        applicationWindow.settings.refresh_token = rtoken
        applicationWindow.settings.expiry_time = oneWeekLater
    }

    function refreshTokens(token) {
        console.log("Update tokens", token)
        var currentUnixTime = Math.floor(new Date().getTime() / 1000)
        var oneWeekLater = currentUnixTime + 604800

        applicationWindow.settings.access_token= token
        applicationWindow.settings.expiry_time= oneWeekLater
    }

    function checkAndLogin() {
        if (isTokenValid()) {
            console.log("old token valid");
            console.log(applicationWindow.settings.token_type, applicationWindow.settings.access_token)
            tidalApi.loginIn(applicationWindow.settings.token_type,
                                applicationWindow.settings.access_token,
                                applicationWindow.settings.refresh_token,
                                applicationWindow.settings.expiry_time)
            } else {
            // Token abgelaufen, mit Refresh Token versuchen
            console.log("old token invalid");
            tidalApi.loginIn(applicationWindow.settings.token_type,
                                applicationWindow.settings.refresh_token,
                                applicationWindow.settings.refresh_token,
                                applicationWindow.settings.expiry_time)
        }

    }

    function isTokenValid() {
        console.log(applicationWindow.settings.expiry_time, applicationWindow.settings.access_token)
        var currentUnixTime = Math.floor(new Date().getTime() / 1000)
        if (!applicationWindow.settings.expiry_time) return false
        return applicationWindow.settings.expiry_time> currentUnixTime
    }

    function clearTokens() {
        applicationWindow.settings.token_type = ""
        applicationWindow.settings.access_token = ""
        applicationWindow.settings.refresh_token = ""
        applicationWindow.settings.expiry_time = ""
        isLoggedIn = false
    }
}
