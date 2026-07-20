import QtQuick
import QtQuick.Layouts
import Quickshell

Rectangle {
    id: root
    property string themeScope: "topbar.Clock"

    implicitWidth: clockLayout.implicitWidth + 32
    implicitHeight: 40
    radius: Globals.customValue(themeScope, "radius", Globals.themeVars.borderRadiusHuge)
    color: (clockMouseArea.containsMouse || popupVisible) ? Globals.customValue(themeScope, "hoverColor", Globals.themeVars.Secondary50) : Globals.customValue(themeScope, "color", Globals.themeVars.Secondary25)
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
        spacing: Globals.customValue(themeScope + ".clockLayout", "spacing", Globals.themeVars.spacingLarge)

        Text {
            id: dateText
            Layout.alignment: Qt.AlignVCenter
            text: Qt.formatDate(new Date(), "ddd, MMM d")
            color: Globals.customValue(themeScope + ".dateText", "color", Globals.themeVars.White)
            font.pixelSize: Globals.customValue(themeScope + ".dateText", "fontSize", Globals.themeVars.fontSizeMedium)
            font.weight: Font.DemiBold
        }

        Text {
            id: timeText
            Layout.alignment: Qt.AlignVCenter
            text: Qt.formatTime(new Date(), "H:mm")
            color: Globals.customValue(themeScope + ".timeText", "color", Globals.themeVars.White)
            font.pixelSize: Globals.customValue(themeScope + ".timeText", "fontSize", Globals.themeVars.fontSizeHuge)
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
