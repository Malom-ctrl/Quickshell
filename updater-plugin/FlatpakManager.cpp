#include "FlatpakManager.hpp"
#include <flatpak.h>
#include <QThread>
#include <QDebug>
#include <QMetaObject>
#include <thread>

FlatpakManager::FlatpakManager(QObject* parent) : QObject(parent) {
}

FlatpakManager::~FlatpakManager() {
}

void FlatpakManager::setProgress(int progress) {
    if (m_progress != progress) {
        m_progress = progress;
        Q_EMIT progressChanged();
    }
}

void FlatpakManager::setStatus(const QString& status) {
    if (m_status != status) {
        m_status = status;
        Q_EMIT statusChanged();
    }
}

void FlatpakManager::setLastError(const QString& error) {
    if (m_lastError != error) {
        m_lastError = error;
        Q_EMIT lastErrorChanged();
    }
}

void FlatpakManager::setUpdating(bool updating) {
    if (m_updating != updating) {
        m_updating = updating;
        Q_EMIT updatingChanged();
    }
}

void FlatpakManager::setChecking(bool checking) {
    if (m_checking != checking) {
        m_checking = checking;
        Q_EMIT isCheckingChanged();
    }
}

void FlatpakManager::setCurrentUpdatingRef(const QString& ref) {
    if (m_currentUpdatingRef != ref) {
        m_currentUpdatingRef = ref;
        Q_EMIT currentUpdatingRefChanged();
    }
}

void FlatpakManager::onNewOperation(void* transaction, void* operation, void* progress, void* user_data) {
    auto* self = static_cast<FlatpakManager*>(user_data);
    
    if (progress) {
        g_signal_connect(progress, "changed", G_CALLBACK(onOperationProgress), self);
    }
    
    FlatpakTransactionOperationType opType = flatpak_transaction_operation_get_operation_type(FLATPAK_TRANSACTION_OPERATION(operation));
    
    QString opStr;
    switch (opType) {
        case FLATPAK_TRANSACTION_OPERATION_INSTALL: opStr = "Installing"; break;
        case FLATPAK_TRANSACTION_OPERATION_UPDATE: opStr = "Updating"; break;
        case FLATPAK_TRANSACTION_OPERATION_UNINSTALL: opStr = "Uninstalling"; break;
        default: opStr = "Processing"; break;
    }
    
    const char* ref = flatpak_transaction_operation_get_ref(FLATPAK_TRANSACTION_OPERATION(operation));
    QString refStr = ref ? QString::fromUtf8(ref) : QString();
    
    QMetaObject::invokeMethod(self, [self, opStr, refStr]() {
        self->setCurrentUpdatingRef(refStr);
        self->setStatus(opStr + " " + refStr);
    });
}

void FlatpakManager::onOperationProgress(void* progress, void* user_data) {
    auto* self = static_cast<FlatpakManager*>(user_data);
    int percent = flatpak_transaction_progress_get_progress(FLATPAK_TRANSACTION_PROGRESS(progress));
    
    QMetaObject::invokeMethod(self, [self, percent]() {
        self->setProgress(percent);
    });
}

void FlatpakManager::onOperationDone(void* transaction, void* operation, const char* commit, int res, void* user_data) {
    auto* self = static_cast<FlatpakManager*>(user_data);
    QString refStr;
    if (operation) {
        const char* ref = flatpak_transaction_operation_get_ref(FLATPAK_TRANSACTION_OPERATION(operation));
        if (ref) refStr = QString::fromUtf8(ref);
    }
    bool success = (res == 0); // FLATPAK_TRANSACTION_RESULT_SUCCESS is 0
    
    QMetaObject::invokeMethod(self, [self, refStr, success]() {
        self->setProgress(100);
        if (!refStr.isEmpty() && success) {
            Q_EMIT self->operationFinished(refStr, true);
        }
    });
}

