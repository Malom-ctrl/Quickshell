/****************************************************************************
** Meta object code from reading C++ file 'OstreeUpdater.hpp'
**
** Created by: The Qt Meta Object Compiler version 69 (Qt 6.11.1)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "../../../OstreeUpdater.hpp"
#include <QtCore/qmetatype.h>

#include <QtCore/qtmochelpers.h>

#include <memory>


#include <QtCore/qxptype_traits.h>
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'OstreeUpdater.hpp' doesn't include <QObject>."
#elif Q_MOC_OUTPUT_REVISION != 69
#error "This file was generated using the moc from 6.11.1. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

#ifndef Q_CONSTINIT
#define Q_CONSTINIT
#endif

QT_WARNING_PUSH
QT_WARNING_DISABLE_DEPRECATED
QT_WARNING_DISABLE_GCC("-Wuseless-cast")
namespace {
struct qt_meta_tag_ZN13OstreeUpdaterE_t {};
} // unnamed namespace

template <> constexpr inline auto OstreeUpdater::qt_create_metaobjectdata<qt_meta_tag_ZN13OstreeUpdaterE_t>()
{
    namespace QMC = QtMocConstants;
    QtMocHelpers::StringRefStorage qt_stringData {
        "OstreeUpdater",
        "QML.Element",
        "auto",
        "progressChanged",
        "",
        "updatingChanged",
        "statusChanged",
        "lastErrorChanged",
        "updateFinished",
        "success",
        "transactionCanceled",
        "isCheckingChanged",
        "availableUpdatesChanged",
        "hasCriticalChanged",
        "isRebootRequiredChanged",
        "hasActiveTransactionChanged",
        "stagedVersionChanged",
        "bootedVersionChanged",
        "startUpdate",
        "checkForUpdates",
        "checkRebootRequired",
        "cancelTransaction",
        "reloadState",
        "onPropertiesChanged",
        "interface",
        "QVariantMap",
        "changedProperties",
        "invalidatedProperties",
        "onTxFinished",
        "QDBusMessage",
        "msg",
        "onTxProgress",
        "onTxStatus",
        "updateProgress",
        "isUpdating",
        "status",
        "lastError",
        "isChecking",
        "updateCount",
        "availableUpdates",
        "QVariantList",
        "hasCritical",
        "isRebootRequired",
        "hasActiveTransaction",
        "stagedVersion",
        "bootedVersion"
    };

    QtMocHelpers::UintData qt_methods {
        // Signal 'progressChanged'
        QtMocHelpers::SignalData<void()>(3, 4, QMC::AccessPublic, QMetaType::Void),
        // Signal 'updatingChanged'
        QtMocHelpers::SignalData<void()>(5, 4, QMC::AccessPublic, QMetaType::Void),
        // Signal 'statusChanged'
        QtMocHelpers::SignalData<void()>(6, 4, QMC::AccessPublic, QMetaType::Void),
        // Signal 'lastErrorChanged'
        QtMocHelpers::SignalData<void()>(7, 4, QMC::AccessPublic, QMetaType::Void),
        // Signal 'updateFinished'
        QtMocHelpers::SignalData<void(bool)>(8, 4, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Bool, 9 },
        }}),
        // Signal 'transactionCanceled'
        QtMocHelpers::SignalData<void(bool)>(10, 4, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Bool, 9 },
        }}),
        // Signal 'isCheckingChanged'
        QtMocHelpers::SignalData<void()>(11, 4, QMC::AccessPublic, QMetaType::Void),
        // Signal 'availableUpdatesChanged'
        QtMocHelpers::SignalData<void()>(12, 4, QMC::AccessPublic, QMetaType::Void),
        // Signal 'hasCriticalChanged'
        QtMocHelpers::SignalData<void()>(13, 4, QMC::AccessPublic, QMetaType::Void),
        // Signal 'isRebootRequiredChanged'
        QtMocHelpers::SignalData<void()>(14, 4, QMC::AccessPublic, QMetaType::Void),
        // Signal 'hasActiveTransactionChanged'
        QtMocHelpers::SignalData<void()>(15, 4, QMC::AccessPublic, QMetaType::Void),
        // Signal 'stagedVersionChanged'
        QtMocHelpers::SignalData<void()>(16, 4, QMC::AccessPublic, QMetaType::Void),
        // Signal 'bootedVersionChanged'
        QtMocHelpers::SignalData<void()>(17, 4, QMC::AccessPublic, QMetaType::Void),
        // Slot 'startUpdate'
        QtMocHelpers::SlotData<void()>(18, 4, QMC::AccessPublic, QMetaType::Void),
        // Slot 'checkForUpdates'
        QtMocHelpers::SlotData<void()>(19, 4, QMC::AccessPublic, QMetaType::Void),
        // Slot 'checkRebootRequired'
        QtMocHelpers::SlotData<void()>(20, 4, QMC::AccessPublic, QMetaType::Void),
        // Slot 'cancelTransaction'
        QtMocHelpers::SlotData<void()>(21, 4, QMC::AccessPublic, QMetaType::Void),
        // Slot 'reloadState'
        QtMocHelpers::SlotData<void()>(22, 4, QMC::AccessPublic, QMetaType::Void),
        // Slot 'onPropertiesChanged'
        QtMocHelpers::SlotData<void(const QString &, const QVariantMap &, const QStringList &)>(23, 4, QMC::AccessPrivate, QMetaType::Void, {{
            { QMetaType::QString, 24 }, { 0x80000000 | 25, 26 }, { QMetaType::QStringList, 27 },
        }}),
        // Slot 'onTxFinished'
        QtMocHelpers::SlotData<void(const QDBusMessage &)>(28, 4, QMC::AccessPrivate, QMetaType::Void, {{
            { 0x80000000 | 29, 30 },
        }}),
        // Slot 'onTxProgress'
        QtMocHelpers::SlotData<void(const QDBusMessage &)>(31, 4, QMC::AccessPrivate, QMetaType::Void, {{
            { 0x80000000 | 29, 30 },
        }}),
        // Slot 'onTxStatus'
        QtMocHelpers::SlotData<void(const QDBusMessage &)>(32, 4, QMC::AccessPrivate, QMetaType::Void, {{
            { 0x80000000 | 29, 30 },
        }}),
    };
    QtMocHelpers::UintData qt_properties {
        // property 'updateProgress'
        QtMocHelpers::PropertyData<int>(33, QMetaType::Int, QMC::DefaultPropertyFlags, 0),
        // property 'isUpdating'
        QtMocHelpers::PropertyData<bool>(34, QMetaType::Bool, QMC::DefaultPropertyFlags, 1),
        // property 'status'
        QtMocHelpers::PropertyData<QString>(35, QMetaType::QString, QMC::DefaultPropertyFlags, 2),
        // property 'lastError'
        QtMocHelpers::PropertyData<QString>(36, QMetaType::QString, QMC::DefaultPropertyFlags, 3),
        // property 'isChecking'
        QtMocHelpers::PropertyData<bool>(37, QMetaType::Bool, QMC::DefaultPropertyFlags, 6),
        // property 'updateCount'
        QtMocHelpers::PropertyData<int>(38, QMetaType::Int, QMC::DefaultPropertyFlags, 7),
        // property 'availableUpdates'
        QtMocHelpers::PropertyData<QVariantList>(39, 0x80000000 | 40, QMC::DefaultPropertyFlags | QMC::EnumOrFlag, 7),
        // property 'hasCritical'
        QtMocHelpers::PropertyData<bool>(41, QMetaType::Bool, QMC::DefaultPropertyFlags, 8),
        // property 'isRebootRequired'
        QtMocHelpers::PropertyData<bool>(42, QMetaType::Bool, QMC::DefaultPropertyFlags, 9),
        // property 'hasActiveTransaction'
        QtMocHelpers::PropertyData<bool>(43, QMetaType::Bool, QMC::DefaultPropertyFlags, 10),
        // property 'stagedVersion'
        QtMocHelpers::PropertyData<QString>(44, QMetaType::QString, QMC::DefaultPropertyFlags, 11),
        // property 'bootedVersion'
        QtMocHelpers::PropertyData<QString>(45, QMetaType::QString, QMC::DefaultPropertyFlags, 12),
    };
    QtMocHelpers::UintData qt_enums {
    };
    QtMocHelpers::UintData qt_constructors {};
    QtMocHelpers::ClassInfos qt_classinfo({
            {    1,    2 },
    });
    return QtMocHelpers::metaObjectData<OstreeUpdater, void>(QMC::MetaObjectFlag{}, qt_stringData,
            qt_methods, qt_properties, qt_enums, qt_constructors, qt_classinfo);
}
Q_CONSTINIT const QMetaObject OstreeUpdater::staticMetaObject = { {
    QMetaObject::SuperData::link<QObject::staticMetaObject>(),
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN13OstreeUpdaterE_t>.stringdata,
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN13OstreeUpdaterE_t>.data,
    qt_static_metacall,
    nullptr,
    qt_staticMetaObjectRelocatingContent<qt_meta_tag_ZN13OstreeUpdaterE_t>.metaTypes,
    nullptr
} };

void OstreeUpdater::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    auto *_t = static_cast<OstreeUpdater *>(_o);
    if (_c == QMetaObject::InvokeMetaMethod) {
        switch (_id) {
        case 0: _t->progressChanged(); break;
        case 1: _t->updatingChanged(); break;
        case 2: _t->statusChanged(); break;
        case 3: _t->lastErrorChanged(); break;
        case 4: _t->updateFinished((*reinterpret_cast<std::add_pointer_t<bool>>(_a[1]))); break;
        case 5: _t->transactionCanceled((*reinterpret_cast<std::add_pointer_t<bool>>(_a[1]))); break;
        case 6: _t->isCheckingChanged(); break;
        case 7: _t->availableUpdatesChanged(); break;
        case 8: _t->hasCriticalChanged(); break;
        case 9: _t->isRebootRequiredChanged(); break;
        case 10: _t->hasActiveTransactionChanged(); break;
        case 11: _t->stagedVersionChanged(); break;
        case 12: _t->bootedVersionChanged(); break;
        case 13: _t->startUpdate(); break;
        case 14: _t->checkForUpdates(); break;
        case 15: _t->checkRebootRequired(); break;
        case 16: _t->cancelTransaction(); break;
        case 17: _t->reloadState(); break;
        case 18: _t->onPropertiesChanged((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QVariantMap>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<QStringList>>(_a[3]))); break;
        case 19: _t->onTxFinished((*reinterpret_cast<std::add_pointer_t<QDBusMessage>>(_a[1]))); break;
        case 20: _t->onTxProgress((*reinterpret_cast<std::add_pointer_t<QDBusMessage>>(_a[1]))); break;
        case 21: _t->onTxStatus((*reinterpret_cast<std::add_pointer_t<QDBusMessage>>(_a[1]))); break;
        default: ;
        }
    }
    if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        switch (_id) {
        default: *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType(); break;
        case 19:
            switch (*reinterpret_cast<int*>(_a[1])) {
            default: *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType(); break;
            case 0:
                *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType::fromType< QDBusMessage >(); break;
            }
            break;
        case 20:
            switch (*reinterpret_cast<int*>(_a[1])) {
            default: *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType(); break;
            case 0:
                *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType::fromType< QDBusMessage >(); break;
            }
            break;
        case 21:
            switch (*reinterpret_cast<int*>(_a[1])) {
            default: *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType(); break;
            case 0:
                *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType::fromType< QDBusMessage >(); break;
            }
            break;
        }
    }
    if (_c == QMetaObject::IndexOfMethod) {
        if (QtMocHelpers::indexOfMethod<void (OstreeUpdater::*)()>(_a, &OstreeUpdater::progressChanged, 0))
            return;
        if (QtMocHelpers::indexOfMethod<void (OstreeUpdater::*)()>(_a, &OstreeUpdater::updatingChanged, 1))
            return;
        if (QtMocHelpers::indexOfMethod<void (OstreeUpdater::*)()>(_a, &OstreeUpdater::statusChanged, 2))
            return;
        if (QtMocHelpers::indexOfMethod<void (OstreeUpdater::*)()>(_a, &OstreeUpdater::lastErrorChanged, 3))
            return;
        if (QtMocHelpers::indexOfMethod<void (OstreeUpdater::*)(bool )>(_a, &OstreeUpdater::updateFinished, 4))
            return;
        if (QtMocHelpers::indexOfMethod<void (OstreeUpdater::*)(bool )>(_a, &OstreeUpdater::transactionCanceled, 5))
            return;
        if (QtMocHelpers::indexOfMethod<void (OstreeUpdater::*)()>(_a, &OstreeUpdater::isCheckingChanged, 6))
            return;
        if (QtMocHelpers::indexOfMethod<void (OstreeUpdater::*)()>(_a, &OstreeUpdater::availableUpdatesChanged, 7))
            return;
        if (QtMocHelpers::indexOfMethod<void (OstreeUpdater::*)()>(_a, &OstreeUpdater::hasCriticalChanged, 8))
            return;
        if (QtMocHelpers::indexOfMethod<void (OstreeUpdater::*)()>(_a, &OstreeUpdater::isRebootRequiredChanged, 9))
            return;
        if (QtMocHelpers::indexOfMethod<void (OstreeUpdater::*)()>(_a, &OstreeUpdater::hasActiveTransactionChanged, 10))
            return;
        if (QtMocHelpers::indexOfMethod<void (OstreeUpdater::*)()>(_a, &OstreeUpdater::stagedVersionChanged, 11))
            return;
        if (QtMocHelpers::indexOfMethod<void (OstreeUpdater::*)()>(_a, &OstreeUpdater::bootedVersionChanged, 12))
            return;
    }
    if (_c == QMetaObject::ReadProperty) {
        void *_v = _a[0];
        switch (_id) {
        case 0: *reinterpret_cast<int*>(_v) = _t->updateProgress(); break;
        case 1: *reinterpret_cast<bool*>(_v) = _t->isUpdating(); break;
        case 2: *reinterpret_cast<QString*>(_v) = _t->status(); break;
        case 3: *reinterpret_cast<QString*>(_v) = _t->lastError(); break;
        case 4: *reinterpret_cast<bool*>(_v) = _t->isChecking(); break;
        case 5: *reinterpret_cast<int*>(_v) = _t->updateCount(); break;
        case 6: *reinterpret_cast<QVariantList*>(_v) = _t->availableUpdates(); break;
        case 7: *reinterpret_cast<bool*>(_v) = _t->hasCritical(); break;
        case 8: *reinterpret_cast<bool*>(_v) = _t->isRebootRequired(); break;
        case 9: *reinterpret_cast<bool*>(_v) = _t->hasActiveTransaction(); break;
        case 10: *reinterpret_cast<QString*>(_v) = _t->stagedVersion(); break;
        case 11: *reinterpret_cast<QString*>(_v) = _t->bootedVersion(); break;
        default: break;
        }
    }
}

const QMetaObject *OstreeUpdater::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->dynamicMetaObject() : &staticMetaObject;
}

void *OstreeUpdater::qt_metacast(const char *_clname)
{
    if (!_clname) return nullptr;
    if (!strcmp(_clname, qt_staticMetaObjectStaticContent<qt_meta_tag_ZN13OstreeUpdaterE_t>.strings))
        return static_cast<void*>(this);
    return QObject::qt_metacast(_clname);
}

int OstreeUpdater::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QObject::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        if (_id < 22)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 22;
    }
    if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 22)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 22;
    }
    if (_c == QMetaObject::ReadProperty || _c == QMetaObject::WriteProperty
            || _c == QMetaObject::ResetProperty || _c == QMetaObject::BindableProperty
            || _c == QMetaObject::RegisterPropertyMetaType) {
        qt_static_metacall(this, _c, _id, _a);
        _id -= 12;
    }
    return _id;
}

// SIGNAL 0
void OstreeUpdater::progressChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 0, nullptr);
}

// SIGNAL 1
void OstreeUpdater::updatingChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 1, nullptr);
}

// SIGNAL 2
void OstreeUpdater::statusChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 2, nullptr);
}

// SIGNAL 3
void OstreeUpdater::lastErrorChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 3, nullptr);
}

// SIGNAL 4
void OstreeUpdater::updateFinished(bool _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 4, nullptr, _t1);
}

// SIGNAL 5
void OstreeUpdater::transactionCanceled(bool _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 5, nullptr, _t1);
}

// SIGNAL 6
void OstreeUpdater::isCheckingChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 6, nullptr);
}

// SIGNAL 7
void OstreeUpdater::availableUpdatesChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 7, nullptr);
}

// SIGNAL 8
void OstreeUpdater::hasCriticalChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 8, nullptr);
}

// SIGNAL 9
void OstreeUpdater::isRebootRequiredChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 9, nullptr);
}

// SIGNAL 10
void OstreeUpdater::hasActiveTransactionChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 10, nullptr);
}

// SIGNAL 11
void OstreeUpdater::stagedVersionChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 11, nullptr);
}

// SIGNAL 12
void OstreeUpdater::bootedVersionChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 12, nullptr);
}
QT_WARNING_POP
