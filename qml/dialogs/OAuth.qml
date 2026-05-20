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

    ConfigurationValue {
        id: mail
        key: "/mail"
    }

    // Error banner for login failures
    Rectangle {
        id: errorBanner
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: errorLabel.height + 2 * Theme.paddingLarge
        color: Theme.rgba(Theme.errorColor, 0.3)
        z: 100
        visible: false

        Label {
            id: errorLabel
            anchors.centerIn: parent
            width: parent.width - 2 * Theme.horizontalPageMargin
            text: qsTr("Login failed. Please try again.")
            color: Theme.primaryColor
            font.pixelSize: Theme.fontSizeSmall
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
        }

        Timer {
            id: errorTimer
            interval: 5000
            onTriggered: errorBanner.visible = false
        }
    }

    WebView {
        width: parent.width
        anchors.horizontalCenter: parent.horizontalCenter
        id: webView
        anchors.fill: parent

        url: "http://www.sailfishos.org"
        httpUserAgent: "Mozilla/5.0 (Mobile; rv:78.0) Gecko/78.0 Firefox/78.0"

        popupProvider: PopupProvider { }
    }

    Connections {
        target: tidalApi
        onAuthUrl: {
            console.log(url)
            Clipboard.text = mail.value
            webView.url = "https://" + url
        }

        onLoginSuccess: {
            accountSettings.canAccept = true
            accountSettings.accept()
            authManager.checkAndLogin()
        }

        onLoginFailed: {
            console.error("OAuth: Login failed")
            errorBanner.visible = true
            errorTimer.start()
        }
    }

    Component.onCompleted: {
        tidalApi.getOAuth()
    }
}
