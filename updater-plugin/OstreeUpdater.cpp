#include "OstreeUpdater.hpp"
#include <QDBusConnection>
#include <QDBusMessage>
#include <QDBusReply>
#include <QDBusArgument>
#include <QDBusMetaType>
#include <QDebug>
#include <QTimer>
#include <QDateTime>

struct OstreeEVR {
    QString version;
    QString arch;
};

Q_DECLARE_METATYPE(OstreeEVR)

QDBusArgument &operator<<(QDBusArgument &arg, const OstreeEVR &evr) {
    arg.beginStructure();
    arg << evr.version << evr.arch;
    arg.endStructure();
    return arg;
}

const QDBusArgument &operator>>(const QDBusArgument &arg, OstreeEVR &evr) {
    arg.beginStructure();
    arg >> evr.version >> evr.arch;
    arg.endStructure();
    return arg;
}

struct OstreeAdvisory {
    QString id;
    quint32 kind;
    quint32 severity;
    QStringList packages;
    QVariantMap metadata;
};

Q_DECLARE_METATYPE(OstreeAdvisory)

QDBusArgument &operator<<(QDBusArgument &arg, const OstreeAdvisory &item) {
    arg.beginStructure();
    arg << item.id << item.kind << item.severity << item.packages << item.metadata;
    arg.endStructure();
    return arg;
}

const QDBusArgument &operator>>(const QDBusArgument &arg, OstreeAdvisory &item) {
    arg.beginStructure();
    arg >> item.id >> item.kind >> item.severity >> item.packages >> item.metadata;
    arg.endStructure();
    return arg;
}

struct OstreeCveReference {
    QString href;
    QString title;
};

Q_DECLARE_METATYPE(OstreeCveReference)

QDBusArgument &operator<<(QDBusArgument &arg, const OstreeCveReference &item) {
    arg.beginStructure();
    arg << item.href << item.title;
    arg.endStructure();
    return arg;
}

const QDBusArgument &operator>>(const QDBusArgument &arg, OstreeCveReference &item) {
    arg.beginStructure();
    arg >> item.href >> item.title;
    arg.endStructure();
    return arg;
}

struct OstreeDiffItem {
    quint32 state;
    QString name;
    OstreeEVR previous;
    OstreeEVR current;
};

Q_DECLARE_METATYPE(OstreeDiffItem)

QDBusArgument &operator<<(QDBusArgument &arg, const OstreeDiffItem &item) {
    arg.beginStructure();
    arg << item.state << item.name << item.previous << item.current;
    arg.endStructure();
    return arg;
}

const QDBusArgument &operator>>(const QDBusArgument &arg, OstreeDiffItem &item) {
    arg.beginStructure();
    arg >> item.state >> item.name >> item.previous >> item.current;
    arg.endStructure();
    return arg;
}

typedef QList<QVariantMap> VariantMapList;
Q_DECLARE_METATYPE(VariantMapList)

OstreeUpdater::OstreeUpdater(QObject* parent) : QObject(parent) {
    qDBusRegisterMetaType<OstreeEVR>();
    qDBusRegisterMetaType<OstreeDiffItem>();
    qDBusRegisterMetaType<QList<OstreeDiffItem>>();
    qDBusRegisterMetaType<OstreeAdvisory>();
    qDBusRegisterMetaType<QList<OstreeAdvisory>>();
    qDBusRegisterMetaType<OstreeCveReference>();
    qDBusRegisterMetaType<QList<OstreeCveReference>>();
    qDBusRegisterMetaType<VariantMapList>();

    m_sysrootInterface = new QDBusInterface(
        "org.projectatomic.rpmostree1",
        "/org/projectatomic/rpmostree1/Sysroot",
        "org.projectatomic.rpmostree1.Sysroot",
        QDBusConnection::systemBus(),
        this
    );

    QDBusConnection::systemBus().connect(
        "org.projectatomic.rpmostree1",
        QString(),
        "org.freedesktop.DBus.Properties",
        "PropertiesChanged",
        this,
        SLOT(onPropertiesChanged(QString, QVariantMap, QStringList))
    );

    resolveOSInterface();
    QMetaObject::invokeMethod(this, "reloadState", Qt::QueuedConnection);
}

