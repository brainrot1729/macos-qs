import QtQuick
import "../theme"

Rectangle {
    id: root
    property bool checked: false
    signal toggled(bool checked)

    implicitWidth: 36
    implicitHeight: 20
    radius: height / 2
    color: checked ? Colors.accent : Colors.surfaceElevated
    border.width: checked ? 0 : 1
    border.color: Colors.separator

    Behavior on color {
        ColorAnimation { duration: Motion.base; easing.type: Motion.standardEasing }
    }

    Rectangle {
        width: parent.height - 4
        height: parent.height - 4
        radius: height / 2
        color: "#ffffff"
        y: 2
        x: root.checked ? parent.width - width - 2 : 2

        Behavior on x {
            NumberAnimation { duration: Motion.base; easing.type: Motion.standardEasing }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            root.checked = !root.checked
            root.toggled(root.checked)
        }
    }
}
