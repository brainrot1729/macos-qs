import Quickshell
import QtQuick
import Quickshell.Io
import "./modules/bar"
import "./modules/dock"
import "./modules/notifications"
import "./modules/launcher"
import "./modules/lockscreen"
import "./services"

ShellRoot {
    IpcHandler {
        target: "lock"
        function lock(): void { LockService.lock() }
    }

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
}
