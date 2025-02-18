import QtQuick 2.0
import Sailfish.Silica 1.0

Dialog {
    id: dialog

    property string playlistName: nameField.text
    property string suggestedName: ""  // Wird von der AlbumPage übergeben

    canAccept: nameField.text.length > 0

    Column {
        width: parent.width
        spacing: Theme.paddingMedium

        DialogHeader {
            title: qsTr("Save as Playlist")
        }

        TextField {
            id: nameField
            width: parent.width
            placeholderText: qsTr("Enter playlist name")
            label: qsTr("Playlist name")
            text: suggestedName  // Verwendet den übergebenen Albumtitel
            EnterKey.enabled: text.length > 0
            EnterKey.iconSource: "image://theme/icon-m-enter-accept"
            EnterKey.onClicked: dialog.accept()
        }

        Label {
            x: Theme.horizontalPageMargin
            width: parent.width - 2*x
            text: qsTr("This will create a new playlist from all tracks in this album.")
            wrapMode: Text.Wrap
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.secondaryColor
        }
    }
}
