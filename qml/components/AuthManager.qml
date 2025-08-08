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
        
        // Show token refresh notification
        applicationWindow.showInfoNotification(qsTr("Session Renewed"), qsTr("Authentication token refreshed automatically"))
        
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
        // Check if we have any authentication data at all
        if (!applicationWindow.settings.access_token || 
            !applicationWindow.settings.refresh_token ||
            applicationWindow.settings.access_token === "" ||
            applicationWindow.settings.refresh_token === "") {
            
            if (applicationWindow.settings.debugLevel >= 1) {
                console.log("AUTH: No valid tokens found, skipping auto-login")
            }
            return
        }
        
        if (isTokenValid()) {
            if (applicationWindow.settings.debugLevel >= 1) {
                console.log("AUTH: Token valid, attempting login")
            }
            tidalApi.loginIn(applicationWindow.settings.token_type,
                                applicationWindow.settings.access_token,
                                applicationWindow.settings.refresh_token,
                                applicationWindow.settings.expiry_time)
        } else {
            // Token abgelaufen, mit Refresh Token versuchen
            if (applicationWindow.settings.debugLevel >= 1) {
                console.log("AUTH: Token expired, attempting refresh")
            }
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
            if (applicationWindow.settings.debugLevel >= 1) {
                console.log("AUTH: Stay logged in is enabled - not clearing tokens")
            }
            return
        }
        
        _performTokenClear("automatic logout")
    }
    
    function forceLogout() {
        // Force logout regardless of stay_logged_in setting
        if (applicationWindow.settings.debugLevel >= 1) {
            console.log("AUTH: Force logout - ignoring stay_logged_in setting")
        }
        _performTokenClear("manual logout")
    }
    
    function _performTokenClear(reason) {
        if (applicationWindow.settings.debugLevel >= 1) {
            console.log("AUTH: Clearing authentication tokens (" + reason + ")")
        }
        
        // Show logout notification
        if (reason === "manual logout") {
            applicationWindow.showSuccessNotification(qsTr("Logged Out"), qsTr("Successfully logged out. Session cleared."))
        } else if (reason === "token expired") {
            applicationWindow.showWarningNotification(qsTr("Session Expired"), qsTr("Your session has expired. Please log in again."))
        }
        
        // Clear QML settings (but keep email for easy re-login)
        applicationWindow.settings.token_type = ""
        applicationWindow.settings.access_token = ""
        applicationWindow.settings.refresh_token = ""
        applicationWindow.settings.expiry_time = ""
        
        // Keep email address for debugging/development convenience
        if (applicationWindow.settings.debugLevel >= 1) {
            console.log("AUTH: Keeping email address for easier re-login:", applicationWindow.settings.mail)
        }
        
        // Clear loginTrue flag
        tidalApi.loginTrue = false
        
        // Stop current playback completely
        try {
            if (mediaController) {
                mediaController.stop()
                mediaController.setSource("")  // Clear source
                if (applicationWindow.settings.debugLevel >= 2) {
                    console.log("AUTH: Media playback stopped and source cleared")
                }
            }
            
            // Clear playlist
            if (playlistManager) {
                playlistManager.clearPlayList()
                if (applicationWindow.settings.debugLevel >= 2) {
                    console.log("AUTH: Playlist cleared")
                }
            }
        } catch (e) {
            if (applicationWindow.settings.debugLevel >= 1) {
                console.log("AUTH: Warning - could not stop playback:", e)
            }
        }
        
        // Clear resume playback data (user-specific)
        applicationWindow.settings.last_track_url = ""
        applicationWindow.settings.last_track_id = ""
        applicationWindow.settings.last_track_position = 0.0
        
        // Clear cache (user-specific data)
        if (cacheManager && cacheManager.clearAllCache) {
            try {
                cacheManager.clearAllCache()
                if (applicationWindow.settings.debugLevel >= 2) {
                    console.log("AUTH: Cache cleared")
                }
            } catch (e) {
                if (applicationWindow.settings.debugLevel >= 1) {
                    console.log("AUTH: Warning - could not clear cache:", e)
                }
            }
        }
        
        // Notify Python backend to clear session
        if (tidalApi && tidalApi.pythonTidal) {
            try {
                tidalApi.pythonTidal.call('tidal.Tidaler.clearSession', [])
                if (applicationWindow.settings.debugLevel >= 2) {
                    console.log("AUTH: Notified Python backend to clear session")
                }
            } catch (e) {
                if (applicationWindow.settings.debugLevel >= 1) {
                    console.log("AUTH: Warning - could not notify Python backend:", e)
                }
            }
        }
        
        // Force settings update to persist cleared values
        updateSettings()
        
        // Double-check: Force clear resume data in persistent storage
        try {
            if (typeof lastTrackUrl !== "undefined") lastTrackUrl.value = ""
            if (typeof lastTrackId !== "undefined") lastTrackId.value = ""
            if (typeof lastTrackPosition !== "undefined") lastTrackPosition.value = 0.0
            
            if (applicationWindow.settings.debugLevel >= 2) {
                console.log("AUTH: Forced clear of persistent resume data")
            }
        } catch (e) {
            if (applicationWindow.settings.debugLevel >= 1) {
                console.log("AUTH: Warning - could not force clear resume data:", e)
            }
        }
        
        if (applicationWindow.settings.debugLevel >= 1) {
            console.log("AUTH: Token clearing completed")
        }
    }
}
