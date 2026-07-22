#include "FwupdManager.hpp"
#include <QDBusConnection>
#include <QDBusMessage>
#include <QDBusReply>
#include <QDBusArgument>
#include <QDBusMetaType>
#include <QDebug>
#include <QTimer>
#include <QProcess>

typedef QList<QVariantMap> VariantMapList;
Q_DECLARE_METATYPE(VariantMapList)

FwupdManager::FwupdManager(QObject* parent) : QObject(parent) {
    if (!QMetaType::isRegistered(qMetaTypeId<VariantMapList>())) {
        qDBusRegisterMetaType<VariantMapList>();
    }

    m_fwupdInterface = new QDBusInterface(
        "org.freedesktop.fwupd",
        "/",
        "org.freedesktop.fwupd",
        QDBusConnection::systemBus(),
        this
    );

    QDBusConnection::systemBus().connect(
        "org.freedesktop.fwupd",
        "/",
        "org.freedesktop.DBus.Properties",
        "PropertiesChanged",
        this,
        SLOT(onPropertiesChanged(QString, QVariantMap, QStringList))
    );

    QDBusConnection::systemBus().connect(
        "org.freedesktop.fwupd",
        "/",
        "org.freedesktop.fwupd",
        "Changed",
        this,
        SLOT(onChanged())
    );

    // Initial check
    QTimer::singleShot(500, this, &FwupdManager::checkForUpdates);
}

void FwupdManager::setProgress(int progress) {
    if (m_progress != progress) {
        m_progress = progress;
        Q_EMIT progressChanged();
    }
}

void FwupdManager::setStatus(const QString& status) {
    if (m_status != status) {
        m_status = status;
        Q_EMIT statusChanged();
    }
}

void FwupdManager::setLastError(const QString& error) {
    if (m_lastError != error) {
        m_lastError = error;
        Q_EMIT lastErrorChanged();
    }
}

void FwupdManager::setUpdating(bool updating) {
    if (m_updating != updating) {
        m_updating = updating;
        Q_EMIT updatingChanged();
    }
}

void FwupdManager::setChecking(bool checking) {
    if (m_checking != checking) {
        m_checking = checking;
        Q_EMIT isCheckingChanged();
    }
}

void FwupdManager::onPropertiesChanged(const QString& interface, const QVariantMap& changedProperties, const QStringList& invalidatedProperties) {
    if (interface == "org.freedesktop.fwupd") {
        if (changedProperties.contains("Percentage")) {
            setProgress(changedProperties.value("Percentage").toInt());
        }
        if (changedProperties.contains("Status")) {
            int statusInt = changedProperties.value("Status").toInt();
            // FwupdStatus enum: 0=Unknown, 1=Idle, 2=Loading, 3=Decompressing, 4=DeviceRestart, 5=DeviceWrite, 6=DeviceVerify, etc.
            if (statusInt == 1) {
                setStatus("");
                setUpdating(false);
            } else {
                setStatus("Working... (" + QString::number(statusInt) + ")");
                setUpdating(true);
            }
        }
    }
}

void FwupdManager::onDeviceAdded(const QVariantMap& device) {
    Q_UNUSED(device);
    checkForUpdates();
}

void FwupdManager::onDeviceChanged(const QVariantMap& device) {
    Q_UNUSED(device);
    checkForUpdates();
}

void FwupdManager::onDeviceRemoved(const QVariantMap& device) {
    Q_UNUSED(device);
    checkForUpdates();
}

void FwupdManager::onChanged() {
    checkForUpdates();
}

void FwupdManager::checkForUpdates() {
    if (m_checking || m_updating) return;
    if (!m_fwupdInterface->isValid()) {
        setLastError("fwupd DBus interface is invalid");
        return;
    }

    setChecking(true);
    setLastError("");

    QDBusMessage devicesMsg = m_fwupdInterface->call("GetDevices");
    if (devicesMsg.type() == QDBusMessage::ErrorMessage) {
        setLastError("Failed to GetDevices: " + devicesMsg.errorMessage());
        setChecking(false);
        return;
    }

    // expect aa{sv}
    QVariantList foundUpdates;

    const QDBusArgument &arg = devicesMsg.arguments().at(0).value<QDBusArgument>();
    arg.beginArray();
    while (!arg.atEnd()) {
        QVariantMap device;
        arg >> device;

        QString deviceId = device.value("DeviceId").toString();
        bool updatable = device.value("Updatable").toBool();
        if (!deviceId.isEmpty()) {
            QDBusMessage upgradesMsg = m_fwupdInterface->call("GetUpgrades", deviceId);
            if (upgradesMsg.type() != QDBusMessage::ErrorMessage) {
                const QDBusArgument &upgArg = upgradesMsg.arguments().at(0).value<QDBusArgument>();
                upgArg.beginArray();
                while (!upgArg.atEnd()) {
                    QVariantMap upgrade;
                    upgArg >> upgrade;

                    QVariantMap outItem;
                    outItem["deviceId"] = deviceId;
                    outItem["deviceName"] = device.value("Name").toString();
                    outItem["name"] = upgrade.value("Name").toString();
                    if (outItem["name"].toString().isEmpty()) {
                        outItem["name"] = device.value("Name").toString();
                    }
                    outItem["oldVersion"] = device.value("Version").toString();
                    outItem["newVersion"] = upgrade.value("Version").toString();
                    outItem["description"] = upgrade.value("Description").toString();
                    outItem["summary"] = upgrade.value("Summary").toString();
                    outItem["uri"] = upgrade.value("Uri").toString();

                    foundUpdates.append(outItem);
                }
                upgArg.endArray();
            }
        }
    }
    arg.endArray();

    m_availableUpdates = foundUpdates;
    Q_EMIT availableUpdatesChanged();
    setChecking(false);
}

void FwupdManager::startUpdate(const QString& deviceId) {
    if (m_updating) return;
    setUpdating(true);
    setStatus("Installing firmware update...");
    setLastError("");

    QProcess* proc = new QProcess(this);
    connect(proc, &QProcess::finished, this, [this, proc, deviceId](int exitCode, QProcess::ExitStatus exitStatus) {
        setUpdating(false);
        if (exitStatus == QProcess::NormalExit && exitCode == 0) {
            setStatus("");
            Q_EMIT updateFinished(deviceId, true);
        } else {
            QString err = proc->readAllStandardError();
            if (err.isEmpty()) err = proc->readAllStandardOutput();
            setLastError(err.isEmpty() ? "Update failed" : err);
            setStatus("");
            Q_EMIT updateFinished(deviceId, false);
        }
        proc->deleteLater();
        checkForUpdates();
    });

    QStringList args;
    args << "update";
    if (!deviceId.isEmpty()) {
        args << deviceId;
    }
    args << "-y";

    proc->start("fwupdmgr", args);
}

void FwupdManager::startAllUpdates() {
    startUpdate("");
}
