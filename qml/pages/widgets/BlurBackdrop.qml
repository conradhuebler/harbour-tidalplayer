// Claude Generated — the current artwork, blurred and dimmed, as a page
// backdrop. Ported from qml-tidalplayer/qml/pages/BlurBackdrop.qml; uses
// FastBlur (Qt 5.6) on a downscaled copy of the artwork so the effect stays
// cheap on device. Falls back to a plain surface while no artwork is there.
import QtQuick 2.0
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0

Item {
    id: backdrop

    property url source
    // How far the artwork is pushed towards the page background (0..1).
    property real dim: 0.55
    property real blurRadius: 48
    // Fades the backdrop out towards the bottom edge of the item.
    property bool fadeOut: true
    // Honour the global artwork switch; without it the backdrop is a plain
    // surface, which is also what a device with effects turned off shows.
    property bool effects: applicationWindow.settings ? applicationWindow.settings.blurBackdrops : true

    clip: true

    Image {
        id: art
        anchors.fill: parent
        source: backdrop.effects ? backdrop.source : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        visible: false
        // The blur destroys the detail anyway - decode small.
        sourceSize.width: 128
        sourceSize.height: 128
    }

    FastBlur {
        anchors.fill: parent
        source: art
        radius: backdrop.blurRadius
        visible: backdrop.effects && art.status === Image.Ready
        cached: true
    }

    // Scrim: keeps text on top readable whatever the artwork does.
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: Theme.rgba(Theme.overlayBackgroundColor, backdrop.dim * 0.75)
            }
            GradientStop {
                position: 1.0
                color: Theme.rgba(Theme.overlayBackgroundColor,
                                  backdrop.fadeOut ? 1.0 : backdrop.dim)
            }
        }
    }
}
