import QtQuick
import Quickshell
import "../theme"

Item {
    id: root
    property var dockItem // { entry, pinned, running, toplevel }
    property bool hovered: false

    implicitWidth: 48
    implicitHeight: 48

    scale: hovered ? 1.25 : 1.0
    Behavior on scale {
        NumberAnimation { duration: Motion.fast; easing.type: Motion.standardEasing }
    }

    function fallbackLetter() {
        if (root.dockItem.entry && root.dockItem.entry.name) {
            return root.dockItem.entry.name.charAt(0).toUpperCase()
        }
        if (root.dockItem.toplevel && root.dockItem.toplevel.appId) {
            return root.dockItem.toplevel.appId.charAt(0).toUpperCase()
        }
        return "?"
    }

    Image {
        id: iconImage
        anchors.fill: parent
        source: root.dockItem.entry ? Quickshell.iconPath(root.dockItem.entry.icon, true) : ""
        visible: source !== ""
        sourceSize.width: 48
        sourceSize.height: 48
        fillMode: Image.PreserveAspectFit
    }

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: Colors.surfaceElevated
        visible: !iconImage.visible

        Text {
            anchors.centerIn: parent
            text: root.fallbackLetter()
            color: Colors.textPrimary
            font.family: Typography.family
            font.pixelSize: Typography.title
        }
    }

    Rectangle {
        visible: root.dockItem.running
        width: 4
        height: 4
        radius: 2
        color: Colors.textPrimary
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: -6
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: root.hovered = true
        onExited: root.hovered = false
        onClicked: {
            if (root.dockItem.toplevel) {
                root.dockItem.toplevel.activate()
            } else if (root.dockItem.entry) {
                root.dockItem.entry.execute()
            }
        }
    }
}
