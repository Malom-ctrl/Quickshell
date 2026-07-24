import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Shapes
import Quickshell

PopupWindow {
    id: root
    property bool isActive: false
    property var widgetRoot: null
    grabFocus: true

    
    Connections {
        target: Globals
        function onClosePopups() {
            if (root.isActive) { root.isActive = false; root.visible = false; }
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
        edges: Edges.Bottom
        gravity: Edges.Bottom
        margins.top: Globals.popupMargin
    }

    property string themeScope: "topbar.AutoresticPopup"

    implicitWidth: Globals.customValue(themeScope + ".popup", "width", 300) + (2 * Globals.popupScreenPadding)
    implicitHeight: Globals.customValue(themeScope + ".popup", "height", Math.min(600, layout.implicitHeight + Globals.customValue(themeScope + ".layout", "margins", Globals.themeVars.spacingHuge) * 2))

    color: "transparent"

    Item {
        width: parent.width - (2 * Globals.popupScreenPadding)
        height: parent.height
        anchors.horizontalCenter: parent.horizontalCenter
        scale: 0.9 + (0.1 * root.openProgress)
        opacity: root.openProgress
        transformOrigin: Item.Top

        Rectangle {
            anchors.fill: parent
            color: Globals.customValue(themeScope + ".background", "color", Globals.themeVars.Black)
            radius: Globals.customValue(themeScope + ".background", "radius", Globals.themeVars.borderRadiusHuge)
            border.color: Globals.customValue(themeScope + ".background", "borderColor", Globals.themeVars.Secondary10)
            border.width: Globals.customValue(themeScope + ".background", "borderWidth", Globals.themeVars.borderWidthSmall)
            clip: true

            ColumnLayout {
                id: layout
                anchors.fill: parent
                anchors.margins: Globals.customValue(themeScope + ".layout", "margins", Globals.themeVars.spacingHuge)
                spacing: Globals.customValue(themeScope + ".layout", "spacing", Globals.themeVars.spacingHuge)

                Text {
                    text: "Autorestic Backup"
                    color: Globals.customValue(themeScope + ".header", "color", Globals.themeVars.White)
                    font.pixelSize: Globals.customValue(themeScope + ".header", "fontSize", Globals.themeVars.fontSizeLarge)
                    font.bold: true
                    Layout.fillWidth: true
                }

                GridLayout {
                    columns: 2
                    Layout.fillWidth: true
                    rowSpacing: Globals.customValue(themeScope + ".grid", "rowSpacing", Globals.themeVars.spacingSmall)
                    columnSpacing: Globals.customValue(themeScope + ".grid", "columnSpacing", Globals.themeVars.spacingLarge)

                    Text { text: "Last Backup:"; color: Globals.customValue(themeScope + ".lastBackupLabel", "color", Globals.themeVars.SecondaryLight); font.pixelSize: Globals.customValue(themeScope + ".lastBackupLabel", "fontSize", Globals.themeVars.fontSizeMedium) }
                    Text {
                        text: (widgetRoot && widgetRoot.lastBackupFormatted && widgetRoot.lastBackupFormatted !== "Never") ? widgetRoot.lastBackupFormatted : "Never"
                        color: Globals.customValue(themeScope + ".lastBackupValue", "color", Globals.themeVars.White)
                        font.pixelSize: Globals.customValue(themeScope + ".lastBackupValue", "fontSize", Globals.themeVars.fontSizeMedium)
                        font.bold: true
                    }

                    Text { text: "Auto-Backup:"; color: Globals.customValue(themeScope + ".autoBackupLabel", "color", Globals.themeVars.SecondaryLight); font.pixelSize: Globals.customValue(themeScope + ".autoBackupLabel", "fontSize", Globals.themeVars.fontSizeMedium) }
                    Text {
                        text: widgetRoot ? widgetRoot.serviceHealth : "unknown"
                        color: (widgetRoot && (widgetRoot.isFailed || widgetRoot.hasLogWarning)) ? Globals.customValue(themeScope + ".autoBackupValue", "errorColor", Globals.themeVars.Warning) : Globals.customValue(themeScope + ".autoBackupValue", "successColor", Globals.themeVars.Success)
                        font.pixelSize: Globals.customValue(themeScope + ".autoBackupValue", "fontSize", Globals.themeVars.fontSizeMedium)
                        font.bold: true
                    }

                    Text { text: "Service State:"; color: Globals.customValue(themeScope + ".serviceStateLabel", "color", Globals.themeVars.SecondaryLight); font.pixelSize: Globals.customValue(themeScope + ".serviceStateLabel", "fontSize", Globals.themeVars.fontSizeMedium) }
                    Text {
                        text: widgetRoot ? widgetRoot.serviceStateDisplay : "unknown"
                        color: Globals.customValue(themeScope + ".serviceStateValue", "color", Globals.themeVars.White)
                        font.pixelSize: Globals.customValue(themeScope + ".serviceStateValue", "fontSize", Globals.themeVars.fontSizeMedium)
                        font.bold: true
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Globals.customValue(themeScope + ".buttonLayout", "spacing", Globals.themeVars.spacingSmall)
                    Layout.topMargin: Globals.customValue(themeScope + ".buttonLayout", "topMargin", Globals.themeVars.spacingSmall)

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Globals.customValue(themeScope + ".button", "height", 36)
                        radius: Globals.customValue(themeScope + ".button", "radius", Globals.themeVars.borderRadiusMedium)
                        color: triggerMouse.containsMouse ? Globals.customValue(themeScope + ".button", "hoverColor", Globals.themeVars.Secondary) : Globals.customValue(themeScope + ".button", "color", Globals.themeVars.Secondary25)
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent
                            text: (widgetRoot && widgetRoot.isRunning) ? "Running..." : "Force Backup Now"
                            color: triggerMouse.containsMouse ? Globals.customValue(themeScope + ".button", "hoverTextColor", Globals.themeVars.Black) : Globals.customValue(themeScope + ".button", "textColor", Globals.themeVars.White)
                            font.pixelSize: Globals.customValue(themeScope + ".button", "fontSize", Globals.themeVars.fontSizeMedium)
                            font.bold: true
                        }
                        MouseArea {
                            id: triggerMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            enabled: widgetRoot && !widgetRoot.isRunning
                            onClicked: {
                                if (widgetRoot) widgetRoot.forceBackup();
                            }
                        }
                    }
                }

                // Warning/Error Section
                ColumnLayout {
                    visible: widgetRoot && (widgetRoot.isFailed || widgetRoot.hasLogWarning)
                    Layout.fillWidth: true
                    spacing: Globals.customValue(themeScope + ".warning", "spacing", Globals.themeVars.spacingSmall)

                    Rectangle {
                        Layout.fillWidth: true
                        height: Globals.customValue(themeScope + ".warning.divider", "height", 1)
                        color: Globals.customValue(themeScope + ".warning.divider", "color", Globals.themeVars.Warning)
                        opacity: Globals.customValue(themeScope + ".warning.divider", "opacity", 0.5)
                    }

                    Text {
                        text: "Recent Warning/Error:"
                        color: Globals.customValue(themeScope + ".warning", "textColor", Globals.themeVars.Warning)
                        font.pixelSize: Globals.customValue(themeScope + ".warning", "fontSize", Globals.themeVars.fontSizeMedium)
                        font.bold: true
                        Layout.topMargin: Globals.customValue(themeScope + ".warning", "topMargin", Globals.themeVars.spacingSmall)
                    }

                    Text {
                        text: (widgetRoot && widgetRoot.lastLogLine !== "") ? widgetRoot.lastLogLine : "No recent errors found in logs."
                        color: Globals.customValue(themeScope + ".warning", "textColor", Globals.themeVars.Warning)
                        font.pixelSize: Globals.customValue(themeScope + ".warning.content", "fontSize", Globals.themeVars.fontSizeSmall)
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }
                }

                Item { Layout.fillHeight: true } // spacer
            }
        }
    }
}
