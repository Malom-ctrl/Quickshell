import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Io

Rectangle {
    id: root
    height: 40
    color: Globals.activeColors.Black // Primary surface
    implicitWidth: layout.implicitWidth + 8
    radius: 20

    property real cpuUsage: 0
    property var perCoreUsage: []
    property var cpuTopProcs: []
    property bool cpuDetailsLoading: true
    property bool cpuPopupOpen: false

    property real ramUsage: 0
    property string ramText: "0%"
    property real memTotalGB: 0
    property real memUsedGB: 0
    property var ramTopProcs: []
    property bool ramDetailsLoading: true
    property bool ramPopupOpen: false

    property string tempText: "0°C"
    property real tempC: 0

    property string netRxText: "0 B/s"
    property string netTxText: "0 B/s"
    property real netTotalRx: 0
    property real netTotalTx: 0

    property var lastCpu: null
    property var lastNet: null
    property double lastTime: 0

    function formatBytes(bytes) {
        if (bytes === 0 || isNaN(bytes)) return "0 B";
        const k = 1024;
        const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
        const i = Math.floor(Math.log(bytes) / Math.log(k));
        return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
    }

    // 1. Fast Poll (Main icons, cpu cores, total RAM, temp, net)
    property string fastBashScript: `
cpu_stat=$(grep '^cpu' /proc/stat | tr '\n' ',' | sed 's/,$//')
mem=$(awk '/MemTotal:/ {t=$2} /MemAvailable:/ {a=$2} END {printf "%s;%s", t, a}' /proc/meminfo)
temp=$(
  for f in /sys/class/hwmon/hwmon*/temp*_input /sys/class/thermal/thermal_zone*/temp; do
    [ -r "$f" ] || continue
    v=$(cat "$f" 2>/dev/null)
    [ -n "$v" ] && [ "$v" -gt 0 ] 2>/dev/null && { echo "$v"; break; }
  done
)
[ -z "$temp" ] && temp=0
net=$(awk '/:/ && !/lo:/ {rx+=$2; tx+=$10} END {printf "%s;%s", rx+0, tx+0}' /proc/net/dev)
echo "SYSINFO@@$cpu_stat@@$mem@@$temp@@$net"
`

    Timer {
        interval: 2000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            fastSysProc.running = false
            fastSysProc.running = true
        }
    }

    Process {
        id: fastSysProc
        command: ["bash", "-c", root.fastBashScript]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: (data) => {
                if (data.startsWith("SYSINFO@@")) {
                    let parts = data.substring(9).split("@@");
                    if (parts.length >= 4) {
                        let now = Date.now();
                        let dt = (now - root.lastTime) / 1000.0;
                        if (root.lastTime === 0) dt = 0;
                        root.lastTime = now;

                        // CPU
                        if (!root.lastCpu) root.lastCpu = {};
                        let cpuCoresRaw = parts[0].split(",");
                        let newPerCoreUsage = [];
                        for (let i = 0; i < cpuCoresRaw.length; i++) {
                            let cParts = cpuCoresRaw[i].trim().split(/\s+/);
                            if (cParts.length >= 5) {
                                let cName = cParts[0];
                                let user = parseInt(cParts[1]);
                                let nice = parseInt(cParts[2]);
                                let sys = parseInt(cParts[3]);
                                let idle = parseInt(cParts[4]);
                                let total = user + nice + sys + idle;
                                let active = user + nice + sys;

                                if (root.lastCpu[cName]) {
                                    let dTotal = total - root.lastCpu[cName].total;
                                    let dActive = active - root.lastCpu[cName].active;
                                    let usage = dTotal > 0 ? (dActive / dTotal) * 100 : 0;

                                    if (cName === "cpu") {
                                        root.cpuUsage = usage;
                                    } else {
                                        newPerCoreUsage.push({name: cName.toUpperCase(), usage: usage});
                                    }
                                }
                                root.lastCpu[cName] = {total: total, active: active};
                            }
                        }
                        root.perCoreUsage = newPerCoreUsage;

                        // RAM
                        let ramParts = parts[1].split(";");
                        if (ramParts.length === 2) {
                            let totalKB = parseInt(ramParts[0]);
                            let availableKB = parseInt(ramParts[1]);
                            if (totalKB > 0 && !isNaN(availableKB)) {
                                let usedKB = totalKB - availableKB;
                                root.ramUsage = (usedKB / totalKB) * 100;
                                root.ramText = Math.round(root.ramUsage) + "%";
                                root.memTotalGB = totalKB / 1024 / 1024;
                                root.memUsedGB = usedKB / 1024 / 1024;
                            }
                        }

                        // TEMP
                        let tempRaw = parseInt(parts[2]);
                        if (!isNaN(tempRaw) && tempRaw > 0) {
                            root.tempC = tempRaw / 1000;
                            root.tempText = Math.round(root.tempC) + "°C";
                        } else {
                            root.tempC = 0;
                            root.tempText = "N/A";
                        }

                        // NET
                        let netParts = parts[3].split(";");
                        if (netParts.length === 2) {
                            let rx = parseInt(netParts[0]);
                            let tx = parseInt(netParts[1]);
                            if (root.lastNet && dt > 0) {
                                let dRx = rx - root.lastNet.rx;
                                let dTx = tx - root.lastNet.tx;

                                let rxRate = Math.max(0, dRx / dt);
                                let txRate = Math.max(0, dTx / dt);

                                root.netRxText = formatBytes(rxRate) + "/s";
                                root.netTxText = formatBytes(txRate) + "/s";
                                root.netTotalRx = rx;
                                root.netTotalTx = tx;
                            }
                            root.lastNet = {rx: rx, tx: tx};
                        }
                    }
                }
            }
        }
    }

    // 2. CPU Details Polling
    Timer {
        id: cpuDetailsTimer
        interval: 3000; running: root.cpuPopupOpen; repeat: true
        onTriggered: {
            cpuDetailsProc.running = false
            cpuDetailsProc.running = true
        }
    }
    onCpuPopupOpenChanged: {
        if (cpuPopupOpen) {
            root.cpuDetailsLoading = true;
            cpuDetailsProc.running = false;
            cpuDetailsProc.running = true;
        }
    }

    Process {
        id: cpuDetailsProc
        command: ["bash", "-c", "ps -eo comm,%cpu --sort=-%cpu | head -n 6 | tail -n 5 | awk '{print $1\"|\"$2}' | paste -sd ';' -"]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: (data) => {
                let procs = data.trim().split(";");
                let arr = [];
                for (let i = 0; i < procs.length; i++) {
                    if (procs[i] !== "") {
                        let p = procs[i].split("|");
                        if (p.length === 2) {
                            arr.push({name: p[0], usage: parseFloat(p[1])});
                        }
                    }
                }
                root.cpuTopProcs = arr;
                root.cpuDetailsLoading = false;
            }
        }
    }

    // 3. RAM Details Polling
    Timer {
        id: ramDetailsTimer
        interval: 3000; running: root.ramPopupOpen; repeat: true
        onTriggered: {
            ramDetailsProc.running = false
            ramDetailsProc.running = true
        }
    }
    onRamPopupOpenChanged: {
        if (ramPopupOpen) {
            root.ramDetailsLoading = true;
            ramDetailsProc.running = false;
            ramDetailsProc.running = true;
        }
    }

    Process {
        id: ramDetailsProc
        // rss is in KB
        command: ["bash", "-c", "ps -eo comm,rss --sort=-rss | head -n 6 | tail -n 5 | awk '{print $1\"|\"$2}' | paste -sd ';' -"]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: (data) => {
                let procs = data.trim().split(";");
                let arr = [];
                for (let i = 0; i < procs.length; i++) {
                    if (procs[i] !== "") {
                        let p = procs[i].split("|");
                        if (p.length === 2) {
                            arr.push({name: p[0], usageGB: parseFloat(p[1]) / 1024 / 1024});
                        }
                    }
                }
                root.ramTopProcs = arr;
                root.ramDetailsLoading = false;
            }
        }
    }

    component SystemInfoItem: Item {
        id: infoItem
        implicitWidth: itemLayout.implicitWidth + 24
        implicitHeight: 40

        property string iconPath: ""
        property color iconColor: Globals.activeColors.White
        property string text: ""
        property color textColor: Globals.activeColors.White
        property string tooltipTitle: ""
        property Component tooltipContent: null

        signal popupOpened()
        signal popupClosed()

        Rectangle {
            anchors.fill: parent
            color: ma.containsMouse ? Globals.activeColors.Secondary25 : "transparent"
            radius: 20
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        RowLayout {
            id: itemLayout
            anchors.centerIn: parent
            spacing: 6

            Icon {
                width: 20; height: 20
                path: infoItem.iconPath
                color: infoItem.iconColor
            }
            Text {
                text: infoItem.text
                color: infoItem.textColor
                font.pixelSize: 15
                font.weight: Font.DemiBold
                // font.bold: true
            }
        }

        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            // cursorShape: Qt.PointingHandCursor
            onEntered: tooltipTimer.restart()
            onExited: {
                tooltipTimer.stop()
                infoPopup.isActive = false
            }
        }

        Timer {
            id: tooltipTimer
            interval: 250
            onTriggered: infoPopup.isActive = true
        }

        PopupWindow {
            id: infoPopup
            property bool isActive: false
            visible: isActive || openProgress > 0.0

            onIsActiveChanged: {
                if (isActive) infoItem.popupOpened();
                else infoItem.popupClosed();
            }

            property real openProgress: isActive ? 1.0 : 0.0
            Behavior on openProgress {
                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
            }
            onOpenProgressChanged: {
                if (openProgress === 0.0 && !isActive) visible = false;
                else if (isActive && !visible) visible = true;
            }

            anchor {
                item: infoItem
                edges: Edges.Bottom
                gravity: Edges.Bottom
                margins.top: Globals.popupMargin
            }

            implicitWidth: popupLayout.implicitWidth + 32 + (2 * Globals.popupScreenPadding)
            implicitHeight: popupLayout.implicitHeight + 32
            color: "transparent"

            Item {
                width: parent.width - (2 * Globals.popupScreenPadding)
                height: parent.height
                anchors.horizontalCenter: parent.horizontalCenter
                scale: 0.9 + (0.1 * infoPopup.openProgress)
                opacity: infoPopup.openProgress
                transformOrigin: Item.Top

                Rectangle {
                    anchors.fill: parent
                    color: Globals.activeColors.Black
                    radius: 16
                    border.color: Globals.activeColors.Secondary10
                    border.width: 1

                    ColumnLayout {
                        id: popupLayout
                        anchors.centerIn: parent
                        spacing: 12

                        Text {
                            text: infoItem.tooltipTitle
                            color: Globals.activeColors.White
                            font.pixelSize: 14
                            font.bold: true
                        }

                        Loader {
                            sourceComponent: infoItem.tooltipContent
                            visible: infoItem.tooltipContent !== null
                            Layout.fillWidth: true
                        }
                    }
                }
            }
        }
    }

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 0

        SystemInfoItem {
            iconPath: "M16,3L12,7H15V14H17V7H20M8,21L12,17H9V10H7V17H4"
            text: root.netRxText + " ↓   " + root.netTxText + " ↑"
            tooltipTitle: "Network Traffic"

            tooltipContent: Component {
                ColumnLayout {
                    spacing: 8
                    RowLayout {
                        spacing: 16
                        Text { text: "Total RX"; color: Globals.activeColors.SecondaryLight; font.pixelSize: 12; Layout.fillWidth: true }
                        Text { text: root.formatBytes(root.netTotalRx); color: Globals.activeColors.White; font.pixelSize: 12; font.family: "monospace" }
                    }
                    RowLayout {
                        spacing: 16
                        Text { text: "Total TX"; color: Globals.activeColors.SecondaryLight; font.pixelSize: 12; Layout.fillWidth: true }
                        Text { text: root.formatBytes(root.netTotalTx); color: Globals.activeColors.White; font.pixelSize: 12; font.family: "monospace" }
                    }
                }
            }
        }

        SystemInfoItem {
            iconPath: "M6,4V6H4V8H6V10H4V12H6V14H4V16H6V18H8V20H10V18H12V20H14V18H16V20H18V18H20V16H22V14H20V12H22V10H20V8H22V6H20V4H18V2H16V4H14V2H12V4H10V2H8V4H6ZM8,6H16V18H8V6ZM10,8V16H14V8H10Z"
            text: Math.round(root.cpuUsage) + "%"
            tooltipTitle: "CPU Usage (" + Math.round(root.cpuUsage) + "%)"

            onPopupOpened: root.cpuPopupOpen = true
            onPopupClosed: root.cpuPopupOpen = false

            tooltipContent: Component {
                ColumnLayout {
                    spacing: 12
                    // Per-core grid
                    GridLayout {
                        columns: 2
                        columnSpacing: 16
                        rowSpacing: 8
                        Repeater {
                            model: root.perCoreUsage
                            RowLayout {
                                spacing: 8
                                Text { text: modelData.name; color: Globals.activeColors.SecondaryLight; font.pixelSize: 12; Layout.preferredWidth: 40; font.family: "monospace" }
                                Rectangle {
                                    Layout.preferredWidth: 60
                                    Layout.preferredHeight: 6
                                    radius: 3
                                    color: Globals.activeColors.Secondary25
                                    Rectangle {
                                        width: parent.width * Math.max(0, Math.min(1, modelData.usage / 100))
                                        height: parent.height
                                        radius: 3
                                        color: Globals.activeColors.Secondary
                                        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                                    }
                                }
                                Text { text: Math.round(modelData.usage) + "%"; color: Globals.activeColors.White; font.pixelSize: 12; font.family: "monospace"; Layout.preferredWidth: 32; horizontalAlignment: Text.AlignRight }
                            }
                        }
                    }

                    // Top procs
                    ColumnLayout {
                        spacing: 8
                        visible: !root.cpuDetailsLoading
                        Text { text: "Top Processes"; color: Globals.activeColors.White; font.pixelSize: 13; font.bold: true; Layout.topMargin: 4 }
                        Repeater {
                            model: root.cpuTopProcs
                            RowLayout {
                                spacing: 8
                                Text { text: modelData.name; color: Globals.activeColors.SecondaryLight; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight; Layout.preferredWidth: 100 }
                                Rectangle {
                                    Layout.preferredWidth: 60
                                    Layout.preferredHeight: 6
                                    radius: 3
                                    color: Globals.activeColors.Secondary25
                                    Rectangle {
                                        width: parent.width * Math.min(1, modelData.usage / 100)
                                        height: parent.height
                                        radius: 3
                                        color: Globals.activeColors.Warning
                                        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                                    }
                                }
                                Text { text: modelData.usage.toFixed(1) + "%"; color: Globals.activeColors.White; font.pixelSize: 12; font.family: "monospace"; Layout.preferredWidth: 40; horizontalAlignment: Text.AlignRight }
                            }
                        }
                    }

                    // Loading indicator
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 24
                        visible: root.cpuDetailsLoading
                        Rectangle {
                            width: 100; height: 4
                            radius: 2; color: Globals.activeColors.Secondary25
                            clip: true
                            anchors.centerIn: parent
                            Rectangle {
                                id: indBar1
                                width: 30; height: 4; radius: 2; color: Globals.activeColors.Secondary
                                SequentialAnimation {
                                    running: root.cpuDetailsLoading; loops: Animation.Infinite
                                    NumberAnimation { target: indBar1; property: "x"; from: -30; to: 100; duration: 800; easing.type: Easing.InOutQuad }
                                }
                            }
                        }
                    }
                }
            }
        }

        SystemInfoItem {
            iconPath: "M2,5V19H22V5H2ZM4,7H20V17H4V7ZM6,9V15H8V9H6ZM10,9V15H12V9H10ZM14,9V15H16V9H14ZM18,9V15H20V9H18Z"
            text: root.ramText
            tooltipTitle: "Memory Usage"

            onPopupOpened: root.ramPopupOpen = true
            onPopupClosed: root.ramPopupOpen = false

            tooltipContent: Component {
                ColumnLayout {
                    spacing: 12

                    // Overall bar
                    ColumnLayout {
                        spacing: 8
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "Usage"; color: Globals.activeColors.SecondaryLight; font.pixelSize: 12 }
                            Item { Layout.fillWidth: true; Layout.minimumWidth: 16 }
                            Text {
                                text: root.memUsedGB.toFixed(1) + " GB / " + root.memTotalGB.toFixed(1) + " GB"
                                color: Globals.activeColors.White
                                font.pixelSize: 12
                                font.bold: true
                                font.family: "monospace"
                            }
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 6
                            radius: 3
                            color: Globals.activeColors.Secondary25
                            Rectangle {
                                width: parent.width * (root.memTotalGB > 0 ? (root.memUsedGB / root.memTotalGB) : 0)
                                height: parent.height
                                radius: 3
                                color: Globals.activeColors.Secondary
                                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                            }
                        }
                    }

                    // Top procs
                    ColumnLayout {
                        spacing: 8
                        visible: !root.ramDetailsLoading
                        Text { text: "Top Processes"; color: Globals.activeColors.White; font.pixelSize: 13; font.bold: true; Layout.topMargin: 4 }
                        Repeater {
                            model: root.ramTopProcs
                            RowLayout {
                                spacing: 8
                                Text { text: modelData.name; color: Globals.activeColors.SecondaryLight; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight; Layout.preferredWidth: 100 }
                                Rectangle {
                                    Layout.preferredWidth: 60
                                    Layout.preferredHeight: 6
                                    radius: 3
                                    color: Globals.activeColors.Secondary25
                                    Rectangle {
                                        width: parent.width * (root.memTotalGB > 0 ? (modelData.usageGB / root.memTotalGB) : 0)
                                        height: parent.height
                                        radius: 3
                                        color: Globals.activeColors.Secondary
                                        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                                    }
                                }
                                Text {
                                    text: modelData.usageGB >= 1.0 ? modelData.usageGB.toFixed(1) + " GB" : (modelData.usageGB * 1024).toFixed(0) + " MB"
                                    color: Globals.activeColors.White; font.pixelSize: 12; font.family: "monospace"; Layout.preferredWidth: 50; horizontalAlignment: Text.AlignRight
                                }
                            }
                        }
                    }

                    // Loading indicator
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 24
                        visible: root.ramDetailsLoading
                        Rectangle {
                            width: 100; height: 4
                            radius: 2; color: Globals.activeColors.Secondary25
                            clip: true
                            anchors.centerIn: parent
                            Rectangle {
                                id: indBar2
                                width: 30; height: 4; radius: 2; color: Globals.activeColors.Secondary
                                SequentialAnimation {
                                    running: root.ramDetailsLoading; loops: Animation.Infinite
                                    NumberAnimation { target: indBar2; property: "x"; from: -30; to: 100; duration: 800; easing.type: Easing.InOutQuad }
                                }
                            }
                        }
                    }
                }
            }
        }

        SystemInfoItem {
            property bool isHot: root.tempC > 80
            iconPath: "M12,2A3,3 0 0,1 15,5V13.27A5,5 0 0,1 17,17A5,5 0 0,1 12,22A5,5 0 0,1 7,17A5,5 0 0,1 9,13.27V5A3,3 0 0,1 12,2ZM12,4A1,1 0 0,0 11,5V14.15L10.22,14.59A3,3 0 0,0 9,17A3,3 0 0,0 12,20A3,3 0 0,0 15,17A3,3 0 0,0 13.78,14.59L13,14.15V5A1,1 0 0,0 12,4ZM12,11A1,1 0 0,1 13,12V14.61C13.56,15.11 13.92,15.82 13.92,16.63C13.92,17.7 13.06,18.56 12,18.56C10.94,18.56 10.08,17.7 10.08,16.63C10.08,15.82 10.44,15.11 11,14.61V12A1,1 0 0,1 12,11Z"
            iconColor: isHot ? Globals.activeColors.Warning : Globals.activeColors.White
            textColor: isHot ? Globals.activeColors.Warning : Globals.activeColors.White
            text: root.tempText
            tooltipTitle: "Temperature"

            tooltipContent: Component {
                ColumnLayout {
                    spacing: 12
                    RowLayout {
                        spacing: 8
                        Text { text: "Current"; color: Globals.activeColors.SecondaryLight; font.pixelSize: 12; Layout.fillWidth: true }
                        Text { text: root.tempC > 0 ? root.tempC.toFixed(1) + " °C" : "N/A"; color: Globals.activeColors.White; font.pixelSize: 12; font.family: "monospace"; font.bold: true }
                    }
                }
            }
        }


    }
}
