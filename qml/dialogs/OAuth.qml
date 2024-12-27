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

        onLoadingChanged: {
            if (loadRequest.status === WebView.LoadSucceededStatus) {
                var script = "function fillEmail() {" +
                    "var emailInput = document.querySelector('input[type=\"email\"]') || " +
                    "document.querySelector('input[name=\"email\"]') || " +
                    "document.querySelector('#email');" +
                    "if (emailInput) {" +
                    "    emailInput.value = '" + mail.value + "';" +
                    "    emailInput.dispatchEvent(new Event('input'));" +
                    "    emailInput.dispatchEvent(new Event('change'));" +
                    "}" +
                    "};" +
                    "fillEmail();" +
                    "setTimeout(fillEmail, 500);";

                webView.runJavaScript(script);
            }
        }
    }

    Connections {
        target: pythonApi
        onAuthUrl: {
            console.log(url)
            webView.url = "https://" + url
        }

        onLoginSuccess: {
            accountSettings.canAccept = true
            accountSettings.accept()
            loginTrue = true
            authManager.checkAndLogin()
        }

        onLoginFailed: {
            mainLabel.text = "Failed"
            loginTrue = false
        }
    }

    Component.onCompleted: {
        pythonApi.getOAuth()
    }
}
