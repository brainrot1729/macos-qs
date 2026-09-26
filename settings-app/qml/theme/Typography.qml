pragma Singleton
import QtQuick

// Uses the locally installed SF Pro Display. Document "install it
// yourself" rather than bundling the font files if this repo is ever
// published — same licensing note as the shell's copy of this file.
QtObject {
    readonly property string family: "SF Pro Display"
    readonly property string monoFamily: "SF Mono"

    readonly property int largeTitle: 26
    readonly property int title: 20
    readonly property int headline: 15
    readonly property int body: 13
    readonly property int caption: 11
}
