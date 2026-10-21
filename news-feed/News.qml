pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils

Item {
    id: root

    property bool isFetching: false
    property string errorMessage: ""
    property int currentFeedIndex: 0
    property var feedsList: [
        {
            "name": "Arch Linux News",
            "url": "https://archlinux.org/feeds/news/",
            "enabled": true
        },
        {
            "name": "Insider Gaming",
            "url": "https://insider-gaming.com/feed/",
            "enabled": true
        },
        {
            "name": "Android Authority",
            "url": "https://www.androidauthority.com/feed/",
            "enabled": true
        },
        {
            "name": "GSMArena",
            "url": "https://www.gsmarena.com/rss-news-reviews.php3",
            "enabled": true
        }
    ]

    readonly property var activeFeed: {
        if (root.feedsList && root.feedsList.length > 0) {
            var idx = Math.min(Math.max(0, root.currentFeedIndex), root.feedsList.length - 1);
            return root.feedsList[idx];
        }
        return { "name": "Arch Linux News", "url": "https://archlinux.org/feeds/news/" };
    }

    // Bind colors at the root to avoid delegate scope resolution issues
    readonly property color cBgHigh: Colours.tPalette.m3surfaceContainerHigh
    readonly property color cBgHighest: Colours.tPalette.m3surfaceContainerHighest
    readonly property color cOnSurface: Colours.palette.m3onSurface
    readonly property color cOnSurfaceVariant: Colours.palette.m3onSurfaceVariant
    readonly property color cError: Colours.palette.m3error

    Component.onCompleted: {
        newsConfigFile.reload();
    }

    function switchFeed(index) {
        if (index === root.currentFeedIndex && newsModel.count > 0) return;
        root.currentFeedIndex = index;
        fetchNews();
    }

    function fetchNews() {
        if (!root.activeFeed || !root.activeFeed.url) return;
        if (root.isFetching) return;

        root.isFetching = true;
        root.errorMessage = "";

        var xhr = new XMLHttpRequest();
        xhr.open("GET", root.activeFeed.url);
        xhr.onreadystatechange = function() {
            if (!root) return;
            if (xhr.readyState === XMLHttpRequest.DONE) {
                root.isFetching = false;
                if (xhr.status === 200) {
                    parseNews(xhr.responseText);
                } else {
                    root.errorMessage = qsTr("Failed to fetch news (Status: %1)").arg(xhr.status);
                }
            }
        };
        xhr.send();
    }

    function cleanText(text) {
        if (!text) return "";
        var s = String(text);
        s = s.replace(/<!\[CDATA\[([\s\S]*?)\]\]>/g, "$1");
        s = s.replace(/<[^>]+>/g, " ");
        s = s.replace(/&amp;/g, "&")
             .replace(/&lt;/g, "<")
             .replace(/&gt;/g, ">")
             .replace(/&quot;/g, "\"")
             .replace(/&#039;/g, "'")
             .replace(/&apos;/g, "'")
             .replace(/&nbsp;/g, " ")
             .replace(/&#8217;/g, "’")
             .replace(/&#8216;/g, "‘")
             .replace(/&#8220;/g, "“")
             .replace(/&#8221;/g, "”")
             .replace(/&#8211;/g, "–")
             .replace(/&#8212;/g, "—")
             .replace(/&#(\d+);/g, function(match, dec) {
                 return String.fromCharCode(dec);
             });
        return s.replace(/\s+/g, " ").trim();
    }

    function formatPubDate(dateStr) {
        if (!dateStr) return "";
        var d = new Date(dateStr);
        if (isNaN(d.getTime())) return cleanText(dateStr);
        
        var now = new Date();
        var diffMs = now.getTime() - d.getTime();
        var diffMinutes = Math.floor(diffMs / (1000 * 60));
        var diffHours = Math.floor(diffMs / (1000 * 60 * 60));
        var diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24));

        if (diffMinutes >= 0 && diffMinutes < 60) {
            return diffMinutes <= 1 ? qsTr("Just now") : qsTr("%1m ago").arg(diffMinutes);
        }
        if (diffHours >= 0 && diffHours < 24) {
            return qsTr("%1h ago").arg(diffHours);
        }
        if (diffDays === 1) return qsTr("Yesterday");
        if (diffDays > 1 && diffDays < 7) return qsTr("%1d ago").arg(diffDays);

        try {
            var options = { month: "short", day: "numeric", year: (d.getFullYear() !== now.getFullYear() ? "numeric" : undefined) };
            return d.toLocaleDateString(undefined, options);
        } catch (e) {
            return d.toLocaleDateString();
        }
    }

    function parseNews(xmlString) {
        newsModel.clear();
        if (!xmlString) {
            root.errorMessage = qsTr("Empty response received.");
            return;
        }

        var isAtom = /<feed\b[^>]*>/i.test(xmlString) && /<entry\b/i.test(xmlString);

        if (isAtom) {
            var entryRegex = /<entry\b[^>]*>([\s\S]*?)<\/entry>/gi;
            var entryMatch;
            while ((entryMatch = entryRegex.exec(xmlString)) !== null) {
                var entryContent = entryMatch[1];
                var titleMatch = entryContent.match(/<title\b[^>]*>([\s\S]*?)<\/title>/i);
                var dateMatch = entryContent.match(/<(?:published|updated)\b[^>]*>([\s\S]*?)<\/(?:published|updated)>/i);
                var linkMatch = entryContent.match(/<link\b[^>]*href=["']([^"']+)["'][^>]*>/i);

                if (titleMatch && linkMatch) {
                    var aTitle = cleanText(titleMatch[1]);
                    var aLink = linkMatch[1];
                    var aDate = dateMatch ? formatPubDate(dateMatch[1]) : "";
                    newsModel.append({
                        "title": aTitle,
                        "link": aLink,
                        "date": aDate
                    });
                }
            }
        } else {
            var itemRegex = /<item\b[^>]*>([\s\S]*?)<\/item>/gi;
            var itemMatch;
            while ((itemMatch = itemRegex.exec(xmlString)) !== null) {
                var itemContent = itemMatch[1];
                var rTitleMatch = itemContent.match(/<title\b[^>]*>([\s\S]*?)<\/title>/i);
                var rLinkMatch = itemContent.match(/<link\b[^>]*>([\s\S]*?)<\/link>/i);
                var rDateMatch = itemContent.match(/<pubDate\b[^>]*>([\s\S]*?)<\/pubDate>/i) || itemContent.match(/<dc:date\b[^>]*>([\s\S]*?)<\/dc:date>/i);

                if (rTitleMatch && rLinkMatch) {
                    var rTitle = cleanText(rTitleMatch[1]);
                    var rLink = cleanText(rLinkMatch[1]);
                    var rDate = rDateMatch ? formatPubDate(rDateMatch[1]) : "";

                    newsModel.append({
                        "title": rTitle,
                        "link": rLink,
                        "date": rDate
                    });
                }
            }
        }

        if (newsModel.count === 0) {
            root.errorMessage = qsTr("No news articles found in this feed.");
        }
    }

    ListModel {
        id: newsModel
    }

    // Process to open Nexus Settings (Plugins page)
    property var _openNexusProc: Process {
        id: openNexusProc
        command: ["caelestia", "shell", "nexus", "openPlugins"]
    }

    // FileView watching ~/.config/caelestia/news.json
    property var _newsConfigFile: FileView {
        id: newsConfigFile
        path: Paths.config + "/news.json"
        printErrors: false
        watchChanges: true
        onLoaded: {
            try {
                var content = text();
                if (content && content.trim().length > 0) {
                    var parsed = JSON.parse(content);
                    if (Array.isArray(parsed) && parsed.length > 0) {
                        // Filter for enabled feeds or all if none have enabled field
                        var filtered = [];
                        for (var i = 0; i < parsed.length; i++) {
                            if (parsed[i].enabled !== false) {
                                filtered.push(parsed[i]);
                            }
                        }
                        if (filtered.length > 0) {
                            root.feedsList = filtered;
                        } else {
                            root.feedsList = parsed;
                        }
                    }
                }
            } catch (e) {
                console.warn("[News] Error reading news.json:", e);
            }
            if (root.currentFeedIndex >= root.feedsList.length) {
                root.currentFeedIndex = 0;
            }
            root.fetchNews();
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Tokens.padding.medium
        spacing: Tokens.spacing.medium

        // Header Row
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            StyledText {
                Layout.fillWidth: true
                text: root.activeFeed ? root.activeFeed.name : qsTr("News Feed")
                font: Tokens.font.title.medium
                color: root.cOnSurface
                elide: Text.ElideRight
            }

            // Configure Feeds in Plugin Manager
            IconButton {
                icon: "tune"
                onClicked: openNexusProc.running = true
            }

            // Refresh Button
            IconButton {
                icon: "refresh"
                onClicked: fetchNews()
            }
        }

        // Horizontal Feed Switcher Chips (when multiple feeds exist)
        Flickable {
            id: chipFlickable
            Layout.fillWidth: true
            implicitHeight: chipRow.implicitHeight
            contentWidth: chipRow.implicitWidth
            flickableDirection: Flickable.HorizontalFlick
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            visible: root.feedsList && root.feedsList.length > 1

            RowLayout {
                id: chipRow
                spacing: Tokens.spacing.small

                Repeater {
                    model: root.feedsList

                    delegate: StyledRect {
                        id: chipItem
                        required property var modelData
                        required property int index

                        readonly property bool isActive: root.currentFeedIndex === chipItem.index

                        implicitWidth: chipLabel.implicitWidth + Tokens.padding.medium * 2
                        implicitHeight: 30
                        radius: Tokens.rounding.full
                        color: chipItem.isActive ? Colours.palette.m3primary : (chipMa.containsMouse ? root.cBgHighest : root.cBgHigh)

                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }

                        StyledText {
                            id: chipLabel
                            anchors.centerIn: parent
                            text: chipItem.modelData.name || qsTr("Feed %1").arg(chipItem.index + 1)
                            font: Tokens.font.label.medium
                            color: chipItem.isActive ? Colours.palette.m3onPrimary : (chipMa.containsMouse ? root.cOnSurface : root.cOnSurfaceVariant)
                        }

                        MouseArea {
                            id: chipMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.switchFeed(chipItem.index)
                        }
                    }
                }
            }
        }

        // Error message
        StyledText {
            Layout.fillWidth: true
            visible: root.errorMessage !== ""
            text: root.errorMessage
            color: root.cError
            wrapMode: Text.WordWrap
        }

        // Loading Indicator
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.isFetching && newsModel.count === 0

            ColumnLayout {
                anchors.centerIn: parent
                spacing: Tokens.spacing.small

                MaterialIcon {
                    Layout.alignment: Qt.AlignHCenter
                    text: "sync"
                    fontStyle: Tokens.font.icon.large
                    color: Colours.palette.m3primary
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("Fetching latest news...")
                    color: root.cOnSurfaceVariant
                    font: Tokens.font.body.medium
                }
            }
        }

        // Articles List
        ListView {
            id: newsListView

            Layout.fillWidth: true
            Layout.fillHeight: true
            model: newsModel
            spacing: Tokens.spacing.small
            clip: true
            visible: !root.isFetching || newsModel.count > 0

            ScrollBar.vertical: StyledScrollBar { flickable: newsListView }

            delegate: StyledRect {
                id: delegateItem

                required property string title
                required property string link
                required property string date

                width: ListView.view.width
                implicitHeight: col.implicitHeight + Tokens.padding.medium * 2
                radius: Tokens.rounding.medium
                color: ma.containsMouse ? root.cBgHighest : root.cBgHigh

                Behavior on color {
                    ColorAnimation { duration: 120 }
                }

                MouseArea {
                    id: ma
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Qt.openUrlExternally(delegateItem.link)
                }

                ColumnLayout {
                    id: col
                    anchors.fill: parent
                    anchors.margins: Tokens.padding.medium
                    spacing: Tokens.spacing.extraSmall

                    StyledText {
                        Layout.fillWidth: true
                        text: delegateItem.title
                        font: Tokens.font.label.large
                        color: root.cOnSurface
                        wrapMode: Text.WordWrap
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: delegateItem.date
                        font: Tokens.font.body.small
                        color: root.cOnSurfaceVariant
                    }
                }
            }
        }
    }
}
