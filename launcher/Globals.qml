pragma Singleton
import QtQuick
import qs.theming

QtObject {
    property string shellName: Theme.shellName
    property string themePrefix: Theme.themePrefix

    property int popupMargin: Theme.popupMargin
    property int popupScreenPadding: Theme.popupScreenPadding

    property string homeDir: Theme.homeDir

    property var activePalette: Theme.activePalette
    property bool themesReady: Theme.themesReady

    property string activeThemePath: Theme.activeThemePath

    property var currentTheme: Theme.themeData
    property var themeVars: Theme.themeVars
    property var customColors: Theme.customColors

    function customValue(scope, key, fallback) {
        return Theme.customValue(scope, key, fallback)
    }

    function forceThemeReload() {
        Theme.forceThemeReload()
    }
}
