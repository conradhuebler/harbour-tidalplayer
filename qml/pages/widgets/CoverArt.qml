// Claude Generated — artwork tile: rounded corners, hairline edge, optional
// drop shadow and an optional mirrored reflection below the artwork.
// Ported from the desktop player (qml-tidalplayer/qml/pages/CoverImage.qml).
//
// Rounding and reflection are done in a single ShaderEffect pass each, sampling
// the Image directly (an Image is a texture provider in its own right). The
// obvious QtGraphicalEffects route - layer.enabled + OpacityMask + a masking
// Rectangle that is itself layered - costs two framebuffers per tile, and a
// homescreen shows dozens of tiles at once.
//
// The heavier extras stay opt-in per use site: `elevation` and `reflection`
// default to 0. `settings.artworkEffects` switches the whole treatment off.
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

    // PreserveAspectCrop happens in the shaders, which see the raw texture and
    // not the Image's fillMode: how much of the source to sample per axis.
    readonly property real _imgAspect: art.implicitHeight > 0 ? art.implicitWidth / art.implicitHeight : 1
    readonly property real _itemAspect: height > 0 ? width / height : 1
    readonly property real _cropX: _imgAspect > _itemAspect ? _itemAspect / _imgAspect : 1
    readonly property real _cropY: _imgAspect > _itemAspect ? 1 : _imgAspect / _itemAspect

    implicitWidth: Theme.itemSizeExtraLarge
    implicitHeight: Theme.itemSizeExtraLarge

    // ---- shadow ---------------------------------------------------------
    // RectangularGlow draws the glow alone; DropShadow would redraw the
    // artwork underneath its own copy.
    RectangularGlow {
        x: 0
        y: Math.round(cover.elevation / 2)
        width: cover.width
        height: cover.height
        visible: cover._shadowed
        glowRadius: cover.elevation * 1.5
        spread: 0.1
        color: Qt.rgba(0, 0, 0, 0.55)
        cornerRadius: cover.radius + glowRadius
    }

    // ---- placeholder ----------------------------------------------------
    // A plain rounded Rectangle - rounding a Rectangle is native, no effect
    // needed. It stays up until the artwork has faded in.
    Rectangle {
        anchors.fill: parent
        radius: cover.radius
        color: Theme.rgba(Theme.highlightBackgroundColor, 0.1)
        visible: artwork.opacity < 1.0

        Image {
            // Only shown when there is nothing to wait for. An icon that
            // appears in the middle of every tile and is replaced by the
            // artwork a moment later reads as flicker across a shelf.
            visible: cover.source == "" || art.status === Image.Error

            // Both dimensions come from the cover, never from each other or
            // from this item's own size - an Image writes its decoded size
            // back into sourceSize, which would close the loop.
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

    // ---- artwork --------------------------------------------------------
    // Drawn directly only when the effects are off; otherwise it just supplies
    // the texture for the shaders below and is not rendered itself.
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

        visible: !cover.effects && opacity > 0
        // Fade in rather than pop: a shelf whose covers arrive one by one
        // otherwise flickers as each one snaps in.
        opacity: status === Image.Ready ? 1.0 : 0.0
        Behavior on opacity { FadeAnimation {} }
    }

    ShaderEffect {
        id: artwork
        anchors.fill: parent
        visible: cover.effects && art.status === Image.Ready && opacity > 0
        opacity: art.status === Image.Ready ? 1.0 : 0.0
        Behavior on opacity { FadeAnimation {} }

        property variant source: art
        property real radiusPx: cover.radius
        property real w: width
        property real h: height
        property real cropX: cover._cropX
        property real cropY: cover._cropY

        fragmentShader: "
            uniform sampler2D source;
            uniform lowp float qt_Opacity;
            uniform highp float w;
            uniform highp float h;
            uniform highp float radiusPx;
            uniform highp float cropX;
            uniform highp float cropY;
            varying highp vec2 qt_TexCoord0;

            void main() {
                highp vec2 uv = vec2(0.5) + (qt_TexCoord0 - vec2(0.5)) * vec2(cropX, cropY);

                // Distance to the nearest horizontal and vertical edge, in
                // pixels; inside a corner box, round it off with a one pixel
                // wide ramp so the edge is not stepped.
                highp vec2 p = qt_TexCoord0 * vec2(w, h);
                highp vec2 d = min(p, vec2(w, h) - p);
                lowp float a = 1.0;
                if (d.x < radiusPx && d.y < radiusPx) {
                    a = clamp(radiusPx - distance(vec2(radiusPx), d) + 0.5, 0.0, 1.0);
                }
                gl_FragColor = texture2D(source, uv) * a * qt_Opacity;
            }
        "
    }

    // A hairline keeps the artwork's edge readable on dark backgrounds,
    // where a drop shadow alone disappears.
    Rectangle {
        anchors.fill: parent
        radius: cover.radius
        color: "transparent"
        border.width: 1
        border.color: Theme.rgba(Theme.primaryColor, 0.15)
        visible: cover.effects
    }

    // ---- reflection -----------------------------------------------------
    // Mirrored artwork under the tile, fading out downwards - again one pass,
    // sampling the same texture. The mirroring is a coordinate flip in the
    // shader, which is also why no wrapper item is needed: a transform on an
    // item feeding an effect would be lost anyway.
    ShaderEffect {
        anchors.top: parent.bottom
        anchors.topMargin: Math.round(cover.elevation / 2)
        width: cover.width
        height: cover._reflected ? cover.height * cover.reflection : 0
        visible: cover._reflected
        opacity: 0.3

        property variant source: art
        property real reflection: cover.reflection
        property real cropX: cover._cropX
        property real cropY: cover._cropY

        fragmentShader: "
            uniform sampler2D source;
            uniform lowp float qt_Opacity;
            uniform highp float reflection;
            uniform highp float cropX;
            uniform highp float cropY;
            varying highp vec2 qt_TexCoord0;

            void main() {
                // 0 at the top of the strip, where it meets the artwork.
                highp float v = qt_TexCoord0.y;
                highp vec2 mirrored = vec2(qt_TexCoord0.x, 1.0 - v * reflection);
                highp vec2 uv = vec2(0.5) + (mirrored - vec2(0.5)) * vec2(cropX, cropY);
                gl_FragColor = texture2D(source, uv) * (1.0 - v) * qt_Opacity;
            }
        "
    }
}
