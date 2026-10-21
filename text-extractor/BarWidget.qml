pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.services
import qs.components

Rectangle {
    id: root

    property var textService: TextService

    readonly property int itemSize: typeof Tokens !== "undefined" ? Tokens.sizes.bar.itemSize : 32
    readonly property int radiusFull: typeof Tokens !== "undefined" ? Tokens.rounding.full : 9999

    implicitWidth: itemSize
    implicitHeight: itemSize
    radius: radiusFull
    color: mouseArea.containsMouse ? (typeof Colours !== "undefined" ? Colours.palette.m3surfaceContainerHigh : Qt.rgba(1, 1, 1, 0.15)) : "transparent"

    MaterialIcon {
        anchors.centerIn: parent
        text: "document_scanner"
        fontStyle: Tokens.font.icon.small
        color: root.textService?.isExtracting ? (typeof Colours !== "undefined" ? Colours.palette.m3primary : "#89B4FA") : (typeof Colours !== "undefined" ? Colours.palette.m3onSurface : "#CDD6F4")
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton) {
                root.textService.extractText();
            } else if (mouse.button === Qt.RightButton) {
                root.textService.windowVisible = !root.textService.windowVisible;
            }
        }
    }
}
