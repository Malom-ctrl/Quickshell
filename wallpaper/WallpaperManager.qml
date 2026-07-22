pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.theming

QtObject {
    id: root

    property Process awwwProc: Process {
        command: []
    }

    property Connections themeConnection: Connections {
        target: Theme.themeData
        function onWallpaperChanged() {
            let wallpaper = Theme.themeData.wallpaper;
            console.error("WallpaperManager wallpaper changed: " + wallpaper)
            if (wallpaper !== undefined && wallpaper !== "") {
                let cmd = "WP='" + wallpaper.replace(/'/g, "'\\''") + "'; WP_EXPANDED=\"${WP/#\\~/$HOME}\"; awww img \"$WP_EXPANDED\" --transition-type fade --transition-duration 0.2";
                root.awwwProc.command = ["bash", "-c", cmd];
                root.awwwProc.running = true;
            }
        }
    }
}
