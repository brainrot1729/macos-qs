import QtQuick
import QtQuick.Layouts
import Quickshell
import "../theme"

Rectangle {
    id: root
    property var entry // { appName, icon, summary, body, time, notification? }
    property bool interactive: false // toast mode: hover-reveal close + action buttons
    property bool hovered: false

    signal dismissRequested()

    implicitWidth: 300
    implicitHeight: column.implicitHeight + Spacing.md * 2
    radius: 12
    color: Colors.surfaceElevated
    border.width: 1
    border.color: Colors.separator

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onEntered: root.hovered = true
        onExited: root.hovered = false
    }

    Column {
        id: column
        anchors.fill: parent
        anchors.margins: Spacing.md
        spacing: Spacing.xs

        RowLayout {
            width: parent.width
            spacing: Spacing.sm

            Image {
                source: root.entry && root.entry.icon ? Quickshell.iconPath(root.entry.icon, true) : ""
                visible: source !== ""
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
                sourceSize.width: 20
                sourceSize.height: 20
                fillMode: Image.PreserveAspectFit
            }

            Text {
                text: root.entry ? root.entry.appName : ""
                color: Colors.textSecondary
                font.family: Typography.family
                font.pixelSize: Typography.caption
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            Text {
                text: root.entry ? Qt.formatTime(root.entry.time, "hh:mm") : ""
                color: Colors.textTertiary
                font.family: Typography.family
                font.pixelSize: Typography.caption
                visible: !(root.interactive && root.hovered)
            }

            Text {
                text: "\u00d7" // ×
                visible: root.interactive && root.hovered
                color: Colors.textSecondary
                font.pixelSize: Typography.body

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    onClicked: root.dismissRequested()
                }
            }
        }

        Text {
            text: root.entry ? root.entry.summary : ""
            width: parent.width
            color: Colors.textPrimary
            font.family: Typography.family
            font.pixelSize: Typography.body
            font.bold: true
            wrapMode: Text.WordWrap
            visible: text.length > 0
        }

        Text {
            text: root.entry ? root.entry.body : ""
            width: parent.width
            color: Colors.textSecondary
            font.family: Typography.family
            font.pixelSize: Typography.caption
            wrapMode: Text.WordWrap
            maximumLineCount: 3
            elide: Text.ElideRight
            visible: text.length > 0
        }

        // Actions need the live Notification object (they call .invoke()
        // on a real NotificationAction), so they only ever show on a
        // toast, never in Notification Center's history, where the
        // underlying object is long gone.
        Row {
            visible: root.interactive && root.entry && root.entry.notification
                     && root.entry.notification.actions.length > 0
            spacing: Spacing.xs

            Repeater {
                model: root.interactive && root.entry && root.entry.notification
                       ? root.entry.notification.actions : []
                delegate: MButton {
                    text: modelData.text
                    onClicked: modelData.invoke()
                }
            }
        }
    }
}
