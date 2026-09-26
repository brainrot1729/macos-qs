import QtQuick
import "../theme"

// Port of shell/components/MButton.qml — see SToggle.qml's header for
// why this is a copy rather than a shared import.
Rectangle {
    id: root
    property string text: ""
    property bool primary: false
    property bool enabled_: true
    signal clicked()

    implicitWidth: label.implicitWidth + Spacing.lg * 2
    implicitHeight: 30
    radius: 7
    opacity: enabled_ ? 1.0 : 0.45
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
        enabled: root.enabled_
        onClicked: root.clicked()
        onEntered: root.opacity = 0.85
        onExited: root.opacity = root.enabled_ ? 1.0 : 0.45
    }
}
