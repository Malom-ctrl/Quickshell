import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Io

Rectangle {
    id: root
    width: layout.implicitWidth + Globals.customValue(themeScope + ".layout", "padding", Globals.themeVars.spacingHuge)
    height: Globals.customValue(themeScope, "height", 40)
    radius: Globals.customValue(themeScope, "radius", Globals.themeVars.borderRadiusHuge)
    color: (mouseArea.containsMouse || popup.isActive) ? Globals.customValue(themeScope, "hoverColor", Globals.themeVars.Secondary50) : Globals.customValue(themeScope, "color", Globals.themeVars.Secondary25)

    Behavior on color { ColorAnimation { duration: 150 } }

    property string themeScope: "topbar.AutoresticWidget"

    property string cronActiveState: "unknown"
    property string forceActiveState: "unknown"
    property string cronResult: "unknown"
    property string forceResult: "unknown"
    property bool isRunning: (cronActiveState === "activating" || cronActiveState === "active" || forceActiveState === "activating" || forceActiveState === "active")

    property string lastLogLine: ""
    property bool hasLogWarning: false
    property bool isFailed: (cronActiveState === "failed" || forceActiveState === "failed") || hasLogWarning

    property bool isBackingUp: false

    property string serviceHealth: {
        if (isFailed) return "Failed/Warning";
        if (cronResult === "success" || forceResult === "success") return "OK";
        return "Unknown";
    }

    property string serviceStateDisplay: {
        if (!isRunning) return "Inactive";
        if (isBackingUp) return "Backing up data";
        return "Checking";
    }

    property string lastBackupTimeStr: "Never"
    property var lastBackupDate: null

    function timeAgo(date) {
        if (!date) return "Never";
        const seconds = Math.floor((new Date() - date) / 1000);

        let interval = seconds / 31536000;
        if (interval > 1) return Math.floor(interval) + " years ago";
        interval = seconds / 2592000;
        if (interval > 1) return Math.floor(interval) + " months ago";
        interval = seconds / 86400;
        if (interval > 1) return Math.floor(interval) + " days ago";
        interval = seconds / 3600;
        if (interval > 1) return Math.floor(interval) + " hours ago";
        interval = seconds / 60;
        if (interval > 1) return Math.floor(interval) + " minutes ago";
        return Math.floor(seconds) + " seconds ago";
    }

    function formatBackupTime() {
        if (!lastBackupDate) return "Never";
        return timeAgo(lastBackupDate);
        // return lastBackupTimeStr + "\n" + timeAgo(lastBackupDate);
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: {
            root.lastBackupFormatted = formatBackupTime();
        }
    }
    property string lastBackupFormatted: formatBackupTime()

    function refreshLastBackupTime() {
        if (!journalProc.running) {
            journalProc.running = true;
        }
    }

    Process {
        id: journalProc
        command: ["bash", "-c", "journalctl --user -t autorestic -r -o short-unix | grep -m 1 'Done'"]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: (data) => {
                let line = data.trim();
                if (!line) return;
                let match = line.match(/^(\d+\.\d+)/);
                if (match) {
                    let epochSeconds = parseFloat(match[1]);
                    let d = new Date(epochSeconds * 1000);
                    if (!isNaN(d.getTime())) {
                        root.lastBackupDate = d;
                        let months = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];
                        root.lastBackupTimeStr = months[d.getMonth()] + " " + d.getDate().toString().padStart(2,'0') + " " + d.toTimeString().split(' ')[0];
                        root.lastBackupFormatted = formatBackupTime();
                    }
                }
            }
        }
    }

    property string previousActiveState: "unknown"

    Process {
        id: stateProc
        command: ["bash", "-c", "systemctl --user show autorestic-cron.service autorestic-force.service --property=Id,ActiveState,SubState,Result"]
        property string currentId: ""
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: (line) => {
                line = line.trim();
                if (line.startsWith("Id=")) {
                    stateProc.currentId = line.substring(3);
                } else if (line.startsWith("ActiveState=")) {
                    let val = line.substring(12);
                    if (stateProc.currentId === "autorestic-cron.service") root.cronActiveState = val;
                    else if (stateProc.currentId === "autorestic-force.service") root.forceActiveState = val;
                } else if (line.startsWith("Result=")) {
                    let val = line.substring(7);
                    if (stateProc.currentId === "autorestic-cron.service") root.cronResult = val;
                    else if (stateProc.currentId === "autorestic-force.service") root.forceResult = val;
                }
            }
        }
        onExited: {
            if (isRunning) {
                root.hasLogWarning = false;
                root.lastLogLine = "";
            } else {
                root.isBackingUp = false;
            }
            let isCurrentActive = root.isRunning ? "active" : "inactive";
            if (previousActiveState === "active" && isCurrentActive === "inactive") {
                refreshLastBackupTime();
            }
            previousActiveState = isCurrentActive;
        }
    }

    Component.onCompleted: {
        stateProc.running = true
        refreshLastBackupTime();
    }

    Timer {
        id: debounceTimer
        interval: 100
        repeat: false
        onTriggered: {
            stateProc.running = false;
            stateProc.running = true;
            refreshLastBackupTime();
        }
    }

    Process {
        id: dbusMonitor
        command: [
            "bash",
            "-c",
            "dbus-monitor --session \"type='signal',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged',path='/org/freedesktop/systemd1/unit/autorestic_2dcron_2eservice'\" \"type='signal',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged',path='/org/freedesktop/systemd1/unit/autorestic_2dforce_2eservice'\""
        ]
        running: true
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: (data) => {
                debounceTimer.restart();
            }
        }
    }

    Process {
        id: logMonitor
        command: ["bash", "-c", "journalctl --user -t autorestic -f -n 15 --no-pager"]
        running: true
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: (data) => {
                let line = data.trim();
                if (line.match(/error|warning|fatal/i)) {
                    root.hasLogWarning = true;
                    root.lastLogLine = line;
                }
                if (line.includes("Backing up location")) {
                    root.isBackingUp = true;
                }
                if (line.includes("Done") || line.includes("Skipping")) {
                    root.isBackingUp = false;
                    root.hasLogWarning = false;
                }
            }
        }
    }

    Process {
        id: forceBackupProc
        command: ["systemd-run", "--user", "--unit=autorestic-force", "--collect", "/usr/bin/autorestic", "backup", "-a"]
    }

    function forceBackup() {
        forceBackupProc.running = false;
        forceBackupProc.running = true;
    }

    property real shapeRadius: Globals.customValue(themeScope, "radius", Globals.themeVars.borderRadiusHuge)
    property real perimeter: 2 * (root.width - 2 * shapeRadius) + 2 * Math.PI * shapeRadius

    // We can show a spinning animation when running
    Shape {
        id: borderShape
        anchors.fill: parent
        visible: root.isRunning
        antialiasing: true
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            id: shapePath
            fillColor: "transparent"
            strokeColor: (mouseArea.containsMouse || popup.isActive) ? Globals.customValue(themeScope + ".indicator", "hoverColor", Globals.themeVars.White) : Globals.customValue(themeScope + ".indicator", "color", Globals.themeVars.Secondary)
            strokeWidth: Globals.customValue(themeScope + ".indicator", "width", Globals.themeVars.borderWidthMedium)
            capStyle: ShapePath.RoundCap
            strokeStyle: ShapePath.DashLine
            dashPattern: [40, root.perimeter]
            startX: root.width / 2; startY: 0
            PathLine { x: root.width - root.shapeRadius; y: 0 }
            PathArc { x: root.width; y: root.shapeRadius; radiusX: root.shapeRadius; radiusY: root.shapeRadius; direction: PathArc.Clockwise }
            PathLine { x: root.width; y: root.height - root.shapeRadius }
            PathArc { x: root.width - root.shapeRadius; y: root.height; radiusX: root.shapeRadius; radiusY: root.shapeRadius; direction: PathArc.Clockwise }
            PathLine { x: root.shapeRadius; y: root.height }
            PathArc { x: 0; y: root.height - root.shapeRadius; radiusX: root.shapeRadius; radiusY: root.shapeRadius; direction: PathArc.Clockwise }
            PathLine { x: 0; y: root.shapeRadius }
            PathArc { x: root.shapeRadius; y: 0; radiusX: root.shapeRadius; radiusY: root.shapeRadius; direction: PathArc.Clockwise }
            PathLine { x: root.width / 2; y: 0 }
        }
        NumberAnimation {
            target: shapePath
            property: "dashOffset"
            from: root.perimeter + 40
            to: 0
            duration: 1500
            loops: Animation.Infinite
            running: root.isRunning
            easing.type: Easing.InOutSine
        }
    }

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: Globals.customValue(themeScope + ".layout", "spacing", Globals.themeVars.spacingMedium)

        Icon {
            width: Globals.customValue(themeScope + ".icon", "width", 18)
            height: Globals.customValue(themeScope + ".icon", "height", 18)
            // Backup/Sync icon
            path: "M19.35 10.04C18.67 6.59 15.64 4 12 4 9.11 4 6.6 5.64 5.35 8.04A5.994 5.994 0 0 0 0 14c0 3.31 2.69 6 6 6h13c2.76 0 5-2.24 5-5 0-2.64-2.05-4.78-4.65-4.96zM19 18H6c-2.21 0-4-1.79-4-4 0-2.05 1.53-3.76 3.56-3.97l1.07-.11.5-.95C8.08 7.14 9.94 6 12 6c2.62 0 4.88 1.86 5.39 4.43l.3 1.5 1.53.11A2.98 2.98 0 0 1 22 15c0 1.65-1.35 3-3 3zM13 9h-2v4l3.5 2.13.75-1.23-2.25-1.34V9z"
            color: {
                if (root.isFailed || root.hasLogWarning) {
                    return Globals.customValue(themeScope + ".icon", "errorColor", Globals.themeVars.Warning)
                } else if (root.isBackingUp) {
                    return Globals.customValue(themeScope + ".icon", "runningColor", Globals.themeVars.Secondary)
                } else {
                    return Globals.customValue(themeScope + ".icon", "color", Globals.themeVars.White)
                }
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

    AutoresticPopup {
        id: popup
        isActive: false
        widgetRoot: root
        anchor.item: root
        anchor.rect.x: root.width / 2
        anchor.rect.y: 0
    }
}
