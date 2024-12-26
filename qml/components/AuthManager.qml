// AuthManager.qml
import QtQuick 2.0
import Nemo.Configuration 1.0

Item {
    id: root

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

    // Funktionen zum Token-Management
    function updateTokens(type, token, rtoken, expiry) {
        token_type.value = type
        access_token.value = token
        refresh_token.value = rtoken
        expiry_time.value = expiry
        isLoggedIn = true
    }

    function checkAndLogin() {
        if (token_type.value && access_token.value) {
            if (isTokenValid()) {
                tidalApi.loginIn(token_type.value,
                                access_token.value,
                                refresh_token.value,
                                expiry_time.value)
            } else {
                // Token abgelaufen, mit Refresh Token versuchen
                tidalApi.loginIn(token_type.value,
                                refresh_token.value,
                                refresh_token.value,
                                expiry_time.value)
            }
        }
    }

    function isTokenValid() {
        if (!expiry_time.value) return false
        return Date.fromLocaleString(Qt.locale(),
                                   expiry_time.value,
                                   "yyyy-MM-ddThh:mm:ss") > currentDate
    }

    function clearTokens() {
        token_type.value = ""
        access_token.value = ""
        refresh_token.value = ""
        expiry_time.value = ""
        isLoggedIn = false
    }
}
