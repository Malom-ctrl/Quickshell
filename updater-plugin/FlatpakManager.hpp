#pragma once
#include <QObject>
#include <QtQml/qqml.h>
#include <QString>
#include <QVariantList>
#include <QTimer>

class FlatpakManager : public QObject {
    Q_OBJECT
    QML_ELEMENT
    
    Q_PROPERTY(int updateProgress READ updateProgress NOTIFY progressChanged)
    Q_PROPERTY(bool isUpdating READ isUpdating NOTIFY updatingChanged)
    Q_PROPERTY(QString status READ status NOTIFY statusChanged)
    Q_PROPERTY(QString lastError READ lastError NOTIFY lastErrorChanged)
    Q_PROPERTY(QString currentUpdatingRef READ currentUpdatingRef NOTIFY currentUpdatingRefChanged)
    
    Q_PROPERTY(bool isChecking READ isChecking NOTIFY isCheckingChanged)
    Q_PROPERTY(int updateCount READ updateCount NOTIFY availableUpdatesChanged)
    Q_PROPERTY(QVariantList availableUpdates READ availableUpdates NOTIFY availableUpdatesChanged)

public:
    explicit FlatpakManager(QObject* parent = nullptr);
    ~FlatpakManager() override;

    int updateProgress() const { return m_progress; }
    bool isUpdating() const { return m_updating; }
    QString status() const { return m_status; }
    QString lastError() const { return m_lastError; }
    QString currentUpdatingRef() const { return m_currentUpdatingRef; }

    bool isChecking() const { return m_checking; }
    int updateCount() const { return m_availableUpdates.size(); }
    QVariantList availableUpdates() const { return m_availableUpdates; }

public Q_SLOTS:
    void startUpdate();
    void checkForUpdates();
    void updatePackage(const QString& ref, bool isSystem);

Q_SIGNALS:
    void progressChanged();
    void updatingChanged();
    void statusChanged();
    void lastErrorChanged();
    void currentUpdatingRefChanged();
    void updateFinished(bool success);
    void operationFinished(const QString& ref, bool success);
    void operationWarning(const QString& ref, const QString& message);
    void operationFailed(const QString& ref, const QString& message);
    
    void isCheckingChanged();
    void availableUpdatesChanged();

private Q_SLOTS:
    void handleMonitorChanged();

private:
    void setProgress(int progress);
    void setStatus(const QString& status);
    void setLastError(const QString& error);
    void setUpdating(bool updating);
    void setChecking(bool checking);
    void setCurrentUpdatingRef(const QString& ref);
    void setupMonitors();

    static void onNewOperation(void* transaction, void* operation, void* progress, void* user_data);
    static void onOperationProgress(void* progress, void* user_data);
    static void onOperationDone(void* transaction, void* operation, const char* commit, int res, void* user_data);
    static int onOperationError(void* transaction, void* operation, void* error, int details, void* user_data);
    static void onMonitorChanged(void* monitor, void* file, void* other_file, int event_type, void* user_data);

    int m_progress = 0;
    bool m_updating = false;
    bool m_checking = false;
    QString m_status;
    QString m_lastError;
    QString m_currentUpdatingRef;
    QVariantList m_availableUpdates;
    
    void* m_userMonitor = nullptr;
    void* m_sysMonitor = nullptr;
    QTimer m_debounceTimer;
};
