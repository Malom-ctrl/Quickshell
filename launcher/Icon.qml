import QtQuick
import QtQuick.Shapes

Item {
    id: root
    width: 24
    height: 24
    property string path: ""
    property color color: Globals.customValue(themeScope, "color", Globals.themeVars.White)

    Shape {
        width: 24
        height: 24
        anchors.centerIn: parent
        scale: Math.min(root.width / 24, root.height / 24)

        ShapePath {
            fillColor: root.color
            strokeColor: "transparent"
            PathSvg {
                path: root.path
            }
        }
    }
}
