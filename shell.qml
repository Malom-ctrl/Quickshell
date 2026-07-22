import QtQuick
import Quickshell
import qs.topbar
import qs.launcher
import qs.wallpaper
import qs.niri
import qs.swaylock
import qs.gtk
import qs.ptyxis
import qs.zed

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
    SwaylockThemeSync {}
    GtkThemeSync {}
    PtyxisThemeSync {}
    ZedThemeSync {}
}
