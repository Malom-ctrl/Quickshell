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

    property string themeScope: "topbar.ThemePopup"

    // 4 columns * ~120 width + 3 * spacing + margins
    implicitWidth: Globals.customValue(themeScope, "width", (120 * 4) + (8 * 3) + 32)
    implicitHeight: Globals.customValue(themeScope, "height", Math.min(600, contentLayout.implicitHeight + 32))
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
        let cmd = "echo -n '" + themeFileName + "' > '" + Quickshell.cachePath("activeTheme.txt") + "'";
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
            color: Globals.customValue(themeScope + ".popup", "color", Globals.themeVars.Black)
            radius: Globals.customValue(themeScope + ".popup", "radius", Globals.themeVars.borderRadiusHuge)
            border.color: Globals.customValue(themeScope + ".popup", "borderColor", Globals.themeVars.Secondary10)
            border.width: Globals.customValue(themeScope + ".popup", "borderWidth", Globals.themeVars.borderWidthSmall)

            ColumnLayout {
                id: contentLayout
                anchors.fill: parent
                anchors.margins: Globals.customValue(themeScope + ".popup.layout", "margins", Globals.themeVars.spacingHuge)
                spacing: Globals.customValue(themeScope + ".popup.layout", "spacing", Globals.themeVars.spacingHuge)

                Text {
                    text: "Themes"
                    color: Globals.customValue(themeScope + ".popup.header", "color", Globals.themeVars.White)
                    font.pixelSize: Globals.customValue(themeScope + ".popup.header", "fontSize", Globals.themeVars.fontSizeLarge)
                    font.bold: true
                    Layout.fillWidth: true
                }

                Flickable {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Globals.customValue(themeScope + ".popup.list", "height", (120 * 2) + 8) // 2 rows of 120px height + 1 spacing
                    contentHeight: flowLayout.implicitHeight
                    clip: true

                    Flow {
                        id: flowLayout
                        width: parent.width
                        spacing: Globals.customValue(themeScope + ".popup.list.layout", "spacing", Globals.themeVars.spacingMedium)

                        property real itemWidth: (width - 3 * 8) / 4
                        property real itemHeight: 120

                        Repeater {
                            model: themesModel
                            delegate: Item {
                                width: flowLayout.itemWidth
                                height: flowLayout.itemHeight

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
                                property bool isActiveTheme: Globals.activeThemeFile === fileName

                                Rectangle {
                                    anchors.fill: parent
                                    radius: Globals.customValue(themeScope + ".popup.listItem", "radius", Globals.themeVars.borderRadiusMedium)
                                    color: isActiveTheme ? Globals.customValue(themeScope + ".popup.listItem", "activeColor", Globals.themeVars.Secondary25) : (themeMouse.containsMouse ? Globals.customValue(themeScope + ".popup.listItem", "hoverColor", Globals.themeVars.Secondary10) : Globals.customValue(themeScope + ".popup.listItem", "color", Globals.themeVars.Black))
                                    border.color: isActiveTheme ? Globals.customValue(themeScope + ".popup.listItem", "activeBorderColor", Globals.themeVars.Secondary) : Globals.customValue(themeScope + ".popup.listItem", "borderColor", "transparent")
                                    border.width: isActiveTheme ? Globals.customValue(themeScope + ".popup.listItem", "activeBorderWidth", 2) : Globals.customValue(themeScope + ".popup.listItem", "borderWidth", 0)

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
                                        anchors.margins: Globals.customValue(themeScope + ".popup.listItem.layout", "margins", 6)
                                        spacing: Globals.customValue(themeScope + ".popup.listItem.layout", "spacing", 6)

                                        // Wallpaper preview
                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            radius: Globals.customValue(themeScope + ".popup.listItem.preview", "radius", Globals.customValue("", "borderRadiusMedium", 8))
                                            color: Globals.customValue(themeScope + ".popup.listItem.preview", "color", Globals.themeVars.Black)
                                            clip: true
                                            border.color: Globals.customValue(themeScope + ".popup.listItem.preview", "borderColor", Globals.themeVars.Secondary10)
                                            border.width: Globals.customValue(themeScope + ".popup.listItem.preview", "borderWidth", Globals.themeVars.borderWidthSmall)

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
                                            color: Globals.customValue(themeScope + ".popup.listItem.name", "color", Globals.themeVars.White)
                                            font.pixelSize: Globals.customValue(themeScope + ".popup.listItem.name", "fontSize", Globals.themeVars.fontSizeSmall)
                                            font.bold: true
                                            horizontalAlignment: Text.AlignHCenter
                                            elide: Text.ElideRight
                                        }

                                        Row {
                                            Layout.alignment: Qt.AlignHCenter
                                            spacing: Globals.customValue(themeScope + ".popup.listItem.colors", "spacing", 4)
                                            Repeater {
                                                model: ["Main", "Secondary", "Success", "Warning", "Error"]
                                                delegate: Rectangle {
                                                    width: Globals.customValue(themeScope + ".popup.listItem.colorDot", "width", 14); height: Globals.customValue(themeScope + ".popup.listItem.colorDot", "height", 4); radius: Globals.customValue(themeScope + ".popup.listItem.colorDot", "radius", 2)
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
