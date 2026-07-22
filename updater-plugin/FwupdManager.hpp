#pragma once
#include <QObject>
#include <QtQml/qqml.h>
#include <QDBusInterface>
#include <QVariantList>
#include <QString>

class FwupdManager : public QObject {
    Q_OBJECT
    QML_ELEMENT
    
    Q_PROPERTY(int updateProgress READ updateProgress NOTIFY progressChanged)
    Q_PROPERTY(bool isUpdating READ isUpdating NOTIFY updatingChanged)
    Q_PROPERTY(QString status READ status NOTIFY statusChanged)
    Q_PROPERTY(QString lastError READ lastError NOTIFY lastErrorChanged)
    
    Q_PROPERTY(bool isChecking READ isChecking NOTIFY isCheckingChanged)
    Q_PROPERTY(int updateCount READ updateCount NOTIFY availableUpdatesChanged)
    Q_PROPERTY(QVariantList availableUpdates READ availableUpdates NOTIFY availableUpdatesChanged)

public:
    explicit FwupdManager(QObject* parent = nullptr);
    
    int updateProgress() const { return m_progress; }
    bool isUpdating() const { return m_updating; }
    QString status() const { return m_status; }
    QString lastError() const { return m_lastError; }
    bool isChecking() const { return m_checking; }
    int updateCount() const { return m_availableUpdates.size(); }
    QVariantList availableUpdates() const { return m_availableUpdates; }

public Q_SLOTS:
    void checkForUpdates();
    void startUpdate(const QString& deviceId);
    void startAllUpdates();

Q_SIGNALS:
    void progressChanged();
    void updatingChanged();
    void statusChanged();
    void lastErrorChanged();
    
    void isCheckingChanged();
    void availableUpdatesChanged();
    
    void updateFinished(const QString& deviceId, bool success);

private Q_SLOTS:
    void onPropertiesChanged(const QString& interface, const QVariantMap& changedProperties, const QStringList& invalidatedProperties);
    void onDeviceAdded(const QVariantMap& device);
    void onDeviceChanged(const QVariantMap& device);
    void onDeviceRemoved(const QVariantMap& device);
    void onChanged();

private:
    void setProgress(int progress);
    void setStatus(const QString& status);
    void setLastError(const QString& error);
    void setUpdating(bool updating);
    void setChecking(bool checking);

    QDBusInterface* m_fwupdInterface = nullptr;

    int m_progress = 0;
    bool m_updating = false;
    bool m_checking = false;
    QString m_status;
    QString m_lastError;
    QVariantList m_availableUpdates;
};
