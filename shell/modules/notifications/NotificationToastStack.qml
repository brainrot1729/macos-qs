import QtQuick
import Quickshell
import "../../theme"
import "../../components"
import "../../services"

// Always-on overlay, instantiated once from shell.qml alongside Bar/Dock.
// Not a popup opened on demand like Control Center - toasts appear on
// their own whenever NotificationService.activeToasts changes.
PanelWindow {
    id: root
    anchors {
        top: true
        right: true
    }
    margins {
        top: 36 // clear the 28px bar plus a little breathing room
        right: Spacing.md
    }
    implicitWidth: 300
    implicitHeight: Math.max(list.contentHeight, 1)
    color: "transparent"

    // Nothing to click when there are no toasts; don't eat input meant
    // for whatever's underneath this corner of the screen.
    mask: Region { item: list }

    ListView {
        id: list
        width: parent.width
        height: contentHeight
        model: NotificationService.activeToasts
        spacing: Spacing.sm
        interactive: false

        delegate: NotificationCard {
            width: list.width
            entry: modelData
            interactive: true
            onDismissRequested: NotificationService.dismissToast(modelData.toastId)

            Timer {
                interval: modelData.timeoutMs
                running: modelData.timeoutMs > 0
                onTriggered: NotificationService.dismissToast(modelData.toastId)
            }
        }

        add: Transition {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Motion.base }
            NumberAnimation { property: "x"; from: list.width; duration: Motion.base; easing.type: Motion.standardEasing }
        }
        remove: Transition {
            NumberAnimation { property: "opacity"; to: 0; duration: Motion.fast }
        }
        displaced: Transition {
            NumberAnimation { property: "y"; duration: Motion.base; easing.type: Motion.standardEasing }
        }
    }
}
