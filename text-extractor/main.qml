import QtQuick
import Quickshell
import "."

ShellRoot {
    id: root

    TextExtractorWindow {
        id: extractorWin
        textService: TextService
    }

    Component.onCompleted: {
        TextService.windowVisible = true;
    }
}
