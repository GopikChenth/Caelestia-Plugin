pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.services
import "ColorUtils.js" as ColorUtils

Rectangle {
    id: root

    property var colorService: ColorService

    readonly property int itemSize: typeof Tokens !== "undefined" ? Tokens.sizes.bar.itemSize : 32
    readonly property int radiusFull: typeof Tokens !== "undefined" ? Tokens.rounding.full : 9999

    implicitWidth: itemSize
    implicitHeight: itemSize
    radius: radiusFull
    color: mouseArea.containsMouse ? (typeof Colours !== "undefined" ? Colours.palette.m3surfaceContainerHigh : Qt.rgba(1, 1, 1, 0.15)) : "transparent"

    Rectangle {
        id: swatch
        anchors.centerIn: parent
        width: Math.round(root.itemSize * 0.55)
        height: width
        radius: root.radiusFull
        color: root.colorService?.currentColor ? root.colorService.currentColor.hex : (typeof Colours !== "undefined" ? Colours.palette.m3primary : "#3B82F6")
        border.color: typeof Colours !== "undefined" ? Colours.palette.m3outlineVariant : Qt.rgba(1, 1, 1, 0.3)
        border.width: 1

        Behavior on color {
            ColorAnimation { duration: 150 }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton) {
                root.colorService.pickColor();
            } else if (mouse.button === Qt.RightButton) {
                root.colorService.editorVisible = !root.colorService.editorVisible;
            }
        }
    }
}
