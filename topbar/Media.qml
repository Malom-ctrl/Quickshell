import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Services.Mpris

Rectangle {
    id: root
    property string themeScope: "topbar.Media"

    height: Globals.customValue(themeScope, "height", 40)
    color: Globals.customValue(themeScope, "color", Globals.themeVars.Main) // Primary Container
    radius: Globals.customValue(themeScope, "radius", Globals.themeVars.borderRadiusHuge)
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
        spacing: Globals.customValue(themeScope + ".layout", "spacing", Globals.themeVars.spacingLarge)

        // Art icon
        Rectangle {
            width: Globals.customValue(themeScope + ".artIcon", "width", 28); height: Globals.customValue(themeScope + ".artIcon", "height", 28)
            radius: Globals.customValue(themeScope + ".artIcon", "radius", 14)
            color: Globals.customValue(themeScope + ".artIcon", "color", Globals.themeVars.Secondary) // Primary
            Icon {
                width: Globals.customValue(themeScope + ".artIcon.icon", "width", 16); height: Globals.customValue(themeScope + ".artIcon.icon", "height", 16)
                anchors.centerIn: parent
                path: "M12 3v10.55c-.59-.34-1.27-.55-2-.55-2.21 0-4 1.79-4 4s1.79 4 4 4 4-1.79 4-4V7h4V3h-6z"
                color: Globals.customValue(themeScope + ".artIcon.icon", "color", Globals.themeVars.Black) // On Primary
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
                color: Globals.customValue(themeScope + ".title", "color", Globals.themeVars.White) // On Primary Container
                font.pixelSize: Globals.customValue(themeScope + ".title", "fontSize", Globals.themeVars.fontSizeMedium)
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
            spacing: Globals.customValue(themeScope + ".controls", "spacing", Globals.themeVars.spacingMedium)
            visible: root.title !== "No Media Playing"
            MouseArea {
                implicitWidth: Globals.customValue(themeScope + ".controls.prev", "width", 24); implicitHeight: Globals.customValue(themeScope + ".controls.prev", "height", 24)
                onClicked: if (root.player && root.player.canGoPrevious) root.player.previous()
                cursorShape: Qt.PointingHandCursor
                Icon { anchors.centerIn: parent; width: Globals.customValue(themeScope + ".controls.prev.icon", "width", 20); height: Globals.customValue(themeScope + ".controls.prev.icon", "height", 20); path: "M6 6h2v12H6zm3.5 6l8.5 6V6z"; color: Globals.customValue(themeScope + ".controls.prev.icon", "color", Globals.themeVars.White) }
            }
            MouseArea {
                implicitWidth: Globals.customValue(themeScope + ".controls.play", "width", 32); implicitHeight: Globals.customValue(themeScope + ".controls.play", "height", 32)
                onClicked: if (root.player && root.player.canTogglePlaying) root.player.togglePlaying()
                cursorShape: Qt.PointingHandCursor
                Rectangle {
                    anchors.fill: parent; radius: Globals.customValue(themeScope + ".controls.play.bg", "radius", Globals.themeVars.borderRadiusLarge); color: Globals.customValue(themeScope + ".controls.play.bg", "color", Globals.themeVars.Secondary)
                    Icon {
                        anchors.centerIn: parent; width: Globals.customValue(themeScope + ".controls.play.icon", "width", 20); height: Globals.customValue(themeScope + ".controls.play.icon", "height", 20);
                        path: root.status === "Playing" ? "M6 19h4V5H6v14zm8-14v14h4V5h-4z" : "M8 5v14l11-7z"
                        color: Globals.customValue(themeScope + ".controls.play.icon", "color", Globals.themeVars.Black)
                    }
                }
            }
            MouseArea {
                implicitWidth: Globals.customValue(themeScope + ".controls.next", "width", 24); implicitHeight: Globals.customValue(themeScope + ".controls.next", "height", 24)
                onClicked: if (root.player && root.player.canGoNext) root.player.next()
                cursorShape: Qt.PointingHandCursor
                Icon { anchors.centerIn: parent; width: Globals.customValue(themeScope + ".controls.next.icon", "width", 20); height: Globals.customValue(themeScope + ".controls.next.icon", "height", 20); path: "M6 18l8.5-6L6 6v12zM16 6v12h2V6h-2z"; color: Globals.customValue(themeScope + ".controls.next.icon", "color", Globals.themeVars.White) }
            }
        }
    }
}
