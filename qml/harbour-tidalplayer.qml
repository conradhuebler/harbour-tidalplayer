import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.tidalplayer 1.0

import "pages"
import "pages/widgets"

ApplicationWindow
{
    initialPage: Component { FirstPage { } }
    cover: Qt.resolvedUrl("cover/CoverPage.qml")
    allowedOrientations: defaultAllowedOrientations
    Connections{
        target: Settings
        onAutoLoginSet :
        {
            console.log(Settings.AutoLogin)
            console.log("Call login")

            PythonApi.setLogin(Settings.loginname, Settings.loginpasswort)
        }
    }

    Component.onCompleted: {
        Settings.CheckLogin
    }
}
