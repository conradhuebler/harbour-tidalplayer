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
            //mainLabel.text = "Failed" //<- mainLabel is not defined
        }
    }

    Component.onCompleted: {
        tidalApi.getOAuth()
    }
}
