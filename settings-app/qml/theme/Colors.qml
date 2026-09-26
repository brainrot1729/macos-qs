pragma Singleton
import QtQuick

// Kept identical to shell/theme/Colors.qml so Settings and the shell look
// like one system. Copied rather than shared, since this app has no
// dependency on the Quickshell process — if you change one, change both.
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
