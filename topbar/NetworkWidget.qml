import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking

Rectangle {
    Component.onCompleted: {
        let devs = Networking.devices.values;
        for (let i = 0; i < devs.length; i++) {
            console.error("DEBUG WIDGET DEVICE:", devs[i].name, "type:", devs[i].type, "hasLink:", devs[i].hasLink, "connected:", devs[i].connected);
        }
    }
    id: root
    property string themeScope: "topbar.NetworkWidget"
    width: Globals.customValue(themeScope, "width", 40)
    height: Globals.customValue(themeScope, "height", 40)
    radius: Globals.customValue(themeScope, "radius", Globals.themeVars.borderRadiusHuge)
    color: (mouseArea.containsMouse || popup.isActive) ? Globals.customValue(themeScope, "hoverColor", Globals.themeVars.Secondary50) : Globals.customValue(themeScope, "color", Globals.themeVars.Secondary25)

    Behavior on color { ColorAnimation { duration: 150 } }

    property var wiredDevice: {
        let devs = Networking.devices.values;
        for (let i = 0; i < devs.length; i++) {
            if (devs[i].type === DeviceType.Wired && devs[i].connected) return devs[i];
        }
        return null;
    }
    property var wifiDevice: {
        let devs = Networking.devices.values;
        for (let i = 0; i < devs.length; i++) {
            if (devs[i].type === DeviceType.Wifi) return devs[i];
        }
        return null;
    }
    property bool isWired: wiredDevice !== null
    property bool isWifi: !isWired && wifiDevice && wifiDevice.connected

    Icon {
        anchors.centerIn: parent
        width: Globals.customValue(themeScope + ".icon", "width", 18)
        height: Globals.customValue(themeScope + ".icon", "height", 18)
        path: {
            if (!Networking.wifiEnabled && !isWired) {
                return "M23.64 7c-.45-.34-4.93-4-11.64-4C5.28 3 .81 6.66.36 7L12 21.5 23.64 7z"
            }
            if (isWired) {
                return "M16 11h-4V7h-3v4H5v2h4v4h3v-4h4v-2z"
            }
            return "M12.01 21.49L23.64 7c-.45-.34-4.93-4-11.64-4C5.28 3 .81 6.66.36 7l11.63 14.49.01.01.01-.01z"
        }
        color: Globals.customValue(themeScope + ".icon", "color", Globals.themeVars.White)
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

    NetworkPopup {
        id: popup
        isActive: false
        anchorItem: root
    }
}
