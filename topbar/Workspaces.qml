import QtQuick
import QtQuick.Layouts
import Quickshell.Io

RowLayout {
    id: root
    property string themeScope: "topbar.Workspaces"

    spacing: Globals.customValue(themeScope, "spacing", Globals.themeVars.spacingMedium)

    property var workspacesList: []
    property string outputName: ""

    Component.onCompleted: {
        niriProc.running = true;
        eventStreamProc.running = true;
    }

    Process {
        id: eventStreamProc
        command: ["bash", "-c", "niri msg -j event-stream || echo ''"]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: (data) => {
                // On any event from niri, refresh workspaces.
                // You can also parse specific events to be more efficient,
                // but re-running the fetch on any event stream output works well.
                try {
                    let ev = JSON.parse(data);
                    if (ev.WorkspacesChanged && ev.WorkspacesChanged.workspaces) {
                        updateWorkspaces(ev.WorkspacesChanged.workspaces);
                    } else {
                        niriProc.running = false;
                        niriProc.running = true;
                    }
                } catch(e) {
                    niriProc.running = false;
                    niriProc.running = true;
                }
            }
        }
    }

    function updateWorkspaces(ws) {
        if (!Array.isArray(ws))
            return;

        let filtered = ws;
        let outName = root.outputName;

        if (!outName && ws.length > 0) {
            let focusedWs = ws.find(w => w.is_focused);
            if (focusedWs)
                outName = focusedWs.output;
        }

        if (outName) {
            filtered = ws.filter(w => w.output === outName);
        }

        filtered = filtered.slice().sort((a, b) => {
            const ai = a.idx ?? 0;
            const bi = b.idx ?? 0;
            return ai - bi;
        });

        root.workspacesList = filtered;
    }

    Process {
        id: niriProc
        command: ["bash", "-c", "niri msg -j workspaces || echo '[]'"]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: (data) => {
                try {
                    let ws = JSON.parse(data)
                    updateWorkspaces(ws);
                } catch(e) {}
            }
        }
    }

    Process {
        id: focusProc
        command: []
    }

    Repeater {
        model: root.workspacesList.length > 0 ? root.workspacesList : [
            {id: 1, name: "1", is_active: true, is_focused: true},
            {id: 2, name: "2", is_active: false, is_focused: false},
            {id: 3, name: "3", is_active: false, is_focused: false}
        ]

        Rectangle {
            id: workspacePill
            property var ws: modelData
            property bool isFocused: ws.is_focused || false
            property bool isActive: ws.is_active || false

            width: isFocused ? Globals.customValue(themeScope + ".pill", "widthFocused", 48) : (isActive ? Globals.customValue(themeScope + ".pill", "widthActive", 24) : Globals.customValue(themeScope + ".pill", "widthInactive", 12))
            height: Globals.customValue(themeScope + ".pill", "height", 12)
            radius: Globals.customValue(themeScope + ".pill", "radius", 6)

            color: isFocused ? Globals.customValue(themeScope + ".pill", "colorFocused", Globals.themeVars.Secondary) : (isActive ? Globals.customValue(themeScope + ".pill", "colorActive", Globals.themeVars.White) : Globals.customValue(themeScope + ".pill", "colorInactive", Globals.themeVars.Secondary25))

            Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
            Behavior on color { ColorAnimation { duration: 300 } }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    let cmd = ["niri", "msg", "action", "focus-workspace"];

                    if (modelData.idx !== undefined) {
                        cmd.push(modelData.idx.toString());
                    } else if (modelData.name) {
                        cmd.push(modelData.name.toString());
                    } else {
                        cmd.push("--id", modelData.id.toString());
                    }

                    focusProc.command = cmd;
                    focusProc.running = false;
                    focusProc.running = true;
                }
            }
        }
    }
}
