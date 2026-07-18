import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Custom.SystemUpdater 1.0

Rectangle {
    id: root
    width: layout.implicitWidth + 24
    height: 40
    radius: 20
    color: mouseArea.containsMouse || popup.isActive ? Globals.activeColors.secondaryContainer : Qt.rgba(Globals.activeColors.secondaryContainer.r, Globals.activeColors.secondaryContainer.g, Globals.activeColors.secondaryContainer.b, 0.4)

    Behavior on color { ColorAnimation { duration: 150 } }

    property var flatpakMgr: flatpakManager
    property var ostreeMgr: ostreeManager

    property var completedUpdates: ({})
    function countCompletedFlatpaks() {
        let count = 0;
        for (let key in completedUpdates) {
            if (completedUpdates.hasOwnProperty(key)) {
                let val = completedUpdates[key];
                if (val === true || (val && val.success === true)) {
                    count++;
                }
            }
        }
        return count;
    }

    property int completedFlatpakCount: countCompletedFlatpaks()
    onCompletedUpdatesChanged: {
        completedFlatpakCount = countCompletedFlatpaks();
    }

    property int flatpakUpdates: Math.max(0, flatpakManager.updateCount - completedFlatpakCount)
    property int ostreeUpdates: (ostreeManager.updateCount > 0 || ostreeManager.isRebootRequired) ? 1 : 0
    property int totalUpdates: flatpakUpdates + ostreeUpdates // count ostree as 1 update chunk

    property bool hasCritical: ostreeManager.hasCritical
    property bool isUpdating: flatpakManager.isUpdating || ostreeManager.isUpdating

    function checkUpdates() {
        if (!flatpakManager.isChecking && !flatpakManager.isUpdating) {
            flatpakManager.checkForUpdates();
        }
        if (!ostreeManager.isChecking && !ostreeManager.isUpdating) {
            ostreeManager.checkForUpdates();
        }
    }

    Component.onCompleted: {
        flatpakManager.checkForUpdates();
    }

    // The native C++ Managers
    FlatpakManager {
        id: flatpakManager
        onUpdateFinished: (success) => {
            console.log("Flatpak Update Finished: " + success)
        }
        onAvailableUpdatesChanged: {
            root.completedUpdates = {};
        }
    }

    property bool pendingOstreeUpdate: false
    OstreeUpdater {
        id: ostreeManager
        onUpdateFinished: (success) => {
            console.log("OSTree Update Finished: " + success)
            root.pendingOstreeUpdate = false;
        }
        onTransactionCanceled: (success) => {
            console.log("OSTree Transaction Canceled: " + success)
            if (success) {
                if (!ostreeManager.hasActiveTransaction) {
                    ostreeManager.startUpdate();
                } else {
                    root.pendingOstreeUpdate = true;
                }
            }
        }
        onHasActiveTransactionChanged: {
            if (!ostreeManager.hasActiveTransaction && root.pendingOstreeUpdate) {
                console.log("Active transaction cleared, starting pending update...");
                root.pendingOstreeUpdate = false;
                ostreeManager.startUpdate();
            }
        }
    }

    Process {
        id: rebootProc
        command: ["systemctl", "reboot"]
    }

    function rebootSystem() {
        rebootProc.running = true;
    }

    property real perimeter: 2 * (root.width - 40) + 2 * Math.PI * 20
    property real currentProgress: flatpakManager.isUpdating ? Math.max(0, flatpakManager.updateProgress) / 100.0 : 0.0

    Shape {
        id: borderShape
        anchors.fill: parent
        visible: root.isUpdating
        antialiasing: true
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            id: shapePath
            fillColor: "transparent"
            strokeColor: Globals.activeColors.primary
            strokeWidth: 2
            capStyle: ShapePath.RoundCap
            strokeStyle: ShapePath.DashLine

            // If flatpak is updating, show progress percentage. If ostree, show spinning dash.
            dashPattern: flatpakManager.isUpdating ? [root.perimeter * Math.max(0.001, root.currentProgress), root.perimeter] : [40, root.perimeter]

            startX: root.width / 2; startY: 0
            PathLine { x: root.width - 20; y: 0 }
            PathArc { x: root.width; y: 20; radiusX: 20; radiusY: 20; direction: PathArc.Clockwise }
            PathLine { x: root.width; y: root.height - 20 }
            PathArc { x: root.width - 20; y: root.height; radiusX: 20; radiusY: 20; direction: PathArc.Clockwise }
            PathLine { x: 20; y: root.height }
            PathArc { x: 0; y: root.height - 20; radiusX: 20; radiusY: 20; direction: PathArc.Clockwise }
            PathLine { x: 0; y: 20 }
            PathArc { x: 20; y: 0; radiusX: 20; radiusY: 20; direction: PathArc.Clockwise }
            PathLine { x: root.width / 2; y: 0 }
        }

        NumberAnimation {
            target: shapePath
            property: "dashOffset"
            from: root.perimeter + 40
            to: 0
            duration: 1500
            loops: Animation.Infinite
            running: root.isUpdating && !flatpakManager.isUpdating
            easing.type: Easing.InOutSine
        }
    }

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 8

        // General state (No updates)
        Icon {
            visible: root.totalUpdates === 0
            width: 18
            height: 18
            path: "M12 4V1L8 5l4 4V6c3.31 0 6 2.69 6 6 0 1.01-.25 1.97-.7 2.8l1.46 1.46C19.54 15.03 20 13.57 20 12c0-4.42-3.58-8-8-8zm0 14c-3.31 0-6-2.69-6-6 0-1.01.25-1.97.7-2.8L5.24 7.74C4.46 8.97 4 10.43 4 12c0 4.42 3.58 8 8 8v3l4-4-4-4v3z"
            color: Globals.activeColors.onSurfaceVariant
        }

        // OS Update Icon
        Icon {
            visible: root.ostreeUpdates > 0
            width: 18
            height: 18
            path: ostreeManager.isRebootRequired ? "M17.65 6.35C16.2 4.9 14.21 4 12 4c-4.42 0-7.99 3.58-7.99 8s3.57 8 7.99 8c3.73 0 6.84-2.55 7.73-6h-2.08c-.82 2.33-3.04 4-5.65 4-3.31 0-6-2.69-6-6s2.69-6 6-6c1.66 0 3.14.69 4.22 1.78L13 11h7V4l-2.35 2.35z" : "M17 1.01L7 1c-1.1 0-2 .9-2 2v18c0 1.1.9 2 2 2h10c1.1 0 2-.9 2-2V3c0-1.1-.9-1.99-2-1.99zM17 19H7V5h10v14zm-1-6h-3V8h-2v5H8l4 4 4-4z"
            color: ostreeManager.isRebootRequired ? Globals.activeColors.success : (root.hasCritical ? Globals.activeColors.error : Globals.activeColors.primary)
        }

        // Flatpak Update Icon & Count
        RowLayout {
            visible: root.flatpakUpdates > 0
            spacing: 4
            Icon {
                width: 16; height: 16
                path: "M21 16.5c0 .38-.21.71-.53.88l-7.9 4.44c-.16.12-.36.18-.57.18-.21 0-.41-.06-.57-.18l-7.9-4.44A.991.991 0 0 1 3 16.5v-9c0-.38.21-.71.53-.88l7.9-4.44c.16-.12.36-.18.57-.18.21 0 .41.06.57.18l7.9 4.44c.32.17.53.5.53.88v9zM12 4.15L6.04 7.5 12 10.85l5.96-3.35L12 4.15zM5 15.91l6 3.38v-6.71L5 9.21v6.7zm14 0v-6.7l-6 3.38v6.71l6-3.38z"
                color: Globals.activeColors.primary
            }
            Text {
                text: root.flatpakUpdates.toString()
                color: Globals.activeColors.primary
                font.pixelSize: 14; font.bold: true
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: popup.isActive = !popup.isActive
    }

    UpdaterPopup {
        id: popup
        isActive: false
        widgetRoot: root
        anchor.item: root
        anchor.rect.x: root.width / 2
        anchor.rect.y: 0
    }
}
