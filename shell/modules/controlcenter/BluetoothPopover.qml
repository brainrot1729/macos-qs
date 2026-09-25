import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import "../../theme"
import "../../components"

PopupWindow {
    id: root

    property var adapter

    implicitWidth: 300
    implicitHeight: content.implicitHeight + Spacing.lg * 2
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        color: Colors.surface
        radius: 14
        border.width: 1
        border.color: Colors.separator
    }

    Column {
        id: content
        anchors.fill: parent
        anchors.margins: Spacing.lg
        spacing: Spacing.sm

        RowLayout {
            width: parent.width

            Text {
                text: "Bluetooth"
                color: Colors.textPrimary
                font.family: Typography.family
                font.pixelSize: Typography.body
                Layout.fillWidth: true
            }

            MToggle {
                checked: root.adapter ? root.adapter.enabled : false
                onToggled: (enabled) => {
                    if (root.adapter) root.adapter.enabled = enabled
                }
            }
        }

        Text {
            visible: !root.adapter || !root.adapter.enabled
            text: "Bluetooth is off"
            color: Colors.textSecondary
            font.family: Typography.family
            font.pixelSize: Typography.caption
        }

        Text {
            visible: root.adapter && root.adapter.enabled && root.adapter.devices.values.length === 0
            text: "No devices found"
            color: Colors.textSecondary
            font.family: Typography.family
            font.pixelSize: Typography.caption
        }

        Repeater {
            model: root.adapter && root.adapter.enabled ? root.adapter.devices.values : []

            delegate: RowLayout {
                required property var modelData
                width: content.width
                spacing: Spacing.sm

                Column {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: modelData.name || modelData.deviceName || "Unknown device"
                        color: Colors.textPrimary
                        font.family: Typography.family
                        font.pixelSize: Typography.body
                        elide: Text.ElideRight
                        width: parent.width
                    }

                    Text {
                        text: modelData.connected ? "Connected" : (modelData.paired ? "Paired" : "Available")
                        color: Colors.textSecondary
                        font.family: Typography.family
                        font.pixelSize: Typography.caption
                    }
                }

                MButton {
                    text: modelData.connected ? "Disconnect" : (modelData.paired ? "Connect" : "Pair")
                    onClicked: {
                        if (modelData.connected) modelData.disconnect()
                        else if (modelData.paired) modelData.connect()
                        else if (!modelData.pairing) modelData.pair()
                    }
                }
            }
        }
    }
}
