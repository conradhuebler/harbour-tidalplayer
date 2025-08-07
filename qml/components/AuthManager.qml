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
        console.log("Update tokens", "expiry from server:", expiry)
        
        applicationWindow.settings.token_type = type
        applicationWindow.settings.access_token = token
        applicationWindow.settings.refresh_token = rtoken
        
        // Convert expiry to Unix timestamp if it's a string
        var expiryTime = expiry
        if (typeof expiry === "string") {
            var expiryDate = new Date(expiry)
            expiryTime = Math.floor(expiryDate.getTime() / 1000)
            console.log("Converted expiry date to timestamp:", expiry, "->", expiryTime)
        } else if (typeof expiry === "number") {
            expiryTime = expiry
        }
        
        applicationWindow.settings.expiry_time = expiryTime
        updateSettings()
    }

    function refreshTokens(token, rtoken, expiry) {
        if (settings.debugLevel >= 3) {
            console.log("AUTH: Refresh tokens - new_token:", token, "new_expiry:", expiry)
        } else if (settings.debugLevel >= 1) {
            console.log("AUTH: Token refreshed (length:", token.length, "chars) expiry:", expiry)
        }
        
        applicationWindow.settings.access_token = token
        if (rtoken) applicationWindow.settings.refresh_token = rtoken
        
        if (expiry) {
            // Convert expiry to Unix timestamp if it's a string
            var expiryTime = expiry
            if (typeof expiry === "string") {
                var expiryDate = new Date(expiry)
                expiryTime = Math.floor(expiryDate.getTime() / 1000)
                console.log("Converted refresh expiry date to timestamp:", expiry, "->", expiryTime)
            }
            applicationWindow.settings.expiry_time = expiryTime
        }
        updateSettings()
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
            console.log("old token invalid, attempting refresh");
            tidalApi.loginIn(applicationWindow.settings.token_type,
                                applicationWindow.settings.refresh_token,  // Als access_token für refresh
                                applicationWindow.settings.refresh_token,  // Als refresh_token
                                applicationWindow.settings.expiry_time)
        }

    }

    function isTokenValid() {
        console.log("Token check - expiry:", applicationWindow.settings.expiry_time, "current:", Math.floor(new Date().getTime() / 1000))
        var currentUnixTime = Math.floor(new Date().getTime() / 1000)
        // Check if expiry_time is set and valid (not -1 or 0)
        if (!applicationWindow.settings.expiry_time || applicationWindow.settings.expiry_time <= 0) {
            console.log("Token invalid - no expiry time set")
            return false
        }
        var isValid = applicationWindow.settings.expiry_time > currentUnixTime
        console.log("Token valid:", isValid, "expires in:", (applicationWindow.settings.expiry_time - currentUnixTime), "seconds")
        return isValid
    }

    function clearTokens() {
        // Check if user wants to stay logged in
        if (applicationWindow.settings.stay_logged_in) {
            console.log("Stay logged in is enabled - not clearing tokens")
            return
        }
        
        console.log("Clearing authentication tokens")
        applicationWindow.settings.token_type = ""
        applicationWindow.settings.access_token = ""
        applicationWindow.settings.refresh_token = ""
        applicationWindow.settings.expiry_time = ""
        updateSettings()
    }
}
