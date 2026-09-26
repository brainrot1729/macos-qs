import QtQuick
import "../theme"

Rectangle {
    id: root
    default property alias content: contentItem.data
    color: Colors.controlBackground
    radius: 12

    Item {
        id: contentItem
        anchors.fill: parent
        anchors.margins: Spacing.md
    }
}
