import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Bluetooth
import Quickshell.Networking
import "../../theme"
import "../../components"
import "../../services"

PopupWindow {
    id: root
    implicitWidth: 260
    implicitHeight: content.implicitHeight + Spacing.lg * 2
    color: "transparent"

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

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
        spacing: Spacing.md

        RowLayout {
            width: parent.width
            Text {
                text: "Wi-Fi"
                color: Colors.textPrimary
                font.family: Typography.family
                font.pixelSize: Typography.body
                Layout.fillWidth: true
            }
            MToggle {
                checked: Networking.wifiEnabled
                onToggled: (c) => { Networking.wifiEnabled = c }
            }
        }

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
                checked: Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.enabled : false
                onToggled: (c) => { if (Bluetooth.defaultAdapter) Bluetooth.defaultAdapter.enabled = c }
            }
        }

        RowLayout {
            width: parent.width
            Text {
                text: "Do Not Disturb"
                color: Colors.textPrimary
                font.family: Typography.family
                font.pixelSize: Typography.body
                Layout.fillWidth: true
            }
            MToggle {
                checked: NotificationService.dndEnabled
                onToggled: (c) => { NotificationService.dndEnabled = c }
            }
        }

        Text {
            text: "Volume"
            color: Colors.textSecondary
            font.family: Typography.family
            font.pixelSize: Typography.caption
        }

        MSlider {
            id: volumeSlider
            width: parent.width
            value: {
                const sink = Pipewire.defaultAudioSink
                return sink && sink.audio ? sink.audio.volume : 0
            }
            onMoved: (v) => {
                const sink = Pipewire.defaultAudioSink
                if (sink && sink.audio) {
                    sink.audio.muted = false
                    sink.audio.volume = v
                }
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

        Text {
            text: "Brightness"
            color: Colors.textSecondary
            font.family: Typography.family
            font.pixelSize: Typography.caption
        }

        MSlider {
            id: brightnessSlider
            width: parent.width
            onMoved: (v) => brightnessSet.run(v)
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
                        brightnessSlider.value = current / max
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

        Component.onCompleted: brightnessGet.running = true
    }
}
