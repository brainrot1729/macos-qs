import QtQuick
import QtQuick.Layouts
import "../theme"
import "../controls"
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

    SCard {
        Layout.fillWidth: true
        implicitHeight: 60

        RowLayout {
            anchors.fill: parent
            spacing: Spacing.md

            SIcon {
                source: Qt.resolvedUrl("../assets/icons/sun.svg")
                color: Colors.textSecondary
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
            }

            SSlider {
                Layout.fillWidth: true
                value: root.brightness
                onMoved: root.setBrightness(value)
            }

            Text {
                text: Math.round(root.brightness * 100) + "%"
                color: Colors.textSecondary
                font.family: Typography.family
                font.pixelSize: Typography.body
                Layout.preferredWidth: 42
            }
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
