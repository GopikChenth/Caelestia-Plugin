pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.services
import Quickshell
import Quickshell.Io

Rectangle {
    id: root

    property var newsService: NewsService

    readonly property int itemSize: typeof Tokens !== "undefined" ? Tokens.sizes.bar.itemSize : 32
    readonly property int radiusFull: typeof Tokens !== "undefined" ? Tokens.rounding.full : 9999

    implicitWidth: itemSize
    implicitHeight: itemSize
    radius: radiusFull
    color: mouseArea.containsMouse ? (typeof Colours !== "undefined" ? Colours.palette.m3surfaceContainerHigh : Qt.rgba(1, 1, 1, 0.15)) : "transparent"

    MaterialIcon {
        id: icon
        anchors.centerIn: parent
        text: "feed"
        fontStyle: Tokens.font.icon.small
        color: typeof Colours !== "undefined" ? Colours.palette.m3primary : "#89B4FA"
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton) {
                toggleSidebarProc.running = true;
            } else if (mouse.button === Qt.RightButton) {
                openNexusProc.running = true;
            }
        }
    }

    property var _toggleSidebarProc: Process {
        id: toggleSidebarProc
        command: ["caelestia", "shell", "drawers", "toggleTab", "sidebar", "news"]
    }

    property var _openNexusProc: Process {
        id: openNexusProc
        command: ["caelestia", "shell", "nexus", "open"]
    }
}
