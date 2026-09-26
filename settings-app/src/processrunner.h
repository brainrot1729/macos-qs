#pragma once

#include <QObject>
#include <QString>
#include <QStringList>

// Quickshell's Process/StdioCollector QML types only exist inside the `qs`
// runtime — this is a plain, separately compiled Qt Quick Controls app
// (per the technical decisions doc: "a crash in Settings can't take down
// your bar"), so it has no access to them, or to Quickshell.Networking /
// Bluetooth / Pipewire / UPower. Instead each settings page shells out to
// the exact same CLI tools the rest of the project already depends on:
// nmcli, bluetoothctl, wpctl, brightnessctl, upower.
//
// run() is synchronous — it blocks the calling thread for up to
// timeoutMs. That's fine for the sub-100ms calls every page here makes
// (get-volume, brightnessctl g/m, a `bluetoothctl info` lookup) but would
// need to move to an async QProcess + signal if a slower command ever
// gets added. `bluetoothctl pair` on a real device is the one call in
// this app that can legitimately take a couple of seconds — see the
// README for that trade-off.
class ProcessRunner : public QObject {
    Q_OBJECT
public:
    explicit ProcessRunner(QObject *parent = nullptr);

    Q_INVOKABLE QString run(const QString &program, const QStringList &args, int timeoutMs = 4000);

    // Fire-and-forget, for actions whose effect is read back separately
    // (rarely needed here since run() already waits for the result, but
    // available for anything that shouldn't block the UI at all).
    Q_INVOKABLE void runDetached(const QString &program, const QStringList &args);
};
