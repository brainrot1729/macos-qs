import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../theme"
import "../../services"

// Full-screen transparent layer-shell surface (so clicking anywhere
// outside the search card dismisses it), with a centered card holding
// the actual search box + results — same visual idea as Spotlight.
//
// Unlike ControlCenter/NotificationCenter (PopupWindow + HyprlandFocusGrab,
// no keyboard input needed), this surface has to actually receive
// keyboard input, so it claims layer-shell keyboard focus directly
// instead of relying on a focus-grab-to-dismiss pattern.
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

    // Exposes `qs ipc call launcher toggle|show|hide` to the outside
    // world, so a Hyprland keybind can summon this without Quickshell
    // needing its own global-hotkey system. See compositor-config/
    // for the keybind that calls this.
    //
    // FIX: Quickshell's IPC system silently refuses to register any
    // handler function whose argument and return types aren't spelled
    // out explicitly (this is documented, not a guess) — a bare
    // "function toggle() { ... }" never becomes callable via
    // `qs ipc call`, even though the QML itself loads without error.
    // That's exactly why the launcher never opened: the keybind was
    // firing, Hyprland was running the command, but there was nothing
    // registered under target "launcher" for it to call. Adding the
    // ": void" return type on every function is the actual fix below.
    IpcHandler {
        target: "launcher"
        function toggle(): void { LauncherService.toggle() }
        function show(): void { LauncherService.show() }
        function hide(): void { LauncherService.hide() }
    }

    onVisibleChanged: {
        if (visible) {
            searchInput.forceActiveFocus()
            resultsList.currentIndex = 0
        }
    }

    // Click anywhere outside the card dismisses, same interaction as
    // Spotlight and as this project's own Control Center/Notification
    // Center popups.
    MouseArea {
        anchors.fill: parent
        onClicked: LauncherService.hide()
    }

    Rectangle {
        id: card
        width: 560
        height: cardColumn.implicitHeight + Spacing.lg * 2
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.22
        radius: 14
        color: Colors.surface
        border.width: 1
        border.color: Colors.separator

        // Swallow clicks inside the card so they don't fall through to
        // the full-screen dismiss MouseArea behind it.
        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            id: cardColumn
            anchors.fill: parent
            anchors.margins: Spacing.lg
            spacing: Spacing.md

            Item {
                Layout.fillWidth: true
                implicitHeight: searchInput.implicitHeight

                Text {
                    text: "Spotlight Search"
                    visible: searchInput.text.length === 0
                    color: Colors.textTertiary
                    font.family: Typography.family
                    font.pixelSize: Typography.title
                }

                TextInput {
                    id: searchInput
                    width: parent.width
                    color: Colors.textPrimary
                    font.family: Typography.family
                    font.pixelSize: Typography.title
                    text: LauncherService.query

                    onTextEdited: LauncherService.query = text
                    onTextChanged: if (text.length === 0) resultsList.currentIndex = 0

                    Keys.onEscapePressed: LauncherService.hide()
                    Keys.onDownPressed: resultsList.incrementCurrentIndex()
                    Keys.onUpPressed: resultsList.decrementCurrentIndex()
                    Keys.onReturnPressed: {
                        const item = LauncherService.results[resultsList.currentIndex]
                        if (item) {
                            item.execute()
                            LauncherService.hide()
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Colors.separator
                visible: resultsList.count > 0
            }

            ListView {
                id: resultsList
                Layout.fillWidth: true
                Layout.preferredHeight: contentHeight
                model: LauncherService.results
                clip: true
                currentIndex: 0

                delegate: Rectangle {
                    id: row
                    required property var modelData
                    required property int index
                    width: resultsList.width
                    height: 44
                    radius: 8
                    color: resultsList.currentIndex === index ? Colors.surfaceElevated : "transparent"

                    Behavior on color {
                        ColorAnimation { duration: Motion.fast }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Spacing.sm
                        anchors.rightMargin: Spacing.sm
                        spacing: Spacing.sm

                        Image {
                            source: row.modelData.icon ? Quickshell.iconPath(row.modelData.icon, true) : ""
                            visible: source !== ""
                            Layout.preferredWidth: 28
                            Layout.preferredHeight: 28
                            sourceSize.width: 28
                            sourceSize.height: 28
                            fillMode: Image.PreserveAspectFit
                        }

                        Rectangle {
                            visible: !(row.modelData.icon && row.modelData.icon.length > 0)
                            Layout.preferredWidth: 28
                            Layout.preferredHeight: 28
                            radius: 6
                            color: Colors.surfaceElevated

                            Text {
                                anchors.centerIn: parent
                                text: row.modelData.name ? row.modelData.name.charAt(0).toUpperCase() : "?"
                                color: Colors.textPrimary
                                font.family: Typography.family
                                font.pixelSize: Typography.caption
                            }
                        }

                        Text {
                            text: row.modelData.name || ""
                            color: Colors.textPrimary
                            font.family: Typography.family
                            font.pixelSize: Typography.body
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: resultsList.currentIndex = row.index
                        onClicked: {
                            row.modelData.execute()
                            LauncherService.hide()
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: resultsList.count === 0 && LauncherService.query.length > 0
                    text: "No results"
                    color: Colors.textTertiary
                    font.family: Typography.family
                    font.pixelSize: Typography.body
                }
            }
        }
    }
}