void OstreeUpdater::checkActiveTransaction() {
    if (!m_sysrootInterface || !m_sysrootInterface->isValid()) return;

    bool active = false;
    const QVariant activeTxPathVar = m_sysrootInterface->property("ActiveTransactionPath");
    if (activeTxPathVar.isValid()) {
        active = !activeTxPathVar.toString().trimmed().isEmpty();
    }

    if (m_hasActiveTransaction != active) {
        m_hasActiveTransaction = active;
        Q_EMIT hasActiveTransactionChanged();
    }
}

void OstreeUpdater::setProgress(int progress) {
    if (m_progress != progress) {
        m_progress = progress;
        Q_EMIT progressChanged();
    }
}

void OstreeUpdater::setStatus(const QString& status) {
    if (m_status != status) {
        m_status = status;
        Q_EMIT statusChanged();
    }
}

void OstreeUpdater::setLastError(const QString& error) {
    if (m_lastError != error) {
        m_lastError = error;
        Q_EMIT lastErrorChanged();
    }
}

void OstreeUpdater::setUpdating(bool updating) {
    if (m_updating != updating) {
        m_updating = updating;
        Q_EMIT updatingChanged();
    }
}

void OstreeUpdater::setChecking(bool checking) {
    if (m_checking != checking) {
        m_checking = checking;
        Q_EMIT isCheckingChanged();
    }
}

void OstreeUpdater::setHasCritical(bool hasCritical) {
    if (m_hasCritical != hasCritical) {
        m_hasCritical = hasCritical;
        Q_EMIT hasCriticalChanged();
    }
}

void OstreeUpdater::setIsRebootRequired(bool required) {
    if (m_isRebootRequired != required) {
        m_isRebootRequired = required;
        Q_EMIT isRebootRequiredChanged();
    }
}

void OstreeUpdater::reloadState() {
    checkRebootRequired();
    checkActiveTransaction();
    parseCachedUpdate();
}

void OstreeUpdater::checkRebootRequired() {
    if (!m_sysrootInterface || !m_sysrootInterface->isValid()) return;

    QVariant deploymentsVar = m_sysrootInterface->property("Deployments");
    QString newStagedVersion;
    QString newBootedVersion;
    bool rebootRequired = false;

    if (deploymentsVar.isValid() && deploymentsVar.userType() == qMetaTypeId<VariantMapList>()) {
        VariantMapList deployments = deploymentsVar.value<VariantMapList>();
        bool isFirst = true;
        for (const QVariantMap& dict : deployments) {
            bool isBooted = dict.value("booted").toBool();
            QString version = dict.value("version").toString();

            if (isBooted) {
                newBootedVersion = version;
            }

            if (isFirst) {
                rebootRequired = !isBooted;
                if (rebootRequired) {
                    newStagedVersion = version;
                }
                isFirst = false;
            }
        }
    } else if (deploymentsVar.isValid() && deploymentsVar.userType() == qMetaTypeId<QDBusArgument>()) {
        QDBusArgument arg = deploymentsVar.value<QDBusArgument>();
        arg.beginArray();
        bool isFirst = true;
        while (!arg.atEnd()) {
            arg.beginStructure();
            QString osname;
            QVariantMap dict;
            arg >> osname >> dict;
            arg.endStructure();

            bool isBooted = dict.value("booted").toBool();
            QString version = dict.value("version").toString();

            if (isBooted) {
                newBootedVersion = version;
            }

            if (isFirst) {
                rebootRequired = !isBooted;
                if (rebootRequired) {
                    newStagedVersion = version;
                }
                isFirst = false;
            }
        }
        arg.endArray();
    } else if (deploymentsVar.isValid() && deploymentsVar.canConvert<QVariantList>()) {
        QVariantList deployments = deploymentsVar.toList();
        bool isFirst = true;
        for (const QVariant& depVar : deployments) {
            QVariantMap dep;
            if (depVar.userType() == qMetaTypeId<QDBusArgument>()) {
                QDBusArgument arg = depVar.value<QDBusArgument>();
                if (arg.currentSignature() == "(sa{sv})") {
                    arg.beginStructure();
                    QString osname;
                    arg >> osname >> dep;
                    arg.endStructure();
                } else {
                    continue;
                }
            } else {
                dep = depVar.toMap();
            }

            bool isBooted = dep.value("booted").toBool();
            QString version = dep.value("version").toString();

            if (isBooted) {
                newBootedVersion = version;
            }

            if (isFirst) {
                rebootRequired = !isBooted;
                if (rebootRequired) {
                    newStagedVersion = version;
                }
                isFirst = false;
            }
        }
    }

    setIsRebootRequired(rebootRequired);
    if (m_stagedVersion != newStagedVersion) {
        m_stagedVersion = newStagedVersion;
        Q_EMIT stagedVersionChanged();
    }
    if (m_bootedVersion != newBootedVersion) {
        m_bootedVersion = newBootedVersion;
        Q_EMIT bootedVersionChanged();
    }
}

