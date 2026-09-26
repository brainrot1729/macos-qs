import QtQuick
import QtQuick.Layouts
import "./theme"
import "./controls"

Rectangle {
    id: root
    color: Colors.background

    // Each section: { id, label, icon } where icon is a resolved SVG url.
    property var sections: []
    property string currentSection: ""
    signal sectionSelected(string id)

    Rectangle {
        anchors.right: parent.right
        width: 1
        height: parent.height
        color: Colors.separator
    }

    ListView {
        anchors.fill: parent
        anchors.margins: Spacing.md
        spacing: 2
        model: root.sections
        interactive: false

        delegate: Rectangle {
            id: row
            required property var modelData
            width: ListView.view.width
            height: 34
            radius: 8
            color: modelData.id === root.currentSection ? Colors.accent : "transparent"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Spacing.sm
                anchors.rightMargin: Spacing.sm
                spacing: Spacing.sm

                SIcon {
                    source: row.modelData.icon
                    color: row.modelData.id === root.currentSection ? "#ffffff" : Colors.textSecondary
                    Layout.preferredWidth: 17
                    Layout.preferredHeight: 17
                }

                Text {
                    text: row.modelData.label
                    color: row.modelData.id === root.currentSection ? "#ffffff" : Colors.textPrimary
                    font.family: Typography.family
                    font.pixelSize: Typography.body
                    Layout.fillWidth: true
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.sectionSelected(row.modelData.id)
            }
        }
    }
}
