import QtQuick
import "../theme"

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
