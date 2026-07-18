import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire

PanelWindow {
    id: root

    property var modelData
    screen: modelData

    PwObjectTracker {
        objects: Pipewire.nodes.values
    }

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: 56
    margins { top: 12; left: 12; right: 12 }
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        color: Globals.activeColors.Black
        radius: height / 2
        border.color: Globals.activeColors.Secondary10
        border.width: 1

        Item {
            anchors.fill: parent
            anchors.margins: 8

            // Left group
            Row {
                anchors.leftMargin: 12
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12

                Workspaces {
                    outputName: root.screen ? root.screen.name : ""
                }
            }

            // True centered group
            Row {
                anchors.centerIn: parent
                spacing: 12

                Rectangle {
                    width: 40
                    height: 40
                    radius: 20
                    color: Globals.activeColors.Warning

                    visible: Pipewire.nodes.values.some(n => {
                        if (!n.ready) return false
                        const p = n.properties || {}
                        return p["media.class"] === "Stream/Input/Video"
                            || p["media.class"] === "Stream/Output/Video"
                            || (p["media.name"] && String(p["media.name"]).includes("screen-cast"))
                    })

                    Icon {
                        anchors.centerIn: parent
                        width: 18
                        height: 18
                        path: "M17 10.5V7c0-.55-.45-1-1-1H4c-.55 0-1 .45-1 1v10c0 .55.45 1 1 1h12c.55 0 1-.45 1-1v-3.5l4 4v-11l-4 4z"
                        color: Globals.activeColors.White
                    }
                }

                Rectangle {
                    width: 40
                    height: 40
                    radius: 20
                    color: Globals.activeColors.Warning

                    visible: Pipewire.nodes.values.some(n => {
                        if (!n.ready) return false
                        const p = n.properties || {}
                        return p["media.class"] === "Stream/Input/Audio"
                    })

                    Icon {
                        anchors.centerIn: parent
                        width: 18
                        height: 18
                        path: "M12 14c1.66 0 3-1.34 3-3V5c0-1.66-1.34-3-3-3S9 3.34 9 5v6c0 1.66 1.34 3 3 3zm5.91-3c-.49 0-.9.36-.98.85C16.52 14.2 14.47 16 12 16s-4.52-1.8-4.93-4.15c-.08-.49-.49-.85-.98-.85-.61 0-1.09.54-1 1.14.49 3 2.89 5.35 5.91 5.78V20c0 .55.45 1 1 1s1-.45 1-1v-2.08c3.02-.43 5.42-2.78 5.91-5.78.1-.6-.39-1.14-1-1.14z"
                        color: Globals.activeColors.White
                    }
                }

                Media { }

                Clock { }

                NotificationWidget { }
            }

            // Right group
            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12

                SystemInfo { }

                ThemeWidget { }

                AudioControl {
                    id: audioControl
                }

                PowerProfile { }
                Battery { }
                UpdaterWidget { }
                PowerControls { }
            }
        }
    }

    AudioPopup {
        id: audioPopup
        screen: root.screen
        isActive: audioControl.popupVisible
        anchorItem: audioControl
    }
}
