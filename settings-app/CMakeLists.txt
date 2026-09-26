cmake_minimum_required(VERSION 3.16)
project(macos-qs-settings LANGUAGES CXX)

include(GNUInstallDirs)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 6.5 REQUIRED COMPONENTS Core Quick QuickControls2)

qt_standard_project_setup(REQUIRES 6.5)

qt_add_executable(macos-qs-settings
    src/main.cpp
    src/processrunner.h
    src/processrunner.cpp
)

# Settings is a plain Qt Quick Controls app, not a Quickshell module — it
# has no access to Quickshell.Networking/Bluetooth/Pipewire/UPower, which
# only exist inside the `qs` runtime. See processrunner.h for why every
# page instead shells out to nmcli/bluetoothctl/wpctl/brightnessctl/upower,
# same as the shell already does for brightness.
qt_add_qml_module(macos-qs-settings
    URI SettingsApp
    VERSION 1.0
    QML_FILES
        qml/Main.qml
        qml/Sidebar.qml
        qml/theme/Colors.qml
        qml/theme/Spacing.qml
        qml/theme/Typography.qml
        qml/theme/Motion.qml
        qml/controls/SToggle.qml
        qml/controls/SButton.qml
        qml/controls/SSlider.qml
        qml/controls/SCard.qml
        qml/controls/SIcon.qml
        qml/pages/GeneralPage.qml
        qml/pages/WiFiPage.qml
        qml/pages/BluetoothPage.qml
        qml/pages/SoundPage.qml
        qml/pages/DisplaysPage.qml
        qml/pages/BatteryPage.qml
        qml/pages/AboutPage.qml
    RESOURCES
        qml/theme/qmldir
        assets/icons/gear.svg
        assets/icons/wifi.svg
        assets/icons/bluetooth.svg
        assets/icons/speaker.svg
        assets/icons/speaker-muted.svg
        assets/icons/display.svg
        assets/icons/sun.svg
        assets/icons/battery.svg
        assets/icons/info.svg
        assets/icons/lock.svg
        assets/icons/open-network.svg
        assets/icons/checkmark.svg
)

target_link_libraries(macos-qs-settings
    PRIVATE
        Qt6::Core
        Qt6::Quick
        Qt6::QuickControls2
)

install(TARGETS macos-qs-settings
    BUNDLE DESTINATION .
    RUNTIME DESTINATION bin
)

configure_file(
    macos-qs-settings-native.desktop.in
    ${CMAKE_CURRENT_BINARY_DIR}/macos-qs-settings-native.desktop
    @ONLY
)

install(FILES ${CMAKE_CURRENT_BINARY_DIR}/macos-qs-settings-native.desktop
    DESTINATION ${CMAKE_INSTALL_DATADIR}/applications
)
