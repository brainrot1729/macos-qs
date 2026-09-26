import QtQuick
import Qt5Compat.GraphicalEffects
import "../theme"

// StatusIcon's fillFromBottom mask works for a single filled shape
// (battery) but breaks down on three disconnected stroke arcs: a
// rectangular bottom-up clip cuts straight through an arc's stroke
// instead of dimming/brightening it as a whole, which looks like a
// rendering glitch rather than "signal strength." Real macOS/iOS Wi-Fi
// icons light up whole arcs one at a time, so that's what this does:
// three independently colored ColorOverlay passes, one per arc asset,
// plus the base dot.
Item {
    id: root

    // 0 = no bars lit (off or disconnected), 1..3 = signal tier
    property int tier: 0
    property bool dimmed: false
    property color activeColor: Colors.textPrimary
    property color inactiveColor: Colors.textTertiary

    implicitWidth: 16
    implicitHeight: 16
    opacity: root.dimmed ? 0.5 : 1.0

    Image {
        id: dotSrc
        anchors.fill: parent
        source: Qt.resolvedUrl("../assets/icons/wifi-dot.svg")
        sourceSize: Qt.size(width * 2, height * 2)
        fillMode: Image.PreserveAspectFit
        visible: false
    }
    ColorOverlay {
        anchors.fill: dotSrc
        source: dotSrc
        color: root.activeColor
    }

    Image {
        id: innerSrc
        anchors.fill: parent
        source: Qt.resolvedUrl("../assets/icons/wifi-arc-inner.svg")
        sourceSize: Qt.size(width * 2, height * 2)
        fillMode: Image.PreserveAspectFit
        visible: false
    }
    ColorOverlay {
        anchors.fill: innerSrc
        source: innerSrc
        color: root.tier >= 1 ? root.activeColor : root.inactiveColor
    }

    Image {
        id: middleSrc
        anchors.fill: parent
        source: Qt.resolvedUrl("../assets/icons/wifi-arc-middle.svg")
        sourceSize: Qt.size(width * 2, height * 2)
        fillMode: Image.PreserveAspectFit
        visible: false
    }
    ColorOverlay {
        anchors.fill: middleSrc
        source: middleSrc
        color: root.tier >= 2 ? root.activeColor : root.inactiveColor
    }

    Image {
        id: outerSrc
        anchors.fill: parent
        source: Qt.resolvedUrl("../assets/icons/wifi-arc-outer.svg")
        sourceSize: Qt.size(width * 2, height * 2)
        fillMode: Image.PreserveAspectFit
        visible: false
    }
    ColorOverlay {
        anchors.fill: outerSrc
        source: outerSrc
        color: root.tier >= 3 ? root.activeColor : root.inactiveColor
    }
}
