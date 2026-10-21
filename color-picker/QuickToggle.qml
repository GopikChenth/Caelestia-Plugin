pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "ColorUtils.js" as ColorUtils

// Caelestia controls when run inside shell
import qs.components.controls
import qs.services

IconButton {
    id: root

    property var colorService: ColorService

    icon: "colorize"
    tooltipText: "Color Picker (" + (colorService.currentColor ? colorService.currentColor.hex : "Pick") + ")"
    isToggle: false
    isRound: true
    fillWidth: true
    shapeMorph: true

    inactiveColour: typeof Colours !== "undefined" ? Colours.layer(Colours.palette.m3surfaceContainerHighest, 2) : "#313244"
    inactiveOnColour: colorService.currentColor ? colorService.currentColor.hex : (typeof Colours !== "undefined" ? Colours.palette.m3primary : "#89B4FA")

    onClicked: {
        colorService.pickColor();
    }
}
