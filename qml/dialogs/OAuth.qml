import QtQuick 2.0
import Sailfish.Silica 1.0
import io.thp.pyotherside 1.5
import Sailfish.WebView 1.0
import Sailfish.WebEngine 1.0
import Sailfish.WebView.Popups 1.0
import Nemo.Configuration 1.0

Dialog {
    id: accountSettings
    allowedOrientations: Orientation.All
    canAccept: false

    // OAuth 2.1 Web Flow properties - Claude Generated
    property string redirectUri: "http://localhost:8080/callback"
    property bool useWebFlow: true  // Prefer new OAuth 2.1 Web Flow
    property bool debugOAuth: applicationWindow.settings.debugLevel >= 1

    ConfigurationValue {
        id: mail
        key: "/mail"
    }

    // Loading indicator for OAuth process - Claude Generated
    BusyIndicator {
        id: loadingIndicator
        anchors.centerIn: parent
        size: BusyIndicatorSize.Large
        running: !webView.visible
        visible: running
    }

    Label {
        id: statusLabel
        anchors.centerIn: parent
        anchors.verticalCenterOffset: loadingIndicator.height + Theme.paddingLarge
        text: qsTr("Loading TIDAL authentication...")
        color: Theme.highlightColor
        visible: loadingIndicator.visible
    }

    WebView {
        width: parent.width
        anchors.horizontalCenter: parent.horizontalCenter
        id: webView
        anchors.fill: parent
        visible: false

        url: "http://www.sailfishos.org"
        httpUserAgent: "Mozilla/5.0 (Mobile; rv:78.0) Gecko/78.0 Firefox/78.0"

        popupProvider: PopupProvider { }
        
        // OAuth 2.1 Web Flow: Monitor URL changes for callback - Claude Generated
        onUrlChanged: {
            var currentUrl = url.toString()
            
            if (debugOAuth) {
                console.log("OAuth WebView URL changed:", currentUrl)
            }
            
            // Check if this is our OAuth callback
            if (currentUrl.indexOf(redirectUri) === 0) {
                if (debugOAuth) {
                    console.log("OAuth callback detected, parsing parameters...")
                }
                handleOAuthCallback(currentUrl)
            }
        }
        
        onLoadingChanged: {
            if (loading === false) {
                visible = true
                loadingIndicator.running = false
                statusLabel.visible = false
            } else {
                if (debugOAuth) {
                    console.log("OAuth WebView loading...")
                }
            }
        }
    }

    // Parse OAuth callback URL parameters - Claude Generated
    function handleOAuthCallback(callbackUrl) {
        try {
            var url = callbackUrl.replace(redirectUri, "")
            if (!url.startsWith("?")) {
                console.log("OAuth callback URL has no parameters")
                return
            }
            
            var params = {}
            var queryString = url.substring(1) // Remove '?'
            var pairs = queryString.split('&')
            
            for (var i = 0; i < pairs.length; i++) {
                var pair = pairs[i].split('=')
                if (pair.length === 2) {
                    params[decodeURIComponent(pair[0])] = decodeURIComponent(pair[1])
                }
            }
            
            if (debugOAuth) {
                console.log("OAuth callback parameters:", JSON.stringify(params))
            }
            
            // Check for authorization code (success)
            if (params.code && params.state) {
                console.log("OAuth authorization code received, exchanging for tokens...")
                statusLabel.text = qsTr("Authorization successful, getting tokens...")
                statusLabel.visible = true
                webView.visible = false
                loadingIndicator.running = true
                
                // Exchange code for tokens
                tidalApi.exchange_authorization_code(params.code, params.state)
                
            } else if (params.error) {
                // OAuth error
                var errorMsg = params.error_description || params.error || "Unknown OAuth error"
                console.log("OAuth error:", errorMsg)
                statusLabel.text = qsTr("Authentication failed: ") + errorMsg
                statusLabel.color = Theme.errorColor
                
                // Auto-dismiss after showing error
                errorTimer.start()
            } else {
                console.log("OAuth callback with unexpected parameters")
            }
            
        } catch (e) {
            console.log("Error parsing OAuth callback:", e.toString())
        }
    }
    
    // Auto-dismiss timer for errors - Claude Generated
    Timer {
        id: errorTimer
        interval: 5000
        onTriggered: {
            accountSettings.reject()
        }
    }

    Connections {
        target: tidalApi
        
        // Handle both old and new OAuth signals - Claude Generated
        onAuthUrl: {
            if (debugOAuth) {
                console.log("OAuth URL received:", url)
            }
            
            // For compatibility: old device flow adds "https://" prefix
            var authUrl = (url.indexOf("https://") === 0) ? url : "https://" + url
            
            // Copy email to clipboard for device flow compatibility
            Clipboard.text = mail.value
            
            // Load the authorization URL
            webView.url = authUrl
        }

        onLoginSuccess: {
            if (debugOAuth) {
                console.log("OAuth login successful")
            }
            accountSettings.canAccept = true
            accountSettings.accept()
            authManager.checkAndLogin()
        }

        onLoginFailed: {
            console.log("OAuth login failed")
            statusLabel.text = qsTr("Login failed")
            statusLabel.color = Theme.errorColor
            errorTimer.start()
        }
        
        // New OAuth 2.1 signals - Claude Generated
        onOauthFailed: {
            console.log("OAuth 2.1 failed:", message || "Unknown error")
            statusLabel.text = qsTr("Authentication failed: ") + (message || "Unknown error")
            statusLabel.color = Theme.errorColor
            errorTimer.start()
        }
    }

    Component.onCompleted: {
        if (useWebFlow) {
            console.log("Starting OAuth 2.1 Web Flow with PKCE")
            tidalApi.request_oauth_web()
        } else {
            console.log("Starting legacy OAuth device flow")
            tidalApi.getOAuth()
        }
    }
}