int FlatpakManager::onOperationError(void* transaction, void* operation, void* error, int details, void* user_data) {
    auto* self = static_cast<FlatpakManager*>(user_data);
    const GError* gerr = static_cast<const GError*>(error);
    
    QString refStr;
    if (operation) {
        const char* ref = flatpak_transaction_operation_get_ref(FLATPAK_TRANSACTION_OPERATION(operation));
        if (ref) refStr = QString::fromUtf8(ref);
    }
    QString msg = gerr ? QString::fromUtf8(gerr->message) : "Unknown error";
    bool isNonFatal = (details & FLATPAK_TRANSACTION_ERROR_DETAILS_NON_FATAL);
    
    QMetaObject::invokeMethod(self, [self, refStr, msg, isNonFatal]() {
        if (!refStr.isEmpty()) {
            if (isNonFatal) {
                Q_EMIT self->operationWarning(refStr, msg);
            } else {
                Q_EMIT self->operationFailed(refStr, msg);
            }
        }
    });
    
    if (isNonFatal) {
        return 1; // TRUE in C: non-fatal, keep going
    }
    return 0; // FALSE: fatal, abort transaction
}

void FlatpakManager::checkForUpdates() {
    if (m_checking || m_updating) return;
    setChecking(true);
    
    std::thread([this]() {
        QVariantList list;
        
        auto checkInstallation = [&list](FlatpakInstallation* installation, bool isSystem) {
            g_autoptr(GError) error = nullptr;
            g_autoptr(GPtrArray) refs = flatpak_installation_list_installed_refs_for_update(installation, nullptr, &error);
            if (refs) {
                for (guint i = 0; i < refs->len; i++) {
                    FlatpakInstalledRef* ref = FLATPAK_INSTALLED_REF(g_ptr_array_index(refs, i));
                    QVariantMap map;
                    
                    const char* app_name = flatpak_installed_ref_get_appdata_name(ref);
                    const char* ref_name = flatpak_ref_get_name(FLATPAK_REF(ref));
                    const char* version = flatpak_installed_ref_get_appdata_version(ref);
                    guint64 size = flatpak_installed_ref_get_installed_size(ref);
                    
                    FlatpakRefKind kind = flatpak_ref_get_kind(FLATPAK_REF(ref));
                    const char* kind_str = (kind == FLATPAK_REF_KIND_APP) ? "app" : "runtime";
                    const char* arch_str = flatpak_ref_get_arch(FLATPAK_REF(ref));
                    const char* branch_str = flatpak_ref_get_branch(FLATPAK_REF(ref));
                    QString full_ref = QString("%1/%2/%3/%4")
                        .arg(QString::fromUtf8(kind_str))
                        .arg(QString::fromUtf8(ref_name))
                        .arg(QString::fromUtf8(arch_str))
                        .arg(QString::fromUtf8(branch_str));
                    
                    map["name"] = app_name ? QString::fromUtf8(app_name) : QString::fromUtf8(ref_name);
                    map["version"] = version ? QString::fromUtf8(version) : "";
                    map["ref"] = full_ref;
                    map["isSystem"] = isSystem;
                    
                    double sizeMB = size / (1024.0 * 1024.0);
                    if (sizeMB > 0) {
                        map["size"] = QString::number(sizeMB, 'f', 1) + " MB";
                    } else {
                        map["size"] = "";
                    }
                    
                    list.append(map);
                }
            }
        };

        g_autoptr(GError) userError = nullptr;
        g_autoptr(FlatpakInstallation) userInst = flatpak_installation_new_user(nullptr, &userError);
        if (userInst) checkInstallation(userInst, false);

        g_autoptr(GError) sysError = nullptr;
        g_autoptr(FlatpakInstallation) sysInst = flatpak_installation_new_system(nullptr, &sysError);
        if (sysInst) checkInstallation(sysInst, true);
        
        QMetaObject::invokeMethod(this, [this, list]() {
            m_availableUpdates = list;
            Q_EMIT availableUpdatesChanged();
            setChecking(false);
        });
    }).detach();
}

