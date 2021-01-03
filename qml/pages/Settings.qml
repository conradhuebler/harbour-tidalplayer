import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page

    // The effective value will be restricted by ApplicationWindow.allowedOrientations
    allowedOrientations: Orientation.All
    /*
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
        VerticalScrollDecorator {}
    }*/

    Button {
        text: "Account details"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        onClicked: {
            var dialog = pageStack.push(Qt.resolvedUrl("../dialogs/Account.qml"))
            dialog.accepted.connect(function() {
                //python.login(dialog.name, dialog.passwort)
            })
        }
    }
}
