import QtQuick
import QtQuick.Layouts
import "../theme"
import "../controls"
import SettingsApp

ColumnLayout {
    id: root
    spacing: Spacing.lg

    property string percentage: "--"
    property string state: "--"
    property bool present: false

    function refresh() {
        const devices = ProcessRunner.run("upower", ["-e"]).split("\n").filter(l => l.indexOf("battery_") !== -1)
        if (devices.length === 0) {
            root.present = false
            return
        }
        const info = ProcessRunner.run("upower", ["-i", devices[0].trim()])
        const pctMatch = info.match(/percentage:\s*([0-9]+)%/)
        const stateMatch = info.match(/state:\s*(\S+)/)
        root.present = true
        root.percentage = pctMatch ? pctMatch[1] + "%" : "--"
        root.state = stateMatch ? stateMatch[1] : "--"
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: root.refresh()

    Text {
        text: "Battery"
        color: Colors.textPrimary
        font.family: Typography.family
        font.pixelSize: Typography.largeTitle
        font.bold: true
    }

    SCard {
        Layout.fillWidth: true
        implicitHeight: contentCol.implicitHeight + Spacing.md * 2
        visible: root.present

        ColumnLayout {
            id: contentCol
            width: parent.width
            spacing: Spacing.sm

            RowLayout {
                Layout.fillWidth: true
                SIcon {
                    source: Qt.resolvedUrl("../assets/icons/battery.svg")
                    color: Colors.textSecondary
                    Layout.preferredWidth: 20
                    Layout.preferredHeight: 20
                }
                Text { text: "Charge"; color: Colors.textSecondary; font.family: Typography.family; font.pixelSize: Typography.body; Layout.fillWidth: true }
                Text { text: root.percentage; color: Colors.textPrimary; font.family: Typography.family; font.pixelSize: Typography.body }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Colors.background }

            RowLayout {
                Layout.fillWidth: true
                Text { text: "State"; color: Colors.textSecondary; font.family: Typography.family; font.pixelSize: Typography.body; Layout.fillWidth: true }
                Text { text: root.state; color: Colors.textPrimary; font.family: Typography.family; font.pixelSize: Typography.body }
            }
        }
    }

    SCard {
        Layout.fillWidth: true
        implicitHeight: 50
        visible: !root.present

        Text {
            anchors.centerIn: parent
            text: "No battery detected."
            color: Colors.textSecondary
            font.family: Typography.family
            font.pixelSize: Typography.body
        }
    }

    Item { Layout.fillHeight: true }
}
