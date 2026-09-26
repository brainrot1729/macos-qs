import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "./theme"
import "./pages"

// Root window. Previously this relied only on a QQC2 `palette {}` block to
// re-theme the default "Basic" style — that only recolors QQC2's own
// native controls (Button/Switch/Slider/ScrollBar chrome), it does not
// touch spacing, radii, or the emoji glyphs pages were using as icons.
// That's the real reason the app looked inconsistent with the shell no
// matter what CMake or palette settings were tried: most of what makes
// the shell look "right" (pill toggles, accent-filled sliders, real SVG
// icons, consistent card radii) was never expressed through QQC2's
// styling hooks at all in the shell either — it's custom QML components,
// not a Controls style. So the fix here is the same: pages now use
// controls/SToggle, SButton, SSlider, SCard, SIcon instead of the raw
// QtQuick.Controls versions and emoji text, and only fall back to plain
// QQC2 for things with no equivalent yet (TextField, ScrollBar internals).
ApplicationWindow {
    id: window
    width: 860
    height: 580
    minimumWidth: 700
    minimumHeight: 460
    visible: true
    title: "System Settings"
    color: Colors.background
    font.family: Typography.family
    font.pixelSize: Typography.body

    palette {
        window: Colors.background
        windowText: Colors.textPrimary
        base: Colors.surface
        alternateBase: Colors.surfaceElevated
        text: Colors.textPrimary
        button: Colors.surfaceElevated
        buttonText: Colors.textPrimary
        highlight: Colors.accent
        highlightedText: "#ffffff"
        placeholderText: Colors.textTertiary
        mid: Colors.separator
    }

    property var sections: [
        { id: "general", label: "General", icon: Qt.resolvedUrl("../assets/icons/gear.svg") },
        { id: "wifi", label: "Wi-Fi", icon: Qt.resolvedUrl("../assets/icons/wifi.svg") },
        { id: "bluetooth", label: "Bluetooth", icon: Qt.resolvedUrl("../assets/icons/bluetooth.svg") },
        { id: "sound", label: "Sound", icon: Qt.resolvedUrl("../assets/icons/speaker.svg") },
        { id: "displays", label: "Displays", icon: Qt.resolvedUrl("../assets/icons/display.svg") },
        { id: "battery", label: "Battery", icon: Qt.resolvedUrl("../assets/icons/battery.svg") },
        { id: "about", label: "About", icon: Qt.resolvedUrl("../assets/icons/info.svg") }
    ]
    property string currentSection: "general"

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Sidebar {
            Layout.preferredWidth: 220
            Layout.fillHeight: true
            sections: window.sections
            currentSection: window.currentSection
            onSectionSelected: (id) => window.currentSection = id
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Colors.surface

            Loader {
                anchors.fill: parent
                anchors.margins: Spacing.xl
                sourceComponent: {
                    switch (window.currentSection) {
                        case "wifi": return wifiPage
                        case "bluetooth": return bluetoothPage
                        case "sound": return soundPage
                        case "displays": return displaysPage
                        case "battery": return batteryPage
                        case "about": return aboutPage
                        default: return generalPage
                    }
                }
            }
        }
    }

    Component { id: generalPage; GeneralPage {} }
    Component { id: wifiPage; WiFiPage {} }
    Component { id: bluetoothPage; BluetoothPage {} }
    Component { id: soundPage; SoundPage {} }
    Component { id: displaysPage; DisplaysPage {} }
    Component { id: batteryPage; BatteryPage {} }
    Component { id: aboutPage; AboutPage {} }
}
