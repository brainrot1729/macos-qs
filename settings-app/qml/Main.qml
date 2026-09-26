import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "./theme"
import "./pages"

ApplicationWindow {
    id: window
    width: 820
    height: 560
    minimumWidth: 680
    minimumHeight: 440
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
        { id: "general", label: "General", icon: "\u2699" },
        { id: "wifi", label: "Wi-Fi", icon: "\ud83d\udcf6" },
        { id: "bluetooth", label: "Bluetooth", icon: "\u24b7" },
        { id: "sound", label: "Sound", icon: "\ud83d\udd0a" },
        { id: "displays", label: "Displays", icon: "\ud83d\udda5" },
        { id: "battery", label: "Battery", icon: "\ud83d\udd0b" },
        { id: "about", label: "About", icon: "\u2139" }
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
