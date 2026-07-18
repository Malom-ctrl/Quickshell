import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Shapes
import Quickshell

PopupWindow {
    id: root
    property bool isActive: false
    property var widgetRoot: null
    property var cveSeverityCache: ({})
    property bool updatingAllFlatpaks: false


    visible: isActive || openProgress > 0.0

    onIsActiveChanged: {
    }

    property real openProgress: isActive ? 1.0 : 0.0
    Behavior on openProgress {
        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
    }

    Component.onCompleted: {
        dumpUpdates("completed")
    }

    Connections {
        target: widgetRoot && widgetRoot.ostreeMgr ? widgetRoot.ostreeMgr : null

        function onAvailableUpdatesChanged() {
            dumpUpdates("availableUpdatesChanged")
        }

        function onHasCriticalChanged() {
            console.log("[ostree] hasCritical =", widgetRoot.ostreeMgr.hasCritical)
        }

        function onStatusChanged() {
            console.log("[ostree] status =", widgetRoot.ostreeMgr.status)
        }
    }

    Connections {
        target: widgetRoot && widgetRoot.flatpakMgr ? widgetRoot.flatpakMgr : null

        function onOperationFinished(ref, success) {
            if (success) {
                let done = widgetRoot.completedUpdates;
                done[ref] = { "success": true, "fatal": false, "message": "" };
                widgetRoot.completedUpdates = Object.assign({}, done);
            }
        }

        function onOperationWarning(ref, message) {
            let done = widgetRoot.completedUpdates;
            done[ref] = { "success": false, "fatal": false, "message": message };
            widgetRoot.completedUpdates = Object.assign({}, done);
        }

        function onOperationFailed(ref, message) {
            let done = widgetRoot.completedUpdates;
            done[ref] = { "success": false, "fatal": true, "message": message };
            widgetRoot.completedUpdates = Object.assign({}, done);
        }

        function onUpdatingChanged() {
            if (!widgetRoot.flatpakMgr.isUpdating) {
                root.updatingAllFlatpaks = false;
            }
        }
    }

    function dumpUpdates(reason) {
        if (!widgetRoot || !widgetRoot.ostreeMgr) {
            console.error("[ostree]", reason, "no manager")
            return
        }

        const updates = widgetRoot.ostreeMgr.availableUpdates || []

        for (let i = 0; i < updates.length; ++i) {
            const u = updates[i]
        }
    }

    onOpenProgressChanged: {
        if (openProgress === 0.0 && !isActive) visible = false;
        else if (isActive && !visible) visible = true;
    }

    anchor {
        edges: Edges.Bottom
        gravity: Edges.Bottom
        margins.top: Globals.popupMargin
    }

    implicitWidth: 360 + (2 * Globals.popupScreenPadding)
    implicitHeight: Math.min(600, contentLayout.implicitHeight + 32)
    color: "transparent"

    Item {
        width: parent.width - (2 * Globals.popupScreenPadding)
        height: parent.height
        anchors.horizontalCenter: parent.horizontalCenter
        scale: 0.9 + (0.1 * root.openProgress)
        opacity: root.openProgress
        transformOrigin: Item.Top

        Rectangle {
            anchors.fill: parent
            color: Globals.activeColors.Black
            radius: 24
            border.color: Globals.activeColors.Secondary25
            border.width: 1
            clip: true

            ColumnLayout {
                id: contentLayout
                anchors.fill: parent
                anchors.margins: 16
                spacing: 16

                // Header
                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: "System Updates"
                        color: Globals.activeColors.White
                        font.pixelSize: 18
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        id: refreshBtnBg
                        width: 32; height: 32; radius: 16
                        property bool isChecking: (widgetRoot && widgetRoot.ostreeMgr && widgetRoot.ostreeMgr.isChecking) || (widgetRoot && widgetRoot.flatpakMgr && widgetRoot.flatpakMgr.isChecking)
                        color: refreshMouse.containsMouse && !isChecking ? Globals.activeColors.Secondary25 : "transparent"
                        Icon {
                            anchors.centerIn: parent; width: 16; height: 16;
                            path: "M17.65 6.35C16.2 4.9 14.21 4 12 4c-4.42 0-7.99 3.58-7.99 8s3.57 8 7.99 8c3.73 0 6.84-2.55 7.73-6h-2.08c-.82 2.33-3.04 4-5.65 4-3.31 0-6-2.69-6-6s2.69-6 6-6c1.66 0 3.14.69 4.22 1.78L13 11h7V4l-2.35 2.35z"
                            color: refreshBtnBg.isChecking ? Globals.activeColors.Secondary : Globals.activeColors.White
                            RotationAnimation on rotation {
                                loops: Animation.Infinite
                                from: 0; to: 360; duration: 1000
                                running: refreshBtnBg.isChecking
                            }
                        }
                        MouseArea {
                            id: refreshMouse; anchors.fill: parent; hoverEnabled: !refreshBtnBg.isChecking
                            enabled: !refreshBtnBg.isChecking
                            onClicked: {
                                if (widgetRoot) {
                                    widgetRoot.checkUpdates();
                                }
                            }
                        }
                    }
                }

                // Update Lists
                ScrollView {
                    id: scrollView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredHeight: Math.min(400, detailsCol.implicitHeight)
                    clip: true
                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                    }

                    ColumnLayout {
                        id: detailsCol
                        width: scrollView.width - 16
                        spacing: 24

                        // 1. OS Tree Section (System updates at the top!)
                        ColumnLayout {
                            visible: widgetRoot && widgetRoot.ostreeMgr && (widgetRoot.ostreeMgr.updateCount > 0 || widgetRoot.ostreeMgr.isRebootRequired)
                            Layout.fillWidth: true
                            spacing: 12

                            RowLayout {
                                Layout.fillWidth: true
                                Icon {
                                    width: 16; height: 16
                                    path: "M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-1 15v-4H8l4-4 4 4h-3v4h-2z"
                                    color: (widgetRoot && widgetRoot.hasCritical) ? Globals.activeColors.Warning : Globals.activeColors.Secondary
                                }
                                Text {
                                    text: "OS System Packages"
                                    color: (widgetRoot && widgetRoot.hasCritical) ? Globals.activeColors.Warning : Globals.activeColors.Secondary
                                    font.pixelSize: 14
                                    font.bold: true
                                }
                            }

                            Repeater {
                                model: widgetRoot ? widgetRoot.ostreeMgr.availableUpdates : []
                                delegate: Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: ostreeItemCol.implicitHeight + 20
                                    color: Globals.activeColors.Secondary10
                                    radius: 12
                                    border.color: Globals.activeColors.Secondary10
                                    border.width: 1

                                    ColumnLayout {
                                        id: ostreeItemCol
                                        width: parent.width - 20
                                        anchors.centerIn: parent
                                        spacing: 4

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 8

                                            Text {
                                                text: modelData.name
                                                color: Globals.activeColors.White
                                                font.pixelSize: 14
                                                font.bold: true
                                                Layout.fillWidth: true
                                                elide: Text.ElideRight
                                            }

                                            // Security Advisory Badge
                                            Rectangle {
                                                visible: modelData.advisory !== undefined && modelData.advisory !== ""
                                                height: 18
                                                width: advisoryText.implicitWidth + 12
                                                radius: 9

                                                property int advisorySeverity: modelData.advisorySeverity !== undefined ? modelData.advisorySeverity : 0
                                                property bool isSecurity: modelData.advisoryType !== undefined && modelData.advisoryType.toLowerCase().includes("sec")

                                                color: !isSecurity ? Globals.activeColors.Secondary25
                                                    : advisorySeverity >= 4 ? Globals.activeColors.Error
                                                    : advisorySeverity >= 3 ? Globals.activeColors.Error
                                                    : advisorySeverity >= 2 ? Globals.activeColors.Main
                                                    : Globals.activeColors.Main

                                                Text {
                                                    id: advisoryText
                                                    anchors.centerIn: parent
                                                    text: modelData.advisory || ""
                                                    color: parent.isSecurity ? Globals.activeColors.Warning : Globals.activeColors.White
                                                    font.pixelSize: 10
                                                    font.bold: true
                                                }
                                            }
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 6
                                            visible: modelData.oldVersion !== undefined && modelData.oldVersion !== ""

                                            Text {
                                                text: modelData.oldVersion || ""
                                                color: Globals.activeColors.SecondaryLight
                                                font.pixelSize: 12
                                                Layout.fillWidth: true
                                                elide: Text.ElideRight
                                            }
                                            Text {
                                                text: "→"
                                                color: Globals.activeColors.Secondary
                                                font.pixelSize: 14
                                                font.bold: true
                                            }
                                            Text {
                                                text: modelData.newVersion || ""
                                                color: Globals.activeColors.Secondary
                                                font.pixelSize: 12
                                                Layout.fillWidth: true
                                                elide: Text.ElideRight
                                            }
                                        }

                                        Text {
                                            visible: (modelData.oldVersion === undefined || modelData.oldVersion === "") && (modelData.newVersion !== undefined && modelData.newVersion !== "")
                                            text: "New Version: " + (modelData.newVersion || "")
                                            color: Globals.activeColors.Secondary
                                            font.pixelSize: 12
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            visible: modelData.synopsis !== undefined && modelData.synopsis !== ""
                                            text: modelData.synopsis || ""
                                            color: Globals.activeColors.SecondaryLight
                                            font.pixelSize: 12
                                            wrapMode: Text.Wrap
                                            Layout.fillWidth: true
                                        }

                                        ColumnLayout {
                                            visible: modelData.name === "System OS Update"
                                                    && modelData.packages !== undefined
                                                    && modelData.packages.length > 0
                                            Layout.fillWidth: true
                                            spacing: 6

                                            Text {
                                                text: "Affected packages"
                                                color: Globals.activeColors.White
                                                font.pixelSize: 12
                                                font.bold: true
                                            }

                                            Repeater {
                                                model: modelData.packages || []
                                                delegate: Text {
                                                    required property var modelData
                                                    Layout.fillWidth: true
                                                    text: "• " + modelData
                                                    color: Globals.activeColors.SecondaryLight
                                                    font.pixelSize: 12
                                                    wrapMode: Text.Wrap
                                                }
                                            }
                                        }

                                        ColumnLayout {
                                            visible: modelData.name === "System OS Update"
                                                    && modelData.cves !== undefined
                                                    && modelData.cves.length > 0
                                            Layout.fillWidth: true
                                            spacing: 6

                                            Text {
                                                text: "Security advisories / CVEs"
                                                color: Globals.activeColors.White
                                                font.pixelSize: 12
                                                font.bold: true
                                            }

                                            Repeater {
                                                model: modelData.cves || []
                                                delegate: Rectangle {
                                                    required property var modelData

                                                    Layout.fillWidth: true
                                                    color: Globals.activeColors.Black
                                                    radius: 8
                                                    border.color: Globals.activeColors.Secondary10
                                                    border.width: 1
                                                    implicitHeight: cveCol.implicitHeight + 16

                                                    property bool _fetching: false
                                                    property bool _fetched: false
                                                    property int _cveSeverity: -1

                                                    function fetchSeverity() {
                                                        if (_fetched || _fetching) return;
                                                        let match = (modelData.title || "").match(/(CVE-\d{4}-\d+)/i);
                                                        if (!match) {
                                                            _fetched = true;
                                                            _cveSeverity = 0;
                                                            return;
                                                        }
                                                        let cveId = match[1].toUpperCase();

                                                        if (root.cveSeverityCache[cveId] !== undefined) {
                                                            _cveSeverity = root.cveSeverityCache[cveId];
                                                            _fetched = true;
                                                            return;
                                                        }

                                                        _fetching = true;
                                                        let req = new XMLHttpRequest();
                                                        req.open("GET", "https://access.redhat.com/hydra/rest/securitydata/cve/" + cveId + ".json");
                                                        req.onreadystatechange = function() {
                                                            if (req.readyState === XMLHttpRequest.DONE) {
                                                                _fetching = false;
                                                                _fetched = true;
                                                                if (req.status === 200) {
                                                                    try {
                                                                        let res = JSON.parse(req.responseText);
                                                                        let sevStr = res.threat_severity;
                                                                        if (sevStr === "Critical") _cveSeverity = 4;
                                                                        else if (sevStr === "Important") _cveSeverity = 3;
                                                                        else if (sevStr === "Moderate") _cveSeverity = 2;
                                                                        else if (sevStr === "Low") _cveSeverity = 1;
                                                                        else _cveSeverity = 0;
                                                                    } catch(e) { _cveSeverity = 0; }
                                                                } else {
                                                                    _cveSeverity = 0;
                                                                }

                                                                let cache = root.cveSeverityCache;
                                                                cache[cveId] = _cveSeverity;
                                                                root.cveSeverityCache = cache;
                                                            }
                                                        }
                                                        req.send();
                                                    }

                                                    Connections {
                                                        target: root
                                                        function onIsActiveChanged() {
                                                            if (root.isActive) fetchSeverity();
                                                        }
                                                    }

                                                    Component.onCompleted: {
                                                        if (root.isActive) fetchSeverity();
                                                    }

                                                    ColumnLayout {
                                                        id: cveCol
                                                        anchors.fill: parent
                                                        anchors.margins: 8
                                                        spacing: 6

                                                        RowLayout {
                                                            Layout.fillWidth: true
                                                            spacing: 8

                                                            Rectangle {
                                                                id: severityPill
                                                                Layout.alignment: Qt.AlignTop
                                                                Layout.preferredHeight: 20
                                                                Layout.preferredWidth: severityText.implicitWidth + 12
                                                                radius: 10
                                                                clip: true

                                                                property int sev: _cveSeverity
                                                                property bool isLoading: !_fetched && _fetching

                                                                color: isLoading ? Globals.activeColors.Secondary10
                                                                    : sev >= 4 ? Globals.activeColors.Error
                                                                    : sev >= 3 ? Globals.activeColors.Error
                                                                    : sev >= 2 ? Globals.activeColors.Main
                                                                    : sev >= 1 ? Globals.activeColors.Main
                                                                    : Globals.activeColors.Secondary25

                                                                Rectangle {
                                                                    anchors.fill: parent
                                                                    radius: parent.radius
                                                                    visible: severityPill.isLoading
                                                                    color: Globals.activeColors.Secondary25
                                                                    SequentialAnimation on opacity {
                                                                        running: severityPill.isLoading
                                                                        loops: Animation.Infinite
                                                                        NumberAnimation { from: 0.4; to: 0.8; duration: 800; easing.type: Easing.InOutSine }
                                                                        NumberAnimation { from: 0.8; to: 0.4; duration: 800; easing.type: Easing.InOutSine }
                                                                    }
                                                                }

                                                                Text {
                                                                    id: severityText
                                                                    anchors.centerIn: parent
                                                                    text: severityPill.isLoading ? "FETCHING"
                                                                        : severityPill.sev >= 4 ? "CRITICAL"
                                                                        : severityPill.sev >= 3 ? "HIGH"
                                                                        : severityPill.sev >= 2 ? "MEDIUM"
                                                                        : severityPill.sev >= 1 ? "LOW"
                                                                        : "UNKNOWN"
                                                                    color: severityPill.isLoading ? "transparent" : Globals.activeColors.Warning
                                                                    font.pixelSize: 10
                                                                    font.bold: true
                                                                }
                                                            }

                                                            Item {
                                                                Layout.fillWidth: true
                                                            }

                                                            Rectangle {
                                                                id: openLinkButton
                                                                visible: modelData.href !== undefined && modelData.href !== ""
                                                                Layout.alignment: Qt.AlignTop
                                                                width: 24
                                                                height: 24
                                                                radius: 12
                                                                color: openLinkMouse.containsMouse ? Globals.activeColors.Secondary : Globals.activeColors.Secondary10
                                                                border.color: Globals.activeColors.Secondary25
                                                                border.width: 1

                                                                Text {
                                                                    anchors.centerIn: parent
                                                                    text: "↗"
                                                                    color: openLinkMouse.containsMouse ? Globals.activeColors.Black : Globals.activeColors.White
                                                                    font.pixelSize: 12
                                                                    font.bold: true
                                                                }

                                                                MouseArea {
                                                                    id: openLinkMouse
                                                                    anchors.fill: parent
                                                                    hoverEnabled: true
                                                                    cursorShape: Qt.PointingHandCursor
                                                                    onClicked: {
                                                                        if (modelData.href)
                                                                            Qt.openUrlExternally(modelData.href)
                                                                    }
                                                                }
                                                            }
                                                        }

                                                        Text {
                                                            id: cveText
                                                            Layout.fillWidth: true
                                                            text: modelData.title || ""
                                                            color: Globals.activeColors.SecondaryLight
                                                            font.pixelSize: 11
                                                            wrapMode: Text.Wrap
                                                            maximumLineCount: 100
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Fallback if there are updates but list is empty (e.g. parsing failed)
                            Rectangle {
                                visible: widgetRoot && widgetRoot.ostreeUpdates > 0 && widgetRoot.ostreeMgr && widgetRoot.ostreeMgr.updateCount === 0
                                Layout.fillWidth: true
                                Layout.preferredHeight: fallbackOstreeCol.implicitHeight + 20
                                color: Globals.activeColors.Secondary10
                                radius: 12
                                border.color: Globals.activeColors.Secondary10
                                border.width: 1

                                ColumnLayout {
                                    id: fallbackOstreeCol
                                    width: parent.width - 20
                                    anchors.centerIn: parent
                                    spacing: 4
                                    Text {
                                        text: "System Update Available"
                                        color: Globals.activeColors.White
                                        font.pixelSize: 14
                                        font.bold: true
                                    }
                                    Text {
                                        text: "An OS update is staged and ready to be installed."
                                        color: Globals.activeColors.SecondaryLight
                                        font.pixelSize: 13
                                        wrapMode: Text.Wrap
                                        Layout.fillWidth: true
                                    }
                                }
                            }

                            // Dedicated Button for rpm-ostree updates
                            Rectangle {
                                id: ostreeBtn
                                Layout.fillWidth: true
                                height: 44
                                radius: 22

                                property bool isOstreeUpdating: widgetRoot && widgetRoot.ostreeMgr && widgetRoot.ostreeMgr.isUpdating
                                property bool isOstreeChecking: widgetRoot && widgetRoot.ostreeMgr && widgetRoot.ostreeMgr.isChecking
                                property bool isTransactionInProgress: widgetRoot && widgetRoot.ostreeMgr && widgetRoot.ostreeMgr.hasActiveTransaction && !isOstreeUpdating
                                property bool isRebootRequired: widgetRoot && widgetRoot.ostreeMgr && widgetRoot.ostreeMgr.isRebootRequired

                                color: isOstreeChecking ? Globals.activeColors.Secondary10
                                      : (isOstreeUpdating ? Globals.activeColors.Secondary10
                                      : (isTransactionInProgress ? Globals.activeColors.Error
                                      : (isRebootRequired ? (ostreeUpdateMouse.containsMouse ? Globals.activeColors.Main : Globals.activeColors.Secondary)
                                      : (ostreeUpdateMouse.containsMouse ? Globals.activeColors.Secondary : Globals.activeColors.Secondary25))))
                                border.color: isTransactionInProgress ? Globals.activeColors.Secondary : "transparent"
                                border.width: isTransactionInProgress ? 1 : 0

                                property real perimeter: 2 * (ostreeBtn.width - 44) + 2 * Math.PI * 22
                                Shape {
                                    id: ostreeBorderShape
                                    anchors.fill: parent
                                    visible: ostreeBtn.isOstreeUpdating || ostreeBtn.isOstreeChecking
                                    antialiasing: true
                                    preferredRendererType: Shape.CurveRenderer
                                    ShapePath {
                                        id: ostreeShapePath
                                        fillColor: "transparent"
                                        strokeColor: Globals.activeColors.Secondary
                                        strokeWidth: 2
                                        capStyle: ShapePath.RoundCap
                                        strokeStyle: ShapePath.DashLine
                                        dashPattern: [40, ostreeBtn.perimeter]
                                        startX: ostreeBtn.width / 2; startY: 0
                                        PathLine { x: ostreeBtn.width - 22; y: 0 }
                                        PathArc { x: ostreeBtn.width; y: 22; radiusX: 22; radiusY: 22; direction: PathArc.Clockwise }
                                        PathLine { x: ostreeBtn.width; y: ostreeBtn.height - 22 }
                                        PathArc { x: ostreeBtn.width - 22; y: ostreeBtn.height; radiusX: 22; radiusY: 22; direction: PathArc.Clockwise }
                                        PathLine { x: 22; y: ostreeBtn.height }
                                        PathArc { x: 0; y: ostreeBtn.height - 22; radiusX: 22; radiusY: 22; direction: PathArc.Clockwise }
                                        PathLine { x: 0; y: 22 }
                                        PathArc { x: 22; y: 0; radiusX: 22; radiusY: 22; direction: PathArc.Clockwise }
                                        PathLine { x: ostreeBtn.width / 2; y: 0 }
                                    }
                                    NumberAnimation {
                                        target: ostreeShapePath
                                        property: "dashOffset"
                                        from: ostreeBtn.perimeter + 40; to: 0
                                        duration: 1500
                                        loops: Animation.Infinite
                                        running: ostreeBorderShape.visible
                                        easing.type: Easing.InOutSine
                                    }
                                }

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 8

                                    Icon {
                                        visible: ostreeBtn.isRebootRequired
                                        width: 18; height: 18
                                        path: "M17.65 6.35C16.2 4.9 14.21 4 12 4c-4.42 0-7.99 3.58-7.99 8s3.57 8 7.99 8c3.73 0 6.84-2.55 7.73-6h-2.08c-.82 2.33-3.04 4-5.65 4-3.31 0-6-2.69-6-6s2.69-6 6-6c1.66 0 3.14.69 4.22 1.78L13 11h7V4l-2.35 2.35z"
                                        color: Globals.activeColors.Black
                                    }

                                    Text {
                                        text: {
                                            if (ostreeBtn.isOstreeChecking) return "Checking for updates...";
                                            if (ostreeBtn.isOstreeUpdating) return widgetRoot.ostreeMgr.status || "Installing...";
                                            if (ostreeBtn.isRebootRequired) return "Reboot to finish updating";
                                            if (ostreeBtn.isTransactionInProgress) return "Other operation running. Cancel ?";
                                            return "Install System OS Update";
                                        }
                                        color: (ostreeBtn.isOstreeUpdating || ostreeBtn.isOstreeChecking) ? Globals.activeColors.White : (ostreeBtn.isRebootRequired ? Globals.activeColors.Black : (ostreeBtn.isTransactionInProgress ? Globals.activeColors.Black : (ostreeUpdateMouse.containsMouse ? Globals.activeColors.Black : Globals.activeColors.White)))
                                        font.pixelSize: 13
                                        font.bold: true
                                        elide: Text.ElideRight
                                        Layout.maximumWidth: ostreeBtn.width - 40
                                    }
                                }

                                MouseArea {
                                    id: ostreeUpdateMouse
                                    anchors.fill: parent
                                    hoverEnabled: !ostreeBtn.isOstreeUpdating && !ostreeBtn.isOstreeChecking
                                    enabled: !ostreeBtn.isOstreeChecking && (ostreeBtn.isTransactionInProgress || !ostreeBtn.isOstreeUpdating)
                                    onClicked: {
                                        if (widgetRoot && widgetRoot.ostreeMgr) {
                                            if (ostreeBtn.isTransactionInProgress) {
                                                widgetRoot.ostreeMgr.cancelTransaction();
                                            } else if (ostreeBtn.isRebootRequired) {
                                                console.log("Triggering reboot...");
                                                if (widgetRoot.rebootSystem) widgetRoot.rebootSystem();
                                            } else {
                                                widgetRoot.ostreeMgr.startUpdate();
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // 2. Flatpak Section (Flatpak updates under OS updates!)
                        ColumnLayout {
                            visible: widgetRoot && widgetRoot.flatpakMgr && widgetRoot.flatpakMgr.updateCount > 0
                            Layout.fillWidth: true
                            spacing: 12

                            RowLayout {
                                Layout.fillWidth: true
                                Icon {
                                    width: 16; height: 16
                                    path: "M21 16.5c0 .38-.21.71-.53.88l-7.9 4.44c-.16.12-.36.18-.57.18-.21 0-.41-.06-.57-.18l-7.9-4.44A.991.991 0 0 1 3 16.5v-9c0-.38.21-.71.53-.88l7.9-4.44c.16-.12.36-.18.57-.18.21 0 .41.06.57.18l7.9 4.44c.32.17.53.5.53.88v9zM12 4.15L6.04 7.5 12 10.85l5.96-3.35L12 4.15zM5 15.91l6 3.38v-6.71L5 9.21v6.7zm14 0v-6.7l-6 3.38v6.71l6-3.38z"
                                    color: Globals.activeColors.Secondary
                                }
                                Text {
                                    text: "Flatpak Applications"
                                    color: Globals.activeColors.Secondary
                                    font.pixelSize: 14
                                    font.bold: true
                                    Layout.fillWidth: true
                                }

                                // Update All Flatpaks button
                                Rectangle {
                                    id: flatpakAllBtn
                                    property int totalCount: widgetRoot && widgetRoot.flatpakMgr ? widgetRoot.flatpakMgr.updateCount : 0
                                    property int completedCount: widgetRoot ? widgetRoot.completedFlatpakCount : 0
                                    property bool isAllCompleted: totalCount > 0 && completedCount === totalCount
                                    property bool isCurrentlyUpdating: widgetRoot && widgetRoot.flatpakMgr && widgetRoot.flatpakMgr.isUpdating && root.updatingAllFlatpaks

                                    visible: totalCount > 1
                                    Layout.preferredWidth: isCurrentlyUpdating ? 100 : 84
                                    Layout.preferredHeight: 26
                                    Layout.alignment: Qt.AlignRight
                                    width: Layout.preferredWidth
                                    height: Layout.preferredHeight
                                    radius: 13
                                    enabled: !isCurrentlyUpdating && !isAllCompleted
                                    color: isAllCompleted ? Globals.activeColors.Secondary10 : (isCurrentlyUpdating ? Globals.activeColors.Secondary10 : (flatpakAllMouse.containsMouse ? Globals.activeColors.Secondary : "transparent"))
                                    border.color: isAllCompleted ? Globals.activeColors.Secondary : "transparent"
                                    border.width: isAllCompleted ? 1 : 0

                                    Behavior on Layout.preferredWidth { NumberAnimation { duration: 250 } }
                                    Behavior on color { ColorAnimation { duration: 250 } }
                                    Behavior on border.color { ColorAnimation { duration: 250 } }

                                    // Progress Fill for global progress
                                    property real perimeter: 2 * (width - 26) + 2 * Math.PI * 13
                                    Shape {
                                        id: flatpakAllBorderShape
                                        anchors.fill: parent
                                        visible: flatpakAllBtn.isCurrentlyUpdating
                                        antialiasing: true
                                        preferredRendererType: Shape.CurveRenderer
                                        ShapePath {
                                            id: flatpakAllShapePath
                                            fillColor: "transparent"
                                            strokeColor: Globals.activeColors.Secondary
                                            strokeWidth: 2
                                            capStyle: ShapePath.RoundCap
                                            strokeStyle: ShapePath.DashLine
                                            dashPattern: [flatpakAllBtn.perimeter * Math.max(0.001, (flatpakAllBtn.totalCount > 0 ? (flatpakAllBtn.completedCount / flatpakAllBtn.totalCount) : 0)), flatpakAllBtn.perimeter]
                                            startX: flatpakAllBtn.width / 2; startY: 0
                                            PathLine { x: flatpakAllBtn.width - 13; y: 0 }
                                            PathArc { x: flatpakAllBtn.width; y: 13; radiusX: 13; radiusY: 13; direction: PathArc.Clockwise }
                                            PathLine { x: flatpakAllBtn.width; y: flatpakAllBtn.height - 13 }
                                            PathArc { x: flatpakAllBtn.width - 13; y: flatpakAllBtn.height; radiusX: 13; radiusY: 13; direction: PathArc.Clockwise }
                                            PathLine { x: 13; y: flatpakAllBtn.height }
                                            PathArc { x: 0; y: flatpakAllBtn.height - 13; radiusX: 13; radiusY: 13; direction: PathArc.Clockwise }
                                            PathLine { x: 0; y: 13 }
                                            PathArc { x: 13; y: 0; radiusX: 13; radiusY: 13; direction: PathArc.Clockwise }
                                            PathLine { x: flatpakAllBtn.width / 2; y: 0 }
                                        }
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        visible: !flatpakAllBtn.isAllCompleted && !flatpakAllBtn.isCurrentlyUpdating
                                        text: "Update All"
                                        color: flatpakAllMouse.containsMouse ? Globals.activeColors.Black : Globals.activeColors.Secondary
                                        font.pixelSize: 11
                                        font.bold: true
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        visible: flatpakAllBtn.isCurrentlyUpdating
                                        text: flatpakAllBtn.completedCount + " / " + flatpakAllBtn.totalCount
                                        color: Globals.activeColors.White
                                        font.pixelSize: 11
                                        font.bold: true
                                    }

                                    Icon {
                                        anchors.centerIn: parent
                                        visible: flatpakAllBtn.isAllCompleted
                                        width: 14; height: 14
                                        path: "M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z"
                                        color: Globals.activeColors.Secondary
                                    }

                                    MouseArea {
                                        id: flatpakAllMouse
                                        anchors.fill: parent
                                        hoverEnabled: parent.enabled
                                        onClicked: {
                                            if (widgetRoot) {
                                                root.updatingAllFlatpaks = true;
                                                widgetRoot.flatpakMgr.startUpdate();
                                            }
                                        }
                                    }
                                }
                            }

                            Repeater {
                                model: widgetRoot ? widgetRoot.flatpakMgr.availableUpdates : []
                                delegate: Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: Math.max(64, flatpakItemRow.implicitHeight + 20)
                                    color: Globals.activeColors.Secondary10
                                    radius: 12
                                    border.color: Globals.activeColors.Secondary10
                                    border.width: 1

                                    RowLayout {
                                        id: flatpakItemRow
                                        width: parent.width - 24
                                        anchors.centerIn: parent
                                        spacing: 12

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 4
                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: 6
                                                Icon {
                                                    width: 14; height: 14
                                                    path: modelData.isSystem ? "M20 18c1.1 0 1.99-.9 1.99-2L22 6c0-1.1-.9-2-2-2H4c-1.1 0-2 .9-2 2v10c0 1.1.9 2 2 2H0v2h24v-2h-4zM4 6h16v10H4V6z" : "M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z"
                                                    color: Globals.activeColors.SecondaryLight
                                                }
                                                Text {
                                                    text: modelData.name || ""
                                                    color: Globals.activeColors.White
                                                    font.pixelSize: 14
                                                    font.bold: true
                                                    Layout.fillWidth: true
                                                    elide: Text.ElideRight
                                                }
                                                Text {
                                                    text: modelData.size || ""
                                                    color: Globals.activeColors.SecondaryLight
                                                    font.pixelSize: 12
                                                }
                                            }
                                            Text {
                                                text: modelData.version ? ("Version " + modelData.version) : "Minor update"
                                                color: Globals.activeColors.SecondaryLight
                                                font.pixelSize: 13
                                                Layout.fillWidth: true
                                                elide: Text.ElideRight
                                            }
                                            Text {
                                                visible: individualBtn.errorMsg !== ""
                                                text: individualBtn.errorMsg
                                                color: individualBtn.isFatal ? Globals.activeColors.Warning : Globals.activeColors.Main
                                                font.pixelSize: 12
                                                Layout.fillWidth: true
                                                wrapMode: Text.Wrap
                                            }
                                        }

                                        // Update button for this specific Flatpak
                                        Rectangle {
                                            id: individualBtn
                                            property var statusObj: widgetRoot.completedUpdates[modelData.ref] || null
                                            property bool isCompleted: statusObj !== null && statusObj.success === true
                                            property bool isWarning: statusObj !== null && statusObj.success === false && statusObj.fatal === false
                                            property bool isFatal: statusObj !== null && statusObj.success === false && statusObj.fatal === true
                                            property string errorMsg: (statusObj !== null && statusObj.message) ? statusObj.message : ""
                                            property bool isUpdating: widgetRoot && widgetRoot.flatpakMgr && widgetRoot.flatpakMgr.isUpdating && widgetRoot.flatpakMgr.currentUpdatingRef === modelData.ref

                                            width: 70
                                            height: 32
                                            radius: 16
                                            color: (isCompleted || isWarning) ? Globals.activeColors.Secondary25 : (isUpdating ? Globals.activeColors.Secondary10 : (individualUpdateMouse.containsMouse ? Globals.activeColors.Secondary : Globals.activeColors.Secondary10))
                                            border.color: isUpdating ? "transparent" : (isFatal ? (individualUpdateMouse.containsMouse ? Globals.activeColors.Secondary : Globals.activeColors.Warning) : (isWarning ? Globals.activeColors.Main : (isCompleted ? Globals.activeColors.Secondary : Globals.activeColors.Secondary25)))
                                            border.width: isUpdating ? 0 : 1

                                            Behavior on color { ColorAnimation { duration: 250 } }
                                            Behavior on border.color { ColorAnimation { duration: 250 } }

                                            // Progress fill
                                            property real perimeter: 2 * (width - 32) + 2 * Math.PI * 16
                                            Shape {
                                                id: flatpakIndivBorderShape
                                                anchors.fill: parent
                                                visible: individualBtn.isUpdating
                                                antialiasing: true
                                                preferredRendererType: Shape.CurveRenderer
                                                ShapePath {
                                                    id: flatpakIndivShapePath
                                                    fillColor: "transparent"
                                                    strokeColor: Globals.activeColors.Secondary
                                                    strokeWidth: 2
                                                    capStyle: ShapePath.RoundCap
                                                    strokeStyle: ShapePath.DashLine
                                                    dashPattern: [individualBtn.perimeter * Math.max(0.001, (widgetRoot && widgetRoot.flatpakMgr && individualBtn.isUpdating) ? widgetRoot.flatpakMgr.updateProgress / 100.0 : 0.001), individualBtn.perimeter]
                                                    startX: individualBtn.width / 2; startY: 0
                                                    PathLine { x: individualBtn.width - 16; y: 0 }
                                                    PathArc { x: individualBtn.width; y: 16; radiusX: 16; radiusY: 16; direction: PathArc.Clockwise }
                                                    PathLine { x: individualBtn.width; y: individualBtn.height - 16 }
                                                    PathArc { x: individualBtn.width - 16; y: individualBtn.height; radiusX: 16; radiusY: 16; direction: PathArc.Clockwise }
                                                    PathLine { x: 16; y: individualBtn.height }
                                                    PathArc { x: 0; y: individualBtn.height - 16; radiusX: 16; radiusY: 16; direction: PathArc.Clockwise }
                                                    PathLine { x: 0; y: 16 }
                                                    PathArc { x: 16; y: 0; radiusX: 16; radiusY: 16; direction: PathArc.Clockwise }
                                                    PathLine { x: individualBtn.width / 2; y: 0 }
                                                }
                                            }

                                            Text {
                                                anchors.centerIn: parent
                                                opacity: (individualBtn.isUpdating) ? 0.0 : ((!individualBtn.isCompleted && !individualBtn.isWarning && !individualBtn.isFatal) || (individualUpdateMouse.containsMouse && individualBtn.isFatal)) ? 1.0 : 0.0
                                                Behavior on opacity { NumberAnimation { duration: 250 } }
                                                text: individualBtn.isFatal ? "Retry" : "Update"
                                                color: individualUpdateMouse.containsMouse ? Globals.activeColors.Black : Globals.activeColors.White
                                                font.pixelSize: 12
                                                font.bold: true
                                            }

                                            Text {
                                                anchors.centerIn: parent
                                                opacity: individualBtn.isUpdating ? 1.0 : 0.0
                                                Behavior on opacity { NumberAnimation { duration: 250 } }
                                                text: (widgetRoot && widgetRoot.flatpakMgr ? widgetRoot.flatpakMgr.updateProgress : 0) + "%"
                                                color: Globals.activeColors.White
                                                font.pixelSize: 12
                                                font.bold: true
                                            }

                                            Icon {
                                                anchors.centerIn: parent
                                                opacity: (individualBtn.isCompleted || individualBtn.isWarning || (individualBtn.isFatal && !individualUpdateMouse.containsMouse)) ? 1.0 : 0.0
                                                Behavior on opacity { NumberAnimation { duration: 250 } }
                                                width: 16; height: 16
                                                path: individualBtn.isFatal ? "M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12z" : (individualBtn.isWarning ? "M11 15h2v2h-2v-2zm0-8h2v6h-2V7zm.99-5C6.47 2 2 6.48 2 12s4.47 10 9.99 10C17.52 22 22 17.52 22 12S17.52 2 11.99 2zM12 20c-4.42 0-8-3.58-8-8s3.58-8 8-8 8 3.58 8 8-3.58 8-8 8z" : "M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z")
                                                color: individualBtn.isFatal ? Globals.activeColors.Warning : (individualBtn.isWarning ? Globals.activeColors.Main : Globals.activeColors.Secondary)
                                            }

                                            MouseArea {
                                                id: individualUpdateMouse
                                                anchors.fill: parent
                                                hoverEnabled: !individualBtn.isCompleted && !individualBtn.isWarning && !individualBtn.isUpdating
                                                enabled: !individualBtn.isCompleted && !individualBtn.isWarning && !individualBtn.isUpdating
                                                onClicked: {
                                                    if (widgetRoot && modelData.ref) {
                                                        widgetRoot.flatpakMgr.updatePackage(modelData.ref, modelData.isSystem ? true : false);
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Text {
                            visible: widgetRoot && widgetRoot.totalUpdates === 0
                            text: (widgetRoot.flatpakMgr && widgetRoot.flatpakMgr.isChecking) || (widgetRoot.ostreeMgr && widgetRoot.ostreeMgr.isChecking) ? "Checking for updates..." : "System is up to date."
                            color: Globals.activeColors.SecondaryLight
                            font.pixelSize: 14
                            Layout.alignment: Qt.AlignCenter
                        }
                    }
                }

                // Error Display (bottom)
                ColumnLayout {
                    property bool hasFlatpakError: widgetRoot && widgetRoot.flatpakMgr && widgetRoot.flatpakMgr.lastError !== ""
                    property bool hasOstreeError: widgetRoot && widgetRoot.ostreeMgr && widgetRoot.ostreeMgr.lastError !== "" && !(
                        widgetRoot.ostreeMgr.lastError.toLowerCase().indexOf("transaction in progress") !== -1 ||
                        widgetRoot.ostreeMgr.lastError.toLowerCase().indexOf("transation in progress") !== -1
                    )
                    visible: hasFlatpakError || hasOstreeError
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: parent.hasFlatpakError ? "Flatpak Error: " + widgetRoot.flatpakMgr.lastError : ""
                        color: Globals.activeColors.Warning
                        font.pixelSize: 12
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                        visible: text !== ""
                    }

                    Text {
                        text: parent.hasOstreeError ? "System Update Error: " + widgetRoot.ostreeMgr.lastError : ""
                        color: Globals.activeColors.Warning
                        font.pixelSize: 12
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                        visible: text !== ""
                    }
                }
            }
        }
    }
}
