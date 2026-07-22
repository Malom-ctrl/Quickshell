import QtQuick
import Quickshell
import Quickshell.Io
import qs.theming

QtObject {
    id: root

    property string ptyxisPalettesDir1: Quickshell.env("HOME") + "/.local/share/org.gnome.Ptyxis/palettes"
    property string ptyxisPalettesDir2: Quickshell.env("HOME") + "/.config/ptyxis/palettes"

    function colorToHex(c) {
        function toHex(v) {
            let h = Math.round(Math.max(0, Math.min(1, v)) * 255).toString(16)
            return h.length < 2 ? "0" + h : h
        }
        if (c.a !== undefined && c.a < 1.0) {
            return "#" + toHex(c.r) + toHex(c.g) + toHex(c.b) + toHex(c.a)
        }
        return "#" + toHex(c.r) + toHex(c.g) + toHex(c.b)
    }

    function writeConfig() {
        if (!Theme.themeVars || !Theme.themeVars.Main || !Theme.themeVars.Secondary)
            return

        let main = Theme.themeVars.Main
        let sec = Theme.themeVars.Secondary
        let success = Theme.themeVars.Success || Qt.rgba(0.1, 0.8, 0.3, 1)
        let warning = Theme.themeVars.Warning || Qt.rgba(0.9, 0.7, 0.1, 1)
        let error = Theme.themeVars.Error || Qt.rgba(0.9, 0.2, 0.2, 1)
        let bg = Theme.themeVars.Black || Qt.rgba(0.05, 0.05, 0.05, 1)
        let fg = Theme.themeVars.White || Qt.rgba(0.95, 0.95, 0.95, 1)
        
        let sec50 = Theme.themeVars.Secondary50 || sec
        let secLight = Theme.themeVars.SecondaryLight || fg

        let colors =
            "Foreground=" + colorToHex(fg) + "\n" +
            "Background=" + colorToHex(bg) + "\n" +
            "TitlebarBackground=" + colorToHex(bg) + "\n" +
            "TitlebarForeground=" + colorToHex(fg) + "\n" +
            "Cursor=" + colorToHex(main) + "\n" +
            "Color0=" + colorToHex(bg) + "\n" +
            "Color1=" + colorToHex(error) + "\n" +
            "Color2=" + colorToHex(success) + "\n" +
            "Color3=" + colorToHex(warning) + "\n" +
            "Color4=" + colorToHex(sec) + "\n" +
            "Color5=" + colorToHex(main) + "\n" +
            "Color6=" + colorToHex(secLight) + "\n" +
            "Color7=" + colorToHex(fg) + "\n" +
            "Color8=" + colorToHex(sec50) + "\n" +
            "Color9=" + colorToHex(error) + "\n" +
            "Color10=" + colorToHex(success) + "\n" +
            "Color11=" + colorToHex(warning) + "\n" +
            "Color12=" + colorToHex(sec) + "\n" +
            "Color13=" + colorToHex(main) + "\n" +
            "Color14=" + colorToHex(secLight) + "\n" +
            "Color15=" + colorToHex(fg) + "\n"

        let palette1 =
            "[Palette]\n" +
            "Name=Quickshell\n" +
            "UseSystemAccent=true\n\n" +
            "[Dark]\n" +
            colors + "\n" +
            "[Light]\n" +
            colors

        let palette2 =
            "[Palette]\n" +
            "Name=Quickshell2\n" +
            "UseSystemAccent=true\n\n" +
            "[Dark]\n" +
            colors + "\n" +
            "[Light]\n" +
            colors

        let cmd =
            "mkdir -p '" + root.ptyxisPalettesDir1 + "' '" + root.ptyxisPalettesDir2 + "'\n" +
            "cat > '" + root.ptyxisPalettesDir1 + "/Quickshell.palette' <<'EOF'\n" + palette1 + "\nEOF\n" +
            "cat > '" + root.ptyxisPalettesDir2 + "/Quickshell.palette' <<'EOF'\n" + palette1 + "\nEOF\n" +
            "cat > '" + root.ptyxisPalettesDir1 + "/Quickshell2.palette' <<'EOF'\n" + palette2 + "\nEOF\n" +
            "cat > '" + root.ptyxisPalettesDir2 + "/Quickshell2.palette' <<'EOF'\n" + palette2 + "\nEOF\n" +
            "UUID=$(gsettings get org.gnome.Ptyxis default-profile-uuid 2>/dev/null | tr -d \"'\")\n" +
            "if [ -n \"$UUID\" ]; then\n" +
            "  PROFILE=\"org.gnome.Ptyxis.Profile:/org/gnome/Ptyxis/Profiles/$UUID/\"\n" +
            "  CURRENT_PALETTE=$(gsettings get \"$PROFILE\" palette 2>/dev/null | tr -d \"'\")\n" +
            "  if [ \"$CURRENT_PALETTE\" = \"Quickshell\" ]; then\n" +
            "    NEXT_PALETTE=\"Quickshell2\"\n" +
            "  else\n" +
            "    NEXT_PALETTE=\"Quickshell\"\n" +
            "  fi\n" +
            "  gsettings set \"$PROFILE\" palette \"$NEXT_PALETTE\" 2>/dev/null || true\n" +
            "fi\n"

        writeProc.command = ["bash", "-c", cmd]
        writeProc.running = true
    }

    property Process writeProc: Process {
        command: []
        onExited: function(exitCode) {
            if (exitCode !== 0) console.error("ptyxis palette write exited with code " + exitCode)
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
