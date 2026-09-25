import QtQuick
import Quickshell
import "../../theme"
import "../../components"
import "../../services"

PanelWindow {
    id: dock

    // Anchored to bottom only (no left/right), so the compositor
    // centers it horizontally, same pattern Quickshell's own OSD
    // examples use for a floating, non-full-width panel.
    anchors.bottom: true
    margins.bottom: Spacing.sm

    implicitWidth: row.implicitWidth + Spacing.md * 2
    implicitHeight: 64
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        color: Colors.surface
        radius: 16
        border.width: 1
        border.color: Colors.separator
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Spacing.sm

        Repeater {
            model: DockService.items
            delegate: DockIcon {
                dockItem: modelData
            }
        }
    }
}
