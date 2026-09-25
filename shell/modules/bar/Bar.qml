import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import Quickshell.Services.Pipewire
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Hyprland
import "../../theme"
import "../../components"
import "../../services"
import "../controlcenter"
import "../notifications"

PanelWindow {
    id: bar
    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: 28
    color: Colors.background

    // Required for Pipewire.defaultAudioSink's properties to actually
    // update, without this the node's volume/muted never notify.
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // First Wifi-type device on the system, or null if there isn't one.
    // .values is used (not iterating the ObjectModel directly) because
    // it's the reactive view, per Quickshell's own docs.
    readonly property var wifiDevice: {
        const devices = Networking.devices.values
        for (let i = 0; i < devices.length; i++) {
            if (devices[i].type === DeviceType.Wifi) return devices[i]
        }
        return null
    }

    readonly property var connectedWifi: {
        if (!bar.wifiDevice || !bar.wifiDevice.connected) return null
        const networks = bar.wifiDevice.networks.values
        for (let i = 0; i < networks.length; i++) {
            if (networks[i].connected) return networks[i]
        }
        return null
    }

    readonly property var btAdapter: Bluetooth.defaultAdapter

    // Control Center and Notification Center both anchor to this same
    // top-right corner, same as macOS. Only one open at a time.
    property bool ccOpen: false
    property bool ncOpen: false

    function openControlCenter() {
        bar.ncOpen = false
        bar.ccOpen = !bar.ccOpen
    }

    function openNotificationCenter() {
        bar.ccOpen = false
        bar.ncOpen = !bar.ncOpen
    }

    ControlCenter {
        id: controlCenter
        anchor.window: bar
        anchor.rect.x: bar.width - width - Spacing.md
        anchor.rect.y: bar.height
        visible: bar.ccOpen

        HyprlandFocusGrab {
            id: ccGrab
            windows: [controlCenter]
            onCleared: bar.ccOpen = false
        }
        onVisibleChanged: if (visible) ccGrab.active = true
    }

    NotificationCenter {
        id: notificationCenter
        anchor.window: bar
        anchor.rect.x: bar.width - width - Spacing.md
        anchor.rect.y: bar.height
        visible: bar.ncOpen

        HyprlandFocusGrab {
            id: ncGrab
            windows: [notificationCenter]
            onCleared: bar.ncOpen = false
        }
        onVisibleChanged: if (visible) ncGrab.active = true
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Spacing.md
        anchors.rightMargin: Spacing.md

        // Left: active app name, now real. Falls back to "Desktop"
        // when nothing is focused, macOS shows Finder in that spot,
        // we don't have an equivalent yet so this is the stand-in.
        Text {
            text: WindowService.activeAppName || "Desktop"
            color: Colors.textPrimary
            font.family: Typography.family
            font.pixelSize: Typography.body
            Layout.alignment: Qt.AlignVCenter
        }

        Item { Layout.fillWidth: true }

        RowLayout {
            spacing: Spacing.md
            Layout.alignment: Qt.AlignVCenter

            StatusIcon {
                source: {
                    if (!Networking.wifiEnabled || !bar.wifiDevice || !bar.wifiDevice.connected)
                        return Qt.resolvedUrl("../../assets/icons/wifi-off.svg")
                    return Qt.resolvedUrl("../../assets/icons/wifi-on.svg")
                }
                fill: !Networking.wifiEnabled || !bar.wifiDevice || !bar.wifiDevice.connected
                    ? 1
                    : (bar.connectedWifi ? bar.connectedWifi.signalStrength : 0)
                fillFromBottom: true
                showBackground: false
                Layout.preferredWidth: 16
                Layout.preferredHeight: 16
            }

            Text {
                text: {
                    const adapter = bar.btAdapter
                    if (!adapter || !adapter.enabled) return "bt off"
                    const connected = adapter.devices.values.filter(d => d.connected).length
                    return connected > 0 ? "bt " + connected : "bt on"
                }
                color: Colors.textSecondary
                font.family: Typography.family
                font.pixelSize: Typography.caption

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -Spacing.xs
                    onClicked: {
                        const adapter = bar.btAdapter
                        if (!adapter) return
                        adapter.enabled = !adapter.enabled
                    }
                }
            }

            Text {
                text: {
                    const sink = Pipewire.defaultAudioSink
                    if (!sink || !sink.audio) return "--"
                    if (sink.audio.muted) return "muted"
                    return Math.round(sink.audio.volume * 100) + "%"
                }
                color: Colors.textSecondary
                font.family: Typography.family
                font.pixelSize: Typography.caption
            }

            RowLayout {
                spacing: Spacing.xs

                StatusIcon {
                    readonly property var battery: UPower.displayDevice
                    source: battery && battery.state === UPowerDeviceState.Charging
                        ? Qt.resolvedUrl("../../assets/icons/battery-charging.svg")
                        : Qt.resolvedUrl("../../assets/icons/battery-draining.svg")
                    fillSource: Qt.resolvedUrl("../../assets/icons/battery-fill.svg")
                    fill: battery && battery.isPresent ? battery.percentage : 0
                    fillStart: 61 / 512
                    fillEnd: 391 / 512
                    backgroundColor: Colors.textPrimary
                    fillColor: battery && battery.percentage <= 0.2 ? "#ff453a" : Colors.textPrimary
                    Layout.preferredWidth: 18
                    Layout.preferredHeight: 16
                }

                Text {
                    text: {
                        const dev = UPower.displayDevice
                        if (!dev || !dev.isPresent) return "--"
                        return Math.round(dev.percentage * 100) + "%"
                    }
                    color: Colors.textSecondary
                    font.family: Typography.family
                    font.pixelSize: Typography.caption
                }
            }

            StatusIcon {
                source: Qt.resolvedUrl("../../assets/icons/control-center.svg")
                fillColor: Colors.textPrimary
                showBackground: false
                Layout.preferredWidth: 18
                Layout.preferredHeight: 18

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -Spacing.xs
                    onClicked: bar.openControlCenter()
                }
            }

            // Clicking the clock opens Notification Center, same as
            // clicking the date/time on macOS's menu bar.
            Text {
                text: Qt.formatDateTime(clock.date, "ddd d MMM  hh:mm")
                color: Colors.textPrimary
                font.family: Typography.family
                font.pixelSize: Typography.body

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -Spacing.xs
                    onClicked: bar.openNotificationCenter()
                }
            }
        }
    }
}
