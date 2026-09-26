import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../theme"
import SettingsApp

ColumnLayout {
    id: root
    spacing: Spacing.md

    property bool btOn: false
    property var devices: []
    property string busyMac: ""

    function refreshPower() {
        const info = ProcessRunner.run("bluetoothctl", ["show"])
        root.btOn = info.indexOf("Powered: yes") !== -1
    }

    function refreshDevices() {
        if (!root.btOn) {
            root.devices = []
            return
        }
        const raw = ProcessRunner.run("bluetoothctl", ["devices"])
        const lines = raw.split("\n").filter(l => l.indexOf("Device ") === 0)
        const result = []
        for (const line of lines) {
            const rest = line.substring("Device ".length)
            const spaceIdx = rest.indexOf(" ")
            if (spaceIdx === -1) continue
            const mac = rest.substring(0, spaceIdx)
            const name = rest.substring(spaceIdx + 1).trim()
            // One `info` call per device — fine for a handful of paired
            // devices, not something to scale up (see README).
            const info = ProcessRunner.run("bluetoothctl", ["info", mac])
            const connected = info.indexOf("Connected: yes") !== -1
            const paired = info.indexOf("Paired: yes") !== -1
            result.push({ mac: mac, name: name.length > 0 ? name : mac, connected: connected, paired: paired })
        }
        result.sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired))
        root.devices = result
    }

    function togglePower() {
        ProcessRunner.run("bluetoothctl", ["power", root.btOn ? "off" : "on"])
        refreshPower()
        refreshDevices()
    }

    function toggleConnect(device) {
        root.busyMac = device.mac
        if (device.connected)
            ProcessRunner.run("bluetoothctl", ["disconnect", device.mac])
        else if (device.paired)
            ProcessRunner.run("bluetoothctl", ["connect", device.mac])
        else
            ProcessRunner.run("bluetoothctl", ["pair", device.mac])
        root.busyMac = ""
        refreshDevices()
    }

    Component.onCompleted: {
        refreshPower()
        refreshDevices()
    }

    RowLayout {
        Layout.fillWidth: true

        Text {
            text: "Bluetooth"
            color: Colors.textPrimary
            font.family: Typography.family
            font.pixelSize: Typography.largeTitle
            font.bold: true
            Layout.fillWidth: true
        }

        Switch {
            checked: root.btOn
            onToggled: root.togglePower()
        }

        Button {
            text: "Refresh"
            onClicked: root.refreshDevices()
        }
    }

    ListView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: root.btOn
        model: root.devices
        spacing: Spacing.xs
        clip: true

        delegate: Rectangle {
            id: row
            required property var modelData
            width: ListView.view.width
            height: 46
            radius: 10
            color: Colors.controlBackground

            RowLayout {
                anchors.fill: parent
                anchors.margins: Spacing.sm
                spacing: Spacing.sm

                Text {
                    text: row.modelData.name
                    color: Colors.textPrimary
                    font.family: Typography.family
                    font.pixelSize: Typography.body
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Text {
                    text: row.modelData.connected ? "Connected" : (row.modelData.paired ? "Paired" : "")
                    color: Colors.textSecondary
                    font.family: Typography.family
                    font.pixelSize: Typography.caption
                }

                Button {
                    text: root.busyMac === row.modelData.mac
                        ? "..."
                        : row.modelData.connected ? "Disconnect" : (row.modelData.paired ? "Connect" : "Pair")
                    enabled: root.busyMac !== row.modelData.mac
                    onClicked: root.toggleConnect(row.modelData)
                }
            }
        }
    }

    Text {
        visible: !root.btOn
        text: "Turn on Bluetooth to see nearby devices."
        color: Colors.textSecondary
        font.family: Typography.family
        font.pixelSize: Typography.body
    }
}
