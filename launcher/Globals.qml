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
        primary: "#D0BCFF",
        onPrimary: "#381E72",
        primaryContainer: "#4F378B",
        onPrimaryContainer: "#EADDFF",
        secondary: "#CCC2DC",
        onSecondary: "#332D41",
        secondaryContainer: "#4A4458",
        onSecondaryContainer: "#E8DEF8",
        background: "#141218",
        onBackground: "#E6E1E5",
        surface: "#1D1B20",
        onSurface: "#E6E1E5",
        surfaceVariant: "#49454F",
        onSurfaceVariant: "#CAC4D0",
        outline: "#938F99",
        error: "#F2B8B5",
        onError: "#601410",
        success: "#81C784",
        onSuccess: "#003314"
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
        let res = {};
        for (let k in activePalette) {
            res[k] = (t && t.palette && t.palette[k]) ? t.palette[k] : activePalette[k];
        }
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
