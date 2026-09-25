import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../theme"
import "../../services"

// Uses Quickshell's WlSessionLock (ext-session-lock-v1), not a full-screen
// PanelWindow. This is the one place in the whole shell where that
// distinction is a security property and not just an implementation
// detail: ext-session-lock-v1 genuinely blocks input and compositing
// of everything underneath while locked=true, whereas a full-screen
// window is just a window another surface could still appear above or
// steal focus from. If this QML object is ever destroyed or Quickshell
// crashes while locked, the compositor leaves the screen locked and
// painted solid rather than exposing the session — that's intentional,
// not a bug to work around.
//
// Authentication never happens in QML. It's delegated to
// helper/qs-authenticate, a small setuid-root PAM helper (see
// helper/README.md for build + install steps). This file only ever
// sends a password to that helper's stdin and reads its exit code.
WlSessionLock {
    id: sessionLock
    locked: LockService.locked

    WlSessionLockSurface {
        id: surface
        color: Colors.background

        Rectangle {
            anchors.fill: parent
            color: Colors.background

            ColumnLayout {
                anchors.top: parent.top
                anchors.topMargin: 200
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Spacing.lg
                width: 340

                SystemClock {
                    id: lockClock
                    precision: SystemClock.Seconds
                }

                Text {
                    text: Qt.formatDateTime(lockClock.date, "hh:mm")
                    color: Colors.textPrimary
                    font.family: Typography.family
                    font.pixelSize: 72
                    font.bold: true
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: Qt.formatDateTime(lockClock.date, "dddd, d MMMM")
                    color: Colors.textSecondary
                    font.family: Typography.family
                    font.pixelSize: Typography.body
                    Layout.alignment: Qt.AlignHCenter
                }

            }

            Rectangle {
                id: fieldBox
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 100
                width: 220
                height: 40
                radius: 10
                color: Colors.surfaceElevated
                property real shakeOffset: 0
                transform: Translate { x: fieldBox.shakeOffset }
                border.width: 1
                border.color: LockService.authError.length > 0 ? "#ff453a" : Colors.separator

                Behavior on border.color {
                    ColorAnimation { duration: Motion.fast }
                }

                SequentialAnimation {
                    id: shakeAnim
                    loops: 1
                    NumberAnimation { target: fieldBox; property: "shakeOffset"; from: 0; to: -8; duration: 40 }
                    NumberAnimation { target: fieldBox; property: "shakeOffset"; from: -8; to: 8; duration: 40 }
                    NumberAnimation { target: fieldBox; property: "shakeOffset"; from: 8; to: -6; duration: 40 }
                    NumberAnimation { target: fieldBox; property: "shakeOffset"; from: -6; to: 0; duration: 40 }
                }

                TextInput {
                    id: passwordInput
                    anchors.fill: parent
                    anchors.margins: Spacing.sm
                    verticalAlignment: TextInput.AlignVCenter
                    color: Colors.textPrimary
                    font.family: Typography.family
                    font.pixelSize: Typography.body
                    echoMode: TextInput.Password
                    enabled: !authProcess.running
                    focus: sessionLock.locked

                    onTextEdited: LockService.authError = ""
                    Keys.onReturnPressed: attemptUnlock()
                }
            }

            Text {
                anchors.horizontalCenter: fieldBox.horizontalCenter
                anchors.bottom: fieldBox.top
                anchors.bottomMargin: Spacing.sm
                text: authProcess.running ? "Checking..." : LockService.authError
                visible: text.length > 0
                color: Colors.textSecondary
                font.family: Typography.family
                font.pixelSize: Typography.caption
            }
        }

        function attemptUnlock() {
            if (authProcess.running || passwordInput.text.length === 0) return
            authProcess.pendingPassword = passwordInput.text
            authProcess.running = true
        }

        // The helper reads exactly one line (the password) from its own
        // stdin, never from argv — argv is world-readable via
        // /proc/<pid>/cmdline while it's running, stdin isn't.
        Process {
            id: authProcess
            property string pendingPassword: ""
            command: ["qs-authenticate", Quickshell.env("USER")]
            stdinEnabled: true

            onRunningChanged: {
                if (running) {
                    write(pendingPassword + "\n")
                }
            }

            onExited: (exitCode) => {
                pendingPassword = ""
                if (exitCode === 0) {
                    LockService.unlock()
                } else {
                    LockService.authError = "Wrong password"
                    passwordInput.text = ""
                    shakeAnim.start()
                }
            }
        }

        // WlSessionLockSurface only ever appears once locked=true, so
        // grab focus every time a surface is (re)created for a screen,
        // not just once at startup.
        Component.onCompleted: passwordInput.forceActiveFocus()
    }
}
