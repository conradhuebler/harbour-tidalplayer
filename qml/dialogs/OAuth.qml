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

    WebView {
            width: parent.width
            anchors.horizontalCenter: parent.horizontalCenter

            id: webView

            anchors.fill: parent

               url: "http://www.sailfishos.org"
               //privateMode: true
               httpUserAgent: "Mozilla/5.0 (Mobile; rv:78.0) Gecko/78.0"
                   + " Firefox/78.0"

               popupProvider: PopupProvider {
                    // Disable the Save Password dialog
                    //passwordManagerPopup: null
               }
        }

        Connections {
            target: pythonApi
            onAuthUrl:
            {
                console.log(url)
                webView.load("https://" + url)
            }

            onLoginSuccess:
            {
                accountSettings.canAccept = true
                accountSettings.accept()
                loginTrue = true

                pythonApi.logIn()
            }

            onLoginFailed:
            {
                mainLabel.text = "Failed";
                loginTrue = false
            }
        }

     Component.onCompleted: {
      pythonApi.getOAuth()
     }
}