void FlatpakManager::startUpdate() {
    if (m_updating) return;
    setUpdating(true);
    setProgress(0);
    setLastError("");
    setStatus("Preparing Flatpak update...");

    std::thread([this]() {
        bool overallSuccess = true;
        QString lastErrorStr;

        auto runUpdateForInstallation = [this](bool isSystem, bool& successOut, QString& errorOut) {
            g_autoptr(GError) error = nullptr;
            g_autoptr(FlatpakInstallation) installation = nullptr;
            
            if (isSystem) {
                installation = flatpak_installation_new_system(nullptr, &error);
            } else {
                installation = flatpak_installation_new_user(nullptr, &error);
            }
            
            if (!installation) {
                successOut = false;
                errorOut = QString::fromUtf8(error->message);
                return;
            }

            g_autoptr(FlatpakTransaction) transaction = flatpak_transaction_new_for_installation(installation, nullptr, &error);
            
            g_signal_connect(transaction, "new-operation", G_CALLBACK(onNewOperation), this);
            g_signal_connect(transaction, "operation-done", G_CALLBACK(onOperationDone), this);
            g_signal_connect(transaction, "operation-error", G_CALLBACK(onOperationError), this);

            bool hasAny = false;
            for (const QVariant& item : m_availableUpdates) {
                QVariantMap map = item.toMap();
                if (map["isSystem"].toBool() == isSystem) {
                    QString refStr = map["ref"].toString();
                    QByteArray refBytes = refStr.toUtf8();
                    if (!flatpak_transaction_add_update(transaction, refBytes.constData(), nullptr, nullptr, &error)) {
                        successOut = false;
                        errorOut = QString::fromUtf8(error->message);
                        return;
                    }
                    hasAny = true;
                }
            }

            if (!hasAny) {
                successOut = true;
                return;
            }

            bool success = flatpak_transaction_run(transaction, nullptr, &error);
            QString errStr = error ? QString::fromUtf8(error->message) : QString();
            
            if (success) {
                successOut = true;
            } else {
                successOut = false;
                errorOut = errStr;
            }
        };

        bool userSuccess = true;
        QString userError;
        runUpdateForInstallation(false, userSuccess, userError);
        
        bool sysSuccess = true;
        QString sysError;
        runUpdateForInstallation(true, sysSuccess, sysError);

        overallSuccess = userSuccess && sysSuccess;
        if (!userSuccess) lastErrorStr = userError;
        else if (!sysSuccess) lastErrorStr = sysError;

        QMetaObject::invokeMethod(this, [this, overallSuccess, lastErrorStr]() {
            this->setUpdating(false);
            
            if (overallSuccess) {
                this->setStatus("Flatpak update complete.");
                Q_EMIT this->updateFinished(true);
            } else {
                this->setStatus("Flatpak update failed.");
                if (!lastErrorStr.isEmpty()) this->setLastError(lastErrorStr);
                Q_EMIT this->updateFinished(false);
            }
        });
    }).detach();
}

void FlatpakManager::updatePackage(const QString& ref, bool isSystem) {
    if (m_updating) return;
    setUpdating(true);
    setProgress(0);
    setLastError("");
    setStatus("Preparing Flatpak update for " + ref + "...");

    std::thread([this, ref, isSystem]() {
        g_autoptr(GError) error = nullptr;
        g_autoptr(FlatpakInstallation) installation = nullptr;
        
        if (isSystem) {
            installation = flatpak_installation_new_system(nullptr, &error);
        } else {
            installation = flatpak_installation_new_user(nullptr, &error);
        }
        
        if (!installation) {
            QMetaObject::invokeMethod(this, [this, errStr = QString::fromUtf8(error->message)]() {
                this->setStatus("Error: " + errStr);
                this->setLastError(errStr);
                this->setUpdating(false);
                Q_EMIT this->updateFinished(false);
            });
            return;
        }

        g_autoptr(FlatpakTransaction) transaction = flatpak_transaction_new_for_installation(installation, nullptr, &error);
        
        g_signal_connect(transaction, "new-operation", G_CALLBACK(onNewOperation), this);
        g_signal_connect(transaction, "operation-done", G_CALLBACK(onOperationDone), this);
        g_signal_connect(transaction, "operation-error", G_CALLBACK(onOperationError), this);

        QByteArray refBytes = ref.toUtf8();
        if (!flatpak_transaction_add_update(transaction, refBytes.constData(), nullptr, nullptr, &error)) {
            QMetaObject::invokeMethod(this, [this, errStr = QString::fromUtf8(error->message)]() {
                this->setStatus("Update Error: " + errStr);
                this->setLastError(errStr);
                this->setUpdating(false);
                Q_EMIT this->updateFinished(false);
            });
            return;
        }

        bool success = flatpak_transaction_run(transaction, nullptr, &error);

        QMetaObject::invokeMethod(this, [this, success, errorStr = error ? QString::fromUtf8(error->message) : QString()]() {
            this->setUpdating(false);
            
            if (success) {
                this->setStatus("Flatpak update complete.");
                Q_EMIT this->updateFinished(true);
            } else {
                this->setStatus("Flatpak update failed.");
                if (!errorStr.isEmpty()) this->setLastError(errorStr);
                Q_EMIT this->updateFinished(false);
            }
        });
    }).detach();
}
