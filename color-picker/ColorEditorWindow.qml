pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.services
import "ColorUtils.js" as ColorUtils

FloatingWindow {
    id: win

    property var colorService: ColorService

    contentItem.Config.screen: screen ? screen.name : ""
    contentItem.Tokens.screen: screen ? screen.name : ""

    title: "Caelestia Color Picker"
    color: "transparent"
    surfaceFormat.opaque: false

    implicitWidth: editorCard.implicitWidth
    implicitHeight: editorCard.implicitHeight
    minimumSize.width: editorCard.implicitWidth
    minimumSize.height: editorCard.implicitHeight

    visible: colorService ? colorService.editorVisible : false

    function closeWindow(): void {
        if (win.colorService) {
            win.colorService.editorVisible = false;
        }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: win.closeWindow()
    }

    ColorEditorCard {
        id: editorCard
        anchors.fill: parent
        colorService: win.colorService
        showCloseButton: true
        onCloseClicked: win.closeWindow()
    }
}
