import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Rectangle {
    id: root
    property string themeScope: "topbar.PowerControls"
    width: Globals.customValue(themeScope, "width", 40)
    height: Globals.customValue(themeScope, "height", 40)
    radius: Globals.customValue(themeScope, "radius", Globals.themeVars.borderRadiusHuge)
    color: mouseArea.containsMouse ? Globals.customValue(themeScope, "hoverColor", Globals.themeVars.Secondary25) : Globals.customValue(themeScope, "color", Globals.themeVars.Secondary10)
    Behavior on color { ColorAnimation { duration: 150 } }

    property bool popupVisible: false

    Icon {
        anchors.centerIn: parent
        width: Globals.customValue(themeScope + ".icon", "width", 20); height: Globals.customValue(themeScope + ".icon", "height", 20)
        path: "M13 3h-2v10h2V3zm4.83 2.17l-1.42 1.42C17.99 7.86 19 9.81 19 12c0 3.87-3.13 7-7 7s-7-3.13-7-7c0-2.19 1.01-4.14 2.58-5.42L6.17 5.17C4.23 6.82 3 9.26 3 12c0 4.97 4.03 9 9 9s9-4.03 9-9c0-2.74-1.23-5.18-3.17-6.83z"
        color: Globals.customValue(themeScope + ".icon", "color", Globals.themeVars.White)
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.popupVisible = !root.popupVisible
    }

    PopupWindow {
        id: powerPopup

        property bool isActive: root.popupVisible
        visible: isActive || openProgress > 0.0

        property real openProgress: isActive ? 1.0 : 0.0
        Behavior on openProgress {
            NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
        }

        onOpenProgressChanged: {
            if (openProgress === 0.0 && !isActive) visible = false;
            else if (isActive && !visible) visible = true;
        }

        anchor {
            item: root
            edges: Edges.Bottom
            gravity: Edges.Bottom
            margins.top: Globals.popupMargin
        }

        implicitWidth: popupLayout.implicitWidth + 16 + (2 * Globals.popupScreenPadding)
        implicitHeight: popupLayout.implicitHeight + 16
        color: "transparent"

        Item {
            width: parent.width - (2 * Globals.popupScreenPadding)
            height: parent.height
            anchors.horizontalCenter: parent.horizontalCenter
            scale: 0.9 + (0.1 * powerPopup.openProgress)
            opacity: powerPopup.openProgress
            transformOrigin: Item.Top

            Rectangle {
                anchors.fill: parent
                color: Globals.customValue(themeScope + ".popup", "color", Globals.themeVars.Black)
                radius: Globals.customValue(themeScope + ".popup", "radius", Globals.themeVars.borderRadiusLarge)
                border.color: Globals.customValue(themeScope + ".popup", "borderColor", Globals.themeVars.Secondary10)
                border.width: Globals.customValue(themeScope + ".popup", "borderWidth", Globals.themeVars.borderWidthSmall)

                ColumnLayout {
                    id: popupLayout
                    anchors.centerIn: parent
                    spacing: Globals.customValue(themeScope + ".popup.layout", "spacing", 4)

                    component PowerButton: Rectangle {
                        id: btn
                        property string iconPath: ""
                        property string actionCmd: ""
                        property string text: ""
                        property color hoverBg: Globals.customValue(themeScope + ".popup.button", "hoverColor", Globals.themeVars.Secondary25)
                        property color iconColor: Globals.customValue(themeScope + ".popup.button.icon", "color", Globals.themeVars.White)

                        Layout.fillWidth: true
                        implicitWidth: Globals.customValue(themeScope + ".popup.button", "width", 160)
                        implicitHeight: Globals.customValue(themeScope + ".popup.button", "height", 48)
                        radius: Globals.customValue(themeScope + ".popup.button", "radius", Globals.themeVars.borderRadiusMedium)
                        color: btnMouse.containsMouse ? hoverBg : "transparent"

                        Behavior on color { ColorAnimation { duration: 150 } }

                        Process {
                            id: actionProc
                            command: ["bash", "-c", actionCmd]
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: Globals.customValue(themeScope + ".popup.button.layout", "margins", Globals.themeVars.spacingLarge)
                            spacing: Globals.customValue(themeScope + ".popup.button.layout", "spacing", Globals.themeVars.spacingLarge)
                            Icon {
                                Layout.alignment: Qt.AlignVCenter
                                width: Globals.customValue(themeScope + ".popup.button.icon", "width", 20); height: Globals.customValue(themeScope + ".popup.button.icon", "height", 20)
                                path: iconPath
                                color: btn.iconColor
                            }
                            Text {
                                Layout.alignment: Qt.AlignVCenter
                                Layout.fillWidth: true
                                text: btn.text
                                color: Globals.customValue(themeScope + ".popup.button.text", "color", Globals.themeVars.White)
                                font.pixelSize: Globals.customValue(themeScope + ".popup.button.text", "fontSize", Globals.themeVars.fontSizeMedium)
                            }
                        }

                        MouseArea {
                            id: btnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (actionCmd !== "") {
                                    actionProc.running = false
                                    actionProc.running = true
                                    root.popupVisible = false
                                }
                            }
                        }
                    }

                    PowerButton {
                        text: "Lock"
                        iconPath: "M18 8h-1V6c0-2.76-2.24-5-5-5S7 3.24 7 6v2H6c-1.1 0-2 .9-2 2v10c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V10c0-1.1-.9-2-2-2zM9 6c0-1.66 1.34-3 3-3s3 1.34 3 3v2H9V6zm9 14H6V10h12v10zm-6-3c1.1 0 2-.9 2-2s-.9-2-2-2-2 .9-2 2 .9 2 2 2z"
                        actionCmd: "swaylock -f -c 000000"
                    }

                    PowerButton {
                        text: "Suspend"
                        iconPath: "M12 22c5.52 0 10-4.48 10-10S17.52 2 12 2 2 6.48 2 12s4.48 10 10 10zm1-17.93c3.94.49 7 3.85 7 7.93s-3.05 7.44-7 7.93V4.07z"
                        actionCmd: "systemctl suspend"
                    }

                    PowerButton {
                        text: "Reboot"
                        iconPath: "M17.65 6.35C16.2 4.9 14.21 4 12 4c-4.42 0-7.99 3.58-7.99 8s3.57 8 7.99 8c3.73 0 6.84-2.55 7.73-6h-2.08c-.82 2.33-3.04 4-5.65 4-3.31 0-6-2.69-6-6s2.69-6 6-6c1.66 0 3.14.69 4.22 1.78L13 11h7V4l-2.35 2.35z"
                        actionCmd: "systemctl reboot"
                    }

                    PowerButton {
                        text: "Power Off"
                        iconPath: "M13 3h-2v10h2V3zm4.83 2.17l-1.42 1.42C17.99 7.86 19 9.81 19 12c0 3.87-3.13 7-7 7s-7-3.13-7-7c0-2.19 1.01-4.14 2.58-5.42L6.17 5.17C4.23 6.82 3 9.26 3 12c0 4.97 4.03 9 9 9s9-4.03 9-9c0-2.74-1.23-5.18-3.17-6.83z"
                        actionCmd: "systemctl poweroff"
                        hoverBg: Globals.customValue(themeScope + ".popup.powerOff", "hoverColor", Globals.themeVars.Error)
                    }
                }
            }
        }
    }
}
