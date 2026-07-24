import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

Item {
    id: root
    property string themeScope: "topbar.AudioControl"
    width: Globals.customValue(themeScope, "width", 40); height: Globals.customValue(themeScope, "height", 40)
    property alias popupVisible: audioPopup.isActive

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool sinkMuted: sink?.audio?.muted ?? false
    readonly property real sinkVol: sink?.audio?.volume ?? 0

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }

    Rectangle {
        anchors.fill: parent
        radius: Globals.customValue(themeScope, "radius", Globals.themeVars.borderRadiusHuge)
        color: (mouseArea.containsMouse || root.popupVisible) ? Globals.customValue(themeScope, "hoverColor", Globals.themeVars.Secondary50) : Globals.customValue(themeScope, "color", Globals.themeVars.Secondary25)
        Behavior on color { ColorAnimation { duration: 150 } }

        Shape {
            antialiasing: true
            preferredRendererType: Shape.CurveRenderer
            anchors.fill: parent
            visible: !root.sinkMuted && root.sinkVol > 0

            ShapePath {
                fillColor: "transparent"
                strokeColor: (mouseArea.containsMouse || root.popupVisible) ? Globals.customValue(themeScope + ".indicator", "hoverColor", Globals.themeVars.White) : Globals.customValue(themeScope + ".indicator", "color", Globals.themeVars.Secondary)
                strokeWidth: Globals.customValue(themeScope + ".indicator", "width", Globals.themeVars.borderWidthMedium)
                capStyle: ShapePath.RoundCap
                Behavior on strokeColor { ColorAnimation { duration: 150 } }

                PathAngleArc {
                    centerX: width / 2
                    centerY: height / 2
                    radiusX: (width / 2) - Globals.customValue(themeScope + ".indicator", "offset", 1)
                    radiusY: (height / 2) - Globals.customValue(themeScope + ".indicator", "offset", 1)
                    startAngle: -90
                    sweepAngle: Math.min(root.sinkVol * 360, 360)
                }
            }
        }

        Icon {
            anchors.centerIn: parent
            width: Globals.customValue(themeScope + ".icon", "width", 16); height: Globals.customValue(themeScope + ".icon", "height", 16) // make icon slightly smaller to fit the circle border
            path: root.sinkMuted ? "M16.5 12c0-1.77-1.02-3.29-2.5-4.03v2.21l2.45 2.45c.03-.2.05-.41.05-.63zm2.5 0c0 .94-.2 1.82-.54 2.64l1.51 1.51C20.63 14.91 21 13.5 21 12c0-4.28-2.99-7.86-7-8.77v2.06c2.89.86 5 3.54 5 6.71zM4.27 3L3 4.27 7.73 9H3v6h4l5 5v-6.73l4.25 4.25c-.67.52-1.42.93-2.25 1.18v2.06c1.38-.31 2.63-.95 3.69-1.81L19.73 21 21 19.73l-9-9L4.27 3zM12 4L9.91 6.09 12 8.18V4z" : "M3 9v6h4l5 5V4L7 9H3zm13.5 3c0-1.77-1.02-3.29-2.5-4.03v8.05c1.48-.73 2.5-2.25 2.5-4.02zM14 3.23v2.06c2.89.86 5 3.54 5 6.71s-2.11 5.85-5 6.71v2.06c4.01-.91 7-4.49 7-8.77s-2.99-7.86-7-8.77z"
            color: Globals.customValue(themeScope + ".icon", "color", Globals.themeVars.White)
        }

        MouseArea {
            id: mouseArea
            hoverEnabled: true
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
            if (!root.popupVisible) {
                Globals.closePopups();
                root.popupVisible = true;
            } else {
                root.popupVisible = false;
            }
        }
            onWheel: (wheel) => {
                if (!root.sink || !root.sink.audio) return
                let v = root.sink.audio.volume
                if (wheel.angleDelta.y > 0) {
                    root.sink.audio.muted = false
                    root.sink.audio.volume = Math.min(v + 0.02, 1.0)
                } else if (wheel.angleDelta.y < 0) {
                    root.sink.audio.volume = Math.max(v - 0.02, 0.0)
                }
            }
        }
    }
    AudioPopup {
        id: audioPopup
        anchorItem: root
    }
}