bool OstreeUpdater::resolveOSInterface() {
    if (m_osInterface && m_osInterface->isValid()) {
        return true;
    }

    if (!m_sysrootInterface || !m_sysrootInterface->isValid()) {
        QDBusMessage startMsg = QDBusMessage::createMethodCall("org.freedesktop.DBus", "/org/freedesktop/DBus", "org.freedesktop.DBus", "StartServiceByName");
        startMsg << "org.projectatomic.rpmostree1" << (uint)0;
        QDBusConnection::systemBus().call(startMsg);

        if (m_sysrootInterface) m_sysrootInterface->deleteLater();
        m_sysrootInterface = new QDBusInterface("org.projectatomic.rpmostree1", "/org/projectatomic/rpmostree1/Sysroot", "org.projectatomic.rpmostree1.Sysroot", QDBusConnection::systemBus(), this);
    }

    if (!m_sysrootInterface->isValid()) {
        return false;
    }

    QVariant bootedVar = m_sysrootInterface->property("Booted");
    QString osPath;
    if (bootedVar.isValid()) {
        if (bootedVar.canConvert<QDBusObjectPath>()) {
            osPath = bootedVar.value<QDBusObjectPath>().path();
        } else if (bootedVar.canConvert<QString>()) {
            osPath = bootedVar.toString();
        }
    }

    if (osPath.isEmpty()) {
        QVariant deploymentsVar = m_sysrootInterface->property("Deployments");
        if (deploymentsVar.isValid() && deploymentsVar.userType() == qMetaTypeId<VariantMapList>()) {
            VariantMapList deployments = deploymentsVar.value<VariantMapList>();
            if (!deployments.isEmpty()) {
                QString osName = deployments.first().value("osname").toString();
                if (!osName.isEmpty()) {
                    QDBusReply<QDBusObjectPath> reply = m_sysrootInterface->call("GetOS", osName);
                    if (reply.isValid()) {
                        osPath = reply.value().path();
                    }
                }
            }
        } else if (deploymentsVar.isValid() && deploymentsVar.userType() == qMetaTypeId<QDBusArgument>()) {
            QDBusArgument arg = deploymentsVar.value<QDBusArgument>();
            arg.beginArray();
            if (!arg.atEnd()) {
                arg.beginStructure();
                QString osName;
                QVariantMap dict;
                arg >> osName >> dict;
                arg.endStructure();

                if (!osName.isEmpty()) {
                    QDBusReply<QDBusObjectPath> reply = m_sysrootInterface->call("GetOS", osName);
                    if (reply.isValid()) {
                        osPath = reply.value().path();
                    }
                }
            }
            arg.endArray();
        } else if (deploymentsVar.isValid() && deploymentsVar.canConvert<QVariantList>()) {
            QVariantList deployments = deploymentsVar.toList();
            if (!deployments.isEmpty()) {
                QVariant depVar = deployments.first();
                QString osName;
                if (depVar.userType() == qMetaTypeId<QDBusArgument>()) {
                    QDBusArgument arg = depVar.value<QDBusArgument>();
                    if (arg.currentSignature() == "(sa{sv})") {
                        arg.beginStructure();
                        QVariantMap dict;
                        arg >> osName >> dict;
                        arg.endStructure();
                    }
                } else {
                    osName = depVar.toMap().value("osname").toString();
                }

                if (!osName.isEmpty()) {
                    QDBusReply<QDBusObjectPath> reply = m_sysrootInterface->call("GetOS", osName);
                    if (reply.isValid()) {
                        osPath = reply.value().path();
                    }
                }
            }
        }
    }

    if (osPath.isEmpty()) {
        qWarning() << "Could not resolve booted OS object path";
        return false;
    }

    qDebug() << "Resolved OS object path:" << osPath;

    if (m_osInterface) {
        m_osInterface->deleteLater();
    }

    m_osInterface = new QDBusInterface(
        "org.projectatomic.rpmostree1",
        osPath,
        "org.projectatomic.rpmostree1.OS",
        QDBusConnection::systemBus(),
        this
    );

    return m_osInterface->isValid();
}

