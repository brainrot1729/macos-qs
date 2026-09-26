import QtQuick
import QtQuick.Layouts
import "../theme"
import "../controls"
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

    // wpctl volume can exceed 1.0 (boosted gain), but SSlider only
    // understands 0..1 — map to/from a fixed 0..1.5 display range here
    // rather than teaching the slider about an app-specific ceiling.
    readonly property real maxVolume: 1.5

    function setVolume(sliderPos) {
        const v = sliderPos * root.maxVolume
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

    SCard {
        Layout.fillWidth: true
        implicitHeight: 60

        RowLayout {
            anchors.fill: parent
            spacing: Spacing.md

            SIcon {
                source: root.muted
                    ? Qt.resolvedUrl("../assets/icons/speaker-muted.svg")
                    : Qt.resolvedUrl("../assets/icons/speaker.svg")
                color: Colors.textSecondary
                Layout.preferredWidth: 22
                Layout.preferredHeight: 22

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    onClicked: root.toggleMute()
                }
            }

            SSlider {
                Layout.fillWidth: true
                value: Math.min(1, root.volume / root.maxVolume)
                onMoved: (v) => root.setVolume(v)
            }

            Text {
                text: Math.round(root.volume * 100) + "%"
                color: Colors.textSecondary
                font.family: Typography.family
                font.pixelSize: Typography.body
                Layout.preferredWidth: 42
            }
        }
    }

    Item { Layout.fillHeight: true }
}
