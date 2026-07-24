import QtQuick.Controls
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking

PopupWindow {
    id: popup
    property bool isActive: false
    property Item anchorItem: null
    property string themeScope: "topbar.NetworkPopup"

    grabFocus: true

    
    Connections {
        target: Globals
        function onClosePopups() {
            if (popup.isActive) { popup.isActive = false; popup.visible = false; }
        }
    }
    onIsActiveChanged: {
        if (isActive) {
            visible = true;
            if (wifiDevice) wifiDevice.scannerEnabled = true;
        }
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
        if (openProgress === 0.0 && !isActive) {
            visible = false;
            if (wifiDevice) wifiDevice.scannerEnabled = false;
        }
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

    property var wifiDevice: {
        let devs = Networking.devices.values;
        for (let i = 0; i < devs.length; i++) {
            if (devs[i].type === DeviceType.Wifi) {
                return devs[i];
            }
        }
        return null;
    }

    property var wiredDevices: {
        let arr = [];
        let devs = Networking.devices.values;
        for (let i = 0; i < devs.length; i++) {
            if (devs[i].type === DeviceType.Wired) {
                arr.push(devs[i]);
            }
        }
        return arr;
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

                Repeater {
                    model: popup.wiredDevices
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: Math.max(48, delegateLayout.implicitHeight + (Globals.themeVars.spacingMedium * 2))
                        radius: Globals.customValue(themeScope + ".listItem", "radius", Globals.themeVars.borderRadiusMedium)
                        color: modelData.connected ? Globals.customValue(themeScope + ".listItem", "activeColor", Globals.themeVars.Secondary25) : (ethMouse.containsMouse ? Globals.customValue(themeScope + ".listItem", "hoverColor", Globals.themeVars.Secondary10) : "transparent")



                        RowLayout {
                            id: delegateLayout
                            anchors.fill: parent
                            anchors.margins: Globals.customValue(themeScope + ".listItem.layout", "margins", Globals.themeVars.spacingMedium)
                            spacing: Globals.customValue(themeScope + ".listItem.layout", "spacing", Globals.themeVars.spacingMedium)

                            Icon {
                                Layout.preferredWidth: 18; Layout.preferredHeight: 18
                                path: "M16 11h-4V7h-3v4H5v2h4v4h3v-4h4v-2z"
                                color: modelData.hasLink ? Globals.themeVars.White : Globals.themeVars.SecondaryLight
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                Text {
                                    text: modelData.name || "Ethernet"
                                    color: Globals.themeVars.White
                                    font.pixelSize: Globals.themeVars.fontSizeMedium
                                    font.bold: modelData.connected
                                    elide: Text.ElideRight
                                }
                                Text {
                                    text: {
                                        if (!modelData.hasLink) return "Cable unplugged";
                                        if (modelData.state === ConnectionState.Connecting) return "Connecting…";
                                        if (modelData.connected) return modelData.linkSpeed > 0 ? modelData.linkSpeed + " Mbps" : "Connected";
                                        return "Disconnected";
                                    }
                                    color: Globals.themeVars.SecondaryLight
                                    font.pixelSize: Globals.themeVars.fontSizeSmall
                                }
                            }

                            Icon {
                                visible: modelData.connected
                                Layout.preferredWidth: 16; Layout.preferredHeight: 16
                                path: "M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z"
                                color: Globals.themeVars.Secondary
                            }
                            
                            Rectangle {
                                width: 24
                                height: 24
                                radius: 12
                                color: "transparent"
                                visible: ethMouse.containsMouse && modelData.hasLink && modelData.network && modelData.network.known
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
                                        if (modelData.network) modelData.network.forget();
                                    }
                                }
                            }
                            
                            Rectangle {
                                width: 24
                                height: 24
                                radius: 12
                                color: "transparent"
                                visible: ethMouse.containsMouse && modelData.hasLink
                                Icon {
                                    anchors.centerIn: parent
                                    width: 14; height: 14
                                    path: "M19.43 12.98c.04-.32.07-.64.07-.98s-.03-.66-.07-.98l2.11-1.65c.19-.15.24-.42.12-.64l-2-3.46c-.12-.22-.39-.3-.61-.22l-2.49 1c-.52-.4-1.08-.73-1.69-.98l-.38-2.65C14.46 2.18 14.25 2 14 2h-4c-.25 0-.46.18-.49.42l-.38 2.65c-.61.25-1.17.59-1.69.98l-2.49-1c-.23-.09-.49 0-.61.22l-2 3.46c-.13.22-.07.49.12.64l2.11 1.65c-.04.32-.07.65-.07.98s.03.66.07.98l-2.11 1.65c-.19.15-.24.42-.12.64l2 3.46c.12.22.39.3.61.22l2.49-1c.52.4 1.08.73 1.69.98l.38 2.65c.03.24.24.42.49.42h4c.25 0 .46-.18.49-.42l.38-2.65c.61-.25 1.17-.59 1.69-.98l2.49 1c.23.09.49 0 .61-.22l2-3.46c.12-.22.07-.49-.12-.64l-2.11-1.65zM12 15.5c-1.93 0-3.5-1.57-3.5-3.5s1.57-3.5 3.5-3.5 3.5 1.57 3.5 3.5-1.57 3.5-3.5 3.5z"
                                    color: Globals.themeVars.White
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Quickshell.execDetached(["nm-connection-editor"]);
                                    }
                                }
                            }
                        }


                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    
                    Text {
                        text: "Wi-Fi"
                        color: Globals.customValue(themeScope + ".header", "color", Globals.themeVars.White)
                        font.pixelSize: Globals.customValue(themeScope + ".header", "fontSize", Globals.themeVars.fontSizeLarge)
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        width: 48
                        height: 24
                        radius: 12
                        color: Networking.wifiEnabled ? Globals.customValue(themeScope + ".toggle", "activeColor", Globals.themeVars.Secondary) : Globals.customValue(themeScope + ".toggle", "inactiveColor", Globals.themeVars.Secondary25)
                        opacity: Networking.wifiHardwareEnabled ? 1.0 : 0.5
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Rectangle {
                            width: 20
                            height: 20
                            radius: 10
                            color: Globals.customValue(themeScope + ".toggle", "handleColor", Globals.themeVars.White)
                            y: 2
                            x: Networking.wifiEnabled ? 26 : 2
                            Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Networking.wifiHardwareEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            enabled: Networking.wifiHardwareEnabled
                            onClicked: {
                                Networking.wifiEnabled = !Networking.wifiEnabled;
                            }
                        }
                    }
                }

                ScrollView {
                    id: apScrollView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredHeight: Math.min(300, apList.implicitHeight)
                    clip: true
                    visible: Networking.wifiEnabled && popup.wifiDevice != null

                    ColumnLayout {
                        id: apList
                        width: apScrollView.width
                        spacing: Globals.customValue(themeScope + ".list", "spacing", Globals.themeVars.spacingMedium)

                        Text {
                            text: "No networks found"
                            visible: repeater.count === 0
                            color: Globals.themeVars.SecondaryLight
                            font.pixelSize: Globals.themeVars.fontSizeMedium
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Repeater {
                            id: repeater
                            model: {
                                if (!popup.wifiDevice || !popup.wifiDevice.networks) return [];
                                let nets = popup.wifiDevice.networks.values;
                                let seen = {};
                                let filtered = [];
                                for (let i = 0; i < nets.length; i++) {
                                    let ssid = nets[i].name;
                                    if (ssid && ssid !== "" && !seen[ssid]) {
                                        seen[ssid] = true;
                                        filtered.push(nets[i]);
                                    }
                                }
                                filtered.sort((a, b) => {
                                    if (a.connected && !b.connected) return -1;
                                    if (!a.connected && b.connected) return 1;
                                    if (a.known && !b.known) return -1;
                                    if (!a.known && b.known) return 1;
                                    return (b.signalStrength || 0) - (a.signalStrength || 0);
                                });
                                return filtered;
                            }
                            delegate: Rectangle {
                                property bool showPasswordInput: false
                                Layout.fillWidth: true
                                implicitHeight: Math.max(48, delegateLayout.implicitHeight + (Globals.themeVars.spacingMedium * 2))
                                radius: Globals.customValue(themeScope + ".listItem", "radius", Globals.themeVars.borderRadiusMedium)
                                color: modelData.connected ? Globals.customValue(themeScope + ".listItem", "activeColor", Globals.themeVars.Secondary25) : (apMouse.containsMouse || showPasswordInput ? Globals.customValue(themeScope + ".listItem", "hoverColor", Globals.themeVars.Secondary10) : "transparent")



                                Connections {
                                    target: modelData
                                    ignoreUnknownSignals: true
                                    function onConnectionFailed(reason) {
                                        if (reason === ConnectionFailReason.NoSecrets) {
                                            showPasswordInput = true;
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
                                        path: {
                                            let s = modelData.signalStrength !== undefined ? modelData.signalStrength : 1.0;
                                            if (s > 0.75) return "M12.01 21.49L23.64 7c-.45-.34-4.93-4-11.64-4C5.28 3 .81 6.66.36 7l11.63 14.49.01.01.01-.01z"; // 4 bars
                                            if (s > 0.5) return "M12.01 21.49L19.2 12.6c-.34-.26-3.8-2.6-7.2-2.6-3.4 0-6.86 2.34-7.2 2.6l7.19 8.89.01.01.01-.01z"; // 3 bars
                                            if (s > 0.25) return "M12.01 21.49L14.7 18.1c-.24-.18-2.68-1.85-5.07-1.85-2.39 0-4.83 1.67-5.07 1.85l2.69 3.39.01.01.01-.01z"; // 2 bars
                                            return "M12.01 21.49L12 21.5c-.17-.13-1.57-1.1-2.92-1.1-1.35 0-2.75.97-2.92 1.1l2.91 3.59.01.01.02-.01z"; // 1 bar
                                        }
                                        color: Globals.customValue(themeScope + ".listItem.icon", "color", Globals.themeVars.White)
                                        opacity: Math.max(0.3, modelData.signalStrength !== undefined ? modelData.signalStrength : 1.0)
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Text {
                                            text: modelData.name
                                            color: Globals.customValue(themeScope + ".listItem.text", "color", Globals.themeVars.White)
                                            font.pixelSize: Globals.customValue(themeScope + ".listItem.text", "fontSize", Globals.themeVars.fontSizeMedium)
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                            font.bold: modelData.connected
                                        }
                                        Text {
                                            visible: modelData.stateChanging || modelData.connected
                                            text: modelData.stateChanging ? "Connecting..." : (modelData.connected ? "Connected" : "")
                                            color: Globals.themeVars.SecondaryLight
                                            font.pixelSize: Globals.themeVars.fontSizeSmall
                                        }
                                        TextField {
                                            id: pskInput
                                            Layout.fillWidth: true
                                            visible: showPasswordInput
                                            placeholderText: "Password..."
                                            color: Globals.themeVars.White
                                            echoMode: TextInput.Password
                                            background: Rectangle {
                                                color: Globals.themeVars.Secondary10
                                                radius: 4
                                            }
                                            onAccepted: {
                                                modelData.connectWithPsk(text);
                                                showPasswordInput = false;
                                                text = "";
                                            }
                                            Keys.onEscapePressed: {
                                                showPasswordInput = false;
                                                text = "";
                                            }
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
                                        visible: apMouse.containsMouse && modelData.known && !showPasswordInput
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
