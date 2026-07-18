import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire

PopupWindow {
    id: audioPopup

    property bool isActive: false
    visible: active

    // Animate open/close
    property bool active: isActive
    Behavior on active {
        // Just rely on Window's built-in window management,
        // or we can use custom animation by overriding MaskWindow/etc.
        // For simplicity, PanelWindow usually doesn't animate unless told to.
        // Let's manually animate window opacity
    }

    property Item anchorItem: null

    anchor {
        item: anchorItem
        edges: Edges.Bottom
        gravity: Edges.Bottom
        margins.top: Globals.popupMargin
    }

    implicitWidth: 320 + (2 * Globals.popupScreenPadding)
    implicitHeight: contentRect.height
    color: "transparent"

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    readonly property bool sinkMuted: sink?.audio?.muted ?? false
    readonly property real sinkVol: sink?.audio?.volume ?? 0
    readonly property string sinkName: sink?.description || sink?.name || "Default Output"

    readonly property bool sourceMuted: !!source?.audio?.muted
    readonly property real sourceVol: source?.audio?.volume ?? 0
    readonly property string sourceName: source?.description || source?.name || "Default Input"

    // Helper to get sinks/sources
    readonly property var sinks: Pipewire.nodes.values.filter(n => !n.isStream && n.isSink)
    readonly property var sources: Pipewire.nodes.values.filter(n => !n.isStream && !n.isSink && n.audio)

    PwObjectTracker {
        objects: [...audioPopup.sinks, ...audioPopup.sources]
    }

    function cycleSink() {
        if (!sinks || sinks.length <= 1) return;
        let idx = sinks.findIndex(n => n.id === sink?.id);
        idx = (idx + 1) % sinks.length;
        Pipewire.preferredDefaultAudioSink = sinks[idx];
    }

    function cycleSource() {
        if (!sources || sources.length <= 1) return;
        let idx = sources.findIndex(n => n.id === source?.id);
        idx = (idx + 1) % sources.length;
        Pipewire.preferredDefaultAudioSource = sources[idx];
    }

    // Animation
    property real openProgress: isActive ? 1.0 : 0.0
    Behavior on openProgress {
        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
    }

    // Defer hide until animation finishes
    onOpenProgressChanged: {
        if (openProgress === 0.0 && !isActive) {
            audioPopup.visible = false;
        } else if (isActive && !audioPopup.visible) {
            audioPopup.visible = true;
        }
    }

    Item {
        id: contentRect
        width: parent.width - (2 * Globals.popupScreenPadding)
        anchors.horizontalCenter: parent.horizontalCenter
        height: layout.implicitHeight
        scale: 0.9 + (0.1 * openProgress)
        opacity: openProgress
        transformOrigin: Item.TopRight

        Rectangle {
            anchors.fill: parent
            color: Globals.activeColors.Black
            radius: 20
            border.color: Globals.activeColors.Secondary10
            border.width: 1

            ColumnLayout {
                id: layout
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 16
                spacing: 20

                Item { height: 4; Layout.fillWidth: true } // top padding

                // OUTPUT
                ColumnLayout {
                    spacing: 12
                    Layout.fillWidth: true

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Icon {
                            width: 20; height: 20
                            path: audioPopup.sinkMuted ? "M16.5 12c0-1.77-1.02-3.29-2.5-4.03v2.21l2.45 2.45c.03-.2.05-.41.05-.63zm2.5 0c0 .94-.2 1.82-.54 2.64l1.51 1.51C20.63 14.91 21 13.5 21 12c0-4.28-2.99-7.86-7-8.77v2.06c2.89.86 5 3.54 5 6.71zM4.27 3L3 4.27 7.73 9H3v6h4l5 5v-6.73l4.25 4.25c-.67.52-1.42.93-2.25 1.18v2.06c1.38-.31 2.63-.95 3.69-1.81L19.73 21 21 19.73l-9-9L4.27 3zM12 4L9.91 6.09 12 8.18V4z" : "M3 9v6h4l5 5V4L7 9H3zm13.5 3c0-1.77-1.02-3.29-2.5-4.03v8.05c1.48-.73 2.5-2.25 2.5-4.02zM14 3.23v2.06c2.89.86 5 3.54 5 6.71s-2.11 5.85-5 6.71v2.06c4.01-.91 7-4.49 7-8.77s-2.99-7.86-7-8.77z"
                            color: Globals.activeColors.White
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: "Output"
                                    color: Globals.activeColors.White
                                    font.pixelSize: 15
                                    font.bold: true
                                    Layout.fillWidth: true
                                }
                                Text {
                                    text: Math.round(audioPopup.sinkVol * 100) + "%"
                                    color: Globals.activeColors.SecondaryLight
                                    font.pixelSize: 13
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 24
                                color: "transparent"
                                radius: 4

                                RowLayout {
                                    anchors.fill: parent
                                    spacing: 4
                                    Text {
                                        text: audioPopup.sinkName
                                        color: Globals.activeColors.SecondaryLight
                                        font.pixelSize: 12
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }
                                    Icon {
                                        visible: audioPopup.sinks.length > 1
                                        width: 14; height: 14
                                        path: "M12 4l-1.41 1.41L16.17 11H4v2h12.17l-5.58 5.59L12 20l8-8z"
                                        color: Globals.activeColors.SecondaryLight
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: audioPopup.cycleSink()
                                }
                            }
                        }
                    }

                    // Slider
                    Rectangle {
                        Layout.fillWidth: true
                        height: 36
                        radius: 18
                        color: Globals.activeColors.Secondary25

                        Rectangle {
                            height: parent.height
                            width: parent.width * Math.min(1, Math.max(0, audioPopup.sinkVol))
                            radius: 18
                            color: Globals.activeColors.Secondary
                        }

                        MouseArea {
                            anchors.fill: parent
                            onPositionChanged: (mouse) => {
                                if (mouse.buttons & Qt.LeftButton) {
                                    let pct = mouse.x / width;
                                    if (audioPopup.sink && audioPopup.sink.audio) {
                                        audioPopup.sink.audio.volume = Math.max(0, Math.min(1, pct));
                                        if (audioPopup.sink.audio.muted && pct > 0) audioPopup.sink.audio.muted = false;
                                    }
                                }
                            }
                            onPressed: (mouse) => {
                                let pct = mouse.x / width;
                                if (audioPopup.sink && audioPopup.sink.audio) {
                                    audioPopup.sink.audio.volume = Math.max(0, Math.min(1, pct));
                                    if (audioPopup.sink.audio.muted && pct > 0) audioPopup.sink.audio.muted = false;
                                }
                            }
                        }
                    }
                }

                // INPUT
                ColumnLayout {
                    spacing: 12
                    Layout.fillWidth: true
                    Layout.topMargin: 8

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Icon {
                            width: 20; height: 20
                            path: audioPopup.sourceMuted ? "M10.8 4.9c0-.66.54-1.2 1.2-1.2s1.2.54 1.2 1.2l-.01 3.91L15 10.6V5c0-1.66-1.34-3-3-3S9 3.34 9 5v3.18l1.8 1.8V4.9zM19 11h-2c0 .91-.26 1.75-.69 2.48l1.46 1.46A6.921 6.921 0 0019 11zM2.93 4.22l8.56 8.56.01.01 2.21 2.21c-.48.24-1.05.39-1.71.39-2.76 0-5-2.24-5-5H5c0 3.53 2.61 6.43 6 6.92V21h2v-3.08c.57-.08 1.12-.24 1.64-.46l5.14 5.14 1.41-1.41L4.34 2.81 2.93 4.22z" : "M12 14c1.66 0 2.99-1.34 2.99-3L15 5c0-1.66-1.34-3-3-3S9 3.34 9 5v6c0 1.66 1.34 3 3 3zm5.3-3c0 3-2.54 5.1-5.3 5.1S6.7 14 6.7 11H5c0 3.41 2.72 6.23 6 6.72V21h2v-3.28c3.28-.48 6-3.3 6-6.72h-1.7z"
                            color: Globals.activeColors.White
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: "Input"
                                    color: Globals.activeColors.White
                                    font.pixelSize: 15
                                    font.bold: true
                                    Layout.fillWidth: true
                                }
                                Text {
                                    text: Math.round(audioPopup.sourceVol * 100) + "%"
                                    color: Globals.activeColors.SecondaryLight
                                    font.pixelSize: 13
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 24
                                color: "transparent"
                                radius: 4

                                RowLayout {
                                    anchors.fill: parent
                                    spacing: 4
                                    Text {
                                        text: audioPopup.sourceName
                                        color: Globals.activeColors.SecondaryLight
                                        font.pixelSize: 12
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }
                                    Icon {
                                        visible: audioPopup.sources.length > 1
                                        width: 14; height: 14
                                        path: "M12 4l-1.41 1.41L16.17 11H4v2h12.17l-5.58 5.59L12 20l8-8z"
                                        color: Globals.activeColors.SecondaryLight
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: audioPopup.cycleSource()
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 36
                        radius: 18
                        color: Globals.activeColors.Secondary25

                        Rectangle {
                            height: parent.height
                            width: parent.width * Math.min(1, Math.max(0, audioPopup.sourceVol))
                            radius: 18
                            color: Globals.activeColors.Secondary
                        }

                        MouseArea {
                            anchors.fill: parent
                            onPositionChanged: (mouse) => {
                                if (mouse.buttons & Qt.LeftButton) {
                                    let pct = mouse.x / width;
                                    if (audioPopup.source && audioPopup.source.audio) {
                                        audioPopup.source.audio.volume = Math.max(0, Math.min(1, pct));
                                        if (audioPopup.source.audio.muted && pct > 0) audioPopup.source.audio.muted = false;
                                    }
                                }
                            }
                            onPressed: (mouse) => {
                                let pct = mouse.x / width;
                                if (audioPopup.source && audioPopup.source.audio) {
                                    audioPopup.source.audio.volume = Math.max(0, Math.min(1, pct));
                                    if (audioPopup.source.audio.muted && pct > 0) audioPopup.source.audio.muted = false;
                                }
                            }
                        }
                    }
                }

                Item { height: 4; Layout.fillWidth: true } // bottom padding
            }
        }
    }
}
