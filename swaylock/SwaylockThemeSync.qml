import QtQuick
import Quickshell
import Quickshell.Io
import qs.theming

QtObject {
    id: root

    property string swaylockConfigDir: Quickshell.env("HOME") + "/.config/swaylock"
    property string configPath: swaylockConfigDir + "/config"

    function colorToHex(c, alpha) {
        function toHex(v) {
            let h = Math.round(Math.max(0, Math.min(1, v)) * 255).toString(16)
            return h.length < 2 ? "0" + h : h
        }
        let a = alpha !== undefined ? toHex(alpha) : toHex(c.a !== undefined ? c.a : 1.0)
        return toHex(c.r) + toHex(c.g) + toHex(c.b) + a
    }

    function writeConfig() {
        if (!Theme.themeVars || !Theme.themeVars.Main || !Theme.themeVars.Secondary)
            return

        let main = Theme.themeVars.Main
        let sec = Theme.themeVars.Secondary
        let bg = Theme.themeVars.Black || Qt.rgba(0,0,0,1)
        let text = Theme.themeVars.White || Qt.rgba(1,1,1,1)
        let error = Theme.themeVars.Error || Qt.rgba(1,0,0,1)

        let config = 
            "color=" + colorToHex(bg, 1.0).substring(0, 6) + "\n" +
            "inside-color=" + colorToHex(bg, 0.0) + "\n" +
            "ring-color=" + colorToHex(main, 1.0) + "\n" +
            "key-hl-color=" + colorToHex(sec, 1.0) + "\n" +
            "line-color=00000000\n" +
            "inside-clear-color=" + colorToHex(bg, 0.0) + "\n" +
            "ring-clear-color=" + colorToHex(sec, 1.0) + "\n" +
            "inside-ver-color=" + colorToHex(bg, 0.0) + "\n" +
            "ring-ver-color=" + colorToHex(main, 1.0) + "\n" +
            "inside-wrong-color=" + colorToHex(bg, 0.0) + "\n" +
            "ring-wrong-color=" + colorToHex(error, 1.0) + "\n" +
            "separator-color=00000000\n" +
            "text-color=" + colorToHex(text, 1.0) + "\n" +
            "text-clear-color=" + colorToHex(text, 1.0) + "\n" +
            "text-ver-color=" + colorToHex(text, 1.0) + "\n" +
            "text-wrong-color=" + colorToHex(text, 1.0) + "\n" +
            "scaling=fill\n" +
            "font-size=" + (Theme.themeVars.fontSizeHuge || 25) + "\n" +
            "indicator-radius=" + ((Theme.themeVars.borderRadiusHuge || 20) * 4) + "\n" +
            "indicator-thickness=" + ((Theme.themeVars.borderWidthLarge || 4) * 2) + "\n"

        let wallpaper = Theme.themeData ? Theme.themeData.wallpaper : "";
        let cmd = 
            "mkdir -p '" + root.swaylockConfigDir + "'\n" +
            "cat > '" + root.configPath + "' <<'EOF'\n" + config + "EOF\n";

        if (wallpaper) {
            cmd += 
                "WP='" + wallpaper.replace(/'/g, "'\\''") + "'\n" +
                "WP_EXP=\"${WP/#\\~/$HOME}\"\n" +
                "if [ -f \"$WP_EXP\" ]; then\n" +
                "  HASH=$(md5sum \"$WP_EXP\" | awk '{print $1}')\n" +
                "  CACHE_DIR='" + Quickshell.cachePath("swaylock") + "'\n" +
                "  mkdir -p \"$CACHE_DIR\"\n" +
                "  BLURRED=\"$CACHE_DIR/${HASH}.jpg\"\n" +
                "  if [ ! -f \"$BLURRED\" ]; then\n" +
                "    convert \"${WP_EXP}[0]\" -scale 10% -blur 0x2 -resize 1000% \"$BLURRED\"\n" +
                "  fi\n" +
                "  echo \"image=$BLURRED\" >> '" + root.configPath + "'\n" +
                "fi\n";
        }

        writeProc.command = [
            "bash", "-c",
            cmd
        ]
        writeProc.running = true
    }

    property Process writeProc: Process {
        command: []
        onExited: function(exitCode) {
            if (exitCode !== 0) console.error("swaylock config write exited with code " + exitCode)
        }
    }

    property Connections themeConnections: Connections {
        target: Theme
        function onThemeVarsChanged() {
            root.writeConfig()
        }
    }

    property Connections wallpaperConnections: Connections {
        target: Theme.themeData
        function onWallpaperChanged() {
            root.writeConfig()
        }
    }

    Component.onCompleted: writeConfig()
}
