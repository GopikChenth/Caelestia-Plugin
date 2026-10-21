pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.services
import "."

FloatingWindow {
    id: win

    property var textService: TextService

    screen: ShellState.forActive()?.modelData ?? Quickshell.screens[0]
    contentItem.Config.screen: screen ? screen.name : ""
    contentItem.Tokens.screen: screen ? screen.name : ""

    title: "Caelestia Text Extractor"
    color: "transparent"
    surfaceFormat.opaque: false

    implicitWidth: extractorCard.implicitWidth
    implicitHeight: extractorCard.implicitHeight
    minimumSize.width: (contentItem.Tokens.sizes?.nexus?.minWidth) ?? 400
    minimumSize.height: (contentItem.Tokens.sizes?.nexus?.minHeight) ?? 360

    visible: textService.windowVisible

    onVisibleChanged: {
        textService.windowVisible = visible;
    }

    Shortcut {
        sequence: "Escape"
        onActivated: win.visible = false
    }

    TextExtractorCard {
        id: extractorCard
        anchors.fill: parent
        textService: win.textService
        showCloseButton: true
        onCloseClicked: win.visible = false
    }
}
