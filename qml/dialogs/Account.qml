import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.tidalplayer 1.0

Dialog {
    id: accountSettings
    allowedOrientations: Orientation.All
    canAccept: false

    property string name
    property string passwort


    Column {
        width: parent.width

        DialogHeader {

        }
        Button {
            anchors.horizontalCenter: parent.horizontalCenter
            id: testCredentials
            text: qsTr("Test login")
            //enabled: loginName.text && token.text && !busyCreds.running
            onClicked: {
                busyCreds.running = true
                PythonApi.setLogin(nameField.text, passwordField.text)
            }

            BusyIndicator {
                anchors.centerIn: testCredentials
                id: busyCreds
            }
        }
        TextField {
            id: nameField
            width: parent.width
            placeholderText: "Enter login name"
            text : Settings.loginname
            label: "Name"
            onTextChanged:
            {
                accountSettings.canAccept = false
            }
        }

        TextSwitch {
            id: saveLoginSwitch
            width: parent.width
            //% "Save password"
            text: "Save login name. It will be stored in clear text."
            checked: Settings.saveLogin
            //% "Save password to the encrypted device storage to perform automatic re-login."
            description: qsTrId("tidal-save-login-help")

        }
        PasswordField {
            id: passwordField
            placeholderText: "Enter passwort"
            text: Settings.loginpasswort
            EnterKey.iconSource: "image://theme/icon-m-enter-accept"
            //    EnterKey.onClicked: dialog.accept()
            onTextChanged:
            {
                accountSettings.canAccept = false
            }
        }

        TextSwitch {
            id: savePasswordSwitch
            width: parent.width
            //% "Save password"
            text: "Save passwort, it will be stored encrypted!"
            //% "Save password to the encrypted device storage to perform automatic re-login."
            checked: Settings.savePasswort >= 1
            description: qsTrId("tidal-save-password-help")
            onClicked: {
                savePasswordSwitchPlain.enabled = savePasswordSwitch.checked
            }
        }
        TextSwitch {
            id: savePasswordSwitchPlain
            width: parent.width
            //% "Save password"
            text: "Save unencrypted!"
            //% "Save password to the encrypted device storage to perform automatic re-login."
            enabled: (Settings.savePasswort >= 2)
            checked: (Settings.savePasswort == 2)
            description: qsTrId("tidal-save-password-help")
        }

        InfoLabel
        {
            id: loginResult
        }
    }




    onDone: {
        if (result == DialogResult.Accepted) {
            name = nameField.text
            passwort = passwordField.text
            Settings.setLoginData(name, passwort, saveLoginSwitch.checked, (savePasswordSwitch.checked + savePasswordSwitchPlain.checked))
        }
    }
    Connections {
        target: PythonApi
        onLoginStateChanged:
        {
            busyCreds.running = false;
            accountSettings.canAccept = PythonApi.loginState;
            if(PythonApi.loginState == true)
            {
                loginResult.text = "Login was successful"
            }else
            {
                loginResult.text = "Login failed, sorry for that"
            }
        }
    }
}

