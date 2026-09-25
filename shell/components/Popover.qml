import QtQuick
import "../theme"

Rectangle {
    id: root
    default property alias content: contentItem.data
    color: Colors.surface
    radius: 10
    border.width: 1
    border.color: Colors.separator

    Item {
        id: contentItem
        anchors.fill: parent
        anchors.margins: Spacing.md
    }
}
