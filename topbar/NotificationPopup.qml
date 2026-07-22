import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications

PopupWindow {
    id: popup
    property bool isActive: false
    property var server: null
    property Item anchorItem: null

    property string themeScope: "topbar.NotificationPopup"

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
        item: anchorItem
        edges: Edges.Bottom
        gravity: Edges.Bottom
        margins.top: Globals.popupMargin
    }

    width: 360 + (2 * Globals.popupScreenPadding)
    height: Math.min(600, contentLayout.implicitHeight + 32)
    color: "transparent"

    Item {
        width: parent.width - (2 * Globals.popupScreenPadding)
        height: parent.height
        anchors.horizontalCenter: parent.horizontalCenter
        scale: 0.9 + (0.1 * popup.openProgress)
        opacity: popup.openProgress
        transformOrigin: Item.Top

        Rectangle {
            anchors.fill: parent
            color: Globals.customValue(root.themeScope + ".popup", "color", Globals.themeVars.Black)
            radius: Globals.customValue(root.themeScope + ".popup", "radius", Globals.themeVars.borderRadiusHuge)
            border.color: Globals.customValue(root.themeScope + ".popup", "borderColor", Globals.themeVars.Secondary10)
            border.width: Globals.customValue(root.themeScope + ".popup", "borderWidth", Globals.themeVars.borderWidthSmall)

            ColumnLayout {
                id: contentLayout
                anchors.fill: parent
                anchors.margins: Globals.customValue(root.themeScope + ".popup.layout", "margins", Globals.themeVars.spacingHuge)
                spacing: Globals.customValue(root.themeScope + ".popup.layout", "spacing", Globals.themeVars.spacingLarge)

                RowLayout {
                    id: headerRow
                    Layout.fillWidth: true
                    Text {
                        text: "Notifications"
                        color: Globals.customValue(root.themeScope + ".popup.header", "color", Globals.themeVars.White)
                        font.pixelSize: Globals.customValue(root.themeScope + ".popup.header", "fontSize", Globals.themeVars.fontSizeLarge)
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        width: Globals.customValue(root.themeScope + ".popup.clearBtn", "width", 32); height: Globals.customValue(root.themeScope + ".popup.clearBtn", "height", 32); radius: Globals.customValue(root.themeScope + ".popup.clearBtn", "radius", Globals.themeVars.borderRadiusLarge)
                        color: clearMouse.containsMouse ? Globals.customValue(root.themeScope + ".popup.clearBtn", "hoverColor", Globals.themeVars.Secondary25) : "transparent"
                        visible: popup.server && popup.server.trackedNotifications.values.length > 0
                        Icon { anchors.centerIn: parent; width: Globals.customValue(root.themeScope + ".popup.clearBtn.icon", "width", 16); height: Globals.customValue(root.themeScope + ".popup.clearBtn.icon", "height", 16); path: "M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12z"; color: Globals.customValue(root.themeScope + ".popup.clearBtn.icon", "color", Globals.themeVars.White) }
                        MouseArea {
                            id: clearMouse; anchors.fill: parent; hoverEnabled: true
                            onClicked: {
                                if (!popup.server) return;
                                let values = popup.server.trackedNotifications.values;
                                for(let i = values.length - 1; i >= 0; i--) {
                                    values[i].dismiss();
                                }
                            }
                        }
                    }
                }

                ListView {
                    id: listView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredHeight: Math.max(1, contentHeight)
                    clip: true
                    spacing: Globals.customValue(root.themeScope + ".popup.list", "spacing", Globals.themeVars.spacingMedium)
                    model: popup.server ? popup.server.trackedNotifications.values : []

                    delegate: Rectangle {
                        width: ListView.view.width
                        height: notifCol.implicitHeight + Globals.customValue(root.themeScope + ".popup.listItem", "padding", Globals.themeVars.spacingHuge)
                        radius: Globals.customValue(root.themeScope + ".popup.listItem", "radius", Globals.themeVars.borderRadiusLarge)
                        color: Globals.customValue(root.themeScope + ".popup.listItem", "color", Globals.themeVars.Secondary10)
                        border.color: Globals.customValue(root.themeScope + ".popup.listItem", "borderColor", "transparent")

                        ColumnLayout {
                            id: notifCol
                            anchors.fill: parent
                            anchors.margins: Globals.customValue(root.themeScope + ".popup.listItem.layout", "margins", Globals.themeVars.spacingLarge)
                            spacing: Globals.customValue(root.themeScope + ".popup.listItem.layout", "spacing", Globals.themeVars.spacingMedium)

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Globals.customValue(root.themeScope + ".popup.listItem.header", "spacing", Globals.themeVars.spacingLarge)

                                // App initial
                                Rectangle {
                                    width: Globals.customValue(root.themeScope + ".popup.listItem.icon", "width", 28); height: Globals.customValue(root.themeScope + ".popup.listItem.icon", "height", 28); radius: Globals.customValue(root.themeScope + ".popup.listItem.icon", "radius", Globals.themeVars.borderRadiusMedium)
                                    color: Globals.customValue(root.themeScope + ".popup.listItem.icon", "color", Globals.themeVars.Black)
                                    Layout.alignment: Qt.AlignVCenter
                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.appName ? modelData.appName.charAt(0).toUpperCase() : "!"
                                        color: Globals.customValue(root.themeScope + ".popup.listItem.icon.text", "color", Globals.themeVars.Secondary)
                                        font.pixelSize: Globals.customValue(root.themeScope + ".popup.listItem.icon.text", "fontSize", Globals.themeVars.fontSizeMedium)
                                        font.bold: true
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: Globals.customValue(root.themeScope + ".popup.listItem.text", "spacing", Globals.themeVars.spacingSmall)
                                    Layout.alignment: Qt.AlignVCenter

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text {
                                            text: modelData.appName || "Notification"
                                            color: Globals.customValue(root.themeScope + ".popup.listItem.appName", "color", Globals.themeVars.SecondaryLight)
                                            font.pixelSize: Globals.customValue(root.themeScope + ".popup.listItem.appName", "fontSize", Globals.themeVars.fontSizeSmall)
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            text: "now" // Placeholder for time
                                            color: Globals.customValue(root.themeScope + ".popup.listItem.time", "color", Globals.themeVars.SecondaryLight)
                                            font.pixelSize: Globals.customValue(root.themeScope + ".popup.listItem.time", "fontSize", Globals.themeVars.fontSizeSmall)
                                        }
                                    }

                                    Text {
                                        text: modelData.summary || ""
                                        color: Globals.customValue(root.themeScope + ".popup.listItem.summary", "color", Globals.themeVars.White)
                                        font.pixelSize: Globals.customValue(root.themeScope + ".popup.listItem.summary", "fontSize", Globals.themeVars.fontSizeMedium)
                                        font.bold: true
                                        Layout.fillWidth: true
                                        wrapMode: Text.Wrap
                                    }

                                    Text {
                                        text: modelData.body || ""
                                        color: Globals.customValue(root.themeScope + ".popup.listItem.body", "color", Globals.themeVars.SecondaryLight)
                                        font.pixelSize: Globals.customValue(root.themeScope + ".popup.listItem.body", "fontSize", Globals.themeVars.fontSizeSmall)
                                        Layout.fillWidth: true
                                        wrapMode: Text.Wrap
                                        visible: text !== ""
                                    }
                                }

                                Rectangle {
                                    width: Globals.customValue(root.themeScope + ".popup.listItem.closeBtn", "width", 28); height: Globals.customValue(root.themeScope + ".popup.listItem.closeBtn", "height", 28); radius: Globals.customValue(root.themeScope + ".popup.listItem.closeBtn", "radius", Globals.themeVars.borderRadiusMedium)
                                    color: closeMouse.containsMouse ? Globals.customValue(root.themeScope + ".popup.listItem.closeBtn", "hoverColor", Globals.themeVars.Secondary25) : "transparent"
                                    Layout.alignment: Qt.AlignTop
                                    Icon { anchors.centerIn: parent; width: Globals.customValue(root.themeScope + ".popup.listItem.closeBtn.icon", "width", 14); height: Globals.customValue(root.themeScope + ".popup.listItem.closeBtn.icon", "height", 14); path: "M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12z"; color: Globals.customValue(root.themeScope + ".popup.listItem.closeBtn.icon", "color", Globals.themeVars.SecondaryLight) }
                                    MouseArea {
                                        id: closeMouse; anchors.fill: parent; hoverEnabled: true
                                        onClicked: modelData.dismiss()
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Globals.customValue(root.themeScope + ".popup.listItem.actions", "spacing", Globals.themeVars.spacingMedium)
                                visible: modelData.actions && modelData.actions.length > 0
                                Repeater {
                                    model: modelData.actions
                                    Rectangle {
                                        property var action: modelData
                                        color: actArea2.containsMouse ? Globals.customValue(root.themeScope + ".popup.listItem.action", "hoverColor", Globals.themeVars.Secondary) : Globals.customValue(root.themeScope + ".popup.listItem.action", "color", Globals.themeVars.Secondary10)
                                        radius: Globals.customValue(root.themeScope + ".popup.listItem.action", "radius", Globals.themeVars.borderRadiusMedium)
                                        implicitWidth: actText2.implicitWidth + 24
                                        implicitHeight: Globals.customValue(root.themeScope + ".popup.listItem.action", "height", 24)
                                        Text {
                                            id: actText2
                                            anchors.centerIn: parent
                                            text: action.text ? (action.text.includes(':') ? action.text.split(':').pop() : (action.text.includes('=') ? action.text.split('=').pop() : action.text)) : ""
                                            color: actArea2.containsMouse ? Globals.customValue(root.themeScope + ".popup.listItem.actionText", "hoverColor", Globals.themeVars.Black) : Globals.customValue(root.themeScope + ".popup.listItem.actionText", "color", Globals.themeVars.White)
                                            font.pixelSize: Globals.customValue(root.themeScope + ".popup.listItem.actionText", "fontSize", Globals.themeVars.fontSizeSmall)
                                            font.bold: true
                                        }
                                        MouseArea {
                                            id: actArea2
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: {
                                                action.invoke()
                                                // modelData.dismiss()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Text {
                    visible: !popup.server || popup.server.trackedNotifications.values.length === 0
                    text: "No new notifications"
                    color: Globals.customValue(root.themeScope + ".popup.emptyText", "color", Globals.themeVars.SecondaryLight)
                    font.pixelSize: Globals.customValue(root.themeScope + ".popup.emptyText", "fontSize", Globals.themeVars.fontSizeMedium)
                    Layout.alignment: Qt.AlignCenter
                    Layout.fillHeight: true
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }
}
