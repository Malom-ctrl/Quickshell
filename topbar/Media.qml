import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Services.Mpris

Rectangle {
    id: root
    height: 40
    color: Globals.activeColors.Main // Primary Container
    radius: 20
    implicitWidth: layout.implicitWidth + 24

    readonly property var player: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null

    property string title: {
        if (!player) return "No Media Playing"
        let artist = player.trackArtist || ""
        let track = player.trackTitle || ""
        if (artist !== "" && track !== "") return artist + " - " + track
        if (track !== "") return track
        return "No Media Playing"
    }

    property string status: {
        if (!player) return "Stopped"
        return player.isPlaying ? "Playing" : "Paused"
    }

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 12

        // Art icon
        Rectangle {
            width: 28; height: 28
            radius: 14
            color: Globals.activeColors.Secondary // Primary
            Icon {
                width: 16; height: 16
                anchors.centerIn: parent
                path: "M12 3v10.55c-.59-.34-1.27-.55-2-.55-2.21 0-4 1.79-4 4s1.79 4 4 4 4-1.79 4-4V7h4V3h-6z"
                color: Globals.activeColors.Black // On Primary
            }
        }

        // Marquee Text for Title
        Item {
            Layout.preferredWidth: Math.min(mediaText.implicitWidth, 150)
            Layout.preferredHeight: 20
            clip: true
            Text {
                id: mediaText
                text: root.title
                color: Globals.activeColors.White // On Primary Container
                font.pixelSize: 15
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter

                property real animX: 0
                x: (root.status === "Playing" && mediaText.implicitWidth > 150) ? animX : 0

                NumberAnimation on animX {
                    from: 150
                    to: -mediaText.implicitWidth
                    duration: 5000 + mediaText.implicitWidth * 20
                    loops: Animation.Infinite
                    running: root.status === "Playing" && mediaText.implicitWidth > 150
                }
            }
        }

        // Controls
        RowLayout {
            spacing: 8
            visible: root.title !== "No Media Playing"
            MouseArea {
                implicitWidth: 24; implicitHeight: 24
                onClicked: if (root.player && root.player.canGoPrevious) root.player.previous()
                cursorShape: Qt.PointingHandCursor
                Icon { anchors.centerIn: parent; width: 20; height: 20; path: "M6 6h2v12H6zm3.5 6l8.5 6V6z"; color: Globals.activeColors.White }
            }
            MouseArea {
                implicitWidth: 32; implicitHeight: 32
                onClicked: if (root.player && root.player.canTogglePlaying) root.player.togglePlaying()
                cursorShape: Qt.PointingHandCursor
                Rectangle {
                    anchors.fill: parent; radius: 16; color: Globals.activeColors.Secondary
                    Icon {
                        anchors.centerIn: parent; width: 20; height: 20;
                        path: root.status === "Playing" ? "M6 19h4V5H6v14zm8-14v14h4V5h-4z" : "M8 5v14l11-7z"
                        color: Globals.activeColors.Black
                    }
                }
            }
            MouseArea {
                implicitWidth: 24; implicitHeight: 24
                onClicked: if (root.player && root.player.canGoNext) root.player.next()
                cursorShape: Qt.PointingHandCursor
                Icon { anchors.centerIn: parent; width: 20; height: 20; path: "M6 18l8.5-6L6 6v12zM16 6v12h2V6h-2z"; color: Globals.activeColors.White }
            }
        }
    }
}
