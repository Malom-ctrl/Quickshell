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

    grabFocus: true


    Connections {
        target: Globals
        function onClosePopups() {
            if (root.isActive) { root.isActive = false; root.visible = false; }
        }
    }
    onIsActiveChanged: {
        if (isActive) visible = true;
    }

    onVisibleChanged: {
        if (!visible && isActive) {
            isActive = false;
        }
    }

    property real openProgress: isActive ? 1.0 : 0.0
    Behavior on openProgress {
        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
    }

    onOpenProgressChanged: {
        if (openProgress === 0.0 && !isActive) visible = false;
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

    anchor {
        edges: Edges.Bottom
        gravity: Edges.Bottom
        margins.top: Globals.popupMargin
    }

    property string themeScope: "topbar.UpdaterPopup"
    implicitWidth: Globals.customValue(themeScope, "width", 360) + (2 * Globals.popupScreenPadding)
    implicitHeight: Globals.customValue(themeScope, "height", Math.min(600, contentLayout.implicitHeight + 32))
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
            color: Globals.customValue(themeScope, "color", Globals.themeVars.Black)
            radius: Globals.customValue(themeScope, "radius", Globals.themeVars.borderRadiusHuge)
            border.color: Globals.customValue(themeScope, "borderColor", Globals.themeVars.Secondary10)
            border.width: Globals.customValue(themeScope, "borderWidth", Globals.themeVars.borderWidthSmall)
            clip: true

            ColumnLayout {
                id: contentLayout
                anchors.fill: parent
                anchors.margins: Globals.customValue(themeScope + ".layout", "margins", Globals.themeVars.spacingHuge)
                spacing: Globals.customValue(themeScope + ".layout", "spacing", Globals.themeVars.spacingHuge)

                // Header
                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: "System Updates"
                        color: Globals.customValue(themeScope + ".header", "color", Globals.themeVars.White)
                        font.pixelSize: Globals.customValue(themeScope + ".header", "fontSize", Globals.themeVars.fontSizeLarge)
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        id: refreshBtnBg
                        width: Globals.customValue(themeScope + ".refreshBtn", "width", 32); height: Globals.customValue(themeScope + ".refreshBtn", "height", 32); radius: Globals.customValue(themeScope + ".refreshBtn", "radius", Globals.themeVars.borderRadiusLarge)
                        property bool isChecking: (widgetRoot && widgetRoot.ostreeMgr && widgetRoot.ostreeMgr.isChecking) || (widgetRoot && widgetRoot.flatpakMgr && widgetRoot.flatpakMgr.isChecking)
                        color: refreshMouse.containsMouse && !isChecking ? Globals.customValue(themeScope + ".refreshBtn", "hoverColor", Globals.themeVars.Secondary25) : Globals.customValue(themeScope + ".refreshBtn", "color", "transparent")
                        Icon {
                            anchors.centerIn: parent; width: Globals.customValue(themeScope + ".refreshBtn.icon", "width", 16); height: Globals.customValue(themeScope + ".refreshBtn.icon", "height", 16);
                            path: "M17.65 6.35C16.2 4.9 14.21 4 12 4c-4.42 0-7.99 3.58-7.99 8s3.57 8 7.99 8c3.73 0 6.84-2.55 7.73-6h-2.08c-.82 2.33-3.04 4-5.65 4-3.31 0-6-2.69-6-6s2.69-6 6-6c1.66 0 3.14.69 4.22 1.78L13 11h7V4l-2.35 2.35z"
                            color: refreshBtnBg.isChecking ? Globals.customValue(themeScope + ".refreshBtn.icon", "checkingColor", Globals.themeVars.Secondary) : Globals.customValue(themeScope + ".refreshBtn.icon", "color", Globals.themeVars.White)
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
                        spacing: Globals.customValue(themeScope + ".layout", "spacing", Globals.themeVars.spacingHuge * 1.5)

                        // OS Tree Section
                        ColumnLayout {
                            visible: widgetRoot && widgetRoot.ostreeMgr && (widgetRoot.ostreeMgr.updateCount > 0 || widgetRoot.ostreeMgr.isRebootRequired)
                            Layout.fillWidth: true
                            spacing: Globals.customValue(themeScope + ".ostree", "spacing", Globals.themeVars.spacingLarge)

                            RowLayout {
                                Layout.fillWidth: true
                                Icon {
                                    width: 16; height: 16
                                    path: "M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-1 15v-4H8l4-4 4 4h-3v4h-2z"
                                    color: (widgetRoot && widgetRoot.hasCritical) ? Globals.customValue(themeScope + ".ostreeTitle", "warningColor", Globals.themeVars.Warning) : Globals.customValue(themeScope + ".ostreeTitle", "color", Globals.themeVars.Secondary)
                                }
                                Text {
                                    text: "OS System Packages"
                                    color: (widgetRoot && widgetRoot.hasCritical) ? Globals.customValue(themeScope + ".ostreeTitleText", "warningColor", Globals.themeVars.Warning) : Globals.customValue(themeScope + ".ostreeTitleText", "color", Globals.themeVars.Secondary)
                                    font.pixelSize: Globals.customValue(themeScope + ".ostreeTitleText", "fontSize", Globals.themeVars.fontSizeMedium)
                                    font.bold: true
                                }
                            }

                            Repeater {
                                model: widgetRoot ? widgetRoot.ostreeMgr.availableUpdates : []
                                delegate: Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: ostreeItemCol.implicitHeight + 20
                                    color: Globals.customValue(themeScope + ".ostreeItem", "color", Globals.themeVars.Secondary10)
                                    radius: Globals.customValue(themeScope + ".ostreeItem", "radius", Globals.themeVars.borderRadiusMedium)
                                    border.color: Globals.customValue(themeScope + ".ostreeItem", "borderColor", Globals.themeVars.Secondary10)
                                    border.width: Globals.customValue(themeScope + ".ostreeItem", "borderWidth", Globals.themeVars.borderWidthSmall)

                                    ColumnLayout {
                                        id: ostreeItemCol
                                        width: parent.width - 20
                                        anchors.centerIn: parent
                                        spacing: Globals.customValue(themeScope + ".ostreeLayout", "spacing", Globals.themeVars.spacingSmall)

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: Globals.customValue(themeScope + ".ostreeInnerLayout", "spacing", Globals.themeVars.spacingMedium)

                                            Text {
                                                text: modelData.name
                                                color: Globals.customValue(themeScope + ".ostreeItem.name", "color", Globals.themeVars.White)
                                                font.pixelSize: Globals.customValue(themeScope + ".ostreeItem.name", "fontSize", Globals.themeVars.fontSizeMedium)
                                                font.bold: true
                                                Layout.fillWidth: true
                                                elide: Text.ElideRight
                                            }

                                            // Security Advisory Badge
                                            Rectangle {
                                                visible: modelData.advisory !== undefined && modelData.advisory !== ""
                                                height: 18
                                                width: advisoryText.implicitWidth + 12
                                                radius: Globals.customValue(themeScope + ".ostreeIcon", "radius", Globals.themeVars.borderRadiusSmall)

                                                property int advisorySeverity: modelData.advisorySeverity !== undefined ? modelData.advisorySeverity : 0
                                                property bool isSecurity: modelData.advisoryType !== undefined && modelData.advisoryType.toLowerCase().includes("sec")

                                                color: !isSecurity ? Globals.customValue(themeScope + ".advisory", "color", Globals.themeVars.Secondary25)
                                                    : advisorySeverity >= 4 ? Globals.customValue(themeScope + ".advisory", "criticalColor", Globals.themeVars.Error)
                                                    : advisorySeverity >= 3 ? Globals.customValue(themeScope + ".advisory", "highColor", Globals.themeVars.Error)
                                                    : advisorySeverity >= 2 ? Globals.customValue(themeScope + ".advisory", "mediumColor", Globals.themeVars.Main)
                                                    : Globals.customValue(themeScope + ".advisory", "lowColor", Globals.themeVars.Main)

                                                Text {
                                                    id: advisoryText
                                                    anchors.centerIn: parent
                                                    text: modelData.advisory || ""
                                                    color: parent.isSecurity ? Globals.customValue(themeScope + ".advisoryText", "securityColor", Globals.themeVars.Warning) : Globals.customValue(themeScope + ".advisoryText", "color", Globals.themeVars.White)
                                                    font.pixelSize: Globals.customValue(themeScope + ".advisoryText", "fontSize", Globals.themeVars.fontSizeSmall)
                                                    font.bold: true
                                                }
                                            }
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: Globals.customValue(themeScope + ".ostreeItemText", "spacing", Globals.themeVars.spacingMedium)
                                            visible: modelData.oldVersion !== undefined && modelData.oldVersion !== ""

                                            Text {
                                                text: modelData.oldVersion || ""
                                                color: Globals.customValue(themeScope + ".ostreeItem.version", "oldColor", Globals.themeVars.SecondaryLight)
                                                font.pixelSize: Globals.customValue(themeScope + ".ostreeItem.version", "fontSize", Globals.themeVars.fontSizeSmall)
                                                Layout.fillWidth: true
                                                elide: Text.ElideRight
                                            }
                                            Text {
                                                text: "→"
                                                color: Globals.customValue(themeScope + ".ostreeItem.version", "arrowColor", Globals.themeVars.Secondary)
                                                font.pixelSize: Globals.customValue(themeScope + ".ostreeItem.version", "arrowFontSize", Globals.themeVars.fontSizeMedium)
                                                font.bold: true
                                            }
                                            Text {
                                                text: modelData.newVersion || ""
                                                color: Globals.customValue(themeScope + ".ostreeItem.version", "newColor", Globals.themeVars.Secondary)
                                                font.pixelSize: Globals.customValue(themeScope + ".ostreeItem.version", "fontSize", Globals.themeVars.fontSizeSmall)
                                                Layout.fillWidth: true
                                                elide: Text.ElideRight
                                            }
                                        }

                                        Text {
                                            visible: (modelData.oldVersion === undefined || modelData.oldVersion === "") && (modelData.newVersion !== undefined && modelData.newVersion !== "")
                                            text: "New Version: " + (modelData.newVersion || "")
                                            color: Globals.customValue(themeScope + ".ostreeVersion", "color", Globals.themeVars.Secondary)
                                            font.pixelSize: Globals.customValue(themeScope + ".ostreeVersion", "fontSize", Globals.themeVars.fontSizeSmall)
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            visible: modelData.synopsis !== undefined && modelData.synopsis !== ""
                                            text: modelData.synopsis || ""
                                            color: Globals.customValue(themeScope + ".ostreeDate", "color", Globals.themeVars.SecondaryLight)
                                            font.pixelSize: Globals.customValue(themeScope + ".ostreeDate", "fontSize", Globals.themeVars.fontSizeSmall)
                                            wrapMode: Text.Wrap
                                            Layout.fillWidth: true
                                        }

                                        ColumnLayout {
                                            visible: modelData.name === "System OS Update"
                                                    && modelData.packages !== undefined
                                                    && modelData.packages.length > 0
                                            Layout.fillWidth: true
                                            spacing: Globals.customValue(themeScope + ".ostreePkgRow", "spacing", Globals.themeVars.spacingMedium)

                                            Text {
                                                text: "Affected packages"
                                                color: Globals.customValue(themeScope + ".ostreePkgTitle", "color", Globals.themeVars.White)
                                                font.pixelSize: Globals.customValue(themeScope + ".ostreePkgTitle", "fontSize", Globals.themeVars.fontSizeSmall)
                                                font.bold: true
                                            }

                                            Repeater {
                                                model: modelData.packages || []
                                                delegate: Text {
                                                    required property var modelData
                                                    Layout.fillWidth: true
                                                    text: "• " + modelData
                                                    color: Globals.customValue(themeScope + ".ostreePkgSubtitle", "color", Globals.themeVars.SecondaryLight)
                                                    font.pixelSize: Globals.customValue(themeScope + ".ostreePkgSubtitle", "fontSize", Globals.themeVars.fontSizeSmall)
                                                    wrapMode: Text.Wrap
                                                }
                                            }
                                        }

                                        ColumnLayout {
                                            visible: modelData.name === "System OS Update"
                                                    && modelData.cves !== undefined
                                                    && modelData.cves.length > 0
                                            Layout.fillWidth: true
                                            spacing: Globals.customValue(themeScope + ".ostreeAdvisoryRow", "spacing", Globals.themeVars.spacingMedium)

                                            Text {
                                                text: "Security advisories / CVEs"
                                                color: Globals.customValue(themeScope + ".ostreeAdvisoryTitle", "color", Globals.themeVars.White)
                                                font.pixelSize: Globals.customValue(themeScope + ".ostreeAdvisoryTitle", "fontSize", Globals.themeVars.fontSizeSmall)
                                                font.bold: true
                                            }

                                            Repeater {
                                                model: modelData.cves || []
                                                delegate: Rectangle {
                                                    required property var modelData

                                                    Layout.fillWidth: true
                                                    color: Globals.customValue(themeScope + ".ostreeAdvisoryBox", "color", Globals.themeVars.Black)
                                                    radius: Globals.customValue(themeScope + ".ostreeAdvisoryBox", "radius", Globals.themeVars.borderRadiusSmall)
                                                    border.color: Globals.customValue(themeScope + ".ostreeAdvisoryBox", "borderColor", Globals.themeVars.Secondary10)
                                                    border.width: Globals.customValue(themeScope + ".ostreeAdvisoryBox", "borderWidth", Globals.themeVars.borderWidthSmall)
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
                                                        anchors.margins: Globals.customValue(themeScope + ".cve", "margins", Globals.themeVars.spacingMedium)
                                                        spacing: Globals.customValue(themeScope + ".cve", "spacing", Globals.themeVars.spacingMedium)

                                                        RowLayout {
                                                            Layout.fillWidth: true
                                                            spacing: Globals.customValue(themeScope + ".cveRow", "spacing", Globals.themeVars.spacingMedium)

                                                            Rectangle {
                                                                id: severityPill
                                                                Layout.alignment: Qt.AlignTop
                                                                Layout.preferredHeight: 20
                                                                Layout.preferredWidth: severityText.implicitWidth + 12
                                                                radius: Globals.customValue(themeScope + ".cvePill", "radius", Globals.themeVars.borderRadiusSmall)
                                                                clip: true

                                                                property int sev: _cveSeverity
                                                                property bool isLoading: !_fetched && _fetching

                                                                color: isLoading ? Globals.customValue(themeScope + ".cvePill", "loadingColor", Globals.themeVars.Secondary10)
                                                                    : sev >= 4 ? Globals.customValue(themeScope + ".cvePill", "criticalColor", Globals.themeVars.Error)
                                                                    : sev >= 3 ? Globals.customValue(themeScope + ".cvePill", "highColor", Globals.themeVars.Error)
                                                                    : sev >= 2 ? Globals.customValue(themeScope + ".cvePill", "mediumColor", Globals.themeVars.Main)
                                                                    : sev >= 1 ? Globals.customValue(themeScope + ".cvePill", "lowColor", Globals.themeVars.Main)
                                                                    : Globals.customValue(themeScope + ".cvePill", "unknownColor", Globals.themeVars.Secondary25)

                                                                Rectangle {
                                                                    anchors.fill: parent
                                                                    radius: parent.radius
                                                                    visible: severityPill.isLoading
                                                                    color: Globals.customValue(themeScope + ".cvePill", "color", Globals.themeVars.Secondary25)
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
                                                                    color: severityPill.isLoading ? "transparent" : Globals.customValue(themeScope + ".cvePillText", "color", Globals.themeVars.Warning)
                                                                    font.pixelSize: Globals.customValue(themeScope + ".cvePillText", "fontSize", Globals.themeVars.fontSizeSmall)
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
                                                                radius: Globals.customValue(themeScope + ".cveLink", "radius", Globals.themeVars.borderRadiusMedium)
                                                                color: openLinkMouse.containsMouse ? Globals.customValue(themeScope + ".cveLink", "hoverColor", Globals.themeVars.Secondary) : Globals.customValue(themeScope + ".cveLink", "hoverColor", Globals.themeVars.Secondary10)
                                                                border.color: Globals.customValue(themeScope + ".cveLink", "borderColor", Globals.themeVars.Secondary25)
                                                                border.width: Globals.customValue(themeScope + ".cveLink", "borderWidth", Globals.themeVars.borderWidthSmall)

                                                                Text {
                                                                    anchors.centerIn: parent
                                                                    text: "↗"
                                                                    color: openLinkMouse.containsMouse ? Globals.customValue(themeScope + ".cveLinkText", "hoverColor", Globals.themeVars.Black) : Globals.customValue(themeScope + ".cveLinkText", "color", Globals.themeVars.White)
                                                                    font.pixelSize: Globals.customValue(themeScope + ".cveLinkText", "fontSize", Globals.themeVars.fontSizeSmall)
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
                                                            color: Globals.customValue(themeScope + ".cveDesc", "color", Globals.themeVars.SecondaryLight)
                                                            font.pixelSize: Globals.customValue(themeScope + ".cveDesc", "fontSize", Globals.themeVars.fontSizeSmall)
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

                            Rectangle {
                                visible: widgetRoot && widgetRoot.ostreeUpdates > 0 && widgetRoot.ostreeMgr && widgetRoot.ostreeMgr.updateCount === 0
                                Layout.fillWidth: true
                                Layout.preferredHeight: fallbackOstreeCol.implicitHeight + 20
                                color: Globals.customValue(themeScope + ".ostreeCheck", "color", Globals.themeVars.Secondary10)
                                radius: Globals.customValue(themeScope + ".ostreeCheck", "radius", Globals.themeVars.borderRadiusMedium)
                                border.color: Globals.customValue(themeScope + ".ostreeCheck", "borderColor", Globals.themeVars.Secondary10)
                                border.width: Globals.customValue(themeScope + ".ostreeCheck", "borderWidth", Globals.themeVars.borderWidthSmall)

                                ColumnLayout {
                                    id: fallbackOstreeCol
                                    width: parent.width - 20
                                    anchors.centerIn: parent
                                    spacing: Globals.customValue(themeScope + ".ostreeCheckLayout", "spacing", Globals.themeVars.spacingSmall)
                                    Text {
                                        text: "System Update Available"
                                        color: Globals.customValue(themeScope + ".ostreeCheckTitle", "color", Globals.themeVars.White)
                                        font.pixelSize: Globals.customValue(themeScope + ".ostreeCheckTitle", "fontSize", Globals.themeVars.fontSizeMedium)
                                        font.bold: true
                                    }
                                    Text {
                                        text: "An OS update is staged and ready to be installed."
                                        color: Globals.customValue(themeScope + ".ostreeCheckSubtitle", "color", Globals.themeVars.SecondaryLight)
                                        font.pixelSize: Globals.customValue(themeScope + ".ostreeCheckSubtitle", "fontSize", Globals.themeVars.fontSizeMedium)
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
                                radius: Globals.customValue(themeScope + ".ostreeCheckBtn", "radius", Globals.themeVars.borderRadiusHuge)

                                property bool isOstreeUpdating: widgetRoot && widgetRoot.ostreeMgr && widgetRoot.ostreeMgr.isUpdating
                                property bool isOstreeChecking: widgetRoot && widgetRoot.ostreeMgr && widgetRoot.ostreeMgr.isChecking
                                property bool isTransactionInProgress: widgetRoot && widgetRoot.ostreeMgr && widgetRoot.ostreeMgr.hasActiveTransaction && !isOstreeUpdating
                                property bool isRebootRequired: widgetRoot && widgetRoot.ostreeMgr && widgetRoot.ostreeMgr.isRebootRequired

                                color: isOstreeChecking ? Globals.customValue(themeScope + ".ostreeCheckBtn", "checkingColor", Globals.themeVars.Secondary10)
                                      : (isOstreeUpdating ? Globals.customValue(themeScope + ".ostreeCheckBtn", "updatingColor", Globals.themeVars.Secondary10)
                                      : (isTransactionInProgress ? Globals.customValue(themeScope + ".ostreeCheckBtn", "errorColor", Globals.themeVars.Error)
                                      : (isRebootRequired ? (ostreeUpdateMouse.containsMouse ? Globals.customValue(themeScope + ".ostreeCheckBtn", "rebootHoverColor", Globals.themeVars.Main) : Globals.customValue(themeScope + ".ostreeCheckBtn", "rebootColor", Globals.themeVars.Secondary))
                                      : (ostreeUpdateMouse.containsMouse ? Globals.customValue(themeScope + ".ostreeCheckBtn", "hoverColor", Globals.themeVars.Secondary) : Globals.customValue(themeScope + ".ostreeCheckBtn", "hoverColor", Globals.themeVars.Secondary25)))))
                                border.color: isTransactionInProgress ? Globals.customValue(themeScope + ".ostreeCheckBtn", "borderColor", Globals.themeVars.Secondary) : "transparent"
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
                                        strokeColor: Globals.customValue(themeScope + ".ostreeCheckSpinner", "color", Globals.themeVars.Secondary)
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
                                    spacing: Globals.customValue(themeScope + ".ostreeBtnLayout", "spacing", Globals.themeVars.spacingMedium)

                                    Icon {
                                        visible: ostreeBtn.isRebootRequired
                                        width: 18; height: 18
                                        path: "M17.65 6.35C16.2 4.9 14.21 4 12 4c-4.42 0-7.99 3.58-7.99 8s3.57 8 7.99 8c3.73 0 6.84-2.55 7.73-6h-2.08c-.82 2.33-3.04 4-5.65 4-3.31 0-6-2.69-6-6s2.69-6 6-6c1.66 0 3.14.69 4.22 1.78L13 11h7V4l-2.35 2.35z"
                                        color: Globals.customValue(themeScope + ".ostreeBtnIcon", "color", Globals.themeVars.Black)
                                    }

                                    Text {
                                        text: {
                                            if (ostreeBtn.isOstreeChecking) return "Checking for updates...";
                                            if (ostreeBtn.isOstreeUpdating) return widgetRoot.ostreeMgr.status || "Installing...";
                                            if (ostreeBtn.isRebootRequired) return "Reboot to finish updating";
                                            if (ostreeBtn.isTransactionInProgress) return "Other operation running. Cancel ?";
                                            return "Install System OS Update";
                                        }
                                        color: (ostreeBtn.isOstreeUpdating || ostreeBtn.isOstreeChecking) ? Globals.customValue(themeScope + ".ostreeBtnText", "loadingColor", Globals.customValue(themeScope + ".ostreeBtnText", "color", Globals.themeVars.White)) : (ostreeBtn.isRebootRequired ? Globals.customValue(themeScope + ".ostreeBtnText", "activeColor", Globals.customValue(themeScope + ".ostreeBtnText", "errorColor", Globals.customValue(themeScope + ".ostreeBtnText", "hoverColor", Globals.themeVars.Black))) : (ostreeBtn.isTransactionInProgress ? Globals.customValue(themeScope + ".ostreeBtnText", "activeColor", Globals.customValue(themeScope + ".ostreeBtnText", "errorColor", Globals.customValue(themeScope + ".ostreeBtnText", "hoverColor", Globals.themeVars.Black))) : (ostreeUpdateMouse.containsMouse ? Globals.customValue(themeScope + ".ostreeBtnText", "activeColor", Globals.customValue(themeScope + ".ostreeBtnText", "errorColor", Globals.customValue(themeScope + ".ostreeBtnText", "hoverColor", Globals.themeVars.Black))) : Globals.customValue(themeScope + ".ostreeBtnText", "loadingColor", Globals.customValue(themeScope + ".ostreeBtnText", "color", Globals.themeVars.White)))))
                                        font.pixelSize: Globals.customValue(themeScope + ".ostreeBtnText", "fontSize", Globals.themeVars.fontSizeMedium)
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

                        // Flatpak Section
                        ColumnLayout {
                            visible: widgetRoot && widgetRoot.flatpakMgr && widgetRoot.flatpakMgr.updateCount > 0
                            Layout.fillWidth: true
                            spacing: Globals.customValue(themeScope + ".flatpak", "spacing", Globals.themeVars.spacingLarge)

                            RowLayout {
                                Layout.fillWidth: true
                                Icon {
                                    width: 16; height: 16
                                    path: "M21 16.5c0 .38-.21.71-.53.88l-7.9 4.44c-.16.12-.36.18-.57.18-.21 0-.41-.06-.57-.18l-7.9-4.44A.991.991 0 0 1 3 16.5v-9c0-.38.21-.71.53-.88l7.9-4.44c.16-.12.36-.18.57-.18.21 0 .41.06.57.18l7.9 4.44c.32.17.53.5.53.88v9zM12 4.15L6.04 7.5 12 10.85l5.96-3.35L12 4.15zM5 15.91l6 3.38v-6.71L5 9.21v6.7zm14 0v-6.7l-6 3.38v6.71l6-3.38z"
                                    color: Globals.customValue(themeScope + ".flatpakTitle", "iconColor", Globals.themeVars.Secondary)
                                }
                                Text {
                                    text: "Flatpak Applications"
                                    color: Globals.customValue(themeScope + ".flatpakTitleText", "color", Globals.themeVars.Secondary)
                                    font.pixelSize: Globals.customValue(themeScope + ".flatpakTitleText", "fontSize", Globals.themeVars.fontSizeMedium)
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
                                    radius: Globals.customValue(themeScope + ".flatpakAllBtn", "radius", Globals.themeVars.borderRadiusMedium)
                                    enabled: !isCurrentlyUpdating && !isAllCompleted
                                    color: isAllCompleted ? Globals.customValue(themeScope + ".flatpakAllBtn", "completedColor", Globals.customValue(themeScope + ".flatpakAllBtn", "updatingColor", Globals.customValue(themeScope + ".flatpakAllBtn", "hoverColor", Globals.themeVars.Secondary10))) : (isCurrentlyUpdating ? Globals.customValue(themeScope + ".flatpakAllBtn", "completedColor", Globals.customValue(themeScope + ".flatpakAllBtn", "updatingColor", Globals.customValue(themeScope + ".flatpakAllBtn", "hoverColor", Globals.themeVars.Secondary10))) : (flatpakAllMouse.containsMouse ? Globals.customValue(themeScope + ".flatpakAllBtn", "hoverColor", Globals.themeVars.Secondary) : "transparent"))
                                    border.color: isAllCompleted ? Globals.customValue(themeScope + ".flatpakAllBtn", "borderColor", Globals.themeVars.Secondary) : "transparent"
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
                                            strokeColor: Globals.customValue(themeScope + ".flatpakAllSpinner", "color", Globals.themeVars.Secondary)
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
                                        color: flatpakAllMouse.containsMouse ? Globals.customValue(themeScope + ".flatpakAllText", "hoverColor", Globals.themeVars.Black) : Globals.customValue(themeScope + ".flatpakAllText", "color", Globals.themeVars.Secondary)
                                        font.pixelSize: Globals.customValue(themeScope + ".flatpakAllText", "fontSize", Globals.themeVars.fontSizeSmall)
                                        font.bold: true
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        visible: flatpakAllBtn.isCurrentlyUpdating
                                        text: flatpakAllBtn.completedCount + " / " + flatpakAllBtn.totalCount
                                        color: Globals.customValue(themeScope + ".flatpakAllValue", "color", Globals.themeVars.White)
                                        font.pixelSize: Globals.customValue(themeScope + ".flatpakAllValue", "fontSize", Globals.themeVars.fontSizeSmall)
                                        font.bold: true
                                    }

                                    Icon {
                                        anchors.centerIn: parent
                                        visible: flatpakAllBtn.isAllCompleted
                                        width: 14; height: 14
                                        path: "M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z"
                                        color: Globals.customValue(themeScope + ".flatpakAllIcon", "color", Globals.themeVars.Secondary)
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
                                    color: Globals.customValue(themeScope + ".flatpakItem", "color", Globals.themeVars.Secondary10)
                                    radius: Globals.customValue(themeScope + ".flatpakItem", "radius", Globals.themeVars.borderRadiusMedium)
                                    border.color: Globals.customValue(themeScope + ".flatpakItem", "borderColor", Globals.themeVars.Secondary10)
                                    border.width: Globals.customValue(themeScope + ".flatpakItem", "borderWidth", Globals.themeVars.borderWidthSmall)

                                    RowLayout {
                                        id: flatpakItemRow
                                        width: parent.width - 24
                                        anchors.centerIn: parent
                                        spacing: Globals.customValue(themeScope + ".flatpakItemLayout", "spacing", Globals.themeVars.spacingLarge)

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: Globals.customValue(themeScope + ".flatpakItemInner", "spacing", Globals.themeVars.spacingSmall)
                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: Globals.customValue(themeScope + ".flatpakItemHeader", "spacing", Globals.themeVars.spacingMedium)
                                                Icon {
                                                    width: 14; height: 14
                                                    path: modelData.isSystem ? "M20 18c1.1 0 1.99-.9 1.99-2L22 6c0-1.1-.9-2-2-2H4c-1.1 0-2 .9-2 2v10c0 1.1.9 2 2 2H0v2h24v-2h-4zM4 6h16v10H4V6z" : "M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z"
                                                    color: Globals.customValue(themeScope + ".flatpakItemIcon", "color", Globals.themeVars.SecondaryLight)
                                                }
                                                Text {
                                                    text: modelData.name || ""
                                                    color: Globals.customValue(themeScope + ".flatpakItemTitle", "color", Globals.themeVars.White)
                                                    font.pixelSize: Globals.customValue(themeScope + ".flatpakItemTitle", "fontSize", Globals.themeVars.fontSizeMedium)
                                                    font.bold: true
                                                    Layout.fillWidth: true
                                                    elide: Text.ElideRight
                                                }
                                                Text {
                                                    text: modelData.size || ""
                                                    color: Globals.customValue(themeScope + ".flatpakItemSubtitle", "color", Globals.themeVars.SecondaryLight)
                                                    font.pixelSize: Globals.customValue(themeScope + ".flatpakItemSubtitle", "fontSize", Globals.themeVars.fontSizeSmall)
                                                }
                                            }
                                            Text {
                                                text: modelData.version ? ("Version " + modelData.version) : "Minor update"
                                                color: Globals.customValue(themeScope + ".flatpakItemVersion", "color", Globals.themeVars.SecondaryLight)
                                                font.pixelSize: Globals.customValue(themeScope + ".flatpakItemVersion", "fontSize", Globals.themeVars.fontSizeMedium)
                                                Layout.fillWidth: true
                                                elide: Text.ElideRight
                                            }
                                            Text {
                                                visible: individualBtn.errorMsg !== ""
                                                text: individualBtn.errorMsg
                                                color: individualBtn.isFatal ? Globals.customValue(themeScope + ".flatpakItemFatal", "color", Globals.themeVars.Warning) : Globals.customValue(themeScope + ".flatpakItemWarning", "color", Globals.themeVars.Main)
                                                font.pixelSize: Globals.customValue(themeScope + ".flatpakItemText", "fontSize", Globals.themeVars.fontSizeSmall)
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
                                            radius: Globals.customValue(themeScope + ".flatpakItemBtn", "radius", Globals.themeVars.borderRadiusLarge)
                                            color: (isCompleted || isWarning) ? Globals.customValue(themeScope + ".flatpakItemBtn", "completedColor", Globals.customValue(themeScope + ".flatpakItemBtn", "hoverColor", Globals.themeVars.Secondary25)) : (isUpdating ? Globals.customValue(themeScope + ".flatpakItemBtn", "updatingColor", Globals.customValue(themeScope + ".flatpakItemBtn", "hoverColor", Globals.themeVars.Secondary10)) : (individualUpdateMouse.containsMouse ? Globals.customValue(themeScope + ".flatpakItemBtn", "hoverColor", Globals.themeVars.Secondary) : Globals.customValue(themeScope + ".flatpakItemBtn", "updatingColor", Globals.customValue(themeScope + ".flatpakItemBtn", "hoverColor", Globals.themeVars.Secondary10))))
                                            border.color: isUpdating ? "transparent" : (isFatal ? (individualUpdateMouse.containsMouse ? Globals.customValue(themeScope + ".flatpakItemBtn", "borderHoverColor", Globals.customValue(themeScope + ".flatpakItemBtn", "completedBorder", Globals.themeVars.Secondary)) : Globals.customValue(themeScope + ".flatpakItemBtn", "fatalColor", Globals.themeVars.Warning)) : (isWarning ? Globals.customValue(themeScope + ".flatpakItemBtn", "warningColor", Globals.themeVars.Main) : (isCompleted ? Globals.customValue(themeScope + ".flatpakItemBtn", "borderHoverColor", Globals.customValue(themeScope + ".flatpakItemBtn", "completedBorder", Globals.themeVars.Secondary)) : Globals.customValue(themeScope + ".flatpakItemBtn", "borderHoverColor", Globals.customValue(themeScope + ".flatpakItemBtn", "completedBorder", Globals.themeVars.Secondary25)))))
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
                                                    strokeColor: Globals.customValue(themeScope + ".flatpakItemSpinner", "color", Globals.themeVars.Secondary)
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
                                                color: individualUpdateMouse.containsMouse ? Globals.customValue(themeScope + ".flatpakItemBtnText", "hoverColor", Globals.themeVars.Black) : Globals.customValue(themeScope + ".flatpakItemBtnText", "color", Globals.themeVars.White)
                                                font.pixelSize: Globals.customValue(themeScope + ".flatpakItemBtnText", "fontSize", Globals.themeVars.fontSizeSmall)
                                                font.bold: true
                                            }

                                            Text {
                                                anchors.centerIn: parent
                                                opacity: individualBtn.isUpdating ? 1.0 : 0.0
                                                Behavior on opacity { NumberAnimation { duration: 250 } }
                                                text: (widgetRoot && widgetRoot.flatpakMgr ? widgetRoot.flatpakMgr.updateProgress : 0) + "%"
                                                color: Globals.customValue(themeScope + ".flatpakItemBtnValue", "color", Globals.themeVars.White)
                                                font.pixelSize: Globals.customValue(themeScope + ".flatpakItemBtnValue", "fontSize", Globals.themeVars.fontSizeSmall)
                                                font.bold: true
                                            }

                                            Icon {
                                                anchors.centerIn: parent
                                                opacity: (individualBtn.isCompleted || individualBtn.isWarning || (individualBtn.isFatal && !individualUpdateMouse.containsMouse)) ? 1.0 : 0.0
                                                Behavior on opacity { NumberAnimation { duration: 250 } }
                                                width: 16; height: 16
                                                path: individualBtn.isFatal ? "M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12z" : (individualBtn.isWarning ? "M11 15h2v2h-2v-2zm0-8h2v6h-2V7zm.99-5C6.47 2 2 6.48 2 12s4.47 10 9.99 10C17.52 22 22 17.52 22 12S17.52 2 11.99 2zM12 20c-4.42 0-8-3.58-8-8s3.58-8 8-8 8 3.58 8 8-3.58 8-8 8z" : "M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z")
                                                color: individualBtn.isFatal ? Globals.customValue(themeScope + ".flatpakItemIcon", "fatalColor", Globals.themeVars.Warning) : (individualBtn.isWarning ? Globals.customValue(themeScope + ".flatpakItemIcon", "warningColor", Globals.themeVars.Main) : Globals.customValue(themeScope + ".flatpakItemIcon", "color", Globals.themeVars.Secondary))
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

                        // Firmware (fwupd)
                        ColumnLayout {
                            visible: widgetRoot && widgetRoot.fwupdMgr && widgetRoot.fwupdMgr.updateCount > 0
                            Layout.fillWidth: true
                            spacing: Globals.customValue(themeScope + ".fwupd", "spacing", Globals.themeVars.spacingLarge)

                            RowLayout {
                                Layout.fillWidth: true
                                Icon {
                                    width: 16; height: 16
                                    path: "M2 13h2v5H2v-5zm18 0h-2v5h2v-5zM17.5 4.5c.83 0 1.5.67 1.5 1.5s-.67 1.5-1.5 1.5-1.5-.67-1.5-1.5.67-1.5 1.5-1.5zM12 2C6.48 2 2 6.48 2 12h20c0-5.52-4.48-10-10-10zm0 3c1.66 0 3 1.34 3 3s-1.34 3-3 3-3-1.34-3-3 1.34-3 3-3z"
                                    color: Globals.customValue(themeScope + ".fwupdTitle", "iconColor", Globals.themeVars.Secondary)
                                }
                                Text {
                                    text: "Firmware Updates"
                                    color: Globals.customValue(themeScope + ".fwupdTitleText", "color", Globals.themeVars.Secondary)
                                    font.pixelSize: Globals.customValue(themeScope + ".fwupdTitleText", "fontSize", Globals.themeVars.fontSizeMedium)
                                    font.bold: true
                                    Layout.fillWidth: true
                                }

                                Rectangle {
                                    id: fwupdAllBtn
                                    property int totalCount: widgetRoot && widgetRoot.fwupdMgr ? widgetRoot.fwupdMgr.updateCount : 0
                                    property bool isCurrentlyUpdating: widgetRoot && widgetRoot.fwupdMgr && widgetRoot.fwupdMgr.isUpdating

                                    visible: totalCount > 1
                                    Layout.preferredWidth: isCurrentlyUpdating ? 100 : 84
                                    Layout.preferredHeight: 26
                                    Layout.alignment: Qt.AlignRight
                                    width: Layout.preferredWidth
                                    height: Layout.preferredHeight
                                    radius: Globals.customValue(themeScope + ".fwupdAllBtn", "radius", Globals.themeVars.borderRadiusMedium)
                                    enabled: !isCurrentlyUpdating
                                    color: isCurrentlyUpdating ? Globals.customValue(themeScope + ".fwupdAllBtn", "updatingColor", Globals.customValue(themeScope + ".fwupdAllBtn", "hoverColor", Globals.themeVars.Secondary10)) : (fwupdAllMouse.containsMouse ? Globals.customValue(themeScope + ".fwupdAllBtn", "hoverColor", Globals.themeVars.Secondary) : "transparent")
                                    border.color: isCurrentlyUpdating ? "transparent" : (fwupdAllMouse.containsMouse ? Globals.customValue(themeScope + ".fwupdAllBtn", "borderHoverColor", Globals.themeVars.Secondary) : Globals.customValue(themeScope + ".fwupdAllBtn", "borderHoverColor", Globals.themeVars.Secondary25))
                                    border.width: isCurrentlyUpdating ? 0 : 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: fwupdAllBtn.isCurrentlyUpdating ? "Updating..." : "Update All"
                                        color: fwupdAllBtn.isCurrentlyUpdating ? Globals.customValue(themeScope + ".fwupdAllText", "updatingColor", Globals.customValue(themeScope + ".fwupdAllText", "color", Globals.themeVars.SecondaryLight)) : (fwupdAllMouse.containsMouse ? Globals.customValue(themeScope + ".fwupdAllText", "hoverColor", Globals.themeVars.Black) : Globals.customValue(themeScope + ".fwupdAllText", "color", Globals.themeVars.Secondary))
                                        font.pixelSize: Globals.customValue(themeScope + ".fwupdAllText", "fontSize", Globals.themeVars.fontSizeSmall)
                                        font.bold: true
                                    }

                                    MouseArea {
                                        id: fwupdAllMouse
                                        anchors.fill: parent
                                        hoverEnabled: !fwupdAllBtn.isCurrentlyUpdating
                                        onClicked: {
                                            if (widgetRoot && widgetRoot.fwupdMgr) {
                                                widgetRoot.fwupdMgr.startAllUpdates();
                                            }
                                        }
                                    }
                                }
                            }

                            Repeater {
                                model: widgetRoot && widgetRoot.fwupdMgr ? widgetRoot.fwupdMgr.availableUpdates : []
                                delegate: Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: fwupdItemRow.implicitHeight + 20
                                    color: Globals.customValue(themeScope + ".fwupdItem", "color", Globals.themeVars.Secondary10)
                                    radius: Globals.customValue(themeScope + ".fwupdItem", "radius", Globals.themeVars.borderRadiusMedium)
                                    border.color: Globals.customValue(themeScope + ".fwupdItem", "borderColor", Globals.themeVars.Secondary10)
                                    border.width: Globals.customValue(themeScope + ".fwupdItem", "borderWidth", Globals.themeVars.borderWidthSmall)

                                    RowLayout {
                                        id: fwupdItemRow
                                        width: parent.width - 24
                                        anchors.centerIn: parent
                                        spacing: Globals.customValue(themeScope + ".fwupdItemLayout", "spacing", Globals.themeVars.spacingHuge)

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: Globals.customValue(themeScope + ".fwupdItemInner", "spacing", Globals.themeVars.spacingSmall)

                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: Globals.customValue(themeScope + ".fwupdItemHeader", "spacing", Globals.themeVars.spacingMedium)
                                                Text {
                                                    text: modelData.deviceName || ""
                                                    color: Globals.customValue(themeScope + ".fwupdItemTitle", "color", Globals.themeVars.White)
                                                    font.pixelSize: Globals.customValue(themeScope + ".fwupdItemTitle", "fontSize", Globals.themeVars.fontSizeMedium)
                                                    font.bold: true
                                                    Layout.fillWidth: true
                                                    elide: Text.ElideRight
                                                }
                                            }
                                            Text {
                                                text: modelData.name || ""
                                                color: Globals.customValue(themeScope + ".fwupdItemVendor", "color", Globals.themeVars.SecondaryLight)
                                                font.pixelSize: Globals.customValue(themeScope + ".fwupdItemVendor", "fontSize", Globals.themeVars.fontSizeMedium)
                                                Layout.fillWidth: true
                                                elide: Text.ElideRight
                                            }
                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: Globals.customValue(themeScope + ".fwupdItemVersions", "spacing", Globals.themeVars.spacingMedium)
                                                visible: modelData.oldVersion !== undefined && modelData.oldVersion !== ""

                                                Text {
                                                    text: modelData.oldVersion || ""
                                                    color: Globals.customValue(themeScope + ".fwupdItemVerOld", "color", Globals.themeVars.SecondaryLight)
                                                    font.pixelSize: Globals.customValue(themeScope + ".fwupdItemVerOld", "fontSize", Globals.themeVars.fontSizeSmall)
                                                    Layout.fillWidth: true
                                                    elide: Text.ElideRight
                                                }
                                                Text {
                                                    text: "→"
                                                    color: Globals.customValue(themeScope + ".fwupdItemArrow", "color", Globals.themeVars.Secondary)
                                                    font.pixelSize: Globals.customValue(themeScope + ".fwupdItemArrow", "fontSize", Globals.themeVars.fontSizeSmall)
                                                    font.bold: true
                                                }
                                                Text {
                                                    text: modelData.newVersion || ""
                                                    color: Globals.customValue(themeScope + ".fwupdItemVerNew", "color", Globals.themeVars.Secondary)
                                                    font.pixelSize: Globals.customValue(themeScope + ".fwupdItemVerNew", "fontSize", Globals.themeVars.fontSizeSmall)
                                                    Layout.fillWidth: true
                                                    elide: Text.ElideRight
                                                }
                                            }
                                            Text {
                                                visible: (modelData.oldVersion === undefined || modelData.oldVersion === "") && (modelData.newVersion !== undefined && modelData.newVersion !== "")
                                                text: "New Version: " + (modelData.newVersion || "")
                                                color: Globals.customValue(themeScope + ".fwupdItemBranch", "color", Globals.themeVars.Secondary)
                                                font.pixelSize: Globals.customValue(themeScope + ".fwupdItemBranch", "fontSize", Globals.themeVars.fontSizeSmall)
                                                Layout.fillWidth: true
                                                elide: Text.ElideRight
                                            }
                                            Text {
                                                visible: modelData.summary !== undefined && modelData.summary !== ""
                                                text: modelData.summary || ""
                                                color: Globals.customValue(themeScope + ".fwupdItemDesc", "color", Globals.themeVars.SecondaryLight)
                                                font.pixelSize: Globals.customValue(themeScope + ".fwupdItemDesc", "fontSize", Globals.themeVars.fontSizeSmall)
                                                wrapMode: Text.Wrap
                                                Layout.fillWidth: true
                                            }
                                        }

                                        Rectangle {
                                            id: fwupdIndivBtn
                                            property bool isUpdating: widgetRoot && widgetRoot.fwupdMgr && widgetRoot.fwupdMgr.isUpdating

                                            width: 70
                                            height: 32
                                            radius: Globals.customValue(themeScope + ".fwupdItemBtn", "radius", Globals.themeVars.borderRadiusLarge)
                                            color: isUpdating ? Globals.customValue(themeScope + ".fwupdItemBtn", "updatingColor", Globals.customValue(themeScope + ".fwupdItemBtn", "hoverColor", Globals.themeVars.Secondary10)) : (fwupdIndivMouse.containsMouse ? Globals.customValue(themeScope + ".fwupdItemBtn", "hoverColor", Globals.themeVars.Secondary) : Globals.customValue(themeScope + ".fwupdItemBtn", "updatingColor", Globals.customValue(themeScope + ".fwupdItemBtn", "hoverColor", Globals.themeVars.Secondary10)))
                                            border.color: isUpdating ? "transparent" : (fwupdIndivMouse.containsMouse ? Globals.customValue(themeScope + ".fwupdItemBtn", "borderHoverColor", Globals.themeVars.Secondary) : Globals.customValue(themeScope + ".fwupdItemBtn", "borderHoverColor", Globals.themeVars.Secondary25))
                                            border.width: isUpdating ? 0 : 1

                                            Text {
                                                anchors.centerIn: parent
                                                opacity: fwupdIndivBtn.isUpdating ? 0.0 : 1.0
                                                text: "Update"
                                                color: fwupdIndivMouse.containsMouse ? Globals.customValue(themeScope + ".fwupdItemBtnText", "hoverColor", Globals.themeVars.Black) : Globals.customValue(themeScope + ".fwupdItemBtnText", "color", Globals.themeVars.White)
                                                font.pixelSize: Globals.customValue(themeScope + ".fwupdItemBtnText", "fontSize", Globals.themeVars.fontSizeSmall)
                                                font.bold: true
                                            }

                                            Text {
                                                anchors.centerIn: parent
                                                opacity: fwupdIndivBtn.isUpdating ? 1.0 : 0.0
                                                text: "..."
                                                color: Globals.customValue(themeScope + ".fwupdItemBtnIcon", "color", Globals.themeVars.White)
                                                font.pixelSize: Globals.customValue(themeScope + ".fwupdItemBtnIcon", "fontSize", Globals.themeVars.fontSizeSmall)
                                                font.bold: true
                                            }

                                            MouseArea {
                                                id: fwupdIndivMouse
                                                anchors.fill: parent
                                                hoverEnabled: !fwupdIndivBtn.isUpdating
                                                enabled: !fwupdIndivBtn.isUpdating
                                                onClicked: {
                                                    if (widgetRoot && modelData.deviceId) {
                                                        widgetRoot.fwupdMgr.startUpdate(modelData.deviceId);
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
                            text: (widgetRoot.flatpakMgr && widgetRoot.flatpakMgr.isChecking) || (widgetRoot.ostreeMgr && widgetRoot.ostreeMgr.isChecking) || (widgetRoot.fwupdMgr && widgetRoot.fwupdMgr.isChecking) ? "Checking for updates..." : "System is up to date."
                            color: Globals.customValue(themeScope + ".emptyText", "color", Globals.themeVars.SecondaryLight)
                            font.pixelSize: Globals.customValue(themeScope + ".emptyText", "fontSize", Globals.themeVars.fontSizeMedium)
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
                    property bool hasFwupdError: widgetRoot && widgetRoot.fwupdMgr && widgetRoot.fwupdMgr.lastError !== ""

                    visible: hasFlatpakError || hasOstreeError || hasFwupdError
                    Layout.fillWidth: true
                    spacing: Globals.customValue(themeScope + ".fatalLayout", "spacing", Globals.themeVars.spacingMedium)

                    Text {
                        text: parent.hasFlatpakError ? "Flatpak Error: " + widgetRoot.flatpakMgr.lastError : ""
                        color: Globals.customValue(themeScope + ".fatalOstree", "color", Globals.themeVars.Warning)
                        font.pixelSize: Globals.customValue(themeScope + ".fatalOstree", "fontSize", Globals.themeVars.fontSizeSmall)
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                        visible: text !== ""
                    }

                    Text {
                        text: parent.hasOstreeError ? "System Update Error: " + widgetRoot.ostreeMgr.lastError : ""
                        color: Globals.customValue(themeScope + ".fatalFlatpak", "color", Globals.themeVars.Warning)
                        font.pixelSize: Globals.customValue(themeScope + ".fatalFlatpak", "fontSize", Globals.themeVars.fontSizeSmall)
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                        visible: text !== ""
                    }

                    Text {
                        text: parent.hasFwupdError ? "Firmware Update Error: " + widgetRoot.fwupdMgr.lastError : ""
                        color: Globals.customValue(themeScope + ".fatalFwupd", "color", Globals.themeVars.Warning)
                        font.pixelSize: Globals.customValue(themeScope + ".fatalFwupd", "fontSize", Globals.themeVars.fontSizeSmall)
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                        visible: text !== ""
                    }
                }
            }
        }
    }
}
