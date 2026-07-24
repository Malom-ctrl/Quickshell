import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth

Rectangle {
    id: root
    visible: Bluetooth.adapters.values.length > 0
    property string themeScope: "topbar.BluetoothWidget"
    width: Globals.customValue(themeScope, "width", 40)
    height: Globals.customValue(themeScope, "height", 40)
    radius: Globals.customValue(themeScope, "radius", Globals.themeVars.borderRadiusHuge)
    color: (mouseArea.containsMouse || popup.isActive) ? Globals.customValue(themeScope, "hoverColor", Globals.themeVars.Secondary50) : Globals.customValue(themeScope, "color", Globals.themeVars.Secondary25)

    Behavior on color { ColorAnimation { duration: 150 } }

    property var adapter: Bluetooth.adapters.values.length > 0 ? Bluetooth.adapters.values[0] : null
    property bool isPowered: adapter && adapter.enabled

    Icon {
        anchors.centerIn: parent
        width: Globals.customValue(themeScope + ".icon", "width", 18)
        height: Globals.customValue(themeScope + ".icon", "height", 18)
        path: root.isPowered ? "M17.71 7.71L12 2h-1v7.59L6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 11 14.41V22h1l5.71-5.71-4.3-4.29 4.3-4.29zM13 5.83l1.88 1.88L13 9.59V5.83zm1.88 10.46L13 18.17v-3.76l1.88 1.88z" : "M13 5.83l1.88 1.88L13 9.59V5.83zm1.88 10.46L13 18.17v-3.76l1.88 1.88zM5.41 4L4 5.41 10.59 12 5 17.59 6.41 19 11 14.41V22h1l4.29-4.29 2.3 2.29L20 18.59 5.41 4zM13 18.17v-3.76l1.88 1.88L13 18.17z"
        color: root.isPowered ? Globals.customValue(themeScope + ".icon", "color", Globals.themeVars.White) : Globals.customValue(themeScope + ".icon", "disabledColor", Globals.themeVars.SecondaryLight)
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (!popup.isActive) {
                Globals.closePopups();
                popup.isActive = true;
            } else {
                popup.isActive = false;
            }
        }
    }

    BluetoothPopup {
        id: popup
        isActive: false
        anchorItem: root
    }
}
