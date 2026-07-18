/****************************************************************************
** Meta object code from reading C++ file 'FlatpakManager.hpp'
**
** Created by: The Qt Meta Object Compiler version 69 (Qt 6.11.1)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "../../../FlatpakManager.hpp"
#include <QtCore/qmetatype.h>

#include <QtCore/qtmochelpers.h>

#include <memory>


#include <QtCore/qxptype_traits.h>
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'FlatpakManager.hpp' doesn't include <QObject>."
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
struct qt_meta_tag_ZN14FlatpakManagerE_t {};
} // unnamed namespace

template <> constexpr inline auto FlatpakManager::qt_create_metaobjectdata<qt_meta_tag_ZN14FlatpakManagerE_t>()
{
    namespace QMC = QtMocConstants;
    QtMocHelpers::StringRefStorage qt_stringData {
        "FlatpakManager",
        "QML.Element",
        "auto",
        "progressChanged",
        "",
        "updatingChanged",
        "statusChanged",
        "lastErrorChanged",
        "currentUpdatingRefChanged",
        "updateFinished",
        "success",
        "operationFinished",
        "ref",
        "operationWarning",
        "message",
        "operationFailed",
        "isCheckingChanged",
        "availableUpdatesChanged",
        "startUpdate",
        "checkForUpdates",
        "updatePackage",
        "isSystem",
        "updateProgress",
        "isUpdating",
        "status",
        "lastError",
        "currentUpdatingRef",
        "isChecking",
        "updateCount",
        "availableUpdates",
        "QVariantList"
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
        // Signal 'currentUpdatingRefChanged'
        QtMocHelpers::SignalData<void()>(8, 4, QMC::AccessPublic, QMetaType::Void),
        // Signal 'updateFinished'
        QtMocHelpers::SignalData<void(bool)>(9, 4, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Bool, 10 },
        }}),
        // Signal 'operationFinished'
        QtMocHelpers::SignalData<void(const QString &, bool)>(11, 4, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 12 }, { QMetaType::Bool, 10 },
        }}),
        // Signal 'operationWarning'
        QtMocHelpers::SignalData<void(const QString &, const QString &)>(13, 4, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 12 }, { QMetaType::QString, 14 },
        }}),
        // Signal 'operationFailed'
        QtMocHelpers::SignalData<void(const QString &, const QString &)>(15, 4, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 12 }, { QMetaType::QString, 14 },
        }}),
        // Signal 'isCheckingChanged'
        QtMocHelpers::SignalData<void()>(16, 4, QMC::AccessPublic, QMetaType::Void),
        // Signal 'availableUpdatesChanged'
        QtMocHelpers::SignalData<void()>(17, 4, QMC::AccessPublic, QMetaType::Void),
        // Slot 'startUpdate'
        QtMocHelpers::SlotData<void()>(18, 4, QMC::AccessPublic, QMetaType::Void),
        // Slot 'checkForUpdates'
        QtMocHelpers::SlotData<void()>(19, 4, QMC::AccessPublic, QMetaType::Void),
        // Slot 'updatePackage'
        QtMocHelpers::SlotData<void(const QString &, bool)>(20, 4, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 12 }, { QMetaType::Bool, 21 },
        }}),
    };
    QtMocHelpers::UintData qt_properties {
        // property 'updateProgress'
        QtMocHelpers::PropertyData<int>(22, QMetaType::Int, QMC::DefaultPropertyFlags, 0),
        // property 'isUpdating'
        QtMocHelpers::PropertyData<bool>(23, QMetaType::Bool, QMC::DefaultPropertyFlags, 1),
        // property 'status'
        QtMocHelpers::PropertyData<QString>(24, QMetaType::QString, QMC::DefaultPropertyFlags, 2),
        // property 'lastError'
        QtMocHelpers::PropertyData<QString>(25, QMetaType::QString, QMC::DefaultPropertyFlags, 3),
        // property 'currentUpdatingRef'
        QtMocHelpers::PropertyData<QString>(26, QMetaType::QString, QMC::DefaultPropertyFlags, 4),
        // property 'isChecking'
        QtMocHelpers::PropertyData<bool>(27, QMetaType::Bool, QMC::DefaultPropertyFlags, 9),
        // property 'updateCount'
        QtMocHelpers::PropertyData<int>(28, QMetaType::Int, QMC::DefaultPropertyFlags, 10),
        // property 'availableUpdates'
        QtMocHelpers::PropertyData<QVariantList>(29, 0x80000000 | 30, QMC::DefaultPropertyFlags | QMC::EnumOrFlag, 10),
    };
    QtMocHelpers::UintData qt_enums {
    };
    QtMocHelpers::UintData qt_constructors {};
    QtMocHelpers::ClassInfos qt_classinfo({
            {    1,    2 },
    });
    return QtMocHelpers::metaObjectData<FlatpakManager, void>(QMC::MetaObjectFlag{}, qt_stringData,
            qt_methods, qt_properties, qt_enums, qt_constructors, qt_classinfo);
}
Q_CONSTINIT const QMetaObject FlatpakManager::staticMetaObject = { {
    QMetaObject::SuperData::link<QObject::staticMetaObject>(),
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN14FlatpakManagerE_t>.stringdata,
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN14FlatpakManagerE_t>.data,
    qt_static_metacall,
    nullptr,
    qt_staticMetaObjectRelocatingContent<qt_meta_tag_ZN14FlatpakManagerE_t>.metaTypes,
    nullptr
} };

void FlatpakManager::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    auto *_t = static_cast<FlatpakManager *>(_o);
    if (_c == QMetaObject::InvokeMetaMethod) {
        switch (_id) {
        case 0: _t->progressChanged(); break;
        case 1: _t->updatingChanged(); break;
        case 2: _t->statusChanged(); break;
        case 3: _t->lastErrorChanged(); break;
        case 4: _t->currentUpdatingRefChanged(); break;
        case 5: _t->updateFinished((*reinterpret_cast<std::add_pointer_t<bool>>(_a[1]))); break;
        case 6: _t->operationFinished((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<bool>>(_a[2]))); break;
        case 7: _t->operationWarning((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2]))); break;
        case 8: _t->operationFailed((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2]))); break;
        case 9: _t->isCheckingChanged(); break;
        case 10: _t->availableUpdatesChanged(); break;
        case 11: _t->startUpdate(); break;
        case 12: _t->checkForUpdates(); break;
        case 13: _t->updatePackage((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<bool>>(_a[2]))); break;
        default: ;
        }
    }
    if (_c == QMetaObject::IndexOfMethod) {
        if (QtMocHelpers::indexOfMethod<void (FlatpakManager::*)()>(_a, &FlatpakManager::progressChanged, 0))
            return;
        if (QtMocHelpers::indexOfMethod<void (FlatpakManager::*)()>(_a, &FlatpakManager::updatingChanged, 1))
            return;
        if (QtMocHelpers::indexOfMethod<void (FlatpakManager::*)()>(_a, &FlatpakManager::statusChanged, 2))
            return;
        if (QtMocHelpers::indexOfMethod<void (FlatpakManager::*)()>(_a, &FlatpakManager::lastErrorChanged, 3))
            return;
        if (QtMocHelpers::indexOfMethod<void (FlatpakManager::*)()>(_a, &FlatpakManager::currentUpdatingRefChanged, 4))
            return;
        if (QtMocHelpers::indexOfMethod<void (FlatpakManager::*)(bool )>(_a, &FlatpakManager::updateFinished, 5))
            return;
        if (QtMocHelpers::indexOfMethod<void (FlatpakManager::*)(const QString & , bool )>(_a, &FlatpakManager::operationFinished, 6))
            return;
        if (QtMocHelpers::indexOfMethod<void (FlatpakManager::*)(const QString & , const QString & )>(_a, &FlatpakManager::operationWarning, 7))
            return;
        if (QtMocHelpers::indexOfMethod<void (FlatpakManager::*)(const QString & , const QString & )>(_a, &FlatpakManager::operationFailed, 8))
            return;
        if (QtMocHelpers::indexOfMethod<void (FlatpakManager::*)()>(_a, &FlatpakManager::isCheckingChanged, 9))
            return;
        if (QtMocHelpers::indexOfMethod<void (FlatpakManager::*)()>(_a, &FlatpakManager::availableUpdatesChanged, 10))
            return;
    }
    if (_c == QMetaObject::ReadProperty) {
        void *_v = _a[0];
        switch (_id) {
        case 0: *reinterpret_cast<int*>(_v) = _t->updateProgress(); break;
        case 1: *reinterpret_cast<bool*>(_v) = _t->isUpdating(); break;
        case 2: *reinterpret_cast<QString*>(_v) = _t->status(); break;
        case 3: *reinterpret_cast<QString*>(_v) = _t->lastError(); break;
        case 4: *reinterpret_cast<QString*>(_v) = _t->currentUpdatingRef(); break;
        case 5: *reinterpret_cast<bool*>(_v) = _t->isChecking(); break;
        case 6: *reinterpret_cast<int*>(_v) = _t->updateCount(); break;
        case 7: *reinterpret_cast<QVariantList*>(_v) = _t->availableUpdates(); break;
        default: break;
        }
    }
}

const QMetaObject *FlatpakManager::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->dynamicMetaObject() : &staticMetaObject;
}

void *FlatpakManager::qt_metacast(const char *_clname)
{
    if (!_clname) return nullptr;
    if (!strcmp(_clname, qt_staticMetaObjectStaticContent<qt_meta_tag_ZN14FlatpakManagerE_t>.strings))
        return static_cast<void*>(this);
    return QObject::qt_metacast(_clname);
}

int FlatpakManager::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QObject::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        if (_id < 14)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 14;
    }
    if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 14)
            *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType();
        _id -= 14;
    }
    if (_c == QMetaObject::ReadProperty || _c == QMetaObject::WriteProperty
            || _c == QMetaObject::ResetProperty || _c == QMetaObject::BindableProperty
            || _c == QMetaObject::RegisterPropertyMetaType) {
        qt_static_metacall(this, _c, _id, _a);
        _id -= 8;
    }
    return _id;
}

// SIGNAL 0
void FlatpakManager::progressChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 0, nullptr);
}

// SIGNAL 1
void FlatpakManager::updatingChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 1, nullptr);
}

// SIGNAL 2
void FlatpakManager::statusChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 2, nullptr);
}

// SIGNAL 3
void FlatpakManager::lastErrorChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 3, nullptr);
}

// SIGNAL 4
void FlatpakManager::currentUpdatingRefChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 4, nullptr);
}

// SIGNAL 5
void FlatpakManager::updateFinished(bool _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 5, nullptr, _t1);
}

// SIGNAL 6
void FlatpakManager::operationFinished(const QString & _t1, bool _t2)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 6, nullptr, _t1, _t2);
}

// SIGNAL 7
void FlatpakManager::operationWarning(const QString & _t1, const QString & _t2)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 7, nullptr, _t1, _t2);
}

// SIGNAL 8
void FlatpakManager::operationFailed(const QString & _t1, const QString & _t2)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 8, nullptr, _t1, _t2);
}

// SIGNAL 9
void FlatpakManager::isCheckingChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 9, nullptr);
}

// SIGNAL 10
void FlatpakManager::availableUpdatesChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 10, nullptr);
}
QT_WARNING_POP
