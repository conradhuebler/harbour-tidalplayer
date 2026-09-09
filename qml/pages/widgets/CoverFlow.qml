// Claude Generated — covers on a path: the centred cover stands upright, its
// neighbours turn away into the depth, each on its reflection.
// Ported from qml-tidalplayer (CoverFlowOverlay.qml / SectionGrid.qml);
// QtQuick 2.6 for Matrix4x4, which Qt 5.6 provides.
import QtQuick 2.6
import Sailfish.Silica 1.0

Item {
    id: flowRoot

    // Any ListModel-ish object with count/get(i).
    property var model: null
    property string titleRole: "title"
    property string subtitleRole: ""
    property string imageRole: "image"
    property string fallbackIcon: "image://theme/icon-m-media-albums"
    // Index that gets the accent frame (the track that is playing, say).
    property int highlightIndex: -1
    // Labels under the flow; a shelf inside a page wants them, the queue
    // page draws its own.
    property bool showLabels: true
    property alias currentIndex: flow.currentIndex
    property alias interactive: flow.interactive

    property real coverSize: Math.max(Theme.itemSizeLarge,
                                      Math.min(height * 0.62, width * 0.55))

    signal activated(int index)
    signal held(int index)

    function itemAt(index) {
        if (!model || index < 0 || index >= model.count)
            return null
        return model.get(index)
    }
    function valueAt(index, role) {
        var it = itemAt(index)
        return (it && role !== "" && it[role]) ? it[role] : ""
    }
    // Moving currentIndex is what snaps the view, and it also marks the item
    // as current - which positionViewAtIndex would not.
    function positionAt(index) {
        if (model && index >= 0 && index < model.count)
            flow.currentIndex = index
    }

    // Plain properties, pushed from the handlers below. As bindings they would
    // close a loop: label text -> label size -> the flow's height -> the path
    // -> the item the view snaps to -> currentIndex -> label text again.
    property string centredTitle: ""
    property string centredSubtitle: ""

    function _updateCentred() {
        centredTitle = valueAt(flow.currentIndex, titleRole)
        centredSubtitle = valueAt(flow.currentIndex, subtitleRole)
    }

    onModelChanged: _updateCentred()

    // The model is filled asynchronously, so react to it growing as well.
    Connections {
        target: flowRoot.model
        ignoreUnknownSignals: true
        onCountChanged: flowRoot._updateCentred()
    }

    PathView {
        id: flow
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            bottom: labels.top
        }
        model: flowRoot.model
        pathItemCount: 9
        preferredHighlightBegin: 0.5
        preferredHighlightEnd: 0.5
        highlightRangeMode: PathView.StrictlyEnforceRange
        snapMode: PathView.SnapToItem
        dragMargin: height / 2
        flickDeceleration: 2000
        clip: false

        onCurrentIndexChanged: flowRoot._updateCentred()

        path: Path {
            startX: 0
            startY: flow.height * 0.5
            PathAttribute { name: "itemAngle"; value: 60 }
            PathAttribute { name: "itemScale"; value: 0.65 }
            PathAttribute { name: "itemZ"; value: 0 }
            // Outer third: covers stay fully turned ...
            PathLine { x: flow.width * 0.28; y: flow.height * 0.5 }
            PathPercent { value: 0.3 }
            PathAttribute { name: "itemAngle"; value: 60 }
            PathAttribute { name: "itemScale"; value: 0.65 }
            PathAttribute { name: "itemZ"; value: 0 }
            // ... then swing upright into the centre band, which stays flat so
            // the item the view snaps to (path position 0.5) faces the viewer.
            PathLine { x: flow.width * 0.5 - flowRoot.coverSize * 0.34; y: flow.height * 0.5 }
            PathPercent { value: 0.46 }
            PathAttribute { name: "itemAngle"; value: 0 }
            PathAttribute { name: "itemScale"; value: 1.0 }
            PathAttribute { name: "itemZ"; value: 100 }
            PathLine { x: flow.width * 0.5 + flowRoot.coverSize * 0.34; y: flow.height * 0.5 }
            PathPercent { value: 0.54 }
            PathAttribute { name: "itemAngle"; value: 0 }
            PathAttribute { name: "itemScale"; value: 1.0 }
            PathAttribute { name: "itemZ"; value: 100 }
            PathLine { x: flow.width * 0.72; y: flow.height * 0.5 }
            PathPercent { value: 0.7 }
            PathAttribute { name: "itemAngle"; value: -60 }
            PathAttribute { name: "itemScale"; value: 0.65 }
            PathAttribute { name: "itemZ"; value: 0 }
            PathLine { x: flow.width; y: flow.height * 0.5 }
            PathPercent { value: 1.0 }
            PathAttribute { name: "itemAngle"; value: -60 }
            PathAttribute { name: "itemScale"; value: 0.65 }
            PathAttribute { name: "itemZ"; value: 0 }
        }

        delegate: Item {
            id: slot

            width: flowRoot.coverSize
            height: flowRoot.coverSize * 1.4
            z: PathView.itemZ === undefined ? 0 : PathView.itemZ
            scale: PathView.itemScale === undefined ? 1 : PathView.itemScale
            opacity: PathView.onPath ? 1 : 0

            transform: [
                Rotation {
                    origin.x: slot.width / 2
                    origin.y: slot.height / 2
                    axis { x: 0; y: 1; z: 0 }
                    angle: slot.PathView.itemAngle === undefined ? 0 : slot.PathView.itemAngle
                },
                // Without a projection term a Y rotation is just a horizontal
                // squash; this gives the turn its depth.
                Matrix4x4 {
                    matrix: Qt.matrix4x4(1, 0, 0, 0,
                                         0, 1, 0, 0,
                                         0, 0, 1, 0,
                                         0, 0, -0.0009, 1)
                }
            ]

            CoverArt {
                id: art
                width: flowRoot.coverSize
                height: flowRoot.coverSize
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                source: flowRoot.valueAt(index, flowRoot.imageRole)
                fallbackIcon: flowRoot.fallbackIcon
                elevation: Theme.paddingSmall
                reflection: 0.4
            }

            // The item that is actually playing keeps an accent frame.
            Rectangle {
                anchors.fill: art
                radius: art.radius
                color: "transparent"
                border.width: 2
                border.color: Theme.highlightColor
                visible: index === flowRoot.highlightIndex
            }

            MouseArea {
                anchors.fill: art
                onClicked: {
                    if (index === flow.currentIndex)
                        flowRoot.activated(index)
                    else
                        flow.currentIndex = index
                }
                onPressAndHold: flowRoot.held(index)
            }
        }
    }

    Column {
        id: labels
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            leftMargin: Theme.horizontalPageMargin
            rightMargin: Theme.horizontalPageMargin
        }
        // Fixed heights, not childrenRect: the flow is anchored to the top of
        // this block, so a label growing with its text would move the flow.
        height: flowRoot.showLabels
                ? Math.round((Theme.fontSizeMedium + Theme.fontSizeExtraSmall) * 1.5) : 0
        visible: flowRoot.showLabels

        Label {
            width: parent.width
            height: Math.round(Theme.fontSizeMedium * 1.5)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            truncationMode: TruncationMode.Fade
            text: flowRoot.centredTitle
        }
        Label {
            width: parent.width
            height: Math.round(Theme.fontSizeExtraSmall * 1.5)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            truncationMode: TruncationMode.Fade
            color: Theme.secondaryColor
            font.pixelSize: Theme.fontSizeExtraSmall
            text: flowRoot.centredSubtitle
        }
    }
}
