import QtQuick
import Quickshell

ShellRoot {
    Variants {
        model: Quickshell.screens.length > 0 ? [Quickshell.screens[0]] : []
        delegate: Bar {}
    }
}