static QString advisorySynopsis(const OstreeAdvisory &adv) {
    QString synopsis = adv.metadata.value("description").toString();
    if (synopsis.isEmpty())
        synopsis = adv.metadata.value("summary").toString();
    if (synopsis.isEmpty())
        synopsis = adv.metadata.value("title").toString();

    QStringList cveTitles;
    QVariant cveVar = adv.metadata.value("cve_references");
    QList<OstreeCveReference> cves;

    if (cveVar.userType() == qMetaTypeId<QDBusArgument>()) {
        const QDBusArgument cveArg = cveVar.value<QDBusArgument>();
        cveArg >> cves;
    }

    for (const auto &cve : cves) {
        if (!cve.title.isEmpty())
            cveTitles << cve.title;
    }

    if (synopsis.isEmpty() && !cveTitles.isEmpty())
        synopsis = cveTitles.join("\n");
    if (synopsis.isEmpty())
        synopsis = QString("Security advisory %1").arg(adv.id);

    return synopsis;
}

void OstreeUpdater::onPropertiesChanged(const QString& interface, const QVariantMap& changedProperties, const QStringList& invalidatedProperties) {
    if (interface == "org.projectatomic.rpmostree1.Sysroot") {
        if (changedProperties.contains("Booted") || changedProperties.contains("Deployments")) {
            resolveOSInterface();
            checkRebootRequired();
            parseCachedUpdate();
        }
        if (changedProperties.contains("ActiveTransaction") || changedProperties.contains("ActiveTransactionPath") ||
            invalidatedProperties.contains("ActiveTransaction") || invalidatedProperties.contains("ActiveTransactionPath")) {
            checkActiveTransaction();
        }
    } else if (interface == "org.projectatomic.rpmostree1.OS") {
        if (changedProperties.contains("CachedUpdate") || invalidatedProperties.contains("CachedUpdate")) {
            parseCachedUpdate();
        }
    }
}

void OstreeUpdater::checkForUpdates() {
    if (m_checking || m_updating) return;

    if (!resolveOSInterface()) {
        setStatus("Error: rpm-ostree OS D-Bus interface is not available.");
        return;
    }

    setChecking(true);
    setLastError("");
    setStatus("Checking for system updates...");

    checkRebootRequired();

    QVariantMap options;
    options["force"] = true; // force refresh
    startTransaction("RefreshMd", options);
}

