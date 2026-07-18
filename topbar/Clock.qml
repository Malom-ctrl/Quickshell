import QtQuick
import QtQuick.Layouts
import Quickshell

Rectangle {
    id: root
    implicitWidth: clockLayout.implicitWidth + 32
    implicitHeight: 40
    radius: 20
    color: (clockMouseArea.containsMouse || popupVisible) ? Globals.activeColors.Secondary50 : Globals.activeColors.Secondary25
    Behavior on color { ColorAnimation { duration: 150 } }

    Behavior on color { ColorAnimation { duration: 150 } }

    property bool popupVisible: false

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            var date = new Date()
            timeText.text = Qt.formatTime(date, "H:mm")
            dateText.text = Qt.formatDate(date, "ddd, MMM d")
        }
    }

    RowLayout {
        id: clockLayout
        anchors.centerIn: parent
        spacing: 12

        Text {
            id: dateText
            Layout.alignment: Qt.AlignVCenter
            text: Qt.formatDate(new Date(), "ddd, MMM d")
            color: Globals.activeColors.White // On Secondary Container
            font.pixelSize: 15
            font.weight: Font.DemiBold
            // opacity: 0.8
            // font.bold: true
        }

        Text {
            id: timeText
            Layout.alignment: Qt.AlignVCenter
            text: Qt.formatTime(new Date(), "H:mm")
            color: Globals.activeColors.White // On Secondary Container
            font.pixelSize: 25
            font.bold: true
        }
    }

    MouseArea {
        id: clockMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.popupVisible = !root.popupVisible
    }

    CalendarPopup {
        id: calendarPopup
        isActive: root.popupVisible

        anchor {
            item: root
            edges: Edges.Bottom
            gravity: Edges.Bottom
            margins.top: Globals.popupMargin
        }
    }
}
