pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property string shellName: Quickshell.shellDir.split("/").pop()
    property string themePrefix: shellName + "."

    property int popupMargin: 52
    property int popupScreenPadding: 12

    property string homeDir: Quickshell.env("HOME")

    property var activePalette: ({
        Main: "#4f378b",
        Secondary: "#d0bcff",
        Success: "#81c784",
        Warning: "#f2b8b5",
        Error: "#8c1d18",
        fontSizeMedium: 15,
        fontSizeSmall: 12,
        fontSizeLarge: 18,
        fontSizeHuge: 25,
        spacingMedium: 8,
        spacingSmall: 4,
        spacingLarge: 12,
        spacingHuge: 16,
        borderWidthSmall: 1,
        borderWidthMedium: 2,
        borderWidthLarge: 4,
        borderRadiusMedium: 12,
        borderRadiusSmall: 8,
        borderRadiusLarge: 16,
        borderRadiusHuge: 20
    })

    property bool themesReady: false

    property Process initProc: Process {
        command: []
        onExited: {
            root.themesReady = true
        }
    }

    property string themesDir: Quickshell.env("HOME") + "/.config/qs-themes"
    property string activeThemeFile: ""

    // Small text file in Quickshell's own state dir, survives restarts
    property FileView activeStateFile: FileView {
        path: root.themesReady ? Quickshell.cachePath("activeTheme.txt") : ""
        watchChanges: true
        onFileChanged: reload()
        onTextChanged: root.activeThemeFile = text().trim()
    }

    property FileView themeFile: FileView {
        path: (root.themesReady && root.activeThemeFile !== "")
            ? root.themesDir + "/" + root.activeThemeFile
            : ""
        watchChanges: true
        onFileChanged: {
            console.error("themeFile changed on disk. Reloading.");
            reload();
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
    property var themeData: themeAdapter
    property var themeVars: activePalette

    property int _themeTrigger: 0

    function resolveThemeValue(val, depth) {
        depth = depth || 0;
        if (depth >= 6) {
            console.error("Theme value resolution exceeded max recursion depth (6). Possible circular reference at value:", val);
            return val;
        }
        if (typeof val !== "string") {
            return val;
        }

        if (val in root.themeVars) {
            return resolveThemeValue(root.themeVars[val], depth + 1);
        }

        let t = themeAdapter;
        if (t && t.palette && val in t.palette) {
            return resolveThemeValue(t.palette[val], depth + 1);
        }

        return val;
    }

    function customValue(scope, key, fallback) {
        let dummy = root._themeTrigger;
        let t = themeAdapter;
        let p = t ? t.palette : null;
        if (p) {
            if (scope && scope !== "") {
                let scopedKey = scope + "." + key;
                if (scopedKey in p) {
                    return resolveThemeValue(p[scopedKey]);
                }
            }
            if (key in p) {
                return resolveThemeValue(p[key]);
            }
        }
        return fallback;
    }

    function updateColors() { console.error("updateColors called");
        root._themeTrigger++;
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
            Secondary50: (t && t.palette && t.palette.Secondary50) ? Qt.color(t.palette.Secondary50) : Qt.rgba(secColor.r, secColor.g, secColor.b, 0.50),
            Secondary25: (t && t.palette && t.palette.Secondary25) ? Qt.color(t.palette.Secondary25) : Qt.rgba(secColor.r, secColor.g, secColor.b, 0.25),
            Secondary10: (t && t.palette && t.palette.Secondary10) ? Qt.color(t.palette.Secondary10) : Qt.rgba(secColor.r, secColor.g, secColor.b, 0.10),
            fontSizeMedium: (t && t.palette && "fontSizeMedium" in t.palette) ? t.palette.fontSizeMedium : activePalette.fontSizeMedium,
            fontSizeSmall: (t && t.palette && "fontSizeSmall" in t.palette) ? t.palette.fontSizeSmall : activePalette.fontSizeSmall,
            fontSizeLarge: (t && t.palette && "fontSizeLarge" in t.palette) ? t.palette.fontSizeLarge : activePalette.fontSizeLarge,
            fontSizeHuge: (t && t.palette && "fontSizeHuge" in t.palette) ? t.palette.fontSizeHuge : activePalette.fontSizeHuge,
            spacingMedium: (t && t.palette && "spacingMedium" in t.palette) ? t.palette.spacingMedium : activePalette.spacingMedium,
            spacingSmall: (t && t.palette && "spacingSmall" in t.palette) ? t.palette.spacingSmall : activePalette.spacingSmall,
            spacingLarge: (t && t.palette && "spacingLarge" in t.palette) ? t.palette.spacingLarge : activePalette.spacingLarge,
            spacingHuge: (t && t.palette && "spacingHuge" in t.palette) ? t.palette.spacingHuge : activePalette.spacingHuge,
            borderWidthSmall: (t && t.palette && "borderWidthSmall" in t.palette) ? t.palette.borderWidthSmall : activePalette.borderWidthSmall,
            borderWidthMedium: (t && t.palette && "borderWidthMedium" in t.palette) ? t.palette.borderWidthMedium : activePalette.borderWidthMedium,
            borderWidthLarge: (t && t.palette && "borderWidthLarge" in t.palette) ? t.palette.borderWidthLarge : activePalette.borderWidthLarge,
            borderRadiusMedium: (t && t.palette && "borderRadiusMedium" in t.palette) ? t.palette.borderRadiusMedium : activePalette.borderRadiusMedium,
            borderRadiusSmall: (t && t.palette && "borderRadiusSmall" in t.palette) ? t.palette.borderRadiusSmall : activePalette.borderRadiusSmall,
            borderRadiusLarge: (t && t.palette && "borderRadiusLarge" in t.palette) ? t.palette.borderRadiusLarge : activePalette.borderRadiusLarge,
            borderRadiusHuge: (t && t.palette && "borderRadiusHuge" in t.palette) ? t.palette.borderRadiusHuge : activePalette.borderRadiusHuge
        };

        res.SecondaryLight = (t && t.palette && t.palette.SecondaryLight) ? Qt.color(t.palette.SecondaryLight) : mix(res.White, secColor, 0.25);

        themeVars = res;

        let prefix = root.themePrefix;
        if (t && t.palette) {
            for (let k in t.palette) {
                if (k.startsWith(prefix)) {
                    let keyName = k.substring(prefix.length);
                    if (keyName in customColors) {
                        customColors[keyName] = Qt.color(t.palette[k]);
                    }
                }
            }
        }
    }

    function forceThemeReload() {
        console.error("forceThemeReload called")
        let f = root.activeThemeFile
        root.activeThemeFile = ""
        root.activeThemeFile = f
    }

    Component.onCompleted: {
        updateColors();
        let defaultTheme = {
            name: "Default Dark",
            palette: {
                Main: activePalette.Main,
                Secondary: activePalette.Secondary,
                Success: activePalette.Success,
                Warning: activePalette.Warning,
                Error: activePalette.Error,
                "//Black": "Calculated from Main with -80 saturation and -70 lightness (e.g. #0a0712)",
                "//White": "Calculated from Main with +90 lightness (e.g. #eaddff)",
                "//Secondary50": "Calculated from Secondary at 50% opacity",
                "//Secondary25": "Calculated from Secondary at 25% opacity",
                "//Secondary10": "Calculated from Secondary at 10% opacity",
                "//SecondaryLight": "Calculated from White mixed with 25% of Secondary",
                fontSizeMedium: activePalette.fontSizeMedium,
                fontSizeSmall: activePalette.fontSizeSmall,
                fontSizeLarge: activePalette.fontSizeLarge,
                fontSizeHuge: activePalette.fontSizeHuge,
                spacingMedium: activePalette.spacingMedium,
                spacingSmall: activePalette.spacingSmall,
                spacingLarge: activePalette.spacingLarge,
                spacingHuge: activePalette.spacingHuge,
                borderWidthSmall: activePalette.borderWidthSmall,
                borderWidthMedium: activePalette.borderWidthMedium,
                borderWidthLarge: activePalette.borderWidthLarge,
                borderRadiusMedium: activePalette.borderRadiusMedium,
                borderRadiusSmall: activePalette.borderRadiusSmall,
                borderRadiusLarge: activePalette.borderRadiusLarge,
                borderRadiusHuge: activePalette.borderRadiusHuge
            },
            wallpaper: ""
        };
        let themeJson = JSON.stringify(defaultTheme, null, 2);
        let escapedContent = themeJson.replace(/'/g, "'\\''");
        let cacheFile = Quickshell.cachePath("activeTheme.txt");
        let cmd = "DIR=\"$HOME/.config/qs-themes\"; mkdir -p \"$DIR\"; mkdir -p \"$(dirname '" + cacheFile + "')\"; if [ ! -f \"$DIR/default.json\" ]; then echo '" + escapedContent + "' > \"$DIR/default.json\"; fi; if [ ! -f '" + cacheFile + "' ]; then echo -n 'default.json' > '" + cacheFile + "'; fi";

        initProc.command = ["bash", "-c", cmd];
        initProc.running = true;
    }
}
