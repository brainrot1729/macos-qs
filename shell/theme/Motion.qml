pragma Singleton
import QtQuick

QtObject {
    readonly property int fast: 150
    readonly property int base: 220
    readonly property int slow: 320

    // Plain named easing for now, close enough to macOS's default
    // deceleration curve. Tuning to a custom cubic-bezier is a later
    // polish pass, not a Phase 1 problem.
    readonly property int standardEasing: Easing.OutCubic
    readonly property int emphasizedEasing: Easing.InOutCubic
}
