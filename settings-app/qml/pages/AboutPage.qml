import QtQuick
import QtQuick.Layouts
import "../theme"
import "../controls"

ColumnLayout {
    id: root
    spacing: Spacing.lg

    Text {
        text: "About This Shell"
        color: Colors.textPrimary
        font.family: Typography.family
        font.pixelSize: Typography.largeTitle
        font.bold: true
    }

    SCard {
        Layout.fillWidth: true
        implicitHeight: col.implicitHeight + Spacing.md * 2

        ColumnLayout {
            id: col
            width: parent.width
            spacing: Spacing.sm

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
        }
    }

    Item { Layout.fillHeight: true }
}
