pragma Singleton
import QtQuick

// Dark-mode tokens only for now. Light mode is a Phase 12 concern,
// deliberately not designed in yet so we don't guess at values we'd
// have to redo anyway.
QtObject {
    readonly property color background: "#1e1e1e"
    readonly property color surface: "#2c2c2e"
    readonly property color surfaceElevated: "#3a3a3c"

    readonly property color accent: "#0a84ff"

    readonly property color textPrimary: "#f5f5f7"
    readonly property color textSecondary: "#a1a1a6"
    readonly property color textTertiary: "#636366"

    readonly property color separator: "#3a3a3c"
    readonly property color controlBackground: "#3a3a3c"
}
