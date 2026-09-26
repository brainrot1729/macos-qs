import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.UPower
import "../../theme"
import "../../components"
import "../../services"

// macOS puts Wi-Fi/Bluetooth detail (the network/device list) *inside*
// Control Center itself — clicking the chevron on a row swaps the whole
// panel to that module's detail view with a back arrow, rather than
// opening a second floating window. That's what expandedPanel drives:
// a Loader swaps between the main grid and one detail view, and the
// PopupWindow's height follows whichever is showing.
PopupWindow {
    id: root
    implicitWidth: 360
    implicitHeight: content.implicitHeight + Spacing.lg * 2
    color: "transparent"

    property bool displayExpanded: false
    property real brightnessValue: 0.5
    property string expandedPanel: "" // "", "wifi", "bluetooth"
    property string connectingSsid: ""
    property string wifiError: ""

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var wifiDevice: {
        const devices = Networking.devices.values
        for (let i = 0; i < devices.length; i++) {
            if (devices[i].type === DeviceType.Wifi) return devices[i]
        }
        return null
    }

    function setVolume(value) {
        const sink = Pipewire.defaultAudioSink
        if (sink && sink.audio) {
            sink.audio.muted = false
            sink.audio.volume = value
        }
    }

    function wifiName() {
        if (!Networking.wifiEnabled) return "Wi-Fi Off"
        if (!root.wifiDevice || !root.wifiDevice.connected) return "Not Connected"
        const networks = root.wifiDevice.networks.values
        for (let i = 0; i < networks.length; i++) {
            if (networks[i].connected) return networks[i].name || "Connected"
        }
        return "Connected"
    }

    function closePanel() {
        root.expandedPanel = ""
        root.connectingSsid = ""
        root.wifiError = ""
    }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    Rectangle {
        anchors.fill: parent
        color: Colors.surface
        radius: 20
        border.width: 1
        border.color: Colors.separator
    }

    Column {
        id: content
        anchors.fill: parent
        anchors.margins: Spacing.lg

        Loader {
            id: panelLoader
            width: parent.width
            sourceComponent: root.expandedPanel === "wifi" ? wifiDetail
                : root.expandedPanel === "bluetooth" ? bluetoothDetail
                : mainGrid
        }
    }

    // ---- Main grid: the default, collapsed view -----------------------
    Component {
        id: mainGrid

        Column {
            width: parent.width
            spacing: Spacing.sm

            Row {
                width: parent.width
                spacing: Spacing.sm

                Rectangle {
                    id: connectivityCard
                    width: parent.width * 0.59
                    height: 140
                    radius: 16
                    color: Colors.controlBackground

                    Column {
                        anchors.fill: parent
                        anchors.margins: Spacing.sm
                        spacing: 0

                        ConnectivityRow {
                            width: parent.width
                            iconSource: Qt.resolvedUrl("../../assets/icons/wifi-on.svg")
                            title: "Wi-Fi"
                            subtitle: root.wifiName()
                            active: Networking.wifiEnabled
                            showChevron: true
                            onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
                            onChevronClicked: root.expandedPanel = "wifi"
                        }

                        Rectangle { width: parent.width; height: 1; color: Colors.background }

                        ConnectivityRow {
                            width: parent.width
                            iconSource: Qt.resolvedUrl("../../assets/icons/bluetooth-on.svg")
                            title: "Bluetooth"
                            subtitle: root.adapter && root.adapter.enabled ? "On" : "Off"
                            active: root.adapter ? root.adapter.enabled : false
                            showChevron: true
                            onClicked: if (root.adapter) root.adapter.enabled = !root.adapter.enabled
                            onChevronClicked: root.expandedPanel = "bluetooth"
                        }

                        Rectangle { width: parent.width; height: 1; color: Colors.background }

                        ConnectivityRow {
                            width: parent.width
                            title: "AirDrop"
                            subtitle: "Unavailable"
                            rowEnabled: false
                        }
                    }
                }

                Column {
                    width: parent.width - connectivityCard.width - parent.spacing
                    spacing: Spacing.sm

                    ControlTile {
                        width: parent.width
                        height: 44
                        title: "Do Not Disturb"
                        subtitle: NotificationService.dndEnabled ? "On" : "Off"
                        active: NotificationService.dndEnabled
                        onClicked: NotificationService.dndEnabled = !NotificationService.dndEnabled
                    }

                    ControlTile {
                        width: parent.width
                        height: 44
                        title: "Keyboard Brightness"
                        subtitle: "Unavailable"
                        enabled: false
                    }

                    ControlTile {
                        width: parent.width
                        height: 44
                        title: "AirPlay"
                        subtitle: "Unavailable"
                        enabled: false
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: root.displayExpanded ? 108 : 62
                radius: 14
                color: Colors.controlBackground
                clip: true

                Behavior on height {
                    NumberAnimation { duration: Motion.base; easing.type: Motion.standardEasing }
                }

                Column {
                    anchors.fill: parent
                    anchors.margins: Spacing.md
                    spacing: Spacing.sm

                    RowLayout {
                        width: parent.width

                        Text {
                            text: "Display"
                            color: Colors.textPrimary
                            font.family: Typography.family
                            font.pixelSize: Typography.caption
                            font.bold: true
                            Layout.fillWidth: true
                        }

                        Text {
                            text: root.displayExpanded ? "\u25b4" : "\u25be"
                            color: Colors.textTertiary
                            font.pixelSize: Typography.caption

                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -8
                                onClicked: root.displayExpanded = !root.displayExpanded
                            }
                        }
                    }

                    RowLayout {
                        width: parent.width
                        spacing: Spacing.sm

                        Text {
                            text: "\u2600"
                            color: Colors.textSecondary
                            font.pixelSize: Typography.body
                        }

                        MSlider {
                            Layout.fillWidth: true
                            value: root.brightnessValue
                            onMoved: (v) => {
                                root.brightnessValue = v
                                brightnessSet.run(v)
                            }
                        }
                    }

                    Row {
                        visible: root.displayExpanded
                        width: parent.width
                        spacing: Spacing.xs

                        Repeater {
                            model: [0, 0.25, 0.5, 0.75, 1.0]
                            delegate: Rectangle {
                                required property real modelData
                                width: (parent.width - Spacing.xs * 4) / 5
                                height: 22
                                radius: 6
                                color: Colors.surfaceElevated

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData === 0 ? "Off" : Math.round(modelData * 100) + "%"
                                    color: Colors.textSecondary
                                    font.family: Typography.family
                                    font.pixelSize: 10
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        root.brightnessValue = modelData
                                        brightnessSet.run(modelData)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 62
                radius: 14
                color: Colors.controlBackground

                Column {
                    anchors.fill: parent
                    anchors.margins: Spacing.md
                    spacing: Spacing.sm

                    Text {
                        text: "Sound"
                        color: Colors.textPrimary
                        font.family: Typography.family
                        font.pixelSize: Typography.caption
                        font.bold: true
                    }

                    RowLayout {
                        width: parent.width
                        spacing: Spacing.sm

                        Text {
                            text: {
                                const sink = Pipewire.defaultAudioSink
                                return sink && sink.audio && sink.audio.muted ? "\ud83d\udd07" : "\ud83d\udd0a"
                            }
                            color: Colors.textSecondary
                            font.pixelSize: Typography.body
                        }

                        MSlider {
                            id: volumeSlider
                            Layout.fillWidth: true
                            value: {
                                const sink = Pipewire.defaultAudioSink
                                return sink && sink.audio ? sink.audio.volume : 0
                            }
                            onMoved: (v) => root.setVolume(v)
                        }
                    }
                }
            }

            // A plain "value: sink.audio.volume" binding above only survives
            // until the user drags the slider once — dragging assigns
            // volumeSlider.value directly, and any imperative write to a
            // property permanently breaks its declarative binding in QML.
            // Re-asserting the value on every real change sidesteps that,
            // since it's just a plain write either way, not a binding to
            // break.
            Connections {
                target: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null
                function onVolumeChanged() {
                    volumeSlider.value = Pipewire.defaultAudioSink.audio.volume
                }
            }

            // Read current brightness on open (brightnessctl has no change
            // notification, so this is poll-on-show rather than push).
            Process {
                id: brightnessGet
                command: ["brightnessctl", "g"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        const current = parseInt(text.trim())
                        if (!isNaN(current)) {
                            brightnessMax.running = true
                        }
                    }
                }
            }
            Process {
                id: brightnessMax
                command: ["brightnessctl", "m"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        const max = parseInt(text.trim())
                        const current = parseInt(brightnessGet.stdout.text.trim())
                        if (!isNaN(max) && max > 0 && !isNaN(current)) {
                            root.brightnessValue = current / max
                        }
                    }
                }
            }
            Process {
                id: brightnessSet
                property real pending: 0
                function run(v) {
                    pending = v
                    command = ["brightnessctl", "s", Math.round(v * 100) + "%"]
                    running = true
                }
            }

            Rectangle {
                width: parent.width
                height: 70
                radius: 14
                color: Colors.controlBackground

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Spacing.md
                    spacing: Spacing.md

                    Text {
                        text: "Now Playing"
                        color: Colors.textPrimary
                        font.family: Typography.family
                        font.pixelSize: Typography.body
                        Layout.fillWidth: true
                    }

                    Text {
                        text: "No media"
                        color: Colors.textSecondary
                        font.family: Typography.family
                        font.pixelSize: Typography.caption
                    }
                }
            }

            RowLayout {
                width: parent.width
                spacing: Spacing.sm

                StatusIcon {
                    readonly property var battery: UPower.displayDevice
                    source: Qt.resolvedUrl("../../assets/icons/battery-draining.svg")
                    fillSource: Qt.resolvedUrl("../../assets/icons/battery-fill.svg")
                    fill: battery && battery.isPresent ? battery.percentage : 0
                    fillStart: 61 / 512
                    fillEnd: 391 / 512
                    backgroundColor: Colors.textSecondary
                    fillColor: Colors.textSecondary
                    Layout.preferredWidth: 20
                    Layout.preferredHeight: 18
                }

                Text {
                    text: "Battery"
                    color: Colors.textSecondary
                    font.family: Typography.family
                    font.pixelSize: Typography.caption
                    Layout.fillWidth: true
                }

                Text {
                    readonly property var battery: UPower.displayDevice
                    text: battery && battery.isPresent ? Math.round(battery.percentage * 100) + "%" : "Unavailable"
                    color: Colors.textPrimary
                    font.family: Typography.family
                    font.pixelSize: Typography.caption
                }
            }

            Component.onCompleted: brightnessGet.running = true
        }
    }

    // ---- Wi-Fi detail: replaces the grid entirely while open -----------
    Component {
        id: wifiDetail

        ColumnLayout {
            width: parent.width
            spacing: Spacing.sm

            RowLayout {
                Layout.fillWidth: true
                spacing: Spacing.sm

                Text {
                    text: "\u2039"
                    color: Colors.textPrimary
                    font.pixelSize: Typography.title

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -8
                        onClicked: root.closePanel()
                    }
                }

                Text {
                    text: "Wi-Fi"
                    color: Colors.textPrimary
                    font.family: Typography.family
                    font.pixelSize: Typography.headline
                    font.bold: true
                    Layout.fillWidth: true
                }

                MToggle {
                    checked: Networking.wifiEnabled
                    onToggled: (checked) => Networking.wifiEnabled = checked
                }
            }

            Text {
                visible: root.wifiError.length > 0
                text: root.wifiError
                color: "#ff453a"
                font.family: Typography.family
                font.pixelSize: Typography.caption
            }

            Text {
                visible: !Networking.wifiEnabled
                text: "Wi-Fi is off"
                color: Colors.textSecondary
                font.family: Typography.family
                font.pixelSize: Typography.caption
            }

            Text {
                visible: Networking.wifiEnabled && root.wifiDevice && root.wifiDevice.networks.values.length === 0
                text: "No networks found"
                color: Colors.textSecondary
                font.family: Typography.family
                font.pixelSize: Typography.caption
            }

            Repeater {
                model: Networking.wifiEnabled && root.wifiDevice ? root.wifiDevice.networks.values : []

                delegate: ColumnLayout {
                    id: netRow
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: Spacing.xs

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Spacing.sm

                        Text {
                            text: netRow.modelData.security === WifiSecurityType.Open ? "\ud83d\udcf6" : "\ud83d\udd12"
                            font.pixelSize: Typography.caption
                        }

                        Text {
                            text: netRow.modelData.name
                            color: Colors.textPrimary
                            font.family: Typography.family
                            font.pixelSize: Typography.body
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Text {
                            visible: netRow.modelData.connected
                            text: "\u2713"
                            color: Colors.accent
                            font.pixelSize: Typography.body
                        }

                        MButton {
                            visible: !netRow.modelData.connected && root.connectingSsid !== netRow.modelData.name
                            text: netRow.modelData.stateChanging ? "..." : "Join"
                            onClicked: {
                                root.wifiError = ""
                                if (netRow.modelData.known || netRow.modelData.security === WifiSecurityType.Open) {
                                    netRow.modelData.connect()
                                } else {
                                    root.connectingSsid = netRow.modelData.name
                                }
                            }
                        }

                        MButton {
                            visible: netRow.modelData.connected
                            text: "Disconnect"
                            onClicked: netRow.modelData.disconnect()
                        }
                    }

                    RowLayout {
                        visible: root.connectingSsid === netRow.modelData.name
                        Layout.fillWidth: true
                        spacing: Spacing.sm

                        TextField {
                            id: pwField
                            Layout.fillWidth: true
                            placeholderText: "Password"
                            echoMode: TextInput.Password
                            Keys.onReturnPressed: netRow.modelData.connectWithPsk(pwField.text)
                        }

                        MButton {
                            text: "Join"
                            primary: true
                            onClicked: netRow.modelData.connectWithPsk(pwField.text)
                        }
                    }

                    // WifiNetwork.connect()/connectWithPsk() are fire-and-forget;
                    // this is how we find out a password was wrong or missing,
                    // and how we clear the prompt again once it actually connects.
                    Connections {
                        target: netRow.modelData
                        function onConnectionFailed(reason) {
                            if (reason === ConnectionFailReason.NoSecrets) {
                                root.connectingSsid = netRow.modelData.name
                                root.wifiError = ""
                            } else {
                                root.wifiError = "Couldn't connect to " + netRow.modelData.name
                            }
                        }
                        function onConnectedChanged() {
                            if (netRow.modelData.connected && root.connectingSsid === netRow.modelData.name)
                                root.connectingSsid = ""
                        }
                    }
                }
            }
        }
    }

    // ---- Bluetooth detail: ported from the old, never-wired-up
    // BluetoothPopover.qml, which is now dead code — safe to delete it.
    Component {
        id: bluetoothDetail

        ColumnLayout {
            width: parent.width
            spacing: Spacing.sm

            RowLayout {
                Layout.fillWidth: true
                spacing: Spacing.sm

                Text {
                    text: "\u2039"
                    color: Colors.textPrimary
                    font.pixelSize: Typography.title

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -8
                        onClicked: root.closePanel()
                    }
                }

                Text {
                    text: "Bluetooth"
                    color: Colors.textPrimary
                    font.family: Typography.family
                    font.pixelSize: Typography.headline
                    font.bold: true
                    Layout.fillWidth: true
                }

                MToggle {
                    checked: root.adapter ? root.adapter.enabled : false
                    onToggled: (checked) => { if (root.adapter) root.adapter.enabled = checked }
                }
            }

            Text {
                visible: !root.adapter || !root.adapter.enabled
                text: "Bluetooth is off"
                color: Colors.textSecondary
                font.family: Typography.family
                font.pixelSize: Typography.caption
            }

            Text {
                visible: root.adapter && root.adapter.enabled && root.adapter.devices.values.length === 0
                text: "No devices found"
                color: Colors.textSecondary
                font.family: Typography.family
                font.pixelSize: Typography.caption
            }

            Repeater {
                model: root.adapter && root.adapter.enabled ? root.adapter.devices.values : []

                delegate: RowLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: Spacing.sm

                    Text {
                        text: modelData.name || modelData.deviceName || "Unknown device"
                        color: Colors.textPrimary
                        font.family: Typography.family
                        font.pixelSize: Typography.body
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    Text {
                        text: modelData.connected ? "Connected" : (modelData.paired ? "Paired" : "")
                        color: Colors.textSecondary
                        font.family: Typography.family
                        font.pixelSize: Typography.caption
                    }

                    MButton {
                        text: modelData.connected ? "Disconnect" : (modelData.paired ? "Connect" : "Pair")
                        onClicked: {
                            if (modelData.connected) modelData.disconnect()
                            else if (modelData.paired) modelData.connect()
                            else if (!modelData.pairing) modelData.pair()
                        }
                    }
                }
            }
        }
    }

    // A single stacked row inside the Connectivity card: icon badge (fills
    // with accent color when active, matching macOS), title/subtitle, and
    // an optional chevron with its own hit target for "show detail" —
    // separate from the row's own click, which just toggles on/off.
    component ConnectivityRow: Item {
        id: connRow
        property url iconSource
        property string title: ""
        property string subtitle: ""
        property bool active: false
        property bool showChevron: false
        property bool rowEnabled: true
        signal clicked()
        signal chevronClicked()

        implicitHeight: 40
        opacity: rowEnabled ? 1 : 0.45

        MouseArea {
            anchors.fill: parent
            enabled: connRow.rowEnabled
            onClicked: connRow.clicked()
        }

        RowLayout {
            anchors.fill: parent
            spacing: Spacing.sm

            Rectangle {
                width: 26
                height: 26
                radius: 7
                color: connRow.active ? Colors.accent : Colors.surfaceElevated

                StatusIcon {
                    anchors.centerIn: parent
                    source: connRow.iconSource
                    fillColor: connRow.active ? "#ffffff" : Colors.textSecondary
                    showBackground: false
                    width: 15
                    height: 15
                    visible: connRow.iconSource.toString().length > 0
                }
            }

            Column {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    text: connRow.title
                    color: Colors.textPrimary
                    font.family: Typography.family
                    font.pixelSize: Typography.caption
                    font.bold: true
                }

                Text {
                    text: connRow.subtitle
                    color: Colors.textSecondary
                    font.family: Typography.family
                    font.pixelSize: 10
                    elide: Text.ElideRight
                    width: parent.width
                }
            }

            Text {
                visible: connRow.showChevron
                text: "\u203a"
                color: Colors.textTertiary
                font.pixelSize: Typography.body

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -8
                    onClicked: connRow.chevronClicked()
                }
            }
        }
    }

    // The standalone square modules on the right (Do Not Disturb, Keyboard
    // Brightness, AirPlay) — whole tile fills with accent color when
    // active, matching how macOS renders Focus in Control Center.
    component ControlTile: Rectangle {
        id: tile
        property string title: ""
        property string subtitle: ""
        property bool active: false
        signal clicked()
        implicitHeight: 30
        radius: 10
        color: active ? Colors.accent : "transparent"
        opacity: enabled ? 1 : 0.45

        RowLayout {
            anchors.fill: parent
            anchors.margins: Spacing.xs
            spacing: Spacing.sm

            Text {
                text: tile.title === "Do Not Disturb" ? "\u25d0" : tile.title === "AirDrop" ? "\u25cc" : tile.title === "Keyboard Brightness" ? "\u2328" : "\u25a3"
                color: tile.active ? "#ffffff" : Colors.textPrimary
                font.pixelSize: Typography.title
                Layout.preferredWidth: 22
                horizontalAlignment: Text.AlignHCenter
            }

            Column {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    text: tile.title
                    color: tile.active ? "#ffffff" : Colors.textPrimary
                    font.family: Typography.family
                    font.pixelSize: Typography.caption
                    font.bold: true
                    elide: Text.ElideRight
                    width: parent.width
                }

                Text {
                    text: tile.subtitle
                    color: tile.active ? "#dbeeff" : Colors.textSecondary
                    font.family: Typography.family
                    font.pixelSize: 10
                    elide: Text.ElideRight
                    width: parent.width
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: tile.enabled
            onClicked: tile.clicked()
        }
    }
}
