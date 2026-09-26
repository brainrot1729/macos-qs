import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../theme"
import SettingsApp

ColumnLayout {
    id: root
    spacing: Spacing.lg

    property real volume: 0.5
    property bool muted: false

    function refresh() {
        const raw = ProcessRunner.run("wpctl", ["get-volume", "@DEFAULT_AUDIO_SINK@"])
        const match = raw.match(/Volume:\s*([0-9.]+)/)
        if (match) root.volume = parseFloat(match[1])
        root.muted = raw.indexOf("MUTED") !== -1
    }

    function setVolume(v) {
        root.volume = v
        ProcessRunner.run("wpctl", ["set-volume", "@DEFAULT_AUDIO_SINK@", v.toFixed(2)])
    }

    function toggleMute() {
        ProcessRunner.run("wpctl", ["set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])
        refresh()
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: root.refresh()

    Text {
        text: "Sound"
        color: Colors.textPrimary
        font.family: Typography.family
        font.pixelSize: Typography.largeTitle
        font.bold: true
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Spacing.md

        Text {
            text: root.muted ? "\ud83d\udd07" : "\ud83d\udd0a"
            font.pixelSize: Typography.title

            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                onClicked: root.toggleMute()
            }
        }

        Slider {
            Layout.fillWidth: true
            from: 0
            to: 1.5
            value: root.volume
            onMoved: root.setVolume(value)
        }

        Text {
            text: Math.round(root.volume * 100) + "%"
            color: Colors.textSecondary
            font.family: Typography.family
            font.pixelSize: Typography.body
            Layout.preferredWidth: 40
        }
    }

    Item { Layout.fillHeight: true }
}
