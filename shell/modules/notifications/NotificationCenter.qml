import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../theme"
import "../../components"
import "../../services"

// Same PopupWindow + HyprlandFocusGrab pattern as ControlCenter: anchored
// to the bar by whoever instantiates this (see Bar.qml), dismissed by
// clicking outside.
PopupWindow {
    id: root
    implicitWidth: 320
    implicitHeight: content.implicitHeight + Spacing.lg * 2
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        color: Colors.surface
        radius: 14
        border.width: 1
        border.color: Colors.separator
    }

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: Spacing.lg
        spacing: Spacing.md

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Notifications"
                color: Colors.textPrimary
                font.family: Typography.family
                font.pixelSize: Typography.headline
                Layout.fillWidth: true
            }

            Text {
                text: "Clear"
                visible: NotificationService.history.length > 0
                color: Colors.textSecondary
                font.family: Typography.family
                font.pixelSize: Typography.caption

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -Spacing.xs
                    onClicked: NotificationService.clearHistory()
                }
            }
        }

        ListView {
            id: list
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(contentHeight, 420)
            visible: NotificationService.history.length > 0
            model: NotificationService.history
            spacing: Spacing.sm
            clip: true

            delegate: NotificationCard {
                width: list.width
                entry: modelData
                interactive: false
            }
        }

        Text {
            visible: NotificationService.history.length === 0
            text: "No notifications"
            color: Colors.textTertiary
            font.family: Typography.family
            font.pixelSize: Typography.body
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Spacing.md
            Layout.bottomMargin: Spacing.md
        }
    }
}