void OstreeUpdater::startUpdate() {
    if (m_updating) return;

    if (!resolveOSInterface()) {
        setStatus("Error: rpm-ostree OS D-Bus interface is not available.");
        Q_EMIT updateFinished(false);
        return;
    }

    setUpdating(true);
    setProgress(0);
    setLastError("");
    setStatus("Initiating system upgrade...");

    QVariantMap options;
    startTransaction("Upgrade", options);
}

void OstreeUpdater::startTransaction(const QString& method, const QVariantMap& options) {
    if (!resolveOSInterface()) return;

    QDBusPendingCall call = m_osInterface->asyncCall(method, options);
    QDBusPendingCallWatcher *watcher = new QDBusPendingCallWatcher(call, this);

    watcher->setProperty("tx_method", method);

    connect(watcher, &QDBusPendingCallWatcher::finished, this, [this](QDBusPendingCallWatcher *w) {
        QDBusPendingReply<QString> reply = *w;
        QString method = w->property("tx_method").toString();
        w->deleteLater();

        if (reply.isError()) {
            QString err = reply.error().message();
            qWarning() << "OSTree" << method << "failed:" << err;
            setLastError(err);
            if (method == "RefreshMd") {
                setStatus("Update check failed: " + err);
                setChecking(false);
            } else if (method == "Upgrade") {
                setStatus("System upgrade failed: " + err);
                setUpdating(false);
                Q_EMIT updateFinished(false);
            }
        } else {
            QString address = reply.value();
            connectToTransaction(address, method);
        }
    });
}

void OstreeUpdater::connectToTransaction(const QString& address, const QString& method) {
    QString busName = QString("rpmostree-tx-%1").arg(QDateTime::currentMSecsSinceEpoch());
    QDBusConnection txBus = QDBusConnection::connectToPeer(address, busName);

    if (!txBus.isConnected()) {
        qWarning() << "Failed to connect to transaction peer" << address;
        if (method == "RefreshMd") setChecking(false);
        else if (method == "Upgrade") { setUpdating(false); Q_EMIT updateFinished(false); }
        return;
    }

    QDBusInterface* txIf = new QDBusInterface(QString(), "/", "org.projectatomic.rpmostree1.Transaction", txBus, this);

    txBus.connect(QString(), "/", "org.projectatomic.rpmostree1.Transaction", "Finished", this, SLOT(onTxFinished(QDBusMessage)));
    txBus.connect(QString(), "/", "org.projectatomic.rpmostree1.Transaction", "PercentProgress", this, SLOT(onTxProgress(QDBusMessage)));
    txBus.connect(QString(), "/", "org.projectatomic.rpmostree1.Transaction", "Status", this, SLOT(onTxStatus(QDBusMessage)));

    m_activeTxName = busName;
    m_activeTxMethod = method;

    QDBusPendingCall call = txIf->asyncCall("Start");
    QDBusPendingCallWatcher *watcher = new QDBusPendingCallWatcher(call, this);
    connect(watcher, &QDBusPendingCallWatcher::finished, this, [this, txIf, method, busName](QDBusPendingCallWatcher* w) {
        QDBusPendingReply<> rep = *w;
        w->deleteLater();
        if (rep.isError()) {
            qWarning() << "Start failed:" << rep.error().message();
            setLastError(rep.error().message());
            if (method == "RefreshMd") setChecking(false);
            else { setUpdating(false); Q_EMIT updateFinished(false); }
            txIf->deleteLater();
            QDBusConnection::disconnectFromPeer(busName);
            if (m_activeTxName == busName) m_activeTxName.clear();
        } else {
            m_activeTxInterface = txIf;
        }
    });
}

void OstreeUpdater::onTxFinished(const QDBusMessage& msg) {
    if (msg.arguments().size() >= 2) {
        bool success = msg.arguments().at(0).toBool();
        QString errorMsg = msg.arguments().at(1).toString();

        QString method = m_activeTxMethod;

        if (m_activeTxInterface) {
            m_activeTxInterface->deleteLater();
            m_activeTxInterface = nullptr;
        }

        QString busName = m_activeTxName;
        m_activeTxName.clear();
        if (!busName.isEmpty()) {
            QDBusConnection::disconnectFromPeer(busName);
        }

        if (method == "RefreshMd") {
            setChecking(false);
            if (!success) {
                setLastError(errorMsg);
                setStatus("Update check failed.");
            } else {
                setStatus("Update check complete.");
                parseCachedUpdate();
            }
        } else if (method == "Upgrade") {
            setUpdating(false);
            if (!success) {
                setLastError(errorMsg);
                setStatus("System upgrade failed.");
                Q_EMIT updateFinished(false);
            } else {
                setStatus("System upgrade completed successfully. Reboot required.");
                setProgress(100);

                // Immediately force a re-check of deployments for reboot required state
                QTimer::singleShot(500, this, [this](){
                    this->checkRebootRequired();
                    this->parseCachedUpdate();
                    Q_EMIT this->updateFinished(true);
                });
            }
        }
    }
}

void OstreeUpdater::onTxProgress(const QDBusMessage& msg) {
    if (msg.arguments().size() >= 2) {
        QString text = msg.arguments().at(0).toString();
        uint percent = msg.arguments().at(1).toUInt();

        if (m_activeTxMethod == "Upgrade") {
            setProgress(percent);
            if (!text.isEmpty()) setStatus(text);
        }
    }
}

void OstreeUpdater::onTxStatus(const QDBusMessage& msg) {
    if (msg.arguments().size() >= 1) {
        QString text = msg.arguments().at(0).toString();
        if (m_activeTxMethod == "Upgrade") {
            setStatus(text);
        }
    }
}

void OstreeUpdater::parseCachedUpdate() {
    if (!resolveOSInterface()) return;

    QVariant cached = m_osInterface->property("CachedUpdate");

    QVariantList list;
    bool hasCritical = false;

    if (cached.isValid() && cached.canConvert<QVariantMap>()) {
        QVariantMap map = cached.toMap();

        QMap<QString, QString> pkgAdvisories;
        QMap<QString, QString> pkgAdvisoryTypes;

        QStringList advisoryPackages;
        QVariantList advisoryCves;
        QStringList seenCveTitles;
        int highestSeverity = 0;

        QMap<QString, QString> pkgAdvisorySynopses;

        QList<OstreeAdvisory> advisories;

        if (map.contains("advisories")) {
            QVariant advVar = map.value("advisories");

            if (advVar.userType() == qMetaTypeId<QDBusArgument>()) {
                const QDBusArgument dbusArg = advVar.value<QDBusArgument>();
                dbusArg >> advisories;
            }
        }

        for (const auto &adv : advisories) {
            QString advId = adv.id;
            QString synopsis = advisorySynopsis(adv);

            QString advType;
            if (adv.kind == 1)
                advType = "security";
            else
                advType = QString::number(adv.kind);

            highestSeverity = qMax(highestSeverity, int(adv.severity));

            for (const QString &pkg : adv.packages) {
                pkgAdvisories[pkg] = advId;
                pkgAdvisoryTypes[pkg] = advType;
                pkgAdvisorySynopses[pkg] = synopsis;

                if (!advisoryPackages.contains(pkg))
                    advisoryPackages.append(pkg);
            }

            QVariant cveVar = adv.metadata.value("cve_references");
            QList<OstreeCveReference> cves;
            if (cveVar.userType() == qMetaTypeId<QDBusArgument>()) {
                const QDBusArgument cveArg = cveVar.value<QDBusArgument>();
                cveArg >> cves;
            }

            for (const auto &cve : cves) {
                if (!cve.title.isEmpty() && !seenCveTitles.contains(cve.title)) {
                    seenCveTitles.append(cve.title);

                    QVariantMap cveMap;
                    cveMap["title"] = cve.title;
                    cveMap["href"] = cve.href;

                    advisoryCves.append(cveMap);
                }
            }

            if (advType.contains("security", Qt::CaseInsensitive) || adv.severity > 0) {
                hasCritical = true;
            }
        }

        QVariant diffVar = map.value("rpm-diff");
        if (diffVar.isValid() && diffVar.canConvert<QVariantMap>()) {
            QVariantMap diffMap = diffVar.toMap();
            QVariant upgradedVar = diffMap.value("upgraded");

            if (upgradedVar.isValid() && upgradedVar.canConvert<QDBusArgument>()) {
                QList<OstreeDiffItem> upgradedItems;
                upgradedVar.value<QDBusArgument>() >> upgradedItems;

                for (const auto& item : upgradedItems) {
                    QVariantMap outMap;
                    outMap["name"] = item.name;
                    outMap["oldVersion"] = item.previous.version;
                    outMap["newVersion"] = item.current.version;

                    // Match package name (exact match or stripping arch suffixes like .x86_64)
                    QString matchedKey;
                    for (auto key : pkgAdvisories.keys()) {
                        if (item.name == key || item.name.startsWith(key + ".") || key.startsWith(item.name + ".")) {
                            matchedKey = key;
                            break;
                        }
                    }

                    if (!matchedKey.isEmpty()) {
                        outMap["advisory"] = pkgAdvisories.value(matchedKey);
                        outMap["advisoryType"] = pkgAdvisoryTypes.value(matchedKey);
                        outMap["synopsis"] = pkgAdvisorySynopses.value(matchedKey);
                    } else {
                        outMap["advisory"] = "";
                        outMap["advisoryType"] = "";
                        outMap["synopsis"] = "";
                    }

                    list.append(outMap);
                }
            }
        }


        // Prepend overall System OS Update if version is known
        QString newOsVersion = map.value("version").toString();
        if (!newOsVersion.isEmpty()) {
            QVariantMap outMap;
            outMap["name"] = "System OS Update";
            outMap["oldVersion"] = "";
            outMap["newVersion"] = newOsVersion;
            outMap["advisory"] = hasCritical ? "Security Update Available" : "";
            outMap["advisoryType"] = hasCritical ? "security" : "";
            outMap["advisorySeverity"] = highestSeverity;
            outMap["synopsis"] = hasCritical
                ? "Base operating system updates and security patches"
                : "Base operating system updates";

            QVariantList packageList;
            for (const QString &pkg : advisoryPackages)
                packageList.append(pkg);
            outMap["packages"] = packageList;

            outMap["cves"] = advisoryCves;

            list.prepend(outMap);
        }
    }

    if (m_isRebootRequired && list.isEmpty()) {
        QVariantMap outMap;
        outMap["name"] = "System OS Update";
        outMap["oldVersion"] = m_bootedVersion;
        outMap["newVersion"] = m_stagedVersion;
        outMap["advisory"] = "";
        outMap["advisoryType"] = "";
        outMap["synopsis"] = "A system update is staged and ready. Reboot to apply changes.";
        list.prepend(outMap);
    }

    m_availableUpdates = list;
    setHasCritical(hasCritical);
    Q_EMIT availableUpdatesChanged();
}

