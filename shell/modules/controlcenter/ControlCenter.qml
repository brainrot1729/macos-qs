import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.UPower
import "../../theme"
import "../../components"
import "../../services"

PopupWindow {
    id: root
    implicitWidth: 360
    implicitHeight: 500
    color: "transparent"

    property bool displayExpanded: false
    property real brightnessValue: 0.5
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var wifiDevice: {
        const devices = Networking.devices.values
        for (let i = 0; i < devices.length; i++) {
            if (devices[i].type === DeviceType.Wifi) return devices[i]
        }
        return null
    }

    function setVolume(value) {
        const sink = Pipewire.defaultAudioSink
        if (sink && sink.audio) {
            sink.audio.muted = false
            sink.audio.volume = value
        }
    }

    function wifiName() {
        if (!Networking.wifiEnabled) return "Wi-Fi Off"
        if (!root.wifiDevice || !root.wifiDevice.connected) return "Not Connected"
        const networks = root.wifiDevice.networks.values
        for (let i = 0; i < networks.length; i++) {
            if (networks[i].connected) return networks[i].name || "Connected"
        }
        return "Connected"
    }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    Rectangle {
        anchors.fill: parent
        color: Colors.surface
        radius: 16
        border.width: 1
        border.color: Colors.separator
    }

    Column {
        id: content
        anchors.fill: parent
        anchors.margins: Spacing.lg
        spacing: Spacing.sm

        Row {
            width: parent.width
            spacing: Spacing.sm

            Rectangle {
                width: parent.width * 0.59
                height: 150
                radius: 12
                color: Colors.controlBackground

                Column {
                    anchors.fill: parent
                    anchors.margins: Spacing.md
                    spacing: Spacing.sm

                    Text {
                        text: "Connectivity"
                        color: Colors.textPrimary
                        font.family: Typography.family
                        font.pixelSize: Typography.body
                        font.bold: true
                    }

                    ControlTile {
                        width: parent.width
                        iconSource: Networking.wifiEnabled
                            ? Qt.resolvedUrl("../../assets/icons/wifi-on.svg")
                            : Qt.resolvedUrl("../../assets/icons/wifi-off.svg")
                        title: "Wi-Fi"
                        subtitle: root.wifiName()
                        active: Networking.wifiEnabled
                        onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
                    }

                    ControlTile {
                        width: parent.width
                        iconSource: root.adapter && root.adapter.enabled
                            ? Qt.resolvedUrl("../../assets/icons/bluetooth-on.svg")
                            : Qt.resolvedUrl("../../assets/icons/bluetooth-off.svg")
                        title: "Bluetooth"
                        subtitle: root.adapter && root.adapter.enabled ? "On" : "Off"
                        active: root.adapter ? root.adapter.enabled : false
                        onClicked: if (root.adapter) root.adapter.enabled = !root.adapter.enabled
                    }

                    ControlTile {
                        width: parent.width
                        title: "AirDrop"
                        subtitle: "Unavailable"
                        enabled: false
                    }
                }
            }

            Column {
                width: parent.width - parent.children[0].width - parent.spacing
                spacing: Spacing.sm

                ControlTile {
                    width: parent.width
                    height: 44
                    title: "Do Not Disturb"
                    subtitle: NotificationService.dndEnabled ? "On" : "Off"
                    active: NotificationService.dndEnabled
                    onClicked: NotificationService.dndEnabled = !NotificationService.dndEnabled
                }

                ControlTile {
                    width: parent.width
                    height: 44
                    title: "Keyboard Brightness"
                    subtitle: "Unavailable"
                    enabled: false
                }

                ControlTile {
                    width: parent.width
                    height: 44
                    title: "AirPlay"
                    subtitle: "Unavailable"
                    enabled: false
                }
            }
        }

        Rectangle {
            width: parent.width
            height: root.displayExpanded ? 104 : 62
            radius: 12
            color: Colors.controlBackground

            Column {
                anchors.fill: parent
                anchors.margins: Spacing.md
                spacing: Spacing.sm

                Item {
                    id: displayHeader
                    width: parent.width
                    height: 20

                    RowLayout {
                        anchors.fill: parent

                        Text {
                            text: "Display"
                            color: Colors.textPrimary
                            font.family: Typography.family
                            font.pixelSize: Typography.body
                            Layout.fillWidth: true
                        }
                        Text {
                            text: root.displayExpanded ? "⌃" : "⌄"
                            color: Colors.textSecondary
                            font.pixelSize: Typography.body
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.displayExpanded = !root.displayExpanded
                    }
                }

                MSlider {
                    visible: root.displayExpanded
                    width: parent.width
                    value: root.brightnessValue
                    onMoved: (v) => {
                        root.brightnessValue = v
                        brightnessSet.run(v)
                    }
                }
            }
        }

        RowLayout {
            width: parent.width
            spacing: Spacing.sm

            Text {
                text: "Volume"
                color: Colors.textSecondary
                font.family: Typography.family
                font.pixelSize: Typography.caption
            }

            MSlider {
                id: volumeSlider
                Layout.fillWidth: true
                value: {
                    const sink = Pipewire.defaultAudioSink
                    return sink && sink.audio ? sink.audio.volume : 0
                }
                onMoved: (v) => root.setVolume(v)
            }

            Text {
                text: Math.round(volumeSlider.value * 100) + "%"
                color: Colors.textSecondary
                font.family: Typography.family
                font.pixelSize: Typography.caption
                Layout.preferredWidth: 34
            }
        }

        // A plain "value: sink.audio.volume" binding above only survives
        // until the user drags the slider once, dragging assigns
        // volumeSlider.value directly, and any imperative write to a
        // property permanently breaks its declarative binding in QML.
        // Without this, the slider would freeze after the first drag
        // and stop following hardware volume keys. Re-asserting the
        // value on every real change sidesteps that entirely, since
        // it's just a plain write either way, not a binding to break.
        Connections {
            target: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null
            function onVolumeChanged() {
                volumeSlider.value = Pipewire.defaultAudioSink.audio.volume
            }
        }

        // Read current brightness on open (brightnessctl has no change
        // notification, so this is poll-on-show rather than push).
        Process {
            id: brightnessGet
            command: ["brightnessctl", "g"]
            stdout: StdioCollector {
                onStreamFinished: {
                    const current = parseInt(text.trim())
                    if (!isNaN(current)) {
                        brightnessMax.running = true
                    }
                }
            }
        }
        Process {
            id: brightnessMax
            command: ["brightnessctl", "m"]
            stdout: StdioCollector {
                onStreamFinished: {
                    const max = parseInt(text.trim())
                    const current = parseInt(brightnessGet.stdout.text.trim())
                    if (!isNaN(max) && max > 0 && !isNaN(current)) {
                        root.brightnessValue = current / max
                    }
                }
            }
        }
        Process {
            id: brightnessSet
            property real pending: 0
            function run(v) {
                pending = v
                command = ["brightnessctl", "s", Math.round(v * 100) + "%"]
                running = true
            }
        }

        Rectangle {
            width: parent.width
            height: 70
            radius: 12
            color: Colors.controlBackground

            RowLayout {
                anchors.fill: parent
                anchors.margins: Spacing.md
                spacing: Spacing.md

                Text {
                    text: "Now Playing"
                    color: Colors.textPrimary
                    font.family: Typography.family
                    font.pixelSize: Typography.body
                    Layout.fillWidth: true
                }

                Text {
                    text: "No media"
                    color: Colors.textSecondary
                    font.family: Typography.family
                    font.pixelSize: Typography.caption
                }
            }
        }

        RowLayout {
            width: parent.width

            Text {
                text: "Battery"
                color: Colors.textSecondary
                font.family: Typography.family
                font.pixelSize: Typography.caption
                Layout.fillWidth: true
            }

            Text {
                readonly property var battery: UPower.displayDevice
                text: battery && battery.isPresent ? Math.round(battery.percentage * 100) + "%" : "Unavailable"
                color: Colors.textPrimary
                font.family: Typography.family
                font.pixelSize: Typography.caption
            }
        }

        Component.onCompleted: brightnessGet.running = true
    }

    component ControlTile: Rectangle {
        id: tile
        property url iconSource
        property string title: ""
        property string subtitle: ""
        property bool active: false
        signal clicked()
        implicitHeight: 30
        radius: 7
        color: active ? Colors.accent : "transparent"
        opacity: enabled ? 1 : 0.45

        RowLayout {
            anchors.fill: parent
            spacing: Spacing.sm

            StatusIcon {
                source: tile.iconSource
                fillColor: tile.active ? "#ffffff" : Colors.textPrimary
                showBackground: false
                visible: tile.iconSource.toString().length > 0
                Layout.preferredWidth: 22
                Layout.preferredHeight: 22
            }

            Text {
                text: tile.title === "Do Not Disturb" ? "◐" : tile.title === "AirDrop" ? "◌" : tile.title === "Keyboard Brightness" ? "⌨" : "▣"
                color: tile.active ? "#ffffff" : Colors.textPrimary
                font.pixelSize: Typography.title
                visible: tile.iconSource.toString().length === 0
                Layout.preferredWidth: 22
                horizontalAlignment: Text.AlignHCenter
            }

            Column {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    text: tile.title
                    color: tile.active ? "#ffffff" : Colors.textPrimary
                    font.family: Typography.family
                    font.pixelSize: Typography.caption
                    font.bold: true
                    elide: Text.ElideRight
                    width: parent.width
                }

                Text {
                    text: tile.subtitle
                    color: tile.active ? "#dbeeff" : Colors.textSecondary
                    font.family: Typography.family
                    font.pixelSize: 10
                    elide: Text.ElideRight
                    width: parent.width
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: tile.enabled
            onClicked: tile.clicked()
        }
    }
}
