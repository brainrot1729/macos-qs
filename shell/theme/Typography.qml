pragma Singleton
import QtQuick

// Uses the locally installed SF Pro Display / SF Mono. If this repo
// is ever published, document "install SF Pro yourself" rather than
// bundling the font files, your license to use it isn't a license
// to redistribute it.
QtObject {
    readonly property string family: "SF Pro Display"
    readonly property string monoFamily: "SF Mono"

    readonly property int largeTitle: 26
    readonly property int title: 20
    readonly property int headline: 15
    readonly property int body: 13
    readonly property int caption: 11
}
