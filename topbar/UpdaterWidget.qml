import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Custom.SystemUpdater 1.0

Rectangle {
    id: root
    property string themeScope: "topbar.UpdaterWidget"
    width: layout.implicitWidth + Globals.customValue(themeScope + ".layout", "padding", Globals.themeVars.spacingHuge)
    height: Globals.customValue(themeScope, "height", 40)
    radius: Globals.customValue(themeScope, "radius", Globals.themeVars.borderRadiusHuge)
    color: (mouseArea.containsMouse || popup.isActive) ? Globals.customValue(themeScope, "hoverColor", Globals.themeVars.Secondary50) : Globals.customValue(themeScope, "color", Globals.themeVars.Secondary25)

    Behavior on color { ColorAnimation { duration: 150 } }

    property var flatpakMgr: flatpakManager
    property var ostreeMgr: ostreeManager
    property var fwupdMgr: fwupdManager

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
    property int fwupdUpdates: Math.max(0, fwupdManager.updateCount)
    property int totalUpdates: flatpakUpdates + ostreeUpdates + fwupdUpdates // count ostree as 1 update chunk

    property bool hasCritical: ostreeManager.hasCritical
    property bool isUpdating: flatpakManager.isUpdating || ostreeManager.isUpdating || fwupdManager.isUpdating

    function checkUpdates() {
        if (!flatpakManager.isChecking && !flatpakManager.isUpdating) {
            flatpakManager.checkForUpdates();
        }
        if (!ostreeManager.isChecking && !ostreeManager.isUpdating) {
            ostreeManager.checkForUpdates();
        }
        if (!fwupdManager.isChecking && !fwupdManager.isUpdating) {
            fwupdManager.checkForUpdates();
        }
    }

    Component.onCompleted: {
        flatpakManager.checkForUpdates();
        fwupdManager.checkForUpdates();
    }

    // The native C++ Managers
    FwupdManager {
        id: fwupdManager
        onUpdateFinished: (deviceId, success) => {
            console.log("Firmware Update Finished: " + success)
        }
    }

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

    property real shapeRadius: Globals.customValue(themeScope, "radius", Globals.themeVars.borderRadiusHuge)
    property real perimeter: 2 * (root.width - 2 * shapeRadius) + 2 * Math.PI * shapeRadius
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
            strokeColor: (mouseArea.containsMouse || popup.isActive) ? Globals.customValue(themeScope + ".indicator", "hoverColor", Globals.themeVars.White) : Globals.customValue(themeScope + ".indicator", "color", Globals.themeVars.Secondary)
            strokeWidth: Globals.customValue(themeScope + ".indicator", "width", Globals.themeVars.borderWidthMedium)
            capStyle: ShapePath.RoundCap
            strokeStyle: ShapePath.DashLine

            // If flatpak is updating, show progress percentage. If ostree, show spinning dash.
            dashPattern: flatpakManager.isUpdating ? [root.perimeter * Math.max(0.001, root.currentProgress), root.perimeter] : [40, root.perimeter]

            startX: root.width / 2; startY: 0
            PathLine { x: root.width - Globals.customValue(themeScope, "radius", Globals.themeVars.borderRadiusHuge); y: 0 }
            PathArc { x: root.width; y: Globals.customValue(themeScope, "radius", Globals.themeVars.borderRadiusHuge); radiusX: Globals.customValue(themeScope, "radius", Globals.themeVars.borderRadiusHuge); radiusY: Globals.customValue(themeScope, "radius", Globals.themeVars.borderRadiusHuge); direction: PathArc.Clockwise }
            PathLine { x: root.width; y: root.height - Globals.customValue(themeScope, "radius", Globals.themeVars.borderRadiusHuge) }
            PathArc { x: root.width - Globals.customValue(themeScope, "radius", Globals.themeVars.borderRadiusHuge); y: root.height; radiusX: Globals.customValue(themeScope, "radius", Globals.themeVars.borderRadiusHuge); radiusY: Globals.customValue(themeScope, "radius", Globals.themeVars.borderRadiusHuge); direction: PathArc.Clockwise }
            PathLine { x: Globals.customValue(themeScope, "radius", Globals.themeVars.borderRadiusHuge); y: root.height }
            PathArc { x: 0; y: root.height - Globals.customValue(themeScope, "radius", Globals.themeVars.borderRadiusHuge); radiusX: Globals.customValue(themeScope, "radius", Globals.themeVars.borderRadiusHuge); radiusY: Globals.customValue(themeScope, "radius", Globals.themeVars.borderRadiusHuge); direction: PathArc.Clockwise }
            PathLine { x: 0; y: Globals.customValue(themeScope, "radius", Globals.themeVars.borderRadiusHuge) }
            PathArc { x: Globals.customValue(themeScope, "radius", Globals.themeVars.borderRadiusHuge); y: 0; radiusX: Globals.customValue(themeScope, "radius", Globals.themeVars.borderRadiusHuge); radiusY: Globals.customValue(themeScope, "radius", Globals.themeVars.borderRadiusHuge); direction: PathArc.Clockwise }
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
        spacing: Globals.customValue(themeScope + ".layout", "spacing", Globals.themeVars.spacingMedium)

        // General state (No updates)
        Icon {
            visible: root.totalUpdates === 0
            width: Globals.customValue(themeScope + ".icon", "width", 18)
            height: Globals.customValue(themeScope + ".icon", "height", 18)
            path: "M12 4V1L8 5l4 4V6c3.31 0 6 2.69 6 6 0 1.01-.25 1.97-.7 2.8l1.46 1.46C19.54 15.03 20 13.57 20 12c0-4.42-3.58-8-8-8zm0 14c-3.31 0-6-2.69-6-6 0-1.01.25-1.97.7-2.8L5.24 7.74C4.46 8.97 4 10.43 4 12c0 4.42 3.58 8 8 8v3l4-4-4-4v3z"
            color: Globals.customValue(themeScope + ".icon", "color", Globals.themeVars.White)
        }

        // OS Update Icon
        Icon {
            visible: root.ostreeUpdates > 0
            width: Globals.customValue(themeScope + ".icon", "width", 18)
            height: Globals.customValue(themeScope + ".icon", "height", 18)
            path: ostreeManager.isRebootRequired ? "M17.65 6.35C16.2 4.9 14.21 4 12 4c-4.42 0-7.99 3.58-7.99 8s3.57 8 7.99 8c3.73 0 6.84-2.55 7.73-6h-2.08c-.82 2.33-3.04 4-5.65 4-3.31 0-6-2.69-6-6s2.69-6 6-6c1.66 0 3.14.69 4.22 1.78L13 11h7V4l-2.35 2.35z" : "M17 1.01L7 1c-1.1 0-2 .9-2 2v18c0 1.1.9 2 2 2h10c1.1 0 2-.9 2-2V3c0-1.1-.9-1.99-2-1.99zM17 19H7V5h10v14zm-1-6h-3V8h-2v5H8l4 4 4-4z"
            color: ostreeManager.isRebootRequired ? Globals.customValue(themeScope + ".icon", "rebootColor", Globals.themeVars.Success) : (root.hasCritical ? Globals.customValue(themeScope + ".icon", "criticalColor", Globals.themeVars.Warning) : Globals.customValue(themeScope + ".icon", "updateColor", Globals.themeVars.Secondary))
        }

        // Flatpak Update Icon & Count
        RowLayout {
            visible: root.flatpakUpdates > 0
            spacing: Globals.customValue(themeScope + ".flatpakLayout", "spacing", Globals.themeVars.spacingSmall)
            Icon {
                width: Globals.customValue(themeScope + ".flatpakIcon", "width", 16); height: Globals.customValue(themeScope + ".flatpakIcon", "height", 16)
                path: "M21 16.5c0 .38-.21.71-.53.88l-7.9 4.44c-.16.12-.36.18-.57.18-.21 0-.41-.06-.57-.18l-7.9-4.44A.991.991 0 0 1 3 16.5v-9c0-.38.21-.71.53-.88l7.9-4.44c.16-.12.36-.18.57-.18.21 0 .41.06.57.18l7.9 4.44c.32.17.53.5.53.88v9zM12 4.15L6.04 7.5 12 10.85l5.96-3.35L12 4.15zM5 15.91l6 3.38v-6.71L5 9.21v6.7zm14 0v-6.7l-6 3.38v6.71l6-3.38z"
                color: Globals.customValue(themeScope + ".flatpakIcon", "color", Globals.themeVars.White)
            }
            Text {
                text: root.flatpakUpdates.toString()
                color: Globals.customValue(themeScope + ".flatpakText", "color", Globals.themeVars.White)
                font.pixelSize: Globals.customValue(themeScope + ".flatpakText", "fontSize", Globals.themeVars.fontSizeMedium); font.bold: true
            }
        }

        // Firmware Update Icon & Count
        RowLayout {
            visible: root.fwupdUpdates > 0
            spacing: Globals.customValue(themeScope + ".fwupdLayout", "spacing", Globals.themeVars.spacingSmall)
            Icon {
                width: Globals.customValue(themeScope + ".fwupdIcon", "width", 16); height: Globals.customValue(themeScope + ".fwupdIcon", "height", 16)
                path: "M2 13h2v5H2v-5zm18 0h-2v5h2v-5zM17.5 4.5c.83 0 1.5.67 1.5 1.5s-.67 1.5-1.5 1.5-1.5-.67-1.5-1.5.67-1.5 1.5-1.5zM12 2C6.48 2 2 6.48 2 12h20c0-5.52-4.48-10-10-10zm0 3c1.66 0 3 1.34 3 3s-1.34 3-3 3-3-1.34-3-3 1.34-3 3-3z"
                color: Globals.customValue(themeScope + ".fwupdIcon", "color", Globals.themeVars.White)
            }
            Text {
                text: root.fwupdUpdates.toString()
                color: Globals.customValue(themeScope + ".fwupdText", "color", Globals.themeVars.White)
                font.pixelSize: Globals.customValue(themeScope + ".fwupdText", "fontSize", Globals.themeVars.fontSizeMedium); font.bold: true
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
