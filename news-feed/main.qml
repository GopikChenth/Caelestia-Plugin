import QtQuick
import Quickshell
import "."

ShellRoot {
    id: root

    Component.onCompleted: {
        NewsService.fetchActiveFeed();
    }
}
