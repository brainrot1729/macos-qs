import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../theme"
import "../controls"
import SettingsApp

ColumnLayout {
    id: root
    spacing: Spacing.md

    property bool wifiOn: false
    property var networks: []
    property string connectingTo: ""
    property string pendingPassword: ""
    property string errorText: ""

    function refreshRadioState() {
        const state = ProcessRunner.run("nmcli", ["radio", "wifi"]).trim()
        root.wifiOn = state === "enabled"
    }

    function refreshNetworks() {
        if (!root.wifiOn) {
            root.networks = []
            return
        }
        // Note: this splits on a plain ":" — nmcli escapes literal colons
        // inside a field (e.g. an SSID containing one), which this does
        // not unescape. Fine for the overwhelming majority of networks;
        // flagged in the README as a known gap.
        const raw = ProcessRunner.run("nmcli", ["-t", "-f", "active,ssid,signal,security", "dev", "wifi", "list"])
        const lines = raw.split("\n").filter(l => l.trim().length > 0)
        const seen = new Set()
        const parsed = []
        for (const line of lines) {
            const parts = line.split(":")
            if (parts.length < 3) continue
            const active = parts[0] === "yes"
            const ssid = parts[1]
            const signal = parseInt(parts[2]) || 0
            const security = parts.slice(3).join(":")
            if (!ssid || seen.has(ssid)) continue
            seen.add(ssid)
            parsed.push({ ssid: ssid, active: active, signal: signal, secured: security.length > 0 })
        }
        parsed.sort((a, b) => b.signal - a.signal)
        root.networks = parsed
    }

    function toggleWifi() {
        ProcessRunner.run("nmcli", ["radio", "wifi", root.wifiOn ? "off" : "on"])
        refreshRadioState()
        refreshNetworks()
    }

    function connectTo(ssid, secured) {
        root.errorText = ""
        if (secured) {
            root.connectingTo = ssid
            return
        }
        const result = ProcessRunner.run("nmcli", ["dev", "wifi", "connect", ssid])
        if (result.toLowerCase().indexOf("error") !== -1)
            root.errorText = "Couldn't connect to " + ssid
        refreshNetworks()
    }

    function submitPassword() {
        const result = ProcessRunner.run("nmcli", ["dev", "wifi", "connect", root.connectingTo, "password", root.pendingPassword])
        root.errorText = result.toLowerCase().indexOf("error") !== -1 ? "Wrong password for " + root.connectingTo : ""
        root.connectingTo = ""
        root.pendingPassword = ""
        refreshNetworks()
    }

    Timer {
        interval: 5000
        running: root.wifiOn
        repeat: true
        onTriggered: root.refreshNetworks()
    }

    Component.onCompleted: {
        refreshRadioState()
        refreshNetworks()
    }

    RowLayout {
        Layout.fillWidth: true

        Text {
            text: "Wi-Fi"
            color: Colors.textPrimary
            font.family: Typography.family
            font.pixelSize: Typography.largeTitle
            font.bold: true
            Layout.fillWidth: true
        }

        SToggle {
            checked: root.wifiOn
            onToggled: root.toggleWifi()
        }
    }

    Text {
        visible: root.errorText.length > 0
        text: root.errorText
        color: "#ff453a"
        font.family: Typography.family
        font.pixelSize: Typography.caption
    }

    ListView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: root.wifiOn
        model: root.networks
        spacing: Spacing.xs
        clip: true

        delegate: Rectangle {
            id: row
            required property var modelData
            width: ListView.view.width
            height: content.implicitHeight + Spacing.sm * 2
            radius: 10
            color: Colors.controlBackground

            Behavior on height { NumberAnimation { duration: Motion.fast } }

            ColumnLayout {
                id: content
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Spacing.sm
                spacing: Spacing.xs

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Spacing.sm

                    SIcon {
                        source: row.modelData.secured
                            ? Qt.resolvedUrl("../assets/icons/lock.svg")
                            : Qt.resolvedUrl("../assets/icons/open-network.svg")
                        color: Colors.textSecondary
                        Layout.preferredWidth: 16
                        Layout.preferredHeight: 16
                    }

                    Text {
                        text: row.modelData.ssid
                        color: Colors.textPrimary
                        font.family: Typography.family
                        font.pixelSize: Typography.body
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    SIcon {
                        visible: row.modelData.active
                        source: Qt.resolvedUrl("../assets/icons/checkmark.svg")
                        color: Colors.accent
                        Layout.preferredWidth: 15
                        Layout.preferredHeight: 15
                    }
                }

                RowLayout {
                    visible: root.connectingTo === row.modelData.ssid
                    Layout.fillWidth: true
                    spacing: Spacing.sm

                    TextField {
                        Layout.fillWidth: true
                        placeholderText: "Password"
                        echoMode: TextInput.Password
                        onTextChanged: root.pendingPassword = text
                        Keys.onReturnPressed: root.submitPassword()
                    }

                    SButton {
                        text: "Join"
                        primary: true
                        onClicked: root.submitPassword()
                    }
                }
            }

            MouseArea {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: 46
                enabled: !row.modelData.active
                onClicked: root.connectTo(row.modelData.ssid, row.modelData.secured)
            }
        }
    }

    Text {
        visible: !root.wifiOn
        text: "Turn on Wi-Fi to see nearby networks."
        color: Colors.textSecondary
        font.family: Typography.family
        font.pixelSize: Typography.body
    }
}
