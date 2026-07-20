import QtQuick
import Quickshell
import Quickshell.Io
import qs.theming

QtObject {
    id: root

    property string niriConfigDir: Quickshell.env("HOME") + "/.config/niri"
    property string themeKdlPath: niriConfigDir + "/niri-theme.kdl"

    function colorToHex(c) {
        function toHex(v) {
            let h = Math.round(Math.max(0, Math.min(1, v)) * 255).toString(16)
            return h.length < 2 ? "0" + h : h
        }
        return "#" + toHex(c.r) + toHex(c.g) + toHex(c.b)
    }

    function writeNiriTheme() {
        if (!Theme.themeVars || !Theme.themeVars.Main || !Theme.themeVars.Secondary)
            return

        let main = colorToHex(Theme.themeVars.Main)
        let sec = colorToHex(Theme.themeVars.Secondary)

        let kdl =
            "layout {\n" +
            "    focus-ring {\n" +
            "        on\n" +
            "        active-gradient from=\"" + sec + "\" to=\"" + main + "\" angle=45\n" +
            "    }\n" +
            "}\n"

        writeProc.command = [
            "bash", "-c",
            "mkdir -p '" + root.niriConfigDir + "' && cat > '" + root.themeKdlPath + "' <<'EOF'\n" + kdl + "EOF"
        ]
        writeProc.running = true
    }

    property Process writeProc: Process {
        command: []
        onExited: function(exitCode) {
            console.error("niri-theme.kdl write exited with code " + exitCode)
        }
    }

    property Connections themeConnections: Connections {
        target: Theme
        function onThemeVarsChanged() {
            root.writeNiriTheme()
        }
    }

    Component.onCompleted: writeNiriTheme()
}
