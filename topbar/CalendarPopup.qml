import QtQuick
import QtQuick.Layouts
import Quickshell

PopupWindow {
    id: calendarPopup

    property bool isActive: false
    visible: isActive || openProgress > 0.0

    property real openProgress: isActive ? 1.0 : 0.0
    Behavior on openProgress {
        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
    }

    onOpenProgressChanged: {
        if (openProgress === 0.0 && !isActive) visible = false;
        else if (isActive && !visible) visible = true;
    }

    implicitWidth: 320 + (2 * Globals.popupScreenPadding)
    implicitHeight: 370
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

        // Previous month days
        for (let i = firstDayIndex - 1; i >= 0; i--) {
            days.push({
                day: daysInPrevMonth - i,
                month: currentMonth - 1,
                year: currentYear
            });
        }

        // Current month days
        for (let i = 1; i <= daysInMonth; i++) {
            days.push({
                day: i,
                month: currentMonth,
                year: currentYear
            });
        }

        // Next month days to fill 42 slots (6 weeks)
        let remaining = 42 - days.length;
        for (let i = 1; i <= remaining; i++) {
            days.push({
                day: i,
                month: currentMonth + 1,
                year: currentYear
            });
        }

        calendarModel = days;
    }

    function nextMonth() {
        if (currentMonth === 11) {
            currentMonth = 0;
            currentYear++;
        } else {
            currentMonth++;
        }
        updateCalendar();
    }

    function prevMonth() {
        if (currentMonth === 0) {
            currentMonth = 11;
            currentYear--;
        } else {
            currentMonth--;
        }
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
            color: Globals.activeColors.Black
            radius: 20
            border.color: Globals.activeColors.Secondary10
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 16

                // Header
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: Qt.formatDate(new Date(currentYear, currentMonth, 1), "MMMM yyyy")
                        color: Globals.activeColors.White
                        font.pixelSize: 18
                        font.bold: true
                        Layout.fillWidth: true
                    }
                    RowLayout {
                        spacing: 8
                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: prevMouse.containsMouse ? Globals.activeColors.Secondary25 : "transparent"
                            Icon { anchors.centerIn: parent; width: 16; height: 16; path: "M15.41 7.41L14 6l-6 6 6 6 1.41-1.41L10.83 12z"; color: Globals.activeColors.White }
                            MouseArea { id: prevMouse; anchors.fill: parent; hoverEnabled: true; onClicked: prevMonth() }
                        }
                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: nextMouse.containsMouse ? Globals.activeColors.Secondary25 : "transparent"
                            Icon { anchors.centerIn: parent; width: 16; height: 16; path: "M10 6L8.59 7.41 13.17 12l-4.58 4.59L10 18l6-6z"; color: Globals.activeColors.White }
                            MouseArea { id: nextMouse; anchors.fill: parent; hoverEnabled: true; onClicked: nextMonth() }
                        }
                    }
                }

                // Calendar Grid
                GridLayout {
                    id: calendarGrid
                    columns: 7
                    rowSpacing: 8
                    columnSpacing: 8
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    // Days of week
                    Repeater {
                        model: ["M", "T", "W", "T", "F", "S", "S"]
                        Item {
                            width: 32; height: 32
                            Layout.alignment: Qt.AlignCenter
                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                color: Globals.activeColors.SecondaryLight
                                font.pixelSize: 13
                                font.bold: true
                            }
                        }
                    }

                    Repeater {
                        model: calendarModel
                        Rectangle {
                            width: 32; height: 32
                            radius: 16
                            Layout.alignment: Qt.AlignCenter
                            color: isToday ? Globals.activeColors.Secondary : (dayMouse.containsMouse && isCurrentMonth ? Globals.activeColors.Secondary25 : "transparent")

                            property bool isToday: {
                                let d = new Date()
                                return modelData.day === d.getDate() && modelData.month === d.getMonth() && modelData.year === d.getFullYear()
                            }
                            property bool isCurrentMonth: modelData.month === currentMonth

                            Text {
                                anchors.centerIn: parent
                                text: modelData.day
                                color: isToday ? Globals.activeColors.Black : (isCurrentMonth ? Globals.activeColors.White : Globals.activeColors.Secondary25)
                                font.pixelSize: 14
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

                Item { Layout.fillHeight: true } // Spacer
            }
        }
    }
}
