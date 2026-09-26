import QtQuick
import "../theme"

// Direct port of shell/components/MToggle.qml. The settings app is a
// separate executable with no dependency on the Quickshell process, so
// it can't import that file across process/module boundaries — hence a
// copy, not a shared import. Keep the two in sync by hand if either
// changes; this is the same trade-off already made for Colors/Spacing/
// Typography/Motion in this app.
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
