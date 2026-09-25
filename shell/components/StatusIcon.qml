import QtQuick
import Qt5Compat.GraphicalEffects

Item {
    id: root

    property url source
    property url fillSource
    property real fill: 1
    property color backgroundColor: "#a1a1a6"
    property color fillColor: "#f5f5f7"
    property bool fillFromBottom: false
    property bool showBackground: true
    property real fillStart: 0
    property real fillEnd: 1

    implicitWidth: 16
    implicitHeight: 16

    Image {
        id: backgroundImage
        anchors.fill: parent
        source: root.source
        sourceSize: Qt.size(root.width * 2, root.height * 2)
        fillMode: Image.PreserveAspectFit
        visible: false
    }

    ColorOverlay {
        anchors.fill: backgroundImage
        source: backgroundImage
        color: root.backgroundColor
        visible: root.showBackground
    }

    Item {
        anchors.fill: parent
        clip: true

        Rectangle {
            x: root.fillFromBottom ? 0 : parent.width * root.fillStart
            width: root.fillFromBottom
                ? parent.width
                : parent.width * (root.fillEnd - root.fillStart) * Math.max(0, Math.min(1, root.fill))
            height: root.fillFromBottom ? parent.height * Math.max(0, Math.min(1, root.fill)) : parent.height
            anchors.bottom: root.fillFromBottom ? parent.bottom : undefined
            color: "transparent"
            clip: true

            Image {
                id: fillImage
                width: root.width
                height: root.height
                y: root.fillFromBottom ? parent.height - root.height : 0
                source: root.fillSource.toString().length > 0 ? root.fillSource : root.source
                sourceSize: Qt.size(root.width * 2, root.height * 2)
                fillMode: Image.PreserveAspectFit
                visible: false
            }

            ColorOverlay {
                anchors.fill: fillImage
                source: fillImage
                color: root.fillColor
            }
        }
    }
}