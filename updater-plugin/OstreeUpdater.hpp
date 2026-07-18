#pragma once
#include <QObject>
#include <QtQml/qqml.h>
#include <QDBusInterface>
#include <QDBusPendingCallWatcher>
#include <QDBusMessage>
#include <QDBusObjectPath>
#include <QVariantList>

class OstreeUpdater : public QObject {
    Q_OBJECT
    QML_ELEMENT
    
    Q_PROPERTY(int updateProgress READ updateProgress NOTIFY progressChanged)
    Q_PROPERTY(bool isUpdating READ isUpdating NOTIFY updatingChanged)
    Q_PROPERTY(QString status READ status NOTIFY statusChanged)
    Q_PROPERTY(QString lastError READ lastError NOTIFY lastErrorChanged)
    
    Q_PROPERTY(bool isChecking READ isChecking NOTIFY isCheckingChanged)
    Q_PROPERTY(int updateCount READ updateCount NOTIFY availableUpdatesChanged)
    Q_PROPERTY(QVariantList availableUpdates READ availableUpdates NOTIFY availableUpdatesChanged)
    Q_PROPERTY(bool hasCritical READ hasCritical NOTIFY hasCriticalChanged)
    Q_PROPERTY(bool isRebootRequired READ isRebootRequired NOTIFY isRebootRequiredChanged)
    Q_PROPERTY(bool hasActiveTransaction READ hasActiveTransaction NOTIFY hasActiveTransactionChanged)
    Q_PROPERTY(QString stagedVersion READ stagedVersion NOTIFY stagedVersionChanged)
    Q_PROPERTY(QString bootedVersion READ bootedVersion NOTIFY bootedVersionChanged)

public:
    explicit OstreeUpdater(QObject* parent = nullptr);
    
    int updateProgress() const { return m_progress; }
    bool isUpdating() const { return m_updating; }
    QString status() const { return m_status; }
    QString lastError() const { return m_lastError; }
    bool isChecking() const { return m_checking; }
    int updateCount() const { return m_availableUpdates.size(); }
    QVariantList availableUpdates() const { return m_availableUpdates; }
    bool hasCritical() const { return m_hasCritical; }
    bool isRebootRequired() const { return m_isRebootRequired; }
    bool hasActiveTransaction() const { return m_hasActiveTransaction; }
    QString stagedVersion() const { return m_stagedVersion; }
    QString bootedVersion() const { return m_bootedVersion; }

public Q_SLOTS:
    void startUpdate();
    void checkForUpdates();
    void checkRebootRequired();
    void cancelTransaction();
    void reloadState();

Q_SIGNALS:
    void progressChanged();
    void updatingChanged();
    void statusChanged();
    void lastErrorChanged();
    void updateFinished(bool success);
    void transactionCanceled(bool success);

    void isCheckingChanged();
    void availableUpdatesChanged();
    void hasCriticalChanged();
    void isRebootRequiredChanged();
    void hasActiveTransactionChanged();
    void stagedVersionChanged();
    void bootedVersionChanged();

private Q_SLOTS:
    void onPropertiesChanged(const QString& interface, const QVariantMap& changedProperties, const QStringList& invalidatedProperties);
    void onTxFinished(const QDBusMessage& msg);
    void onTxProgress(const QDBusMessage& msg);
    void onTxStatus(const QDBusMessage& msg);

private:
    void setProgress(int progress);
    void setStatus(const QString& status);
    void setLastError(const QString& error);
    void setUpdating(bool updating);
    void setChecking(bool checking);
    void setHasCritical(bool hasCritical);
    void setIsRebootRequired(bool required);
    void checkActiveTransaction();
    void parseCachedUpdate();
    bool resolveOSInterface();

    void startTransaction(const QString& method, const QVariantMap& options);
    void connectToTransaction(const QString& address, const QString& method);

    QDBusInterface* m_sysrootInterface;
    QDBusInterface* m_osInterface = nullptr;
    
    QString m_activeTxName;
    QString m_activeTxMethod;
    QDBusInterface* m_activeTxInterface = nullptr;

    int m_progress = 0;
    bool m_updating = false;
    bool m_checking = false;
    bool m_hasCritical = false;
    bool m_isRebootRequired = false;
    bool m_hasActiveTransaction = false;
    QString m_status;
    QString m_lastError;
    QString m_stagedVersion;
    QString m_bootedVersion;
    QVariantList m_availableUpdates;
};
