import QtQuick
import Quickshell
import Quickshell.Io
import qs.theming

QtObject {
    id: root

    property string gtk3ConfigDir: Quickshell.env("HOME") + "/.config/gtk-3.0"
    property string gtk4ConfigDir: Quickshell.env("HOME") + "/.config/gtk-4.0"

    function colorToHex(c) {
        function toHex(v) {
            let h = Math.round(Math.max(0, Math.min(1, v)) * 255).toString(16)
            return h.length < 2 ? "0" + h : h
        }
        return "#" + toHex(c.r) + toHex(c.g) + toHex(c.b)
    }

    function getNearestGnomeAccentColor(c) {
        let colors = {
            "blue":   { r: 53/255, g: 132/255, b: 228/255 },
            "teal":   { r: 85/255, g: 193/255, b: 203/255 },
            "green":  { r: 51/255, g: 209/255, b: 122/255 },
            "yellow": { r: 246/255, g: 211/255, b: 45/255 },
            "orange": { r: 255/255, g: 120/255, b: 0/255 },
            "red":    { r: 224/255, g: 27/255,  b: 36/255 },
            "pink":   { r: 213/255, g: 97/255,  b: 153/255 },
            "purple": { r: 145/255, g: 65/255,  b: 172/255 },
            "slate":  { r: 111/255, g: 131/255, b: 150/255 }
        };

        let minDistance = 1000000;
        let closestName = "blue";

        for (let name in colors) {
            let target = colors[name];
            let dr = c.r - target.r;
            let dg = c.g - target.g;
            let db = c.b - target.b;
            let distance = (dr * dr) + (dg * dg) + (db * db);

            if (distance < minDistance) {
                minDistance = distance;
                closestName = name;
            }
        }

        return closestName;
    }

    function writeConfig() {
        if (!Theme.themeVars || !Theme.themeVars.Main || !Theme.themeVars.Secondary)
            return

        let main = Theme.themeVars.Main
        let hexMain = colorToHex(main)
        let gnomeAccent = getNearestGnomeAccentColor(main)

        let cssContent =
            "@define-color accent_color " + hexMain + ";\n" +
            "@define-color accent_bg_color " + hexMain + ";\n"

        let cmd =
            "mkdir -p '" + root.gtk3ConfigDir + "' && cat > '" + root.gtk3ConfigDir + "/gtk.css' <<'EOF'\n" + cssContent + "EOF\n" +
            "mkdir -p '" + root.gtk4ConfigDir + "' && cat > '" + root.gtk4ConfigDir + "/gtk.css' <<'EOF'\n" + cssContent + "EOF\n" +
            "if command -v gsettings >/dev/null 2>&1; then\n" +
            "  gsettings set org.gnome.desktop.interface accent-color '" + gnomeAccent + "'\n" +
            "fi\n"

        writeProc.command = ["bash", "-c", cmd]
        writeProc.running = true
    }

    property Process writeProc: Process {
        command: []
        onExited: function(exitCode) {
            if (exitCode !== 0) console.error("gtk config write exited with code " + exitCode)
        }
    }

    property Connections themeConnections: Connections {
        target: Theme
        function onThemeVarsChanged() {
            root.writeConfig()
        }
    }

    Component.onCompleted: writeConfig()
}
