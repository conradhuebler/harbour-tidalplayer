import QtQuick 2.0
import Nemo.Configuration 1.0

Item {
    id: root

    // Signals
    signal loginStateChanged(bool isLoggedIn)
    signal tokenUpdated()

    // Properties
    property bool isLoggedIn: false
    property date currentDate: new Date()
    readonly property alias accessToken: access_token.value
    readonly property alias tokenType: token_type.value
    readonly property alias refreshToken: refresh_token.value
    readonly property alias expiryTime: expiry_time.value

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

    // Public Functions
    function updateTokens(type, token, rtoken, expiry) {
        token_type.value = type
        access_token.value = token
        refresh_token.value = rtoken
        expiry_time.value = expiry

        isLoggedIn = true
        tokenUpdated()
        loginStateChanged(true)
    }

    function clearTokens() {
        token_type.value = ""
        access_token.value = ""
        refresh_token.value = ""
        expiry_time.value = ""

        isLoggedIn = false
        loginStateChanged(false)
    }

    function isTokenValid() {
        if (!expiry_time.value) return false
        return Date.fromLocaleString(Qt.locale(),
                                   expiry_time.value,
                                   "yyyy-MM-ddThh:mm:ss") > currentDate
    }

    function getLoginCredentials() {
        return {
            tokenType: token_type.value,
            accessToken: access_token.value,
            refreshToken: refresh_token.value,
            expiryTime: expiry_time.value
        }
    }

    // Debug Function
    function printLoginState() {
        console.log("Token Type:", token_type.value)
        console.log("Access Token:", access_token.value)
        console.log("Refresh Token:", refresh_token.value)
        console.log("Expiry Time:", expiry_time.value)
        console.log("Is Valid:", isTokenValid())
    }
}
