import QtQuick
import QtQuick.Layouts
import "../theme"
import SettingsApp

ColumnLayout {
    id: root
    spacing: Spacing.lg

    property string hostname: ""
    property string kernel: ""

    Component.onCompleted: {
        root.hostname = ProcessRunner.run("hostnamectl", ["hostname"]).trim()
        root.kernel = ProcessRunner.run("uname", ["-r"]).trim()
    }

    Text {
        text: "General"
        color: Colors.textPrimary
        font.family: Typography.family
        font.pixelSize: Typography.largeTitle
        font.bold: true
    }

    GridLayout {
        columns: 2
        columnSpacing: Spacing.lg
        rowSpacing: Spacing.sm

        Text { text: "Device name"; color: Colors.textSecondary; font.family: Typography.family; font.pixelSize: Typography.body }
        Text { text: root.hostname.length > 0 ? root.hostname : "Unknown"; color: Colors.textPrimary; font.family: Typography.family; font.pixelSize: Typography.body }

        Text { text: "Kernel"; color: Colors.textSecondary; font.family: Typography.family; font.pixelSize: Typography.body }
        Text { text: root.kernel.length > 0 ? root.kernel : "Unknown"; color: Colors.textPrimary; font.family: Typography.family; font.pixelSize: Typography.body }

        Text { text: "Window manager"; color: Colors.textSecondary; font.family: Typography.family; font.pixelSize: Typography.body }
        Text { text: "Hyprland (floating-only)"; color: Colors.textPrimary; font.family: Typography.family; font.pixelSize: Typography.body }
    }

    Item { Layout.fillHeight: true }
}