void OstreeUpdater::cancelTransaction() {
    if (!m_sysrootInterface || !m_sysrootInterface->isValid()) {
        if (m_sysrootInterface) m_sysrootInterface->deleteLater();
        m_sysrootInterface = new QDBusInterface("org.projectatomic.rpmostree1", "/org/projectatomic/rpmostree1/Sysroot", "org.projectatomic.rpmostree1.Sysroot", QDBusConnection::systemBus(), this);
    }

    if (!m_sysrootInterface->isValid()) {
        setStatus("Error: rpm-ostree Sysroot D-Bus interface is not available.");
        setLastError("Sysroot D-Bus interface is not available");
        Q_EMIT transactionCanceled(false);
        return;
    }

    QString methodName;
    QString senderName;
    QString objectPath;
    QString transactionAddress;

    // ActiveTransaction (method-name, sender-name, object path)
    const QVariant activeTxVar = m_sysrootInterface->property("ActiveTransaction");
    if (activeTxVar.isValid() && activeTxVar.userType() == qMetaTypeId<QDBusArgument>()) {
        QDBusArgument arg = activeTxVar.value<QDBusArgument>();
        arg.beginStructure();
        arg >> methodName >> senderName >> objectPath;
        arg.endStructure();
    } else if (activeTxVar.isValid() && activeTxVar.canConvert<QStringList>()) {
        const QStringList parts = activeTxVar.toStringList();
        if (parts.size() >= 3) {
            methodName = parts.at(0);
            senderName = parts.at(1);
            objectPath = parts.at(2);
        }
    }

    // ActiveTransactionPath is the DBus address to connect to
    const QVariant activeTxPathVar = m_sysrootInterface->property("ActiveTransactionPath");
    if (activeTxPathVar.isValid()) {
        transactionAddress = activeTxPathVar.toString().trimmed();
    }

    const bool hasActiveTransaction =
        !transactionAddress.isEmpty() ||
        !objectPath.isEmpty() ||
        !methodName.isEmpty() ||
        !senderName.isEmpty();

    if (!hasActiveTransaction) {
        setStatus("No active rpm-ostree transaction is blocking updates.");
        setLastError("No active transaction");
        Q_EMIT transactionCanceled(false);
        return;
    }

    if (transactionAddress.isEmpty()) {
        QString detail = "Active transaction detected";
        if (!methodName.isEmpty())
            detail += " (" + methodName + ")";
        if (!senderName.isEmpty())
            detail += " from " + senderName;
        detail += ", but no transaction D-Bus address was provided.";

        setStatus("Failed to cancel active transaction: no transaction address available.");
        setLastError(detail);
        Q_EMIT transactionCanceled(false);
        return;
    }

    setStatus(QString("Canceling active transaction%1%2...")
                  .arg(!methodName.isEmpty() ? " (" + methodName + ")" : "")
                  .arg(!senderName.isEmpty() ? " started by " + senderName : ""));

    // rpm-ostree transaction methods live on a peer DBus address, not the system bus object path
    QDBusConnection txBus = QDBusConnection::connectToPeer(transactionAddress, "rpmostree-transaction");
    if (!txBus.isConnected()) {
        setStatus("Error: Failed to connect to rpm-ostree transaction peer.");
        setLastError("Failed to connect to transaction peer at address: " + transactionAddress);
        Q_EMIT transactionCanceled(false);
        return;
    }

    QDBusInterface *transactionInterface = new QDBusInterface(
        QString(),
        "/",
        "org.projectatomic.rpmostree1.Transaction",
        txBus,
        this
    );

    if (!transactionInterface->isValid()) {
        setStatus("Error: Failed to connect to transaction D-Bus interface.");
        setLastError("Failed to connect to transaction interface on peer address: " + transactionAddress);
        transactionInterface->deleteLater();
        QDBusConnection::disconnectFromPeer("rpmostree-transaction");
        Q_EMIT transactionCanceled(false);
        return;
    }

    QDBusPendingCall call = transactionInterface->asyncCall("Cancel");
    QDBusPendingCallWatcher *watcher = new QDBusPendingCallWatcher(call, this);

    connect(watcher, &QDBusPendingCallWatcher::finished, this,
            [this, transactionInterface](QDBusPendingCallWatcher *watcher) {
        QDBusPendingReply<> reply = *watcher;
        watcher->deleteLater();
        transactionInterface->deleteLater();
        QDBusConnection::disconnectFromPeer("rpmostree-transaction");

        if (reply.isError()) {
            qWarning() << "OSTree Transaction Cancel failed:" << reply.error().message();
            setStatus("Failed to cancel active transaction: " + reply.error().message());
            setLastError(reply.error().message());
            Q_EMIT transactionCanceled(false);
        } else {
            setStatus("Active transaction canceled.");
            setLastError("");
            Q_EMIT transactionCanceled(true);
        }
    });
}
