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
                        path: "M16.32 14.9l5.39 5.4a1 1 0 0 1-1.42 1.4l-5.38-5.38a8 8 0 1 1 1.41-1.41zM10 16a6 6 0 1 0 0-12 6 6 0 0 0 0 12z"
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
                            } else if (event.key === Qt.Key_Right) {
                                launcherLogic.completeCurrent();
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
                    id: delegateRoot
                    property bool isCurrent: ListView.isCurrentItem
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

                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: titleText.implicitHeight
                                clip: true
                                Row {
                                    id: titleRow
                                    spacing: 40
                                    property bool shouldScroll: (delegateRoot.isCurrent || mouseArea.containsMouse) && titleText.implicitWidth > parent.width
                                    property real animX: 0
                                    x: shouldScroll ? animX : 0

                                    Text {
                                        id: titleText
                                        text: modelData.title || ""
                                        color: delegateRoot.isCurrent ? Globals.customValue(themeScope + ".listItem.title", "selectedColor", Globals.themeVars.White) : Globals.customValue(themeScope + ".listItem.title", "color", Globals.themeVars.White)
                                        font.pixelSize: Globals.customValue(themeScope + ".listItem.title", "fontSize", Globals.themeVars.fontSizeMedium)
                                        font.bold: true
                                    }
                                    Text {
                                        text: modelData.title || ""
                                        color: titleText.color
                                        font.pixelSize: titleText.font.pixelSize
                                        font.bold: titleText.font.bold
                                        visible: titleRow.shouldScroll
                                    }

                                    onShouldScrollChanged: {
                                        if (shouldScroll) {
                                            animX = 0;
                                            scrollAnim.restart();
                                        } else {
                                            scrollAnim.stop();
                                            animX = 0;
                                        }
                                    }

                                    SequentialAnimation on animX {
                                        id: scrollAnim
                                        loops: Animation.Infinite
                                        running: false
                                        //PauseAnimation { duration: 1000 }
                                        NumberAnimation {
                                            from: 0
                                            to: -(titleText.implicitWidth + titleRow.spacing)
                                            duration: (titleText.implicitWidth + titleRow.spacing) * 15
                                        }
                                    }
                                }
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

    Timer {
        id: fileSearchDebounce
        interval: 30
        repeat: false
        onTriggered: launcherLogic.runFileSearch(launcherLogic.debouncedQuery)
    }


    Item {
        id: launcherLogic

        property int fileSearchGeneration: 0
        property var pendingSearchText: null
        property string debouncedQuery: ""


        property var allApps: []
        property var resultsModel: []
        property var appHistory: []

        property string historyBuffer: ""

        Process {
            id: historyReadProc
            command: ["bash", "-c", "touch '" + Quickshell.cachePath("launcher-history.txt") + "' && tail -n 100 '" + Quickshell.cachePath("launcher-history.txt") + "'"]
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

                let histFile = "'" + Quickshell.cachePath("launcher-history.txt") + "'";
                let tmpFile = "'" + Quickshell.cachePath("launcher-history.txt.tmp") + "'";
                historyTruncateProc.command = ["bash", "-c", "tail -n 100 " + histFile + " > " + tmpFile + " && mv " + tmpFile + " " + histFile];
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

        function runFileSearch(text) {
            if (fileProc.running) {
                launcherLogic.pendingSearchText = text;
                fileProc.running = false;
                return;
            }
            launchFileSearch(text);
        }

        function launchFileSearch(text) {
            let isHome = text.startsWith("~");
            let query = text.substring(1).trim();

            let myGen = ++launcherLogic.fileSearchGeneration;
            fileProc.myGeneration = myGen;
            fileProc.currentResults = [];

            let root = isHome ? "$HOME" : "/";
            let excludes = isHome
                ? "-E .git -E .cache -E node_modules -E target -E .cargo"
                : "-E .git -E .cache -E node_modules -E target -E .cargo -E proc -E sys -E dev -E run";

            let cmd;
            if (query === "") {
                cmd = "trap 'pkill -P $$' TERM EXIT INT; fd . " + root + " -H " + excludes + " --max-depth 2 2>/dev/null | head -n 20";
                fileProc.command = ["bash", "-c", cmd];
            } else {
                cmd = "trap 'pkill -P $$' TERM EXIT INT; fd . " + root + " -H " + excludes + " --max-depth 8 2>/dev/null | fzf -f \"$1\" | head -n 20";
                fileProc.command = ["bash", "-c", cmd, "_", query];
            }
            fileProc.running = true;
        }

        function recordApp(appObj) {
            if (!appObj) return;
            let name = appObj.name || (typeof appObj === "string" ? appObj : "");
            if (!name) return;
            appHistory.push(name);
            if (appHistory.length > 100) {
                appHistory.shift();
            }
            let histFile = "'" + Quickshell.cachePath("launcher-history.txt") + "'";
            historyWriteProc.command = ["bash", "-c", "printf '%s\\n' '" + name.replace(/'/g, "'\\''") + "' >> " + histFile];
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
            command: []
            property int myGeneration: 0
            property var currentResults: []
            stdout: SplitParser {
                splitMarker: "\n"
                onRead: (data) => {
                    let pathStr = data.trim();
                    if (pathStr !== "") {
                        let isDir = pathStr.endsWith("/");
                        let subStr = isDir ? "Folder" : "File";
                        let icon = "M6 2c-1.1 0-1.99.9-1.99 2L4 20c0 1.1.89 2 1.99 2H18c1.1 0 2-.9 2-2V8l-6-6H6zm7 7V3.5L18.5 9H13z"; // default file

                        if (isDir) {
                            icon = "M10 4H4c-1.1 0-1.99.9-1.99 2L2 18c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V8c0-1.1-.9-2-2-2h-8l-2-2z"; // folder
                        } else {
                            let parts = pathStr.split('.');
                            let ext = parts.length > 1 ? parts.pop().toLowerCase() : "";
                            let images = ["png", "jpg", "jpeg", "gif", "svg", "webp", "bmp"];
                            let videos = ["mp4", "mkv", "avi", "mov", "webm"];
                            let audios = ["mp3", "wav", "ogg", "flac", "m4a"];
                            let texts = ["txt", "md", "csv", "json", "xml", "html", "js", "qml", "sh", "py", "rs", "toml", "yml", "yaml", "ini", "conf"];
                            let archives = ["zip", "tar", "gz", "bz2", "xz", "rar", "7z"];
                            let pdfs = ["pdf"];

                            if (images.includes(ext)) {
                                icon = "M21 19V5c0-1.1-.9-2-2-2H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2zM8.5 13.5l2.5 3.01L14.5 12l4.5 6H5l3.5-4.5z";
                                subStr = "Image";
                            } else if (videos.includes(ext)) {
                                icon = "M18 3v2h-2V3H8v2H6V3H4v18h2v-2h2v2h8v-2h2v2h2V3h-2zM8 17H6v-2h2v2zm0-4H6v-2h2v2zm0-4H6V7h2v2zm10 8h-2v-2h2v2zm0-4h-2v-2h2v2zm0-4h-2V7h2v2z";
                                subStr = "Video";
                            } else if (audios.includes(ext)) {
                                icon = "M12 3v9.28c-.47-.17-.97-.28-1.5-.28C8.01 12 6 14.01 6 16.5S8.01 21 10.5 21c2.31 0 4.2-1.75 4.45-4H15V6h4V3h-7z";
                                subStr = "Audio";
                            } else if (texts.includes(ext)) {
                                icon = "M14 2H6c-1.1 0-1.99.9-1.99 2L4 20c0 1.1.89 2 1.99 2H18c1.1 0 2-.9 2-2V8l-8-6zm2 14H8v-2h8v2zm0-4H8v-2h8v2zm-3-5V3.5L18.5 9H13z";
                                subStr = "Text";
                            } else if (archives.includes(ext)) {
                                icon = "M20 6h-8l-2-2H4c-1.1 0-1.99.9-1.99 2L2 18c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V8c0-1.1-.9-2-2-2zm-6 10H6v-2h8v2zm4-4H6v-2h12v2z";
                                subStr = "Archive";
                            } else if (pdfs.includes(ext)) {
                                icon = "M20 2H8c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2zm-8.5 7.5c0 .83-.67 1.5-1.5 1.5H9v2H7.5V7H10c.83 0 1.5.67 1.5 1.5v1zm5 2c0 .83-.67 1.5-1.5 1.5h-2.5V7H15c.83 0 1.5.67 1.5 1.5v3zm4-3H19v1h1.5V11H19v2h-1.5V7h3v1.5zM9 9.5h1v-1H9v1zM14 11h1V8.5h-1V11z";
                                subStr = "PDF Document";
                            }
                        }

                        fileProc.currentResults.push({
                            title: pathStr,
                            subtitle: subStr,
                            action: "file",
                            target: pathStr,
                            iconPath: icon,
                            completion: isDir ? pathStr : undefined
                        });
                    }
                }
            }
            onRunningChanged: {
                if (running) return;

                if (fileProc.myGeneration === launcherLogic.fileSearchGeneration) {
                    launcherLogic.resultsModel = fileProc.currentResults;
                }

                if (launcherLogic.pendingSearchText !== null) {
                    let next = launcherLogic.pendingSearchText;
                    launcherLogic.pendingSearchText = null;
                    launcherLogic.launchFileSearch(next);
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
                        // Strip all characters except numbers, decimal point, and math operators
                        let sanitizedExpr = expr.replace(/[^0-9.\-+*/()%]/g, '');
                        // eslint-disable-next-line
                        let evalRes = eval(sanitizedExpr);
                        res = evalRes !== undefined && evalRes !== null ? String(evalRes) : "";
                    }
                } catch(e) {
                    res = "Error";
                }
                let isValidResult = res !== "" && res !== "Error";
                launcherLogic.resultsModel = [{
                    title: res !== "" ? res : "Type an expression",
                    subtitle: "Calculator",
                    action: "copy",
                    target: res,
                    iconPath: "M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm-6 16h-2v-2h2v2zm0-4h-2v-2h2v2zm0-4h-2V9h2v2zm-4 8H7v-2h2v2zm0-4H7v-2h2v2zm0-4H7V9h2v2zm8 8h-2v-4h2v4zm0-6h-2V9h2v2z",
                    completion: isValidResult ? "=" + res : undefined
                }];
            } else if (text.startsWith("?")) {
                let query = text.substring(1).trim();
                launcherLogic.resultsModel = [{
                    title: query !== "" ? "Search for: " + query : "Type a search query",
                    subtitle: "Google Search",
                    action: "search",
                    target: query,
                    iconPath: "M15.5 14h-.79l-.28-.27A6.471 6.471 0 0016 9.5 6.5 6.5 0 109.5 16c1.61 0 3.09-.59 4.23-1.57l.27.28v.79l5 4.99L20.49 19l-4.99-5zm-6 0C7.01 14 5 11.99 5 9.5S7.01 5 9.5 5 14 7.01 14 9.5 11.99 14 9.5 14z"
                }];
            } else if (text.startsWith("$")) {
                let cmd = text.substring(1).trim();
                launcherLogic.resultsModel = [{
                    title: cmd !== "" ? "Run: " + cmd : "Type a command",
                    subtitle: "Execute Shell Command",
                    action: "shell",
                    target: cmd,
                    iconPath: "M20 4H4c-1.11 0-2 .9-2 2v12c0 1.1.89 2 2 2h16c1.1 0 2-.9 2-2V6c0-1.1-.89-2-2-2zm-8.5 11H19v2h-7.5v-2zM5.5 15l-1.41-1.41L8.67 9 4.09 4.41 5.5 3l6 6-6 6z"
                }];
            } else if (text.startsWith(":")) {
                let cmd = text.substring(1).trim().toLowerCase();
                let sysActions = [
                    { title: "Lock Screen", subtitle: "System", action: "shell", target: "systemctl --user restart swaylock.service", iconPath: "M18 8h-1V6c0-2.76-2.24-5-5-5S7 3.24 7 6v2H6c-1.1 0-2 .9-2 2v10c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V10c0-1.1-.9-2-2-2z" },
                    { title: "Suspend", subtitle: "System", action: "shell", target: "systemctl suspend", iconPath: "M12 22c5.52 0 10-4.48 10-10S17.52 2 12 2 2 6.48 2 12s4.48 10 10 10zm1-17.93c3.94.49 7 3.85 7 7.93s-3.05 7.44-7 7.93V4.07z" },
                    { title: "Logout", subtitle: "System", action: "shell", target: "loginctl terminate-user $USER", iconPath: "M17 7l-1.41 1.41L18.17 11H8v2h10.17l-2.58 2.58L17 17l5-5zM4 5h8V3H4c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h8v-2H4V5z" },
                    { title: "Reboot", subtitle: "System", action: "shell", target: "systemctl reboot", iconPath: "M17.65 6.35C16.2 4.9 14.21 4 12 4c-4.42 0-7.99 3.58-7.99 8s3.57 8 7.99 8c3.73 0 6.84-2.55 7.73-6h-2.08c-.82 2.33-3.04 4-5.65 4-3.31 0-6-2.69-6-6s2.69-6 6-6c1.66 0 3.14.69 4.22 1.78L13 11h7V4l-2.35 2.35z" },
                    { title: "Shutdown", subtitle: "System", action: "shell", target: "systemctl poweroff", iconPath: "M13 3h-2v10h2V3zm4.83 2.17l-1.42 1.42C17.99 7.86 19 9.81 19 12c0 3.87-3.13 7-7 7s-7-3.13-7-7c0-2.19 1.01-4.14 2.58-5.42L6.17 5.17C4.23 6.82 3 9.26 3 12c0 4.97 4.03 9 9 9s9-4.03 9-9c0-2.74-1.23-5.18-3.17-6.83z" }
                ];
                if (cmd !== "") {
                    sysActions = sysActions.filter(a => a.title.toLowerCase().includes(cmd));
                }
                launcherLogic.resultsModel = sysActions;
            } else if (text.startsWith("/") || text.startsWith("~")) {
                launcherLogic.debouncedQuery = text;
                fileSearchDebounce.restart();
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
                    launcherLogic.resultsModel = top.map(a => ({
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
                    launcherLogic.resultsModel = top.map(a => ({
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
                    Quickshell.execDetached(["xdg-open", "https://www.google.com/search?q=" + encodeURIComponent(current.target)]);
                    hideLauncher();
                }
            } else if (current.action === "file") {
                Quickshell.execDetached(["xdg-open", current.target]);
                hideLauncher();
            } else if (current.action === "copy") {
                if (current.target !== "" && current.target !== "Error") {
                    Quickshell.execDetached(["wl-copy", current.target]);
                    hideLauncher();
                }
            }
        }

        function completeCurrent() {
            if (resultsModel.length === 0) return;
            let current = resultsModel[resultsList.currentIndex];
            if (!current) return;
            if (current.completion === undefined || current.completion === null || current.completion === "") return;

            searchInput.text = current.completion;
            searchInput.cursorPosition = searchInput.text.length;
        }

        function hideLauncher() {
            root.visible = false;
        }
    }
}
