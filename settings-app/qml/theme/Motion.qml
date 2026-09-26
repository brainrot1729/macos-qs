pragma Singleton
import QtQuick

QtObject {
    readonly property int fast: 150
    readonly property int base: 220
    readonly property int slow: 320

    readonly property int standardEasing: Easing.OutCubic
    readonly property int emphasizedEasing: Easing.InOutCubic
}
