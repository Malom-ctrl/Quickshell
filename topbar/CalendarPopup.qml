import QtQuick
import QtQuick.Layouts
import Quickshell

PopupWindow {
    id: calendarPopup

    property bool isActive: false
    grabFocus: true


    Connections {
        target: Globals
        function onClosePopups() {
            if (calendarPopup.isActive) { calendarPopup.isActive = false; calendarPopup.visible = false; }
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

    property string themeScope: "topbar.CalendarPopup"

    implicitWidth: mainColumn.implicitWidth + (2 * Globals.customValue(themeScope + ".popup.layout", "margins", Globals.themeVars.spacingHuge)) + (2 * Globals.popupScreenPadding)
    implicitHeight: mainColumn.implicitHeight + (2 * Globals.customValue(themeScope + ".popup.layout", "margins", Globals.themeVars.spacingHuge))
    color: "transparent"

    property int currentMonth: new Date().getMonth()
    property int currentYear: new Date().getFullYear()
    property var calendarModel: []

    function updateCalendar() {
        let firstDay = new Date(currentYear, currentMonth, 1).getDay();
        let firstDayIndex = firstDay === 0 ? 6 : firstDay - 1;
        let daysInMonth = new Date(currentYear, currentMonth + 1, 0).getDate();
        let daysInPrevMonth = new Date(currentYear, currentMonth, 0).getDate();
        let days = [];

        for (let i = firstDayIndex - 1; i >= 0; i--) {
            days.push({ day: daysInPrevMonth - i, month: currentMonth - 1, year: currentYear });
        }
        for (let i = 1; i <= daysInMonth; i++) {
            days.push({ day: i, month: currentMonth, year: currentYear });
        }
        let remaining = 42 - days.length;
        for (let i = 1; i <= remaining; i++) {
            days.push({ day: i, month: currentMonth + 1, year: currentYear });
        }
        calendarModel = days;
    }

    function nextMonth() {
        if (currentMonth === 11) { currentMonth = 0; currentYear++; }
        else currentMonth++;
        updateCalendar();
    }

    function prevMonth() {
        if (currentMonth === 0) { currentMonth = 11; currentYear--; }
        else currentMonth--;
        updateCalendar();
    }

    Component.onCompleted: updateCalendar()

    Item {
        width: parent.width - (2 * Globals.popupScreenPadding)
        height: parent.height
        anchors.horizontalCenter: parent.horizontalCenter
        scale: 0.9 + (0.1 * calendarPopup.openProgress)
        opacity: calendarPopup.openProgress
        transformOrigin: Item.Top

        Rectangle {
            anchors.fill: parent
            color: Globals.customValue(themeScope + ".popup", "color", Globals.themeVars.Black)
            radius: Globals.customValue(themeScope + ".popup", "radius", Globals.themeVars.borderRadiusHuge)
            border.color: Globals.customValue(themeScope + ".popup", "borderColor", Globals.themeVars.Secondary10)
            border.width: Globals.customValue(themeScope + ".popup", "borderWidth", Globals.themeVars.borderWidthSmall)

            ColumnLayout {
                id: mainColumn
                anchors.fill: parent
                anchors.margins: Globals.customValue(themeScope + ".popup.layout", "margins", Globals.themeVars.spacingHuge)
                spacing: Globals.customValue(themeScope + ".popup.layout", "spacing", Globals.themeVars.spacingHuge)

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: Qt.formatDate(new Date(currentYear, currentMonth, 1), "MMMM yyyy")
                        color: Globals.customValue(themeScope + ".popup.header", "color", Globals.themeVars.White)
                        font.pixelSize: Globals.customValue(themeScope + ".popup.header", "fontSize", Globals.themeVars.fontSizeLarge)
                        font.bold: true
                        Layout.fillWidth: true
                    }
                    RowLayout {
                        spacing: Globals.customValue(themeScope + ".popup.headerButtons", "spacing", Globals.themeVars.spacingMedium)
                        Rectangle {
                            width: Globals.customValue(themeScope + ".popup.headerBtn", "width", 32)
                            height: Globals.customValue(themeScope + ".popup.headerBtn", "height", 32)
                            radius: Globals.customValue(themeScope + ".popup.headerBtn", "radius", Globals.themeVars.borderRadiusLarge)
                            color: prevMouse.containsMouse ? Globals.customValue(themeScope + ".popup.headerBtn", "hoverColor", Globals.themeVars.Secondary25) : "transparent"
                            Icon { anchors.centerIn: parent; width: Globals.customValue(themeScope + ".popup.headerBtn.icon", "width", 16); height: Globals.customValue(themeScope + ".popup.headerBtn.icon", "height", 16); path: "M15.41 7.41L14 6l-6 6 6 6 1.41-1.41L10.83 12z"; color: Globals.customValue(themeScope + ".popup.headerBtn.icon", "color", Globals.themeVars.White) }
                            MouseArea { id: prevMouse; anchors.fill: parent; hoverEnabled: true; onClicked: prevMonth() }
                        }
                        Rectangle {
                            width: Globals.customValue(themeScope + ".popup.headerBtn", "width", 32)
                            height: Globals.customValue(themeScope + ".popup.headerBtn", "height", 32)
                            radius: Globals.customValue(themeScope + ".popup.headerBtn", "radius", Globals.themeVars.borderRadiusLarge)
                            color: nextMouse.containsMouse ? Globals.customValue(themeScope + ".popup.headerBtn", "hoverColor", Globals.themeVars.Secondary25) : "transparent"
                            Icon { anchors.centerIn: parent; width: Globals.customValue(themeScope + ".popup.headerBtn.icon", "width", 16); height: Globals.customValue(themeScope + ".popup.headerBtn.icon", "height", 16); path: "M10 6L8.59 7.41 13.17 12l-4.58 4.59L10 18l6-6z"; color: Globals.customValue(themeScope + ".popup.headerBtn.icon", "color", Globals.themeVars.White) }
                            MouseArea { id: nextMouse; anchors.fill: parent; hoverEnabled: true; onClicked: nextMonth() }
                        }
                    }
                }

                GridLayout {
                    id: calendarGrid
                    columns: 7
                    rowSpacing: Globals.customValue(themeScope + ".popup.grid", "rowSpacing", Globals.themeVars.spacingMedium)
                    columnSpacing: Globals.customValue(themeScope + ".popup.grid", "columnSpacing", Globals.themeVars.spacingMedium)
                    Layout.alignment: Qt.AlignHCenter

                    Repeater {
                        model: ["M", "T", "W", "T", "F", "S", "S"]
                        Item {
                            width: Globals.customValue(themeScope + ".popup.grid.dayLabel", "width", 32)
                            height: Globals.customValue(themeScope + ".popup.grid.dayLabel", "height", 32)
                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                color: Globals.customValue(themeScope + ".popup.grid.dayLabel", "color", Globals.themeVars.SecondaryLight)
                                font.pixelSize: Globals.customValue(themeScope + ".popup.grid.dayLabel", "fontSize", Globals.themeVars.fontSizeSmall)
                                font.bold: true
                            }
                        }
                    }

                    Repeater {
                        model: calendarModel
                        Rectangle {
                            width: Globals.customValue(themeScope + ".popup.grid.dayCell", "width", 32)
                            height: Globals.customValue(themeScope + ".popup.grid.dayCell", "height", 32)
                            radius: Globals.customValue(themeScope + ".popup.grid.dayCell", "radius", Globals.themeVars.borderRadiusLarge)
                            color: isToday ? Globals.customValue(themeScope + ".popup.grid.dayCell", "todayColor", Globals.themeVars.Secondary) : (dayMouse.containsMouse && isCurrentMonth ? Globals.customValue(themeScope + ".popup.grid.dayCell", "hoverColor", Globals.themeVars.Secondary25) : "transparent")

                            property bool isToday: {
                                let d = new Date()
                                return modelData.day === d.getDate() && modelData.month === d.getMonth() && modelData.year === d.getFullYear()
                            }
                            property bool isCurrentMonth: modelData.month === currentMonth

                            Text {
                                anchors.centerIn: parent
                                text: modelData.day
                                color: isToday ? Globals.customValue(themeScope + ".popup.grid.dayCell", "todayTextColor", Globals.themeVars.Black) : (isCurrentMonth ? Globals.customValue(themeScope + ".popup.grid.dayCell", "textColor", Globals.themeVars.White) : Globals.customValue(themeScope + ".popup.grid.dayCell", "otherMonthTextColor", Globals.themeVars.Secondary25))
                                font.pixelSize: Globals.customValue(themeScope + ".popup.grid.dayCell", "fontSize", Globals.themeVars.fontSizeMedium)
                                font.bold: isToday
                            }

                            MouseArea {
                                id: dayMouse
                                anchors.fill: parent
                                hoverEnabled: isCurrentMonth
                            }
                        }
                    }
                }
            }
        }
    }
}
