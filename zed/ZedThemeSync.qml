import QtQuick
import Quickshell
import Quickshell.Io
import qs.theming

QtObject {
    id: root

    property string zedThemeDir: Quickshell.env("HOME") + "/.config/zed/themes"
    property string themeName: "quickshell-theme.json"

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
        let sec25 = Theme.themeVars.Secondary25 || sec
        let sec10 = Theme.themeVars.Secondary10 || sec
        let secLight = Theme.themeVars.SecondaryLight || fg

        let hexMain = colorToHex(main)
        let hexSec = colorToHex(sec)
        let hexSuccess = colorToHex(success)
        let hexWarning = colorToHex(warning)
        let hexError = colorToHex(error)
        let hexBg = colorToHex(bg)
        let hexFg = colorToHex(fg)
        let hexSec50 = colorToHex(sec50)
        let hexSec25 = colorToHex(sec25)
        let hexSec10 = colorToHex(sec10)
        let hexSecLight = colorToHex(secLight)

        let themeJson = {
            "$schema": "https://zed.dev/schema/themes/v0.1.0.json",
            "name": "Quickshell Theme",
            "author": "Quickshell",
            "themes": [
                {
                    "name": "Quickshell Dark",
                    "appearance": "dark",
                    "style": {
                        "border": hexSec10,
                        "border.variant": hexSec25,
                        "border.focused": hexMain,
                        "border.selected": hexMain,
                        "border.transparent": "#00000000",
                        "border.disabled": hexSec10,
                        "elevated_surface.background": hexBg,
                        "surface.background": hexBg,
                        "background": hexBg,
                        "element.background": hexBg,
                        "element.hover": hexSec10,
                        "element.active": hexSec25,
                        "element.selected": hexSec25,
                        "drop_target.background": hexSec25,
                        "ghost_element.background": "#00000000",
                        "ghost_element.hover": hexSec10,
                        "ghost_element.active": hexSec25,
                        "ghost_element.selected": hexSec25,
                        "text": hexFg,
                        "text.muted": hexSecLight,
                        "text.placeholder": hexSec50,
                        "text.disabled": hexSec50,
                        "text.accent": hexMain,
                        "icon": hexFg,
                        "icon.muted": hexSecLight,
                        "icon.disabled": hexSec50,
                        "icon.placeholder": hexSec50,
                        "icon.accent": hexMain,
                        "status_bar.background": hexBg,
                        "title_bar.background": hexBg,
                        "toolbar.background": hexBg,
                        "tab_bar.background": hexBg,
                        "tab.inactive_background": hexBg,
                        "tab.active_background": hexSec10,
                        "search.match_background": hexSec25,
                        "panel.background": hexBg,
                        "panel.focused_border": hexMain,
                        "pane.focused_border": hexMain,
                        "scrollbar_thumb.background": hexSec25,
                        "scrollbar_thumb.hover_background": hexSec50,
                        "scrollbar_thumb.border": "#00000000",
                        "scrollbar.track.background": "#00000000",
                        "scrollbar.track.border": "#00000000",
                        "editor.foreground": hexFg,
                        "editor.background": hexBg,
                        "editor.gutter.background": hexBg,
                        "editor.subheader.background": hexBg,
                        "editor.active_line.background": hexSec10,
                        "editor.highlighted_line.background": hexSec10,
                        "editor.line_number": hexSec50,
                        "editor.active_line_number": hexMain,
                        "editor.invisible": hexSec10,
                        "editor.wrap_guide": hexSec10,
                        "editor.active_wrap_guide": hexSec25,
                        "editor.document_highlight.read_background": hexSec25,
                        "editor.document_highlight.write_background": hexSec25,
                        "terminal.background": hexBg,
                        "terminal.foreground": hexFg,
                        "terminal.ansi.black": hexBg,
                        "terminal.ansi.red": hexError,
                        "terminal.ansi.green": hexSuccess,
                        "terminal.ansi.yellow": hexWarning,
                        "terminal.ansi.blue": hexSec,
                        "terminal.ansi.magenta": hexMain,
                        "terminal.ansi.cyan": hexSecLight,
                        "terminal.ansi.white": hexFg,
                        "terminal.ansi.bright_black": hexSec50,
                        "terminal.ansi.bright_red": hexError,
                        "terminal.ansi.bright_green": hexSuccess,
                        "terminal.ansi.bright_yellow": hexWarning,
                        "terminal.ansi.bright_blue": hexSec,
                        "terminal.ansi.bright_magenta": hexMain,
                        "terminal.ansi.bright_cyan": hexSecLight,
                        "terminal.ansi.bright_white": hexFg,
                        "created": hexSuccess,
                        "created.background": hexSec10,
                        "created.border": hexSuccess,

                        "modified": hexWarning,
                        "modified.background": hexSec10,
                        "modified.border": hexWarning,

                        "deleted": hexError,
                        "deleted.background": hexSec10,
                        "deleted.border": hexError,
                        "syntax": {
                            "comment": { "color": hexSecLight, "font_style": "italic" },
                            "string": { "color": hexSuccess },
                            "constant": { "color": hexWarning },
                            "keyword": { "color": hexMain, "font_weight": "bold" },
                            "function": { "color": hexSec },
                            "type": { "color": hexSecLight },
                            "variable": { "color": hexFg },
                            "property": { "color": hexSec },
                            "number": { "color": hexWarning },
                            "boolean": { "color": hexWarning },
                            "operator": { "color": hexMain },
                            "punctuation": { "color": hexSecLight },
                            "punctuation.bracket": { "color": hexSecLight },
                            "tag": { "color": hexSec },
                            "attribute": { "color": hexWarning }
                        }
                    }
                }
            ]
        }

        let zedFlatpakDir = Quickshell.env("HOME") + "/.var/app/dev.zed.Zed/config/zed"

        let cmd =
            "mkdir -p '" + root.zedThemeDir + "' && cat > '" + root.zedThemeDir + "/" + root.themeName + "' <<'EOF'\n" + JSON.stringify(themeJson, null, 2) + "\nEOF\n" +
            "if [ -d '" + zedFlatpakDir + "' ]; then\n" +
            "  mkdir -p '" + zedFlatpakDir + "/themes'\n" +
            "  cat > '" + zedFlatpakDir + "/themes/" + root.themeName + "' <<'EOF'\n" + JSON.stringify(themeJson, null, 2) + "\nEOF\n" +
            "fi\n"

        writeProc.command = ["bash", "-c", cmd]
        writeProc.running = true
    }

    property Process writeProc: Process {
        command: []
        onExited: function(exitCode) {
            if (exitCode !== 0) console.error("zed theme write exited with code " + exitCode)
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
