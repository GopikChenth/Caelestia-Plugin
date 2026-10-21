import QtQuick
import Quickshell
import "."

ShellRoot {
    id: root

    ColorEditorWindow {
        id: editorWin
        colorService: ColorService
    }

    Component.onCompleted: {
        ColorService.editorVisible = true;
    }
}
