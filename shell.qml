import QtQuick
import Quickshell
import qs.topbar
import qs.launcher
import qs.wallpaper
import qs.niri

ShellRoot {
    Component.onCompleted: {
        console.log("WallpaperManager loaded", WallpaperManager)
    }

    Variants {
        model: Quickshell.screens.length > 0 ? [Quickshell.screens[0]] : []
        delegate: Bar {}
    }

    LauncherWindow {}

    NiriThemeSync {}
}
