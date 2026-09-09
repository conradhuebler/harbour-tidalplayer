// Claude Generated — artwork tile: rounded corners, hairline edge, optional
// drop shadow and an optional mirrored reflection below the artwork.
// Ported from the desktop player (qml-tidalplayer/qml/pages/CoverImage.qml),
// rebuilt on QtGraphicalEffects 1.0 for Qt 5.6 / Silica.
//
// The heavier effects are opt-in per use site: `elevation` and `reflection`
// default to 0, so a list of covers costs little more than a plain Image.
// `settings.artworkEffects` switches the whole treatment off.
import QtQuick 2.0
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0

Item {
    id: cover

    property url source
    property string fallbackIcon: "image://theme/icon-m-media-albums"
    // Global kill switch for the artwork treatment.
    property bool effects: applicationWindow.settings ? applicationWindow.settings.artworkEffects : true
    property real radius: effects ? Theme.paddingMedium : 0
    // Shadow depth in pixels; 0 turns the shadow off.
    property real elevation: 0
    // Height of the reflection as a fraction of the artwork; 0 turns it off.
    property real reflection: 0
    // Downscale hint for the decoder; 0 leaves the source untouched.
    property int sourceSize: 0

    readonly property bool loaded: art.status === Image.Ready
    readonly property bool _shadowed: effects && elevation > 0
    readonly property bool _reflected: effects && reflection > 0 && art.status === Image.Ready

    implicitWidth: Theme.itemSizeExtraLarge
    implicitHeight: Theme.itemSizeExtraLarge

    // ---- shadow ---------------------------------------------------------
    // RectangularGlow, not DropShadow: it draws the glow alone, while
    // DropShadow would redraw the artwork underneath its own copy.
    RectangularGlow {
        x: frame.x
        y: frame.y + Math.round(cover.elevation / 2)
        width: frame.width
        height: frame.height
        visible: cover._shadowed
        glowRadius: cover.elevation * 1.5
        spread: 0.1
        color: Qt.rgba(0, 0, 0, 0.55)
        cornerRadius: cover.radius + glowRadius
    }

    // ---- artwork --------------------------------------------------------
    Item {
        id: frame
        anchors.fill: parent
        layer.enabled: cover.effects
        layer.effect: OpacityMask { maskSource: cornerMask }

        // Placeholder while the artwork loads or when the item has none.
        Rectangle {
            anchors.fill: parent
            color: Theme.rgba(Theme.highlightBackgroundColor, 0.1)
            visible: art.status !== Image.Ready

            Image {
                // Both dimensions come from the cover, never from each other
                // or from this item's own size - an Image writes its decoded
                // size back into sourceSize, which would close the loop.
                readonly property int iconSize:
                    Math.round(Math.min(cover.width, cover.height) * 0.45)
                anchors.centerIn: parent
                width: iconSize
                height: iconSize
                source: cover.fallbackIcon
                opacity: 0.4
                asynchronous: true
                sourceSize.width: iconSize
                sourceSize.height: iconSize
            }
        }

        Image {
            id: art
            anchors.fill: parent
            source: cover.source
            fillMode: Image.PreserveAspectCrop
            smooth: true
            asynchronous: true
            cache: true
            sourceSize.width: cover.sourceSize
            sourceSize.height: cover.sourceSize
            visible: status === Image.Ready
        }
    }

    Rectangle {
        id: cornerMask
        anchors.fill: frame
        radius: cover.radius
        color: "black"
        visible: false
        layer.enabled: true
    }

    // A hairline keeps the artwork's edge readable on dark backgrounds,
    // where a drop shadow alone disappears.
    Rectangle {
        anchors.fill: frame
        radius: cover.radius
        color: "transparent"
        border.width: 1
        border.color: Theme.rgba(Theme.primaryColor, 0.15)
        visible: cover.effects
    }

    // ---- reflection -----------------------------------------------------
    Item {
        id: mirror
        anchors.top: parent.bottom
        anchors.topMargin: Math.round(cover.elevation / 2)
        width: parent.width
        height: cover._reflected ? cover.height * cover.reflection : 0
        visible: cover._reflected
        clip: true

        // The flip lives on this wrapper, not on the Image: an Image handed to
        // an effect as a texture provider contributes its pixels, never its
        // transform. Flipping the item that draws the masked result keeps it.
        Item {
            id: flipped
            width: mirror.width
            height: cover.height
            transform: Scale { origin.y: cover.height / 2; yScale: -1 }

            Image {
                id: mirrorSource
                anchors.fill: parent
                source: cover.source
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                // An Image is a texture provider in its own right, so no
                // layer is needed here (and none is wanted: the layer would
                // depend on the item being drawn).
                visible: false
            }

            // Alpha ramp in the artwork's own coordinates: opaque at its
            // bottom edge, gone `reflection` of the height above it. After the
            // flip that is bright where the reflection meets the artwork.
            LinearGradient {
                id: fadeMask
                anchors.fill: parent
                visible: false
                layer.enabled: true
                start: Qt.point(0, cover.height)
                end: Qt.point(0, cover.height * (1.0 - cover.reflection))
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#ffffffff" }
                    GradientStop { position: 1.0; color: "#00ffffff" }
                }
            }

            OpacityMask {
                anchors.fill: parent
                source: mirrorSource
                maskSource: fadeMask
                opacity: 0.3
            }
        }
    }
}
