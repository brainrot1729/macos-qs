import QtQuick
import QtQuick.Layouts
import "../theme"

ColumnLayout {
    id: root
    spacing: Spacing.md

    Text {
        text: "About This Shell"
        color: Colors.textPrimary
        font.family: Typography.family
        font.pixelSize: Typography.largeTitle
        font.bold: true
    }

    Text {
        text: "macos-qs"
        color: Colors.textPrimary
        font.family: Typography.family
        font.pixelSize: Typography.title
    }

    Text {
        text: "A macOS-inspired desktop shell built with Quickshell and Hyprland."
        color: Colors.textSecondary
        font.family: Typography.family
        font.pixelSize: Typography.body
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }

    Item { Layout.fillHeight: true }
}
