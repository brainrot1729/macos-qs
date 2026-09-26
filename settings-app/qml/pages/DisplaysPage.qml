import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../theme"
import SettingsApp

ColumnLayout {
    id: root
    spacing: Spacing.lg

    property real brightness: 0.5

    function refresh() {
        const current = parseInt(ProcessRunner.run("brightnessctl", ["g"]).trim())
        const max = parseInt(ProcessRunner.run("brightnessctl", ["m"]).trim())
        if (!isNaN(current) && !isNaN(max) && max > 0)
            root.brightness = current / max
    }

    function setBrightness(v) {
        root.brightness = v
        ProcessRunner.run("brightnessctl", ["s", Math.round(v * 100) + "%"])
    }

    Component.onCompleted: root.refresh()

    Text {
        text: "Displays"
        color: Colors.textPrimary
        font.family: Typography.family
        font.pixelSize: Typography.largeTitle
        font.bold: true
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Spacing.md

        Text {
            text: "\u2600"
            font.pixelSize: Typography.title
        }

        Slider {
            Layout.fillWidth: true
            from: 0
            to: 1
            value: root.brightness
            onMoved: root.setBrightness(value)
        }

        Text {
            text: Math.round(root.brightness * 100) + "%"
            color: Colors.textSecondary
            font.family: Typography.family
            font.pixelSize: Typography.body
            Layout.preferredWidth: 40
        }
    }

    Text {
        text: "Requires brightnessctl and membership in the video group."
        color: Colors.textTertiary
        font.family: Typography.family
        font.pixelSize: Typography.caption
    }

    Item { Layout.fillHeight: true }
}
