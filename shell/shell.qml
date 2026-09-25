import Quickshell
import QtQuick
import "./theme"
import "./components"
import "./modules/bar"
import "./modules/dock"
import "./modules/notifications"
import "./modules/launcher"
import "./modules/lockscreen"

ShellRoot {
    Bar {}
    Dock {}

    // Always-on overlay: shows toasts whenever NotificationService gets a
    // new notification. Not opened on demand like Control Center/Notification
    // Center, which live as children of Bar instead.
    NotificationToastStack {}

    // Opened on demand via IPC (see Launcher.qml's IpcHandler and
    // compositor-config/ for the Hyprland keybind that calls it), not
    // via a click target the way Control Center/Notification Center are.
    Launcher {}

    // Also opened on demand via IPC (`qs ipc call lock lock`, bound to
    // Super+L). Unlike everything else in this list, it must exist for
    // the entire lifetime of the shell process even while not locked —
    // see LockScreen.qml's header comment on why destroying it while
    // locked would be a security problem, not just a bug.
    LockScreen {}

    // Phase 1 test harness: every base component in one floating window.
    // Close it once you're done checking it, it's not part of the shell,
    // just a workbench for building the design system.
    FloatingWindow {
        id: harness
        visible: true
        title: "macos-qs component harness"
        implicitWidth: 360
        implicitHeight: 340
        color: Colors.background

        Column {
            anchors.fill: parent
            anchors.margins: Spacing.lg
            spacing: Spacing.md

            Text {
                text: "Component harness"
                color: Colors.textPrimary
                font.family: Typography.family
                font.pixelSize: Typography.title
            }

            Row {
                spacing: Spacing.sm
                MButton { text: "Cancel" }
                MButton { text: "Continue"; primary: true }
            }

            MToggle { checked: true }

            MSlider { value: 0.4 }

            Popover {
                width: 220
                height: 70
                Text {
                    text: "Popover content"
                    color: Colors.textPrimary
                    font.family: Typography.family
                    font.pixelSize: Typography.body
                }
            }
        }
    }
}
