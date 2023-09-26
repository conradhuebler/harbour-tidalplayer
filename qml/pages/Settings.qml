import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Configuration 1.0

Page {
    id: page

    // The effective value will be restricted by ApplicationWindow.allowedOrientations
    allowedOrientations: Orientation.All

    SilicaListView {
        id: listView
        //model: 20
        anchors.fill: parent
        header: PageHeader {
            title: qsTr("Settings")
        }
        delegate: BackgroundItem {
            id: delegate


        }
        //VerticalScrollDecorator {}

     width: parent.width

     spacing: Theme.paddingLarge

        Button {
            id:loginButton
            text: "Tidal Login via OAuth"
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            visible: !loginTrue
            onClicked: {
                var dialog = pageStack.push(Qt.resolvedUrl("../dialogs/OAuth.qml"))
            }
        }

        Button {
            id:logoutButton

            text: "Remove Session"
            anchors.horizontalCenter: loginButton.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            visible: loginTrue

            onClicked: {
                token_type.value = "clear"
                access_token.value = "clear"
                loginTrue = false
            }
        }



    }


}
