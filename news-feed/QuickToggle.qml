pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.components.controls
import qs.services
import Quickshell
import Quickshell.Io

IconButton {
    id: root

    property var newsService: NewsService

    icon: "feed"
    isToggle: false
    isRound: true
    fillWidth: true
    shapeMorph: true

    inactiveColour: typeof Colours !== "undefined" ? Colours.layer(Colours.palette.m3surfaceContainerHighest, 2) : "#313244"
    inactiveOnColour: typeof Colours !== "undefined" ? Colours.palette.m3primary : "#89B4FA"

    onClicked: {
        toggleSidebarProc.running = true;
    }

    property var _toggleSidebarProc: Process {
        id: toggleSidebarProc
        command: ["caelestia", "shell", "drawers", "toggleTab", "sidebar", "news"]
    }
}
