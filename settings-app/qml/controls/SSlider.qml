import QtQuick
import "../theme"

// Port of shell/components/MSlider.qml — see SToggle.qml's header for
// why this is a copy rather than a shared import. `value` here is
// pre-normalized to 0..1 by the caller (SoundPage's volume can exceed
// 1.0 for boosted gain, so it maps to/from this slider's 0..1 range
// itself rather than this component knowing about that range).
Item {
    id: root
    property real value: 0.5 // 0..1
    property real trackHeight: 4
    implicitWidth: 140
    implicitHeight: 20
    signal moved(real value)

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: root.trackHeight
        radius: height / 2
        color: Colors.surfaceElevated

        Rectangle {
            width: track.width * root.value
            height: track.height
            radius: height / 2
            color: Colors.accent
        }
    }

    Rectangle {
        id: handle
        width: 14
        height: 14
        radius: 7
        color: "#ffffff"
        anchors.verticalCenter: parent.verticalCenter
        x: track.width * root.value - width / 2
    }

    MouseArea {
        anchors.fill: parent

        function updateFromMouse(mx) {
            root.value = Math.max(0, Math.min(1, mx / track.width))
            root.moved(root.value)
        }

        onPressed: (mouse) => updateFromMouse(mouse.x)
        onPositionChanged: (mouse) => { if (pressed) updateFromMouse(mouse.x) }
    }
}
