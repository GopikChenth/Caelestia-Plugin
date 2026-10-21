pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils
import "NewsUtils.js" as NewsUtils

Singleton {
    id: root

    readonly property string newsConfigPath: Paths.config + "/news.json"
    readonly property string settingsFilePath: Paths.config + "/news-feed-settings.json"

    // Settings
    property bool pluginEnabled: true
    property int refreshInterval: 30
    property int maxArticles: 20
    property bool openInBrowser: true
    property int activeFeedIndex: 0

    // Feeds list
    property var feeds: []
    
    // Testing state
    property bool isTestingFeed: false
    property var lastTestResult: null

    // Active feed articles cache
    property var activeArticles: []
    property bool isFetchingArticles: false
    property string fetchError: ""

    signal feedsUpdated()
    signal testCompleted(var result)
    signal articlesFetched()

    Component.onCompleted: {
        settingsFile.reload();
        newsConfigFile.reload();
    }

    // Default feeds catalog if news.json is empty or missing
    readonly property var defaultFeeds: [
        {
            "name": "Arch Linux News",
            "url": "https://archlinux.org/feeds/news/",
            "enabled": true,
            "icon": "terminal"
        },
        {
            "name": "Insider Gaming",
            "url": "https://insider-gaming.com/feed/",
            "enabled": true,
            "icon": "sports_esports"
        },
        {
            "name": "Android Authority",
            "url": "https://www.androidauthority.com/feed/",
            "enabled": true,
            "icon": "android"
        },
        {
            "name": "GSMArena",
            "url": "https://www.gsmarena.com/rss-news-reviews.php3",
            "enabled": true,
            "icon": "smartphone"
        },
        {
            "name": "Hacker News",
            "url": "https://news.ycombinator.com/rss",
            "enabled": true,
            "icon": "code"
        }
    ]

    function addFeed(name, url, icon): bool {
        if (!name || !url) return false;
        var cleanUrl = url.trim();
        var cleanName = name.trim();
        if (cleanUrl.length === 0 || cleanName.length === 0) return false;

        var current = (root.feeds && Array.isArray(root.feeds)) ? root.feeds.slice() : [];
        
        // Prevent duplicate URLs
        for (var i = 0; i < current.length; i++) {
            if (current[i].url === cleanUrl) {
                return false;
            }
        }

        current.push({
            "name": cleanName,
            "url": cleanUrl,
            "enabled": true,
            "icon": icon || "feed"
        });

        root.feeds = current;
        saveFeeds();
        return true;
    }

    function removeFeed(index): void {
        if (index < 0 || index >= root.feeds.length) return;
        var current = root.feeds.slice();
        current.splice(index, 1);
        root.feeds = current;
        if (root.activeFeedIndex >= root.feeds.length) {
            root.activeFeedIndex = Math.max(0, root.feeds.length - 1);
        }
        saveFeeds();
    }

    function updateFeed(index, name, url, icon, enabled): void {
        if (index < 0 || index >= root.feeds.length) return;
        var current = root.feeds.slice();
        current[index] = {
            "name": name.trim(),
            "url": url.trim(),
            "enabled": enabled !== undefined ? enabled : (current[index].enabled ?? true),
            "icon": icon || current[index].icon || "feed"
        };
        root.feeds = current;
        saveFeeds();
    }

    function toggleFeed(index, enabled): void {
        if (index < 0 || index >= root.feeds.length) return;
        var current = root.feeds.slice();
        current[index].enabled = enabled;
        root.feeds = current;
        saveFeeds();
    }

    function moveFeed(fromIdx, toIdx): void {
        if (fromIdx < 0 || fromIdx >= root.feeds.length) return;
        if (toIdx < 0 || toIdx >= root.feeds.length) return;
        if (fromIdx === toIdx) return;

        var current = root.feeds.slice();
        var item = current.splice(fromIdx, 1)[0];
        current.splice(toIdx, 0, item);
        root.feeds = current;

        if (root.activeFeedIndex === fromIdx) {
            root.activeFeedIndex = toIdx;
        } else if (fromIdx < root.activeFeedIndex && toIdx >= root.activeFeedIndex) {
            root.activeFeedIndex--;
        } else if (fromIdx > root.activeFeedIndex && toIdx <= root.activeFeedIndex) {
            root.activeFeedIndex++;
        }

        saveFeeds();
    }

    function resetToDefaults(): void {
        root.feeds = JSON.parse(JSON.stringify(root.defaultFeeds));
        root.activeFeedIndex = 0;
        saveFeeds();
    }

    function saveFeeds(): void {
        try {
            var toSave = [];
            for (var i = 0; i < root.feeds.length; i++) {
                var f = root.feeds[i];
                toSave.push({
                    "name": f.name,
                    "url": f.url,
                    "enabled": f.enabled !== false,
                    "icon": f.icon || "feed"
                });
            }
            var jsonStr = JSON.stringify(toSave, null, 2);
            saveNewsProc.command = ["bash", "-c", "cat << 'EOF' > \"" + root.newsConfigPath + "\"\n" + jsonStr + "\nEOF"];
            saveNewsProc.running = true;
            root.feedsUpdated();
        } catch (e) {
            console.warn("[NewsService] Error saving news.json:", e);
        }
    }

    function saveSettings(): void {
        try {
            var data = {
                "pluginEnabled": root.pluginEnabled,
                "refreshInterval": root.refreshInterval,
                "maxArticles": root.maxArticles,
                "openInBrowser": root.openInBrowser,
                "activeFeedIndex": root.activeFeedIndex
            };
            var jsonStr = JSON.stringify(data, null, 2);
            saveSettingsProc.command = ["bash", "-c", "cat << 'EOF' > \"" + root.settingsFilePath + "\"\n" + jsonStr + "\nEOF"];
            saveSettingsProc.running = true;
        } catch (e) {
            console.warn("[NewsService] Error saving settings:", e);
        }
    }

    function openNewsFile(): void {
        openFileProc.command = ["xdg-open", root.newsConfigPath];
        openFileProc.running = true;
    }

    function openUrl(url): void {
        if (!url) return;
        Qt.openUrlExternally(url);
    }

    function reloadFeeds(): void {
        newsConfigFile.reload();
    }

    function nextFeed(): void {
        if (!root.feeds || root.feeds.length <= 1) return;
        root.activeFeedIndex = (root.activeFeedIndex + 1) % root.feeds.length;
        fetchActiveFeed();
    }

    // Validate and preview any RSS/Atom feed URL
    function testFeedUrl(testUrl, callback): void {
        if (!testUrl || testUrl.trim().length === 0) {
            if (callback) callback({ success: false, error: "URL cannot be empty." });
            return;
        }
        var cleanUrl = testUrl.trim();
        root.isTestingFeed = true;
        root.lastTestResult = null;

        var xhr = new XMLHttpRequest();
        xhr.open("GET", cleanUrl);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                root.isTestingFeed = false;
                var res;
                if (xhr.status === 200) {
                    try {
                        var xml = xhr.responseText;
                        var title = NewsUtils.getFeedTitle(xml) || NewsUtils.getDomain(cleanUrl);
                        var articles = NewsUtils.parseFeedXml(xml);
                        if (articles && articles.length > 0) {
                            res = {
                                success: true,
                                title: title,
                                count: articles.length,
                                firstItem: articles[0],
                                error: ""
                            };
                        } else {
                            res = {
                                success: false,
                                title: title,
                                count: 0,
                                error: "Connected successfully, but found 0 valid RSS/Atom articles."
                            };
                        }
                    } catch (e) {
                        res = {
                            success: false,
                            error: "XML parse exception: " + e.message
                        };
                    }
                } else {
                    res = {
                        success: false,
                        error: "HTTP Request failed (Status " + xhr.status + ": " + xhr.statusText + ")"
                    };
                }
                root.lastTestResult = res;
                root.testCompleted(res);
                if (callback) callback(res);
            }
        };
        xhr.send();
    }

    // Fetch articles for the currently active feed
    function fetchActiveFeed(): void {
        if (!root.feeds || root.feeds.length === 0) {
            root.activeArticles = [];
            return;
        }
        var feed = root.feeds[root.activeFeedIndex] || root.feeds[0];
        if (!feed || !feed.url) return;

        root.isFetchingArticles = true;
        root.fetchError = "";

        var xhr = new XMLHttpRequest();
        xhr.open("GET", feed.url);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                root.isFetchingArticles = false;
                if (xhr.status === 200) {
                    try {
                        var list = NewsUtils.parseFeedXml(xhr.responseText);
                        if (root.maxArticles > 0 && list.length > root.maxArticles) {
                            list = list.slice(0, root.maxArticles);
                        }
                        root.activeArticles = list;
                        root.articlesFetched();
                    } catch (e) {
                        root.fetchError = "Failed to parse feed data.";
                    }
                } else {
                    root.fetchError = "Failed to fetch feed (HTTP " + xhr.status + ")";
                }
            }
        };
        xhr.send();
    }

    // Processes
    property var _saveNewsProc: Process {
        id: saveNewsProc
        command: ["bash", "-c", "true"]
    }

    property var _saveSettingsProc: Process {
        id: saveSettingsProc
        command: ["bash", "-c", "true"]
    }

    property var _openFileProc: Process {
        id: openFileProc
        command: ["xdg-open", ""]
    }

    // FileView: news.json
    property var _newsConfigFile: FileView {
        id: newsConfigFile
        path: root.newsConfigPath
        printErrors: false
        watchChanges: true
        onLoaded: {
            try {
                var content = text();
                if (!content || content.trim().length === 0) {
                    root.resetToDefaults();
                    return;
                }
                var parsed = JSON.parse(content);
                if (Array.isArray(parsed)) {
                    // Check if Arch Linux is present; if not and empty, restore
                    if (parsed.length === 0) {
                        root.resetToDefaults();
                    } else {
                        root.feeds = parsed;
                        root.feedsUpdated();
                    }
                }
            } catch (err) {
                console.warn("[NewsService] Error loading news.json:", err);
            }
        }
    }

    // FileView: news-feed-settings.json
    property var _settingsFile: FileView {
        id: settingsFile
        path: root.settingsFilePath
        printErrors: false
        watchChanges: false
        onLoaded: {
            try {
                var content = text();
                if (!content || content.trim().length === 0) return;
                var parsed = JSON.parse(content);
                if (parsed.pluginEnabled !== undefined) root.pluginEnabled = parsed.pluginEnabled;
                if (parsed.refreshInterval !== undefined) root.refreshInterval = parsed.refreshInterval;
                if (parsed.maxArticles !== undefined) root.maxArticles = parsed.maxArticles;
                if (parsed.openInBrowser !== undefined) root.openInBrowser = parsed.openInBrowser;
                if (parsed.activeFeedIndex !== undefined) root.activeFeedIndex = parsed.activeFeedIndex;
            } catch (err) {
                console.warn("[NewsService] Error loading news-feed-settings.json:", err);
            }
        }
    }
}
