pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Qt.labs.folderlistmodel

QtObject {
    id: root

    property int popupMargin: 52
    property int popupScreenPadding: 12

    property string homeDir: Quickshell.env("HOME")

    property var activePalette: ({
        Main: "#4f378b",
        Secondary: "#d0bcff",
        Success: "#81c784",
        Warning: "#f2b8b5",
        Error: "#8c1d18"
    })

    property bool themesReady: false

    property Process initProc: Process {
        command: []
        onExited: {
            root.themesReady = true
        }
    }

    property FolderListModel activeWatcher: FolderListModel {
        folder: root.themesReady ? "file://" + Quickshell.env("HOME") + "/.config/qs-themes" : ""
        nameFilters: ["__ACTIVE__.json"]
        showDirs: false
    }

    property string activeThemePath: Quickshell.env("HOME") + "/.config/qs-themes/__ACTIVE__.json"

    property FileView themeFile: FileView {
        path: activeWatcher.count > 0 ? root.activeThemePath : ""
        watchChanges: true
        onFileChanged: {
            console.error("themeFile changed on disk. Reloading.")
            reload()
        }

        JsonAdapter {
            id: themeAdapter
            property string name: ""
            property var palette: null
            property string wallpaper: ""
            onPaletteChanged: {
                console.error("themeAdapter palette changed!")
                root.updateColors()
            }
        }
    }

    property var currentTheme: themeAdapter
    property var activeColors: activePalette

    function updateColors() {
        let t = themeAdapter;

        function mix(c1, c2, ratio) {
            return Qt.rgba(
                c1.r * (1 - ratio) + c2.r * ratio,
                c1.g * (1 - ratio) + c2.g * ratio,
                c1.b * (1 - ratio) + c2.b * ratio,
                1.0
            );
        }

        let mainHex = (t && t.palette && t.palette.Main) ? t.palette.Main : activePalette.Main;
        let secHex = (t && t.palette && t.palette.Secondary) ? t.palette.Secondary : activePalette.Secondary;
        let successHex = (t && t.palette && t.palette.Success) ? t.palette.Success : activePalette.Success;
        let warningHex = (t && t.palette && t.palette.Warning) ? t.palette.Warning : activePalette.Warning;
        let errorHex = (t && t.palette && t.palette.Error) ? t.palette.Error : activePalette.Error;

        let mainColor = Qt.color(mainHex);
        let secColor = Qt.color(secHex);

        let blackHsl = Qt.hsla(mainColor.hslHue, mainColor.hslSaturation * 0.2, mainColor.hslLightness * 0.3, 1.0);
        let whiteHsl = Qt.hsla(mainColor.hslHue, mainColor.hslSaturation, mainColor.hslLightness + (1.0 - mainColor.hslLightness) * 0.90, 1.0);

        let res = {
            Main: mainColor,
            Secondary: secColor,
            Success: Qt.color(successHex),
            Warning: Qt.color(warningHex),
            Error: Qt.color(errorHex),
            Black: (t && t.palette && t.palette.Black) ? Qt.color(t.palette.Black) : blackHsl,
            White: (t && t.palette && t.palette.White) ? Qt.color(t.palette.White) : whiteHsl,
            Secondary50: (t && t.palette && t.palette.Secondary50) ? Qt.color(t.palette.Secondary50) : Qt.rgba(secColor.r, secColor.g, secColor.b, 0.5),
            Secondary25: (t && t.palette && t.palette.Secondary25) ? Qt.color(t.palette.Secondary25) : Qt.rgba(secColor.r, secColor.g, secColor.b, 0.25),
            Secondary10: (t && t.palette && t.palette.Secondary10) ? Qt.color(t.palette.Secondary10) : Qt.rgba(secColor.r, secColor.g, secColor.b, 0.10)
        };

        res.SecondaryLight = (t && t.palette && t.palette.SecondaryLight) ? Qt.color(t.palette.SecondaryLight) : mix(res.White, secColor, 0.25);

        activeColors = res;
    }

    function forceThemeReload() {
        console.error("forceThemeReload called")
        let p = root.activeThemePath
        root.activeThemePath = ""
        root.activeThemePath = p
        themeFile.reload()
    }

    Component.onCompleted: {
        updateColors();
        let defaultTheme = {
            name: "Default Dark",
            palette: activePalette,
            wallpaper: ""
        };
        let themeJson = JSON.stringify(defaultTheme, null, 2);
        let escapedContent = themeJson.replace(/'/g, "'\\''");
        let cmd = "DIR=\"$HOME/.config/qs-themes\"; if [ ! -d \"$DIR\" ]; then mkdir -p \"$DIR\"; echo '" + escapedContent + "' > \"$DIR/default.json\"; cp -f \"$DIR/default.json\" \"$DIR/__ACTIVE__.json\"; else if [ -L \"$DIR/__ACTIVE__.json\" ]; then TARGET=$(readlink \"$DIR/__ACTIVE__.json\"); rm -f \"$DIR/__ACTIVE__.json\"; cp -f \"$DIR/$TARGET\" \"$DIR/__ACTIVE__.json\"; fi; fi";

        initProc.command = ["bash", "-c", cmd];
        initProc.running = true;
    }

    function pColor(name) {
        return activeColors[name];
    }
}
