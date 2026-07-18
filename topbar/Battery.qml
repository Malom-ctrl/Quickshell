import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Shapes
import Quickshell
import Quickshell.Services.UPower

Item {
    id: root
    width: 40
    height: 40

    readonly property bool hasBattery: UPower.displayDevice.isLaptopBattery
    readonly property real batteryPctRaw: hasBattery ? UPower.displayDevice.percentage : 1.0
    readonly property int capacity: Math.round(batteryPctRaw * 100)
    readonly property int arcCapacity: Math.max(0, Math.min(capacity, 100))

    readonly property int deviceState: hasBattery ? UPower.displayDevice.state : UPowerDeviceState.FullyCharged
    readonly property real changeRate: hasBattery ? UPower.displayDevice.changeRate : 0

    readonly property bool isCharging: deviceState === UPowerDeviceState.Charging
                                   || deviceState === UPowerDeviceState.PendingCharge
    readonly property bool isFull: deviceState === UPowerDeviceState.FullyCharged || (!hasBattery)
    readonly property bool isPlugged: isCharging || isFull
    readonly property bool isLow: capacity <= 20 && !isCharging

    property color accentColor: {
        if (isLow) return Globals.activeColors.error
        if (isPlugged) return Globals.activeColors.success
        return Globals.activeColors.onSecondaryContainer
    }

    property color bgColor: Globals.activeColors.secondaryContainer
    property color fgColor: accentColor

    property bool hovered: hoverArea.containsMouse
    property bool showTooltip: false

    Timer {
        id: tooltipTimer
        interval: 250
        onTriggered: root.showTooltip = true
    }

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: root.bgColor

        Shape {
            anchors.fill: parent
            antialiasing: true
            preferredRendererType: Shape.CurveRenderer
            visible: root.hasBattery

            ShapePath {
                fillColor: "transparent"
                strokeColor: root.fgColor
                strokeWidth: 2
                capStyle: ShapePath.RoundCap

                PathAngleArc {
                    centerX: 20
                    centerY: 20
                    radiusX: 19
                    radiusY: 19
                    startAngle: -90
                    sweepAngle: Math.min(root.arcCapacity * 3.6, 360)
                }
            }
        }

        Item {
            anchors.centerIn: parent
            width: 14
            height: 18

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                width: 8
                height: 16
                radius: 2
                color: "transparent"
                border.width: 2
                border.color: root.fgColor
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.top
                anchors.bottomMargin: -1
                width: 4
                height: 2
                radius: 1
                color: root.fgColor
            }

            Item {
                x: 4
                y: 4
                width: 6
                height: 10
                clip: true

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: Math.max(1, parent.height * root.arcCapacity / 100)
                    color: root.fgColor
                    radius: 1
                    Behavior on height { NumberAnimation { duration: 350; easing.type: Easing.OutQuint } }
                }
            }

            Shape {
                anchors.fill: parent
                visible: root.isCharging
                antialiasing: true
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    fillColor: root.fgColor
                    strokeColor: "transparent"

                    PathSvg {
                        path: "M 8 2 L 5.5 9 H 8 L 6 16 L 11 8.5 H 8.5 Z"
                    }
                }
            }

            Shape {
                anchors.fill: parent
                visible: root.isFull && !root.isCharging
                antialiasing: true
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    fillColor: "transparent"
                    strokeColor: root.fgColor
                    strokeWidth: 1.8
                    capStyle: ShapePath.RoundCap
                    joinStyle: ShapePath.RoundJoin

                    PathSvg {
                        path: "M 4.5 9.5 L 7 12 L 10.5 7.5"
                    }
                }
            }
        }

        MouseArea {
            id: hoverArea
            anchors.fill: parent
            hoverEnabled: true
            onEntered: tooltipTimer.restart()
            onExited: {
                tooltipTimer.stop()
                root.showTooltip = false
            }
        }

        PopupWindow {
            id: batteryPopup

            property bool isActive: root.showTooltip
            visible: isActive || openProgress > 0.0

            property real openProgress: isActive ? 1.0 : 0.0
            Behavior on openProgress {
                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
            }

            onOpenProgressChanged: {
                if (openProgress === 0.0 && !isActive) {
                    batteryPopup.visible = false;
                } else if (isActive && !batteryPopup.visible) {
                    batteryPopup.visible = true;
                }
            }

            anchor {
                item: root
                edges: Edges.Bottom
                gravity: Edges.Bottom
                margins.top: Globals.popupMargin
            }

            implicitWidth: contentLayout.implicitWidth + 24 + (2 * Globals.popupScreenPadding)
            implicitHeight: contentLayout.implicitHeight + 16
            color: "transparent"

            Item {
                width: parent.width - (2 * Globals.popupScreenPadding)
                height: parent.height
                anchors.horizontalCenter: parent.horizontalCenter
                scale: 0.9 + (0.1 * batteryPopup.openProgress)
                opacity: batteryPopup.openProgress
                transformOrigin: Item.Top

                Rectangle {
                    anchors.fill: parent
                    color: Globals.activeColors.background
                    radius: 12
                    border.color: Globals.activeColors.surfaceVariant
                    border.width: 1

                    ColumnLayout {
                        id: contentLayout
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: !root.hasBattery ? "No battery" : (root.capacity + "% · " + (root.isCharging ? "Charging" : root.isFull ? "Full" : "Discharging"))
                            color: Globals.activeColors.onSecondaryContainer
                            font.pixelSize: 13
                            font.bold: true
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            visible: root.hasBattery && root.isPlugged && Math.abs(root.changeRate) > 0.01
                            text: Math.abs(root.changeRate).toFixed(1) + " W"
                            color: Globals.activeColors.onSurfaceVariant
                            font.pixelSize: 12
                        }
                    }
                }
            }
        }
    }
}
