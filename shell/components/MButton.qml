import QtQuick
import "../theme"

Rectangle {
    id: root
    property string text: ""
    property bool primary: false
    signal clicked()

    implicitWidth: label.implicitWidth + Spacing.lg * 2
    implicitHeight: 28
    radius: 6
    color: primary ? Colors.accent : Colors.surfaceElevated
    border.width: primary ? 0 : 1
    border.color: Colors.separator

    Behavior on color {
        ColorAnimation { duration: Motion.fast }
    }
    Behavior on opacity {
        NumberAnimation { duration: Motion.fast }
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: primary ? "#ffffff" : Colors.textPrimary
        font.family: Typography.family
        font.pixelSize: Typography.body
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
        onEntered: root.opacity = 0.85
        onExited: root.opacity = 1.0
    }
}
