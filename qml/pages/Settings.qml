import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Configuration 1.0

Page {
    id: page
    allowedOrientations: Orientation.All

    ConfigurationValue {
        id: mail
        key: "/mail"
    }

    ConfigurationValue {
        id: audioQuality
        key: "/audioQuality"
        defaultValue: "HIGH"  // Standardwert
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge

            PageHeader {
                title: qsTr("Settings")
            }

            SectionHeader {
                text: qsTr("Account")
            }

            TextField {
                id: emailField
                width: parent.width
                text: mail.value || ""
                label: qsTr("Email address")
                placeholderText: qsTr("Enter your email")
                EnterKey.enabled: text.length > 0
                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: focus = false

                onTextChanged: {
                    mail.value = text
                }
            }

            Item {
                width: parent.width
                height: Theme.paddingLarge
            }

            TextSwitch {
                visible: loginTrue
                text: qsTr("Stay logged in")
                description: qsTr("Keep your session active")
                // Verbinde dies mit deiner Konfiguration
                checked: false
            }

            Button {
                anchors {
                    left: parent.left
                    right: parent.right
                    margins: Theme.horizontalPageMargin
                }
                text: qsTr("Login with Tidal")
                visible: !loginTrue
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("../dialogs/OAuth.qml"))
                }
            }

            Button {
                anchors {
                    left: parent.left
                    right: parent.right
                    margins: Theme.horizontalPageMargin
                }
                text: qsTr("Logout")
                visible: loginTrue
                onClicked: {
                    authManager.clearTokens()
                    token_type.value = "clear"
                    access_token.value = "clear"
                    loginTrue = false
                }
            }

            SectionHeader {
                text: qsTr("Playback")
                visible: loginTrue
            }

            ComboBox {
                visible: loginTrue
                label: qsTr("Audio Quality")
                    currentIndex: 1 // Default auf HIGH
                    description: qsTr("Select streaming quality")
                    menu: ContextMenu {
                        MenuItem { text: qsTr("Low (96 kbps)") }
                        MenuItem { text: qsTr("High (320 kbps)") }
                        MenuItem { text: qsTr("Lossless (FLAC)") }
                        MenuItem { text: qsTr("Master (MQA)") }
                    }
                    onCurrentIndexChanged: {
                           var qualities = ["LOW", "HIGH", "LOSSLESS", "HI_RES"]
                           audioQuality.value = qualities[currentIndex]
                       }
            }
        }

        VerticalScrollDecorator {}
    }
}
