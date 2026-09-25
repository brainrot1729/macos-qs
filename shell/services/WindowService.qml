pragma Singleton
import QtQuick
import Quickshell.Wayland

// Wraps ToplevelManager (wlr-foreign-toplevel-management, compositor
// agnostic) instead of Hyprland's own IPC module. Same protocol works
// on labwc, so this doesn't have to be rewritten if the compositor
// choice ever gets revisited. This is also the data source the dock
// will read from directly, no separate lookup needed there.
QtObject {
    readonly property var active: ToplevelManager.activeToplevel

    // appId is a raw identifier ("kitty", "firefox"), not a display
    // name. Real pretty names and icons need a .desktop file lookup,
    // which is deferred to the dock, where it's actually required
    // for icons and not just cosmetic for a text label.
    readonly property string activeAppName: {
        if (!active || !active.appId || active.appId.length === 0) return ""
        return active.appId.charAt(0).toUpperCase() + active.appId.slice(1)
    }

    readonly property var toplevels: ToplevelManager.toplevels
}
