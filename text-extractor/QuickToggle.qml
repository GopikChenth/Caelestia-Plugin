pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

// Caelestia controls when run inside shell
import qs.components.controls
import qs.services

IconButton {
    id: root

    property var textService: TextService

    icon: "document_scanner"
    tooltipText: "Text Extractor (Screen OCR)"
    isToggle: false
    isRound: true
    fillWidth: true
    shapeMorph: true

    inactiveColour: typeof Colours !== "undefined" ? Colours.layer(Colours.palette.m3surfaceContainerHighest, 2) : "#313244"
    inactiveOnColour: typeof Colours !== "undefined" ? Colours.palette.m3primary : "#89B4FA"

    onClicked: {
        textService.extractText();
    }
}
