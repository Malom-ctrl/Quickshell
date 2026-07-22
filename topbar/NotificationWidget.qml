import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications

Rectangle {
    id: root
    property string themeScope: "topbar.NotificationWidget"

    height: Globals.customValue(themeScope, "height", 40)
    implicitWidth: Math.max(40, layout.implicitWidth + 16)
    radius: Globals.customValue(themeScope, "radius", Globals.themeVars.borderRadiusHuge)
    color: (mouseArea.containsMouse || popupVisible) ? Globals.customValue(themeScope, "hoverColor", Globals.themeVars.Secondary50) : Globals.customValue(themeScope, "color", Globals.themeVars.Secondary25)
    Behavior on color { ColorAnimation { duration: 150 } }

    property bool popupVisible: false
    property var activeNotification: null

    NotificationServer {
        id: server
        actionsSupported: true
        onNotification: (notif) => {
            notif.tracked = true;
            root.activeNotification = notif;
            activeTimer.restart();
        }
    }

    Timer {
        id: activeTimer
        interval: 5000
        onTriggered: {
            root.activeNotification = null;
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.popupVisible = !root.popupVisible;
        }
    }

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: root.activeNotification ? Globals.customValue(themeScope + ".layout", "spacingActive", Globals.themeVars.spacingLarge) : Globals.customValue(themeScope + ".layout", "spacing", 0)
        Behavior on spacing { NumberAnimation { duration: 350; easing.type: Easing.OutQuint } }

        // Bell Icon & Count
        Item {
            width: Globals.customValue(themeScope + ".bellIcon", "width", 24); height: Globals.customValue(themeScope + ".bellIcon", "height", 24)
            Layout.alignment: Qt.AlignVCenter
            Icon {
                anchors.centerIn: parent
                path: root.activeNotification ? "M12 22c1.1 0 2-.9 2-2h-4c0 1.1.9 2 2 2zm6-6v-5c0-3.07-1.63-5.64-4.5-6.32V4c0-.83-.67-1.5-1.5-1.5s-1.5.67-1.5 1.5v.68C7.64 5.36 6 7.92 6 11v5l-2 2v1h16v-1l-2-2z" : "M12 22c1.1 0 2-.9 2-2h-4c0 1.1.9 2 2 2zm6-6v-5c0-3.07-1.63-5.64-4.5-6.32V4c0-.83-.67-1.5-1.5-1.5s-1.5.67-1.5 1.5v.68C7.64 5.36 6 7.92 6 11v5l-2 2v1h16v-1l-2-2zm-2 1H8v-6c0-2.48 1.51-4.5 4-4.5s4 2.02 4 4.5v6z"
                color: root.activeNotification ? Globals.customValue(themeScope + ".bellIcon.icon", "activeColor", Globals.themeVars.Secondary) : Globals.customValue(themeScope + ".bellIcon.icon", "color", Globals.themeVars.White)
            }
            Rectangle {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: Globals.customValue(themeScope + ".badge", "margins", -4)
                width: Globals.customValue(themeScope + ".badge", "width", 14); height: Globals.customValue(themeScope + ".badge", "height", 14)
                radius: Globals.customValue(themeScope + ".badge", "radius", Globals.themeVars.borderRadiusSmall)
                color: Globals.customValue(themeScope + ".badge", "color", Globals.themeVars.Secondary)
                visible: server.trackedNotifications.values.length > 0
                Text {
                    anchors.centerIn: parent
                    text: server.trackedNotifications.values.length
                    color: Globals.customValue(themeScope + ".badge.text", "color", Globals.themeVars.Black)
                    font.pixelSize: Globals.customValue(themeScope + ".badge.text", "fontSize", Globals.themeVars.fontSizeSmall)
                    font.bold: true
                }
            }
        }

        // Expanded Incoming Notification
        Item {
            id: expander
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredHeight: 32
            Layout.preferredWidth: root.activeNotification ? expandedLayout.implicitWidth : 0
            clip: true

            Behavior on Layout.preferredWidth {
                NumberAnimation { duration: 350; easing.type: Easing.OutQuint }
            }

            RowLayout {
                id: expandedLayout
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: Globals.customValue(themeScope + ".expandedLayout", "spacing", Globals.themeVars.spacingLarge)
                opacity: root.activeNotification ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 250 } }

                // App initial
                Rectangle {
                    width: Globals.customValue(themeScope + ".expandedIcon", "width", 28); height: Globals.customValue(themeScope + ".expandedIcon", "height", 28); radius: Globals.customValue(themeScope + ".expandedIcon", "radius", Globals.themeVars.borderRadiusMedium)
                    color: Globals.customValue(themeScope + ".expandedIcon", "color", Globals.themeVars.Black)
                    Layout.alignment: Qt.AlignVCenter
                    Text {
                        anchors.centerIn: parent
                        text: root.activeNotification && root.activeNotification.appName ? root.activeNotification.appName.charAt(0).toUpperCase() : "!"
                        color: Globals.customValue(themeScope + ".expandedIcon.text", "color", Globals.themeVars.Secondary)
                        font.pixelSize: Globals.customValue(themeScope + ".expandedIcon.text", "fontSize", Globals.themeVars.fontSizeMedium)
                        font.bold: true
                    }
                }

                // Title and Body
                ColumnLayout {
                    spacing: Globals.customValue(themeScope + ".expandedText", "spacing", Globals.themeVars.spacingSmall)
                    Layout.alignment: Qt.AlignVCenter
                    Layout.maximumWidth: Globals.customValue(themeScope + ".expandedText", "maximumWidth", 180)

                    Text {
                        text: root.activeNotification ? root.activeNotification.summary : ""
                        color: Globals.customValue(themeScope + ".expandedText.title", "color", Globals.themeVars.White)
                        font.pixelSize: Globals.customValue(themeScope + ".expandedText.title", "fontSize", Globals.themeVars.fontSizeMedium)
                        font.bold: true
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    Text {
                        text: root.activeNotification ? root.activeNotification.body : ""
                        color: Globals.customValue(themeScope + ".expandedText.body", "color", Globals.themeVars.SecondaryLight)
                        font.pixelSize: Globals.customValue(themeScope + ".expandedText.body", "fontSize", Globals.themeVars.fontSizeSmall)
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        visible: text !== ""
                    }
                }

                // Actions
                RowLayout {
                    spacing: Globals.customValue(themeScope + ".expandedActions", "spacing", Globals.themeVars.spacingMedium)
                    Repeater {
                        model: root.activeNotification ? root.activeNotification.actions : []
                        Rectangle {
                            property var action: modelData
                            color: actArea.containsMouse ? Globals.customValue(themeScope + ".expandedActions.action", "hoverColor", Globals.themeVars.Secondary) : Globals.customValue(themeScope + ".expandedActions.action", "color", Globals.themeVars.Secondary10)
                            radius: Globals.customValue(themeScope + ".expandedActions.action", "radius", Globals.themeVars.borderRadiusMedium)
                            implicitWidth: actText.implicitWidth + 24
                            implicitHeight: Globals.customValue(themeScope + ".expandedActions.action", "height", 24)
                            Text {
                                id: actText
                                anchors.centerIn: parent
                                text: action.text ? (action.text.includes(':') ? action.text.split(':').pop() : (action.text.includes('=') ? action.text.split('=').pop() : action.text)) : ""
                                color: actArea.containsMouse ? Globals.customValue(themeScope + ".expandedActions.text", "hoverColor", Globals.themeVars.Black) : Globals.customValue(themeScope + ".expandedActions.text", "color", Globals.themeVars.White)
                                font.pixelSize: Globals.customValue(themeScope + ".expandedActions.text", "fontSize", Globals.themeVars.fontSizeSmall)
                                font.bold: true
                            }
                            MouseArea {
                                id: actArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    action.invoke();
                                    // root.activeNotification.dismiss();
                                    root.activeNotification = null;
                                    activeTimer.stop();
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    NotificationPopup {
        id: popup
        isActive: root.popupVisible
        server: server
        anchorItem: root
    }
}
