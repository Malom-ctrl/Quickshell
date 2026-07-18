import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell.Io
import Quickshell.Services.UPower

Rectangle {
    id: root
    width: 40
    height: 40
    radius: 20

    property int profile: PowerProfiles.profile

    color: Qt.rgba(root.dialColor.r, root.dialColor.g, root.dialColor.b, 0.2)
    // color: ma.containsMouse ? Globals.activeColors.secondaryContainer : "transparent"
    Behavior on color { ColorAnimation { duration: 150 } }

    property real dialAngle: {
        if (profile === PowerProfile.PowerSaver) return 140;
        if (profile === PowerProfile.Performance) return 400;
        return 270;
    }
    Behavior on dialAngle { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }

    property color dialColor: {
        if (profile === PowerProfile.Performance) return Globals.activeColors.error // Red
        if (profile === PowerProfile.PowerSaver) return Globals.activeColors.success // Green
        return Globals.activeColors.primary // Blue / Light purple
    }
    Behavior on dialColor { ColorAnimation { duration: 300 } }

    NumberAnimation on scale {
        id: clickAnim
        from: 0.8
        to: 1.0
        duration: 200
        easing.type: Easing.OutBack
        running: false
    }

    Item {
        anchors.centerIn: parent
        width: 24; height: 24

        // Gauge arc background
        Shape {
            anchors.fill: parent
            antialiasing: true
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: "transparent"
                strokeColor: Qt.rgba(root.dialColor.r, root.dialColor.g, root.dialColor.b, 0.6)
                strokeWidth: 2
                capStyle: ShapePath.RoundCap
                PathAngleArc {
                    centerX: 12; centerY: 12
                    radiusX: 8; radiusY: 8
                    startAngle: 140
                    sweepAngle: 260
                }
            }
        }

        // Needle
        Rectangle {
            width: 2; height: 10
            color: root.dialColor
            x: 11; y: 12 - height
            transformOrigin: Item.Bottom
            rotation: root.dialAngle - 270
            antialiasing: true
        }

        // Needle center dot
        Rectangle {
            width: 6; height: 6
            radius: 3
            color: root.dialColor
            x: 9; y: 9
            antialiasing: true
        }
    }

    Rectangle {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: -2
        width: 14; height: 14
        radius: 7
        color: Globals.activeColors.error // Error color
        visible: PowerProfiles.degradationReason !== PerformanceDegradationReason.None

        Icon {
            anchors.centerIn: parent
            width: 10; height: 10
            color: Globals.activeColors.onPrimary
            // Flame icon for HighTemperature, else a generic warning (!)
            path: PowerProfiles.degradationReason === PerformanceDegradationReason.HighOperatingTemperature
                ? "M17.66 11.2C17.43 10.9 17.15 10.64 16.89 10.38C16.22 9.78 15.46 9.35 14.82 8.72C13.33 7.26 12.81 5.04 13.56 3.06C13.62 2.9 13.63 2.72 13.59 2.55C13.54 2.38 13.44 2.23 13.3 2.13C13.15 2.03 12.98 1.98 12.8 1.99C12.62 2.01 12.46 2.08 12.33 2.2C10.6 3.75 9.39 5.86 8.77 8.09C8.36 9.56 8.35 11.13 8.76 12.6C8.82 12.83 8.79 13.07 8.67 13.27C8.54 13.47 8.35 13.61 8.12 13.67C7.89 13.73 7.64 13.69 7.43 13.58C7.22 13.46 7.06 13.26 6.98 13.04C6.63 12.01 6.57 10.91 6.81 9.85C6.86 9.61 6.81 9.36 6.67 9.16C6.54 8.96 6.32 8.84 6.08 8.82C5.83 8.79 5.59 8.88 5.4 9.04C5.21 9.21 5.09 9.44 5.06 9.68C4.54 12.59 5.51 15.65 7.6 17.66C9.13 19.12 11.23 19.98 13.41 19.99C15.63 19.96 17.72 18.99 19.18 17.33C20.64 15.66 21.36 13.46 21.18 11.25C21.14 10.82 20.89 10.45 20.5 10.25C20.1 10.05 19.64 10.07 19.26 10.3C18.67 10.63 18.14 10.99 17.66 11.2ZM13.41 17.99C12.05 17.99 10.74 17.47 9.77 16.53C8.61 15.42 7.97 13.9 7.97 12.31C8.24 12.56 8.54 12.78 8.86 12.96C9.57 13.36 10.4 13.46 11.18 13.25C11.96 13.04 12.63 12.55 13.06 11.87C13.48 11.19 13.63 10.37 13.48 9.59C13.33 8.8 12.9 8.1 12.27 7.59C12.52 7.37 12.78 7.15 13.06 6.96C13.68 6.55 14.34 6.22 15.04 6C14.7 7.74 15.11 9.54 16.14 10.97C16.48 11.45 16.89 11.87 17.36 12.22C17.84 12.57 18.3 12.87 18.73 13.12C18.9 14.12 18.69 15.14 18.14 16C17.58 16.86 16.73 17.5 15.73 17.79C15.01 18.01 14.22 18.05 13.41 17.99Z"
                : "M11 15h2v2h-2v-2zm0-8h2v6h-2V7zm.99-5C6.47 2 2 6.48 2 12s4.47 10 9.99 10C17.52 22 22 17.52 22 12S17.52 2 11.99 2zM12 20c-4.42 0-8-3.58-8-8s3.58-8 8-8 8 3.58 8 8-3.58 8-8 8z"
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            clickAnim.running = true;

            // Cycle through profiles: Balanced -> Performance -> PowerSaver -> Balanced
            if (root.profile === PowerProfile.Balanced) {
                PowerProfiles.profile = PowerProfile.Performance;
            } else if (root.profile === PowerProfile.Performance) {
                PowerProfiles.profile = PowerProfile.PowerSaver;
            } else {
                PowerProfiles.profile = PowerProfile.Balanced;
            }
        }
    }
}
