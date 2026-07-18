import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Qt.labs.folderlistmodel

PopupWindow {
    id: popup
    property bool isActive: false
    property Item anchorItem: null

    visible: isActive || openProgress > 0.0

    property real openProgress: isActive ? 1.0 : 0.0
    Behavior on openProgress {
        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
    }

    onOpenProgressChanged: {
        if (openProgress === 0.0 && !isActive) {
            visible = false;
        }
        else if (isActive && !visible) visible = true;
    }

    anchor {
        item: anchorItem
        edges: Edges.Bottom
        gravity: Edges.Bottom
        margins.top: Globals.popupMargin
    }

    // 4 columns * ~120 width + 3 * spacing + margins
    implicitWidth: (120 * 4) + (8 * 3) + 32
    implicitHeight: Math.min(600, contentLayout.implicitHeight + 32)
    color: "transparent"

    property string themesDir: Quickshell.env("HOME") + "/.config/qs-themes"

    FolderListModel {
        id: themesModel
        folder: Globals.themesReady ? "file://" + popup.themesDir : ""
        nameFilters: ["*.json"]
        showDirs: false
    }

    function applyTheme(themeFileName) {
        console.error("applyTheme called with: " + themeFileName)
        let cmd = "cd '" + popup.themesDir + "' && if [ -L __ACTIVE__.json ]; then rm -f __ACTIVE__.json; fi && cp -f '" + themeFileName + "' __ACTIVE__.json";
        applyProc.command = ["bash", "-c", cmd];
        applyProc.running = true;
    }

    Process {
        id: applyProc
        command: []
        onExited: function(exitCode) {
            console.error("applyProc exited with code " + exitCode)
        }
    }

    Item {
        id: bgItem
        width: parent.width
        height: parent.height
        scale: 0.9 + (0.1 * popup.openProgress)
        opacity: popup.openProgress
        transformOrigin: Item.Top

        Rectangle {
            anchors.fill: parent
            color: Globals.activeColors.Black
            radius: 20
            border.color: Globals.activeColors.Secondary10
            border.width: 1

            ColumnLayout {
                id: contentLayout
                anchors.fill: parent
                anchors.margins: 16
                spacing: 16

                Text {
                    text: "Themes"
                    color: Globals.activeColors.White
                    font.pixelSize: 18
                    font.bold: true
                    Layout.fillWidth: true
                }

                Flickable {
                    Layout.fillWidth: true
                    Layout.preferredHeight: (120 * 2) + 8 // 2 rows of 120px height + 1 spacing
                    contentHeight: flowLayout.implicitHeight
                    clip: true

                    Flow {
                        id: flowLayout
                        width: parent.width
                        spacing: 8

                        property real itemWidth: (width - 3 * 8) / 4
                        property real itemHeight: 120

                        Repeater {
                            model: themesModel
                            delegate: Item {
                                property bool isVisible: fileName !== "__ACTIVE__.json"
                                width: isVisible ? flowLayout.itemWidth : 0
                                height: isVisible ? flowLayout.itemHeight : 0
                                visible: isVisible

                                FileView {
                                    id: delegateFile
                                    path: popup.themesDir + "/" + fileName
                                    watchChanges: true
                                    onFileChanged: reload()
                                    JsonAdapter {
                                        id: delegateAdapter
                                        property string name: ""
                                        property var palette: null
                                        property string wallpaper: ""
                                    }
                                }

                                property var themeData: delegateAdapter
                                property bool isActiveTheme: Globals.currentTheme && themeData && Globals.currentTheme.name === themeData.name

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 12
                                    color: isActiveTheme ? Globals.activeColors.Secondary25 : (themeMouse.containsMouse ? Globals.activeColors.Secondary10 : Globals.activeColors.Black)
                                    border.color: isActiveTheme ? Globals.activeColors.Secondary : "transparent"
                                    border.width: isActiveTheme ? 2 : 0

                                    MouseArea {
                                        id: themeMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: {
                                            popup.applyTheme(fileName)
                                        }
                                    }

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 6
                                        spacing: 6

                                        // Wallpaper preview
                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            radius: 8
                                            color: Globals.activeColors.Black
                                            clip: true
                                            border.color: Globals.activeColors.Secondary10
                                            border.width: 1

                                            Image {
                                                anchors.fill: parent
                                                source: (themeData && themeData.wallpaper) ? ("file://" + themeData.wallpaper) : ""
                                                fillMode: Image.PreserveAspectCrop
                                                visible: source !== ""
                                            }
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: themeData ? themeData.name : fileName
                                            color: Globals.activeColors.White
                                            font.pixelSize: 12
                                            font.bold: true
                                            horizontalAlignment: Text.AlignHCenter
                                            elide: Text.ElideRight
                                        }

                                        Row {
                                            Layout.alignment: Qt.AlignHCenter
                                            spacing: 4
                                            Repeater {
                                                model: ["Main", "Secondary", "Success", "Warning", "Error"]
                                                delegate: Rectangle {
                                                    width: 14; height: 4; radius: 2
                                                    color: (themeData && themeData.palette && themeData.palette[modelData]) ? themeData.palette[modelData] : "#000"
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
