pragma Singleton
import QtQuick

// Deliberately thin: this singleton only ever tracks *state*, never
// performs authentication itself. PAM auth happens in a separate
// setuid-root helper binary (helper/qs-authenticate.c), invoked from
// LockScreen.qml as a Process — the same "never roll your own auth
// logic in QML" rule from the technical decisions doc.
//
// unlock() is intentionally NOT exposed over IPC (see LockScreen.qml's
// IpcHandler, which only registers lock()). Only a successful PAM
// check should ever be able to flip `locked` back to false — exposing
// an unlock IPC target would let any local process unlock the session
// without a password.
QtObject {
    id: root

    property bool locked: false

    // Set on a failed attempt, cleared on the next keystroke or on a
    // fresh lock. Purely cosmetic (drives the error text + shake in
    // LockScreen.qml), never anything an unauthenticated caller can
    // read to learn account state.
    property string authError: ""

    function lock() {
        root.authError = ""
        root.locked = true
    }

    // Called only from inside LockScreen.qml after pam auth succeeds.
    function unlock() {
        root.locked = false
        root.authError = ""
    }
}
