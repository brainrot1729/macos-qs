#include "processrunner.h"

#include <QProcess>

ProcessRunner::ProcessRunner(QObject *parent) : QObject(parent) {}

QString ProcessRunner::run(const QString &program, const QStringList &args, int timeoutMs)
{
    QProcess process;
    process.start(program, args);

    if (!process.waitForFinished(timeoutMs)) {
        process.kill();
        process.waitForFinished(200);
        return QString();
    }

    return QString::fromUtf8(process.readAllStandardOutput());
}

void ProcessRunner::runDetached(const QString &program, const QStringList &args)
{
    QProcess::startDetached(program, args);
}
