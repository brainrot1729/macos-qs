import QtQuick
import Qt5Compat.GraphicalEffects
import "../theme"

// Same pattern as shell/components/StatusIcon.qml, trimmed to what the
// settings pages actually need: one source, one solid overlay color.
// Exists so pages stop using emoji ("\ud83d\udd0a", "\u2699", etc.) as
// icons — emoji render inconsistently across fonts/platforms and don't
// take a theme color, which is a big part of why the app looked
// mismatched from the shell.
Item {
    id: root
    property url source
    property color color: Colors.textPrimary

    implicitWidth: 18
    implicitHeight: 18

    Image {
        id: img
        anchors.fill: parent
        source: root.source
        sourceSize: Qt.size(width * 2, height * 2)
        fillMode: Image.PreserveAspectFit
        visible: false
    }

    ColorOverlay {
        anchors.fill: img
        source: img
        color: root.color
    }
}
