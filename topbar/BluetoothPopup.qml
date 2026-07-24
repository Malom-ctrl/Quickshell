import QtQuick.Controls
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth

PopupWindow {
    id: popup
    property bool isActive: false
    property Item anchorItem: null
    property string themeScope: "topbar.BluetoothPopup"

    grabFocus: true

    
    Connections {
        target: Globals
        function onClosePopups() {
            if (popup.isActive) { popup.isActive = false; popup.visible = false; }
        }
    }
    onIsActiveChanged: {
        if (isActive) visible = true;
    }

    onVisibleChanged: {
        if (!visible && isActive) {
            isActive = false;
        }
    }

    property real openProgress: isActive ? 1.0 : 0.0
    Behavior on openProgress {
        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
    }

    onOpenProgressChanged: {
        if (openProgress === 0.0 && !isActive) visible = false;
    }

    anchor {
        item: anchorItem
        edges: Edges.Bottom
        gravity: Edges.Bottom
        margins.top: Globals.popupMargin
    }

    implicitWidth: Globals.customValue(themeScope, "width", 320) + (2 * Globals.popupScreenPadding)
    implicitHeight: Math.min(600, contentLayout.implicitHeight + 32)
    color: "transparent"

    property var adapter: Bluetooth.adapters.values.length > 0 ? Bluetooth.adapters.values[0] : null
    property bool isPowered: adapter && adapter.enabled

    Process {
        id: rfkillProcess
        command: []
        running: false
    }

    function setBluetoothBlocked(block) {
        rfkillProcess.running = false;
        rfkillProcess.command = ["rfkill", block ? "block" : "unblock", "bluetooth"];
        rfkillProcess.running = true;
    }

    Item {
        width: parent.width - (2 * Globals.popupScreenPadding)
        height: parent.height
        anchors.horizontalCenter: parent.horizontalCenter
        scale: 0.9 + (0.1 * popup.openProgress)
        opacity: popup.openProgress
        transformOrigin: Item.Top

        Rectangle {
            anchors.fill: parent
            color: Globals.customValue(themeScope + ".popup", "color", Globals.themeVars.Black)
            radius: Globals.customValue(themeScope + ".popup", "radius", Globals.themeVars.borderRadiusHuge)
            border.color: Globals.customValue(themeScope + ".popup", "borderColor", Globals.themeVars.Secondary10)
            border.width: Globals.customValue(themeScope + ".popup", "borderWidth", Globals.themeVars.borderWidthSmall)
            clip: true

            ColumnLayout {
                id: contentLayout
                anchors.fill: parent
                anchors.margins: Globals.customValue(themeScope + ".layout", "margins", Globals.themeVars.spacingHuge)
                spacing: Globals.customValue(themeScope + ".layout", "spacing", Globals.themeVars.spacingHuge)

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: "Bluetooth"
                        color: Globals.customValue(themeScope + ".header", "color", Globals.themeVars.White)
                        font.pixelSize: Globals.customValue(themeScope + ".header", "fontSize", Globals.themeVars.fontSizeLarge)
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        width: 24
                        height: 24
                        radius: 12
                        color: popup.adapter && popup.adapter.discovering ? Globals.themeVars.Secondary25 : "transparent"
                        visible: popup.isPowered
                        Icon {
                            anchors.centerIn: parent
                            width: 14; height: 14
                            path: "M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm5 11h-4v4h-2v-4H7v-2h4V7h2v4h4v2z" // plus/scan icon
                            color: popup.adapter && popup.adapter.discovering ? Globals.themeVars.Secondary : Globals.themeVars.White
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (popup.adapter) popup.adapter.discovering = !popup.adapter.discovering;
                            }
                        }
                    }

                    Rectangle {
                        width: 48
                        height: 24
                        radius: 12
                        color: popup.isPowered ? Globals.customValue(themeScope + ".toggle", "activeColor", Globals.themeVars.Secondary) : Globals.customValue(themeScope + ".toggle", "inactiveColor", Globals.themeVars.Secondary25)
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Rectangle {
                            width: 20
                            height: 20
                            radius: 10
                            color: Globals.customValue(themeScope + ".toggle", "handleColor", Globals.themeVars.White)
                            y: 2
                            x: popup.isPowered ? 26 : 2
                            Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (popup.adapter) {
                                    popup.setBluetoothBlocked(popup.isPowered);
                                }
                            }
                        }
                    }
                }

                ScrollView {
                    id: btScrollView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredHeight: Math.min(300, btList.implicitHeight)
                    clip: true
                    visible: popup.isPowered

                    ColumnLayout {
                        id: btList
                        width: btScrollView.width
                        spacing: Globals.customValue(themeScope + ".list", "spacing", Globals.themeVars.spacingMedium)

                        Text {
                            text: "No devices found"
                            visible: repeater.count === 0
                            color: Globals.themeVars.SecondaryLight
                            font.pixelSize: Globals.themeVars.fontSizeMedium
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Repeater {
                            id: repeater
                            model: {
                                if (!popup.adapter || !popup.adapter.devices) return [];
                                let devs = popup.adapter.devices.values;
                                let arr = [];
                                for (let i = 0; i < devs.length; i++) {
                                    let d = devs[i];
                                    if (d && d.name && d.name !== "") {
                                        arr.push(d);
                                    }
                                }
                                arr.sort((a, b) => {
                                    if (a.connected && !b.connected) return -1;
                                    if (!a.connected && b.connected) return 1;
                                    if (a.paired && !b.paired) return -1;
                                    if (!a.paired && b.paired) return 1;
                                    return (a.name || "").localeCompare(b.name || "");
                                });
                                return arr;
                            }
                            delegate: Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: Math.max(48, delegateLayout.implicitHeight + (Globals.themeVars.spacingMedium * 2))
                                radius: Globals.customValue(themeScope + ".listItem", "radius", Globals.themeVars.borderRadiusMedium)
                                color: modelData.connected ? Globals.customValue(themeScope + ".listItem", "activeColor", Globals.themeVars.Secondary25) : (btMouse.containsMouse ? Globals.customValue(themeScope + ".listItem", "hoverColor", Globals.themeVars.Secondary10) : "transparent")

                                MouseArea {
                                    id: btMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (modelData.connected) {
                                            modelData.disconnect();
                                        } else if (modelData.paired) {
                                            modelData.connect();
                                        } else {
                                            modelData.pair();
                                        }
                                    }
                                }

                                RowLayout {
                                    id: delegateLayout
                                    anchors.fill: parent
                                    anchors.margins: Globals.customValue(themeScope + ".listItem.layout", "margins", Globals.themeVars.spacingMedium)
                                    spacing: Globals.customValue(themeScope + ".listItem.layout", "spacing", Globals.themeVars.spacingMedium)

                                    Icon {
                                        Layout.preferredWidth: 18; Layout.preferredHeight: 18
                                        path: "M17.71 7.71L12 2h-1v7.59L6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 11 14.41V22h1l5.71-5.71-4.3-4.29 4.3-4.29zM13 5.83l1.88 1.88L13 9.59V5.83zm1.88 10.46L13 18.17v-3.76l1.88 1.88z"
                                        color: Globals.customValue(themeScope + ".listItem.icon", "color", Globals.themeVars.White)
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Text {
                                            text: modelData.name || modelData.alias || "Unknown Device"
                                            color: Globals.customValue(themeScope + ".listItem.text", "color", Globals.themeVars.White)
                                            font.pixelSize: Globals.customValue(themeScope + ".listItem.text", "fontSize", Globals.themeVars.fontSizeMedium)
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                            font.bold: modelData.connected
                                        }
                                        Text {
                                            visible: modelData.connected || modelData.state === 3 || (!modelData.paired && modelData.pairing)
                                            text: {
                                                if (modelData.state === 3) return "Connecting..."; // Connecting
                                                if (!modelData.paired && modelData.pairing) return "Pairing...";
                                                if (modelData.connected) {
                                                    if (modelData.batteryAvailable) return "Connected - " + Math.round(modelData.battery * 100) + "%";
                                                    return "Connected";
                                                }
                                                return "";
                                            }
                                            color: Globals.themeVars.SecondaryLight
                                            font.pixelSize: Globals.themeVars.fontSizeSmall
                                        }
                                    }

                                    Icon {
                                        visible: modelData.connected
                                        Layout.preferredWidth: 16; Layout.preferredHeight: 16
                                        path: "M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z"
                                        color: Globals.customValue(themeScope + ".listItem.check", "color", Globals.themeVars.Secondary)
                                    }

                                    Rectangle {
                                        width: 24
                                        height: 24
                                        radius: 12
                                        color: "transparent"
                                        visible: btMouse.containsMouse && modelData.paired
                                        Icon {
                                            anchors.centerIn: parent
                                            width: 14; height: 14
                                            path: "M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12z" // close icon for forget
                                            color: Globals.themeVars.White
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                modelData.forget();
                                            }
                                        }
                                    }
                                }


                            }
                        }
                    }
                }
            }
        }
    }
}
