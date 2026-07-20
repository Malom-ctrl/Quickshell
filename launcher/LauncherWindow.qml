import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: root

    property string themeScope: "launcher.LauncherWindow"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    visible: false

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"

    IpcHandler {
        target: "launcher"
        function toggle() {
            root.visible = !root.visible;
            if (root.visible) {
                searchInput.text = "";
                searchInput.forceActiveFocus();
            }
        }
        function show() {
            root.visible = true;
            searchInput.text = "";
            searchInput.forceActiveFocus();
        }
        function hide() {
            root.visible = false;
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: launcherLogic.hideLauncher()
    }

    Rectangle {
        width: Globals.customValue(themeScope, "width", 640)
        height: Math.min(600, 100 + resultsList.contentHeight)
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.3
        color: Globals.customValue(themeScope, "color", Globals.themeVars.Black)
        radius: Globals.customValue(themeScope, "radius", Globals.themeVars.borderRadiusHuge)
        border.color: Globals.customValue(themeScope, "borderColor", Globals.themeVars.Secondary10)
        border.width: Globals.customValue(themeScope, "borderWidth", Globals.themeVars.borderWidthSmall)

        Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Globals.customValue(themeScope + ".layout", "margins", Globals.themeVars.spacingHuge)
            spacing: Globals.customValue(themeScope + ".layout", "spacing", Globals.themeVars.spacingHuge)

            Rectangle {
                Layout.fillWidth: true
                height: Globals.customValue(themeScope + ".searchBox", "height", 56)
                color: Globals.customValue(themeScope + ".searchBox", "color", Globals.themeVars.Black)
                radius: Globals.customValue(themeScope + ".searchBox", "radius", 28)
                border.color: searchInput.focus ? Globals.customValue(themeScope + ".searchBox", "borderColorFocused", Globals.themeVars.Secondary) : Globals.customValue(themeScope + ".searchBox", "borderColor", Globals.themeVars.Secondary25)
                border.width: Globals.customValue(themeScope + ".searchBox", "borderWidth", Globals.themeVars.borderWidthMedium)

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Globals.customValue(themeScope + ".searchBox.layout", "margins", Globals.themeVars.spacingHuge)
                    spacing: Globals.customValue(themeScope + ".searchBox.layout", "spacing", Globals.themeVars.spacingLarge)

                    Icon {
                        path: "M15.5 14h-.79l-.28-.27A6.471 6.471 0 0016 9.5 6.5 6.5 0 109.5 16c1.61 0 3.09-.59 4.23-1.57l.27.28v.79l5 4.99L20.49 19l-4.99-5zm-6 0C7.01 14 5 11.99 5 9.5S7.01 5 9.5 5 14 7.01 14 9.5 11.99 14 9.5 14z"
                        color: Globals.customValue(themeScope + ".searchBox.icon", "color", Globals.themeVars.Secondary)
                    }

                    TextInput {
                        id: searchInput
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        verticalAlignment: TextInput.AlignVCenter
                        color: Globals.customValue(themeScope + ".searchInput", "color", Globals.themeVars.White)
                        font.pixelSize: Globals.customValue(themeScope + ".searchInput", "fontSize", Globals.themeVars.fontSizeLarge)
                        clip: true
                        focus: true

                        onTextChanged: launcherLogic.updateResults(text)

                        Keys.onPressed: (event) => {
                            if (event.key === Qt.Key_Down) {
                                resultsList.currentIndex = Math.min(resultsList.count - 1, resultsList.currentIndex + 1);
                                resultsList.positionViewAtIndex(resultsList.currentIndex, ListView.Contain);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Up) {
                                resultsList.currentIndex = Math.max(0, resultsList.currentIndex - 1);
                                resultsList.positionViewAtIndex(resultsList.currentIndex, ListView.Contain);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                launcherLogic.executeCurrent();
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Escape) {
                                launcherLogic.hideLauncher();
                                event.accepted = true;
                            }
                        }
                    }
                }
            }

            ListView {
                id: resultsList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: Globals.customValue(themeScope + ".list", "spacing", Globals.themeVars.spacingMedium)
                model: launcherLogic.resultsModel

                delegate: Rectangle {
                    width: ListView.view.width
                    height: Globals.customValue(themeScope + ".listItem", "height", 56)
                    radius: Globals.customValue(themeScope + ".listItem", "radius", Globals.themeVars.borderRadiusMedium)
                    color: ListView.isCurrentItem ? Globals.customValue(themeScope + ".listItem", "selectedColor", Globals.themeVars.Secondary25) : (mouseArea.containsMouse ? Globals.customValue(themeScope + ".listItem", "hoverColor", Globals.themeVars.Black) : "transparent")

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: Globals.customValue(themeScope + ".listItem.layout", "margins", Globals.themeVars.spacingLarge)
                        spacing: Globals.customValue(themeScope + ".listItem.layout", "spacing", Globals.themeVars.spacingHuge)

                        Item {
                            width: Globals.customValue(themeScope + ".listItem.icon", "width", 24)
                            height: Globals.customValue(themeScope + ".listItem.icon", "height", 24)

                            Image {
                                id: appIcon
                                anchors.fill: parent
                                visible: modelData.iconName !== undefined && modelData.iconName !== "" && status !== Image.Null && status !== Image.Error
                                source: (modelData.iconName !== undefined && modelData.iconName !== "") ? Quickshell.iconPath(modelData.iconName, true) : ""
                                sourceSize: Qt.size(24, 24)
                                fillMode: Image.PreserveAspectFit
                            }

                            Icon {
                                anchors.fill: parent
                                visible: !appIcon.visible
                                path: modelData.iconPath || "M4 6H2v14c0 1.1.9 2 2 2h14v-2H4V6zm16-4H8c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2zm-1 9H9V9h10v2zm-4 4H9v-2h6v2zm4-8H9V5h10v2z"
                                color: ListView.isCurrentItem ? Globals.customValue(themeScope + ".listItem.iconFallback", "selectedColor", Globals.themeVars.Secondary) : Globals.customValue(themeScope + ".listItem.iconFallback", "color", Globals.themeVars.White)
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Globals.customValue(themeScope + ".listItem.textLayout", "spacing", 2)

                            Text {
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignLeft
                                text: modelData.title || ""
                                color: ListView.isCurrentItem ? Globals.customValue(themeScope + ".listItem.title", "selectedColor", Globals.themeVars.White) : Globals.customValue(themeScope + ".listItem.title", "color", Globals.themeVars.White)
                                font.pixelSize: Globals.customValue(themeScope + ".listItem.title", "fontSize", Globals.themeVars.fontSizeMedium)
                                font.bold: true
                                elide: Text.ElideRight
                            }
                            //Text {
                            //    Layout.fillWidth: true
                            //    horizontalAlignment: Text.AlignLeft
                            //    visible: modelData.subtitle !== undefined && modelData.subtitle !== ""
                            //    text: modelData.subtitle || ""
                            //    color: Globals.themeVars.SecondaryLight
                            //    font.pixelSize: 12
                            //    elide: Text.ElideRight
                            //}
                        }
                    }

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            resultsList.currentIndex = index;
                            launcherLogic.executeCurrent();
                        }
                    }
                }
            }
        }
    }

    Item {
        id: launcherLogic

        property var allApps: []
        property var resultsModel: []
        property var appHistory: []

        property string historyBuffer: ""

        Process {
            id: historyReadProc
            command: ["bash", "-c", "touch " + Quickshell.cachePath("launcher-history.txt") + " && tail -n 100 " + Quickshell.cachePath("launcher-history.txt")]
            stdout: SplitParser {
                splitMarker: ""
                onRead: (data) => {
                    console.error("historyReadProc read chunk:", data.length, "bytes");
                    launcherLogic.historyBuffer += data;
                }
            }
            onExited: {
                console.error("historyReadProc exited. Total history bytes read:", launcherLogic.historyBuffer.length);
                let lines = launcherLogic.historyBuffer.split('\n');
                let newHistory = [];
                for (let i = 0; i < lines.length; i++) {
                    if (lines[i].trim() !== "") {
                        newHistory.push(lines[i].trim());
                    }
                }
                launcherLogic.appHistory = newHistory;
                console.error("Loaded", launcherLogic.appHistory.length, "history items.");
                launcherLogic.updateResults(searchInput.text);

                historyTruncateProc.command = ["bash", "-c", "tail -n 100 " + Quickshell.cachePath("launcher-history.txt") + " > " + Quickshell.cachePath("launcher-history.txt.tmp") + " && mv " + Quickshell.cachePath("launcher-history.txt.tmp") + " " + Quickshell.cachePath("launcher-history.txt")];
                historyTruncateProc.running = true;
            }
        }

        Process {
            id: historyTruncateProc
            command: []
        }

        Process {
            id: historyWriteProc
            command: []
        }

        function recordApp(appObj) {
            if (!appObj) return;
            let name = appObj.name || (typeof appObj === "string" ? appObj : "");
            if (!name) return;
            appHistory.push(name);
            if (appHistory.length > 100) {
                appHistory.shift();
            }
            historyWriteProc.command = ["bash", "-c", "echo '" + name.replace(/'/g, "'\\''") + "' >> " + Quickshell.cachePath("launcher-history.txt")];
            historyWriteProc.running = false;
            historyWriteProc.running = true;
        }

        function getAppFrequency(name) {
            let count = 0;
            for (let i = 0; i < appHistory.length; i++) {
                if (appHistory[i] === name) count++;
            }
            return count;
        }

        Connections {
            target: DesktopEntries.applications
            function onValuesChanged() {
                launcherLogic.loadApps();
            }
        }

        function loadApps() {
            let appsList = [];
            if (DesktopEntries && DesktopEntries.applications && DesktopEntries.applications.values) {
                let vals = DesktopEntries.applications.values;
                for (let i = 0; i < vals.length; i++) {
                    appsList.push(vals[i]);
                }
            }
            // console.error("Loaded apps count:", appsList.length);
            allApps = appsList;
            updateResults(searchInput.text);
        }

        Process {
            id: fileProc
            command: ["bash", "-c", "ls -1dp " + searchInput.text + "* 2>/dev/null | head -n 20"]
            property string currentQuery: ""
            property var currentResults: []
            stdout: SplitParser {
                splitMarker: "\n"
                onRead: (data) => {
                    if (data.trim() !== "") {
                        currentResults.push({
                            title: data.trim(),
                            subtitle: "File/Folder",
                            action: "file",
                            target: data.trim(),
                            iconPath: "M10 4H4c-1.1 0-1.99.9-1.99 2L2 18c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V8c0-1.1-.9-2-2-2h-8l-2-2z"
                        });
                    }
                }
            }
            onRunningChanged: {
                if (!running && currentQuery === searchInput.text) {
                    resultsModel = currentResults;
                }
            }
        }

        Component.onCompleted: {
            historyReadProc.running = true;
            loadApps();
            searchInput.forceActiveFocus();
        }

        function fuzzyMatch(pattern, str) {
            pattern = pattern.toLowerCase();
            str = str.toLowerCase();
            let patternIdx = 0;
            let strIdx = 0;
            while (patternIdx < pattern.length && strIdx < str.length) {
                if (pattern[patternIdx] === str[strIdx]) patternIdx++;
                strIdx++;
            }
            return patternIdx === pattern.length;
        }

        function fuzzyScore(pattern, str) {
            if (!fuzzyMatch(pattern, str)) return -999999;
            pattern = pattern.toLowerCase();
            str = str.toLowerCase();
            let score = 0;
            let patternIdx = 0;
            for (let i = 0; i < str.length; i++) {
                if (patternIdx < pattern.length && str[i] === pattern[patternIdx]) {
                    score += 10;
                    if (i === 0 || str[i-1] === ' ' || str[i-1] === '-') score += 20;
                    patternIdx++;
                }
            }
            score -= str.length;
            return score;
        }

        function updateResults(text) {
            if (text.startsWith("=")) {
                let expr = text.substring(1).trim();
                let res = "";
                try {
                    if (expr !== "") {
                        // eslint-disable-next-line
                        let evalRes = eval(expr);
                        res = evalRes !== undefined && evalRes !== null ? String(evalRes) : "";
                    }
                } catch(e) {
                    res = "Error";
                }
                resultsModel = [{
                    title: res !== "" ? res : "Type an expression",
                    subtitle: "Calculator",
                    action: "copy",
                    target: res,
                    iconPath: "M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm-6 16h-2v-2h2v2zm0-4h-2v-2h2v2zm0-4h-2V9h2v2zm-4 8H7v-2h2v2zm0-4H7v-2h2v2zm0-4H7V9h2v2zm8 8h-2v-4h2v4zm0-6h-2V9h2v2z"
                }];
            } else if (text.startsWith("?")) {
                let query = text.substring(1).trim();
                resultsModel = [{
                    title: query !== "" ? "Search for: " + query : "Type a search query",
                    subtitle: "Google Search",
                    action: "search",
                    target: query,
                    iconPath: "M15.5 14h-.79l-.28-.27A6.471 6.471 0 0016 9.5 6.5 6.5 0 109.5 16c1.61 0 3.09-.59 4.23-1.57l.27.28v.79l5 4.99L20.49 19l-4.99-5zm-6 0C7.01 14 5 11.99 5 9.5S7.01 5 9.5 5 14 7.01 14 9.5 11.99 14 9.5 14z"
                }];
            } else if (text.startsWith("$")) {
                let cmd = text.substring(1).trim();
                resultsModel = [{
                    title: cmd !== "" ? "Run: " + cmd : "Type a command",
                    subtitle: "Execute Shell Command",
                    action: "shell",
                    target: cmd,
                    iconPath: "M20 4H4c-1.11 0-2 .9-2 2v12c0 1.1.89 2 2 2h16c1.1 0 2-.9 2-2V6c0-1.1-.89-2-2-2zm-8.5 11H19v2h-7.5v-2zM5.5 15l-1.41-1.41L8.67 9 4.09 4.41 5.5 3l6 6-6 6z"
                }];
            } else if (text.startsWith(":")) {
                let cmd = text.substring(1).trim().toLowerCase();
                let sysActions = [
                    { title: "Lock Screen", subtitle: "System", action: "shell", target: "loginctl lock-session", iconPath: "M18 8h-1V6c0-2.76-2.24-5-5-5S7 3.24 7 6v2H6c-1.1 0-2 .9-2 2v10c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V10c0-1.1-.9-2-2-2z" },
                    { title: "Suspend", subtitle: "System", action: "shell", target: "systemctl suspend", iconPath: "M12 22c5.52 0 10-4.48 10-10S17.52 2 12 2 2 6.48 2 12s4.48 10 10 10zm1-17.93c3.94.49 7 3.85 7 7.93s-3.05 7.44-7 7.93V4.07z" },
                    { title: "Reboot", subtitle: "System", action: "shell", target: "systemctl reboot", iconPath: "M17.65 6.35C16.2 4.9 14.21 4 12 4c-4.42 0-7.99 3.58-7.99 8s3.57 8 7.99 8c3.73 0 6.84-2.55 7.73-6h-2.08c-.82 2.33-3.04 4-5.65 4-3.31 0-6-2.69-6-6s2.69-6 6-6c1.66 0 3.14.69 4.22 1.78L13 11h7V4l-2.35 2.35z" },
                    { title: "Shutdown", subtitle: "System", action: "shell", target: "systemctl poweroff", iconPath: "M13 3h-2v10h2V3zm4.83 2.17l-1.42 1.42C17.99 7.86 19 9.81 19 12c0 3.87-3.13 7-7 7s-7-3.13-7-7c0-2.19 1.01-4.14 2.58-5.42L6.17 5.17C4.23 6.82 3 9.26 3 12c0 4.97 4.03 9 9 9s9-4.03 9-9c0-2.74-1.23-5.18-3.17-6.83z" }
                ];
                if (cmd !== "") {
                    sysActions = sysActions.filter(a => a.title.toLowerCase().includes(cmd));
                }
                resultsModel = sysActions;
            } else if (text.startsWith("/") || text.startsWith("~")) {
                fileProc.currentQuery = text;
                fileProc.currentResults = [];
                fileProc.command = ["bash", "-c", "ls -1dp " + text + "* 2>/dev/null | head -n 20"];
                fileProc.running = false;
                fileProc.running = true;
            } else {
                let query = text.trim();

                if (query === "") {
                    let sorted = allApps.slice();
                    sorted.sort((a, b) => {
                        let freqA = getAppFrequency(a.name || "");
                        let freqB = getAppFrequency(b.name || "");
                        if (freqA !== freqB) return freqB - freqA;
                        return (a.name || "").localeCompare(b.name || "");
                    });
                    let top = sorted.slice(0, 50);
                    resultsModel = top.map(a => ({
                        title: a.name || "Unknown",
                        subtitle: a.genericName || a.execString || "Application",
                        action: "app",
                        target: a,
                        iconName: a.icon || "",
                        iconPath: "M4 6H2v14c0 1.1.9 2 2 2h14v-2H4V6zm16-4H8c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2zm-1 9H9V9h10v2zm-4 4H9v-2h6v2zm4-8H9V5h10v2z"
                    }));
                } else {
                    let scored = [];
                    for (let i = 0; i < allApps.length; i++) {
                        let a = allApps[i];
                        let name = a.name || "Unknown";
                        let score = fuzzyScore(query, name);
                        if (score > -900000) {
                            let freq = getAppFrequency(name);
                            score += freq * 5;
                            scored.push({ app: a, score: score });
                        }
                    }
                    scored.sort((a, b) => b.score - a.score);
                    let top = scored.slice(0, 50);
                    resultsModel = top.map(a => ({
                        title: a.app.name || "Unknown",
                        subtitle: a.app.genericName || a.app.execString || "Application",
                        action: "app",
                        target: a.app,
                        iconName: a.app.icon || "",
                        iconPath: "M4 6H2v14c0 1.1.9 2 2 2h14v-2H4V6zm16-4H8c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2zm-1 9H9V9h10v2zm-4 4H9v-2h6v2zm4-8H9V5h10v2z"
                    }));
                }
            }
            resultsList.currentIndex = 0;
        }

        function executeCurrent() {
            if (resultsModel.length === 0) return;
            let current = resultsModel[resultsList.currentIndex];
            if (!current) return;

            if (current.action === "app") {
                recordApp(current.target);
                if (typeof current.target.execute === "function") {
                    current.target.execute();
                } else if (current.target.execString) {
                    Quickshell.execDetached(["bash", "-c", "setsid " + current.target.execString + " &"]);
                }
                hideLauncher();
            } else if (current.action === "shell") {
                Quickshell.execDetached(["bash", "-c", "setsid " + current.target + " &"]);
                hideLauncher();
            } else if (current.action === "search") {
                if (current.target !== "") {
                    Quickshell.execDetached(["bash", "-c", "xdg-open 'https://www.google.com/search?q=" + encodeURIComponent(current.target).replace(/'/g, "%27") + "'"]);
                    hideLauncher();
                }
            } else if (current.action === "file") {
                if (current.target.endsWith("/")) {
                    searchInput.text = current.target;
                } else {
                    Quickshell.execDetached(["xdg-open", current.target]);
                    hideLauncher();
                }
            } else if (current.action === "copy") {
                if (current.target !== "" && current.target !== "Error") {
                    Quickshell.execDetached(["bash", "-c", "echo -n '" + current.target + "' | wl-copy"]);
                    hideLauncher();
                }
            }
        }

        function hideLauncher() {
            root.visible = false;
        }
    }
}
