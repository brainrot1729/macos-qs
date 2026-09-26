import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../theme"

// Adjust this import if LauncherService.qml is in another module.
import "../../services"

PanelWindow {
    id: root

    visible: LauncherService.visible
    color: "transparent"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.namespace: "macos-qs-launcher"

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            LauncherService.toggle();
        }

        function show(): void {
            LauncherService.show();
        }

        function hide(): void {
            LauncherService.hide();
        }
    }

    function close(): void {
        LauncherService.hide();
    }

    function launchSelected(): void {
        const index = results.currentIndex;
        const entries = LauncherService.results;
        const entry = index >= 0 ? entries[index] : null;

        if (!entry)
            return;
        entry.execute();
        root.close();
    }

    function updateCurrentIndex(): void {
        results.currentIndex = LauncherService.results.length > 0 ? 0 : -1;
    }

    Timer {
        id: focusTimer

        interval: 1
        repeat: false

        onTriggered: search.forceActiveFocus()
    }

    Connections {
        target: LauncherService

        function onVisibleChanged() {
            if (LauncherService.visible) {
                focusTimer.restart();
                updateCurrentIndex();
            }
        }

        function onQueryChanged() {
            updateCurrentIndex();

            if (search.text !== LauncherService.query)
                search.text = LauncherService.query;
        }
    }

    // Clicking outside the card closes the launcher.
    MouseArea {
        anchors.fill: parent

        onClicked: root.close()
    }

    Rectangle {
        id: card

        width: Math.min(parent.width - Spacing.xl * 2, 680)
        height: 520

        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.22

        radius: 14
        color: Colors.background
        border.width: 1
        border.color: Colors.separator
        clip: true

        // Consume clicks inside the card.
        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Spacing.md
            spacing: Spacing.md

            RowLayout {
                Layout.fillWidth: true
                spacing: Spacing.sm

                // The search asset lives under assets/icons.
                Item {
                    Layout.preferredWidth: 22
                    Layout.preferredHeight: 22
                    Layout.alignment: Qt.AlignVCenter

                    Image {
                        id: searchIcon
                        anchors.fill: parent
                        source: Qt.resolvedUrl("../../assets/icons/search.svg")
                        sourceSize: Qt.size(width * 2, height * 2)
                        fillMode: Image.PreserveAspectFit
                        visible: false
                    }

                    ColorOverlay {
                        anchors.fill: searchIcon
                        source: searchIcon
                        color: Colors.textPrimary
                        opacity: 0.8
                    }
                }

                Item {
                    Layout.fillWidth: true
                    implicitHeight: search.implicitHeight

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: search.verticalCenter

                        text: "Search applications"
                        color: Colors.textTertiary
                        font.family: Typography.family
                        font.pixelSize: Typography.title

                        visible: search.text.length === 0 && !search.activeFocus
                    }

                    TextInput {
                        id: search

                        anchors.fill: parent

                        color: Colors.textPrimary
                        selectionColor: Colors.accent
                        font.family: Typography.family
                        font.pixelSize: Typography.title
                        clip: true

                        text: LauncherService.query
                        focus: LauncherService.visible

                        onTextEdited: {
                            if (LauncherService.query !== text)
                                LauncherService.query = text;
                        }

                        Keys.onPressed: function (event) {
                            if (event.key === Qt.Key_Down) {
                                results.incrementCurrentIndex();
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Up) {
                                results.decrementCurrentIndex();
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                root.launchSelected();
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Escape) {
                                root.close();
                                event.accepted = true;
                            }
                        }
                    }
                }

                Text {
                    text: "esc"
                    color: Colors.textTertiary
                    font.family: Typography.monoFamily
                    font.pixelSize: Typography.caption
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Colors.separator
            }

            ListView {
                id: results

                Layout.fillWidth: true
                Layout.fillHeight: true

                model: LauncherService.results
                currentIndex: LauncherService.results.length > 0 ? 0 : -1

                clip: true
                spacing: 2

                flickDeceleration: 1500
                maximumFlickVelocity: 1800
                boundsBehavior: Flickable.StopAtBounds

                NumberAnimation {
                    id: smoothScrollAnimation

                    target: results
                    property: "contentY"
                    duration: 200
                    easing.type: Easing.OutCubic
                }

                WheelHandler {
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad

                    onWheel: function (event) {
                        const delta = event.pixelDelta.y !== 0 ? event.pixelDelta.y : event.angleDelta.y / 120 * 58;

                        const maximumScroll = Math.max(0, results.contentHeight - results.height);

                        const nextY = Math.max(0, Math.min(maximumScroll, results.contentY - delta));

                        smoothScrollAnimation.stop();
                        smoothScrollAnimation.from = results.contentY;
                        smoothScrollAnimation.to = nextY;
                        smoothScrollAnimation.restart();

                        event.accepted = true;
                    }
                }

                delegate: Rectangle {
                    id: row

                    required property int index
                    required property var modelData

                    property var entry: modelData

                    width: results.width
                    height: 58
                    radius: 9

                    color: ListView.isCurrentItem ? Colors.surfaceElevated : "transparent"

                    Image {
                        id: appIcon

                        anchors.left: parent.left
                        anchors.leftMargin: Spacing.sm
                        anchors.verticalCenter: parent.verticalCenter

                        width: 40
                        height: 40

                        source: Quickshell.iconPath(row.entry.icon, true)
                        sourceSize.width: 40
                        sourceSize.height: 40
                        fillMode: Image.PreserveAspectFit

                        visible: status === Image.Ready
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.leftMargin: Spacing.sm
                        anchors.verticalCenter: parent.verticalCenter

                        width: 40
                        height: 40
                        radius: 9

                        color: Colors.controlBackground
                        visible: !appIcon.visible

                        Text {
                            anchors.centerIn: parent

                            text: row.entry.name && row.entry.name.length > 0 ? row.entry.name.charAt(0).toUpperCase() : "?"

                            color: Colors.textPrimary
                            font.family: Typography.family
                            font.pixelSize: Typography.title
                        }
                    }

                    Column {
                        anchors.left: parent.left
                        anchors.leftMargin: 64
                        anchors.right: parent.right
                        anchors.rightMargin: Spacing.md
                        anchors.verticalCenter: parent.verticalCenter

                        spacing: 2

                        Text {
                            width: parent.width

                            text: row.entry.name || ""
                            color: Colors.textPrimary
                            font.family: Typography.family
                            font.pixelSize: Typography.body
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width

                            text: row.entry.genericName || row.entry.comment || "Application"

                            color: Colors.textSecondary
                            font.family: Typography.family
                            font.pixelSize: Typography.caption
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true

                        onEntered: {
                            results.currentIndex = row.index;
                        }

                        onClicked: {
                            results.currentIndex = row.index;
                            root.launchSelected();
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent

                    visible: results.count === 0

                    text: LauncherService.query.trim().length > 0 ? "No applications found" : "No applications available"

                    color: Colors.textSecondary
                    font.family: Typography.family
                    font.pixelSize: Typography.body
                }

                ScrollBar.vertical: ScrollBar {
                    id: verticalScrollBar

                    policy: ScrollBar.AsNeeded
                    width: 10

                    contentItem: Rectangle {
                        implicitWidth: 10
                        radius: width / 2

                        color: verticalScrollBar.pressed ? Colors.textPrimary : Colors.textSecondary

                        opacity: verticalScrollBar.active || verticalScrollBar.pressed ? 1.0 : 0.85

                        Behavior on color {
                            ColorAnimation {
                                duration: Motion.fast
                            }
                        }

                        Behavior on opacity {
                            NumberAnimation {
                                duration: Motion.fast
                            }
                        }
                    }

                    background: Rectangle {
                        implicitWidth: 10
                        radius: width / 2

                        color: Colors.controlBackground
                        opacity: 0.8
                    }
                }
            }
        }
    }
}
