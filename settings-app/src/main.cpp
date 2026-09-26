#include <QCoreApplication>
#include <QGuiApplication>
#include <QJSEngine>
#include <QQmlApplicationEngine>
#include <QQmlEngine>

#include "processrunner.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setApplicationName("macos-qs Settings");
    app.setOrganizationName("macos-qs");

    // Exposed to QML as "SettingsApp.ProcessRunner" — see processrunner.h
    // for what it does and why it exists at all.
    qmlRegisterSingletonType<ProcessRunner>(
        "SettingsApp", 1, 0, "ProcessRunner",
        [](QQmlEngine *, QJSEngine *) -> QObject * { return new ProcessRunner(); });

    QQmlApplicationEngine engine;
    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreationFailed,
        &app, [] { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);

    engine.loadFromModule("SettingsApp", "Main");

    return app.exec();
}
