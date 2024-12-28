// AuthManager.qml
import QtQuick 2.0
import Nemo.Configuration 1.0

Item {
    id: authManager

    // Properties
    property bool isLoggedIn: false
    property date currentDate: new Date()

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

    // Funktionen zum Token-Management
    function updateTokens(type, token, rtoken, expiry) {
        console.log("Update tokes")
        var currentUnixTime = Math.floor(new Date().getTime() / 1000)
        var oneWeekLater = currentUnixTime + 604800

        token_type.value = type
        access_token.value = token
        refresh_token.value = rtoken
        expiry_time.value = oneWeekLater
        isLoggedIn = true
    }

    function checkAndLogin() {
        pythonApi.quality = audioQuality.value
        if (token_type.value && access_token.value) {
            if (isTokenValid()) {
                console.log("old token valid");
                console.log(token_type.value, access_token.value)
                pythonApi.loginIn(token_type.value,
                                access_token.value,
                                refresh_token.value,
                                expiry_time.value)
            } else {
                // Token abgelaufen, mit Refresh Token versuchen
                console.log("old token invalid");
                pythonApi.loginIn(token_type.value,
                                refresh_token.value,
                                refresh_token.value,
                                expiry_time.value)
            }
        }
    }

    function isTokenValid() {

        var currentUnixTime = Math.floor(new Date().getTime() / 1000)
        if (!expiry_time.value) return false
        return expiry_time.value > currentUnixTime
    }

    function clearTokens() {
        token_type.value = ""
        access_token.value = ""
        refresh_token.value = ""
        expiry_time.value = ""
        isLoggedIn = false
    }
}
