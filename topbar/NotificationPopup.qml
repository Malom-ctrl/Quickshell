import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications

PopupWindow {
    id: popup
    property bool isActive: false
    property var server: null
    property Item anchorItem: null

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
            color: Globals.activeColors.Black
            radius: 20
            border.color: Globals.activeColors.Secondary10
            border.width: 1

            ColumnLayout {
                id: contentLayout
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                RowLayout {
                    id: headerRow
                    Layout.fillWidth: true
                    Text {
                        text: "Notifications"
                        color: Globals.activeColors.White
                        font.pixelSize: 18
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        width: 32; height: 32; radius: 16
                        color: clearMouse.containsMouse ? Globals.activeColors.Secondary25 : "transparent"
                        visible: popup.server && popup.server.trackedNotifications.values.length > 0
                        Icon { anchors.centerIn: parent; width: 16; height: 16; path: "M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12z"; color: Globals.activeColors.White }
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
                    spacing: 8
                    model: popup.server ? popup.server.trackedNotifications.values : []

                    delegate: Rectangle {
                        width: ListView.view.width
                        height: notifCol.implicitHeight + 24
                        radius: 16
                        color: Globals.activeColors.Secondary10
                        border.color: "transparent"

                        ColumnLayout {
                            id: notifCol
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 8

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 12

                                // App initial
                                Rectangle {
                                    width: 28; height: 28; radius: 14
                                    color: Globals.activeColors.Black
                                    Layout.alignment: Qt.AlignVCenter
                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.appName ? modelData.appName.charAt(0).toUpperCase() : "!"
                                        color: Globals.activeColors.Secondary
                                        font.pixelSize: 14
                                        font.bold: true
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    Layout.alignment: Qt.AlignVCenter

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text {
                                            text: modelData.appName || "Notification"
                                            color: Globals.activeColors.SecondaryLight
                                            font.pixelSize: 11
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            text: "now" // Placeholder for time
                                            color: Globals.activeColors.SecondaryLight
                                            font.pixelSize: 11
                                        }
                                    }

                                    Text {
                                        text: modelData.summary || ""
                                        color: Globals.activeColors.White
                                        font.pixelSize: 13
                                        font.bold: true
                                        Layout.fillWidth: true
                                        wrapMode: Text.Wrap
                                    }

                                    Text {
                                        text: modelData.body || ""
                                        color: Globals.activeColors.SecondaryLight
                                        font.pixelSize: 12
                                        Layout.fillWidth: true
                                        wrapMode: Text.Wrap
                                        visible: text !== ""
                                    }
                                }

                                Rectangle {
                                    width: 28; height: 28; radius: 14
                                    color: closeMouse.containsMouse ? Globals.activeColors.Secondary25 : "transparent"
                                    Layout.alignment: Qt.AlignTop
                                    Icon { anchors.centerIn: parent; width: 14; height: 14; path: "M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12z"; color: Globals.activeColors.SecondaryLight }
                                    MouseArea {
                                        id: closeMouse; anchors.fill: parent; hoverEnabled: true
                                        onClicked: modelData.dismiss()
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6
                                visible: modelData.actions && modelData.actions.length > 0
                                Repeater {
                                    model: modelData.actions
                                    Rectangle {
                                        property var action: modelData
                                        color: actArea2.containsMouse ? Globals.activeColors.Secondary : Globals.activeColors.Secondary10
                                        radius: 12
                                        implicitWidth: actText2.implicitWidth + 24
                                        implicitHeight: 24
                                        Text {
                                            id: actText2
                                            anchors.centerIn: parent
                                            text: action.text ? (action.text.includes(':') ? action.text.split(':').pop() : (action.text.includes('=') ? action.text.split('=').pop() : action.text)) : ""
                                            color: actArea2.containsMouse ? Globals.activeColors.Black : Globals.activeColors.White
                                            font.pixelSize: 12
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
                    color: Globals.activeColors.SecondaryLight
                    font.pixelSize: 14
                    Layout.alignment: Qt.AlignCenter
                    Layout.fillHeight: true
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }
}
