pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils
import "TextUtils.js" as TextUtils

Singleton {
    id: root

    readonly property string pluginDir: {
        try {
            return Paths.toLocalFile(Qt.resolvedUrl("."));
        } catch (e) {
            return Qt.resolvedUrl(".").toString().replace(/^file:\/\//, "");
        }
    }
    readonly property string settingsFilePath: {
        try {
            return Paths.config + "/text-extractor-settings.json";
        } catch (e) {
            return pluginDir + "/settings.json";
        }
    }

    // Configuration matching PowerToys Text Extractor
    property bool pluginEnabled: true
    property string activationShortcut: "SHIFT + SUPER + T"
    // activationBehavior: "extract_and_window", "extract_only", "window_only"
    property string activationBehavior: "extract_and_window"
    property string ocrLanguage: "eng"
    property int psmMode: 3 // 3: Auto, 6: Single Block, 7: Single Line
    property bool singleLineMode: false
    property bool autoCopy: true
    property bool sendNotification: true
    property bool openWindowOnExtract: true
    property string slurpBorderColor: "#89B4FA"
    property string slurpBgColor: "#16141788"
    property int maxHistory: 20

    // Reactive State
    property string currentText: "Welcome to Text Extractor!\nSelect any region on screen to capture text instantly."
    property var history: []
    property bool isExtracting: false
    property bool windowVisible: false

    signal textExtracted(string text)
    signal requestOpenWindow()

    Component.onCompleted: {
        settingsFile.reload();
    }

    function triggerActivation() {
        if (!pluginEnabled) return;
        if (activationBehavior === "window_only") {
            windowVisible = !windowVisible;
        } else {
            extractText();
        }
    }

    function extractText() {
        if (!pluginEnabled || isExtracting) return;
        isExtracting = true;
        extractionTimeout.restart();
        let scriptPath = pluginDir + "/extract.sh";
        let args = [
            scriptPath,
            "-l", ocrLanguage,
            "-p", psmMode.toString(),
            "--border", slurpBorderColor,
            "--bg", slurpBgColor
        ];
        if (singleLineMode) {
            args.push("-s");
        } else {
            args.push("-m");
        }
        if (!autoCopy && activationBehavior !== "extract_only") {
            args.push("--no-copy");
        }
        if (!sendNotification) {
            args.push("--no-notify");
        }

        extractProc.command = args;
        extractProc.running = true;
    }

    function setText(rawText) {
        if (!rawText || rawText.trim().length === 0) return;
        currentText = rawText;

        const date = new Date();
        const timeStr = date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });

        let newItem = {
            id: Date.now().toString(),
            text: rawText,
            snippet: TextUtils.snippet(rawText, 70),
            charCount: TextUtils.countChars(rawText),
            wordCount: TextUtils.countWords(rawText),
            lang: ocrLanguage,
            timestamp: timeStr
        };

        let newHistory = [newItem];
        for (let i = 0; i < history.length; i++) {
            if (history[i].text !== rawText && newHistory.length < maxHistory) {
                newHistory.push(history[i]);
            }
        }

        history = newHistory;
        saveSettings();
    }

    function copyFormatted(formatName) {
        if (!currentText) return;
        const formatted = TextUtils.formatText(formatName, currentText);
        copyText(formatted, formatName);
    }

    function copyText(text, label) {
        if (!text) return;
        copyProc.command = ["wl-copy", text];
        copyProc.running = true;

        if (sendNotification) {
            notifyProc.command = [
                "notify-send",
                "-a", "PowerToys Text Extractor",
                `Copied ${label || "Text"}`,
                TextUtils.snippet(text, 60)
            ];
            notifyProc.running = true;
        }
    }

    function clearHistory() {
        history = [];
        saveSettings();
    }

    function removeHistoryItem(index) {
        let copy = history.slice();
        copy.splice(index, 1);
        history = copy;
        saveSettings();
    }

    function saveSettings() {
        const data = {
            pluginEnabled: pluginEnabled,
            activationShortcut: activationShortcut,
            activationBehavior: activationBehavior,
            ocrLanguage: ocrLanguage,
            psmMode: psmMode,
            singleLineMode: singleLineMode,
            autoCopy: autoCopy,
            sendNotification: sendNotification,
            openWindowOnExtract: openWindowOnExtract,
            slurpBorderColor: slurpBorderColor,
            slurpBgColor: slurpBgColor,
            maxHistory: maxHistory,
            history: history
        };

        const jsonStr = JSON.stringify(data, null, 4);
        const scClean = activationShortcut ? activationShortcut.trim().toUpperCase() : "SUPER + SHIFT + T";
        const script = `cat << 'EOF' > "${settingsFilePath}"
${jsonStr}
EOF
if [ -f "$HOME/.config/caelestia/hypr-user.lua" ]; then
    sed -i -E 's/hl\\.bind\\(".*",\\s*hl\\.dsp\\.exec_cmd\\("caelestia-text-extractor"\\)\\)/hl.bind("${scClean}", hl.dsp.exec_cmd("caelestia-text-extractor"))/g' "$HOME/.config/caelestia/hypr-user.lua" 2>/dev/null || true
    hyprctl reload 2>/dev/null || true
fi`;
        saveProc.command = ["bash", "-c", script];
        saveProc.running = true;
    }

    Timer {
        id: extractionTimeout
        interval: 45000
        repeat: false
        onTriggered: {
            root.isExtracting = false;
        }
    }

    // Process: OCR Pipeline Runner
    property var _extractProc: Process {
        id: extractProc
        command: ["bash", "-c", "true"]
        stdout: StdioCollector {
            id: extractOut
            onStreamFinished: {
                extractionTimeout.stop();
                const raw = extractOut.text ? extractOut.text.trim() : "";
                if (raw && raw.length > 0) {
                    root.setText(raw);
                    root.textExtracted(raw);
                    // Determine window visibility: never open window in extract_only mode
                    if (root.activationBehavior === "extract_and_window" || (root.openWindowOnExtract && root.activationBehavior !== "extract_only")) {
                        root.windowVisible = true;
                        root.requestOpenWindow();
                    } else {
                        root.windowVisible = false;
                    }
                }
                root.isExtracting = false;
            }
        }
        onExited: code => {
            extractionTimeout.stop();
            root.isExtracting = false;
        }
    }

    // Process: wl-copy
    property var _copyProc: Process {
        id: copyProc
        command: ["wl-copy", ""]
    }

    // Process: notify-send
    property var _notifyProc: Process {
        id: notifyProc
        command: ["notify-send", ""]
    }

    // Process: Atomic file save
    property var _saveProc: Process {
        id: saveProc
        command: ["bash", "-c", "true"]
    }

    // FileView for loading settings
    property var _settingsFile: FileView {
        id: settingsFile
        path: root.settingsFilePath
        printErrors: false
        watchChanges: false
        onLoaded: {
            try {
                const content = text();
                if (!content || content.trim().length === 0) return;
                const parsed = JSON.parse(content);
                if (parsed.pluginEnabled !== undefined) root.pluginEnabled = parsed.pluginEnabled;
                if (parsed.activationShortcut !== undefined) root.activationShortcut = parsed.activationShortcut;
                if (parsed.activationBehavior !== undefined) root.activationBehavior = parsed.activationBehavior;
                if (parsed.ocrLanguage !== undefined) root.ocrLanguage = parsed.ocrLanguage;
                if (parsed.psmMode !== undefined) root.psmMode = parsed.psmMode;
                if (parsed.singleLineMode !== undefined) root.singleLineMode = parsed.singleLineMode;
                if (parsed.autoCopy !== undefined) root.autoCopy = parsed.autoCopy;
                if (parsed.sendNotification !== undefined) root.sendNotification = parsed.sendNotification;
                if (parsed.openWindowOnExtract !== undefined) root.openWindowOnExtract = parsed.openWindowOnExtract;
                if (parsed.slurpBorderColor !== undefined) root.slurpBorderColor = parsed.slurpBorderColor;
                if (parsed.slurpBgColor !== undefined) root.slurpBgColor = parsed.slurpBgColor;
                if (parsed.maxHistory !== undefined) root.maxHistory = parsed.maxHistory;
                if (Array.isArray(parsed.history)) root.history = parsed.history;

                if (root.history.length > 0 && root.history[0].text) {
                    root.currentText = root.history[0].text;
                }
            } catch (err) {
                console.warn("[TextService] Error loading settings.json:", err);
            }
        }
    }
}
