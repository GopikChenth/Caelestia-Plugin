pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils
import "ColorUtils.js" as ColorUtils

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
            return Paths.config + "/color-picker-settings.json";
        } catch (e) {
            return pluginDir + "/settings.json";
        }
    }

    // Configuration matching PowerToys Color Picker
    property bool pluginEnabled: true
    property string activationShortcut: "SUPER + SHIFT + C"
    // activationBehavior: "editor" (Open editor), "pick_and_editor" (Pick color and open editor), "pick_only" (Pick color only)
    property string activationBehavior: "editor"
    property string defaultFormat: "HEX"
    property bool showColorName: true
    property var enabledFormats: ({
        "HEX": true,
        "HEX (no #)": true,
        "RGB": true,
        "HSL": true,
        "HSV": true,
        "CMYK": true
    })

    property bool autoCopy: true
    property bool sendNotification: true
    property bool openEditorOnPick: true
    property bool zoomLens: true
    property int zoomScale: 5
    property int circleRadius: 40
    property int maxHistory: 20

    // Reactive State
    property var currentColor: ColorUtils.formatColor("#161417")
    property var history: []
    property bool isPicking: false
    property bool editorVisible: false

    signal colorPicked(string hex)
    signal requestOpenEditor()

    Component.onCompleted: {
        settingsFile.reload();
    }

    function triggerActivation() {
        if (!pluginEnabled) return;
        if (activationBehavior === "editor") {
            editorVisible = !editorVisible;
        } else if (activationBehavior === "pick_only") {
            pickColor();
        } else {
            // pick_and_editor
            pickColor();
        }
    }

    function pickColor() {
        if (!pluginEnabled) return;
        if (pickerProc.running) return;
        isPicking = true;
        let args = ["hyprpicker", "-b"];
        if (!zoomLens) {
            args.push("-z");
        }
        if (zoomScale > 1) {
            args.push("-s", zoomScale.toString());
        }
        if (circleRadius > 0) {
            args.push("-u", circleRadius.toString());
        }

        pickerProc.command = args;
        pickerProc.running = true;
    }

    function setColor(hexInput) {
        const formatted = ColorUtils.formatColor(hexInput);
        if (!formatted) return;

        currentColor = formatted;

        // Add to history (deduplicate, most recent first)
        let newHistory = [];
        newHistory.push({
            hex: formatted.hex,
            name: formatted.colorName,
            rgb: formatted.rgb
        });

        for (let i = 0; i < history.length; i++) {
            if (history[i].hex !== formatted.hex && newHistory.length < maxHistory) {
                newHistory.push(history[i]);
            }
        }

        history = newHistory;
        saveSettings();
    }

    function setColorFromHsv(h, s, v) {
        const rgb = ColorUtils.hsvToRgb(h, s, v);
        const hex = ColorUtils.rgbToHex(rgb.r, rgb.g, rgb.b);
        const formatted = ColorUtils.formatColor(hex);
        if (formatted) {
            currentColor = formatted;
        }
    }

    function setColorFromRgb(r, g, b) {
        const hex = ColorUtils.rgbToHex(r, g, b);
        const formatted = ColorUtils.formatColor(hex);
        if (formatted) {
            currentColor = formatted;
        }
    }

    function formatValue(formatName, c) {
        const col = c || currentColor;
        if (!col) return "";
        switch (formatName) {
            case "HEX":
                return col.hex;
            case "HEX (no #)":
                return col.hexClean;
            case "RGB":
                return col.rgb;
            case "HSL":
                return col.hsl;
            case "HSV":
                return col.hsv;
            case "CMYK":
                return col.cmyk;
            default:
                return col.hex;
        }
    }

    function copyFormatted(formatName, customColor) {
        const col = customColor || currentColor;
        if (!col) return;
        const text = formatValue(formatName, col);
        if (text) {
            copyText(text, formatName);
        }
    }

    function copyText(text, label) {
        copyProc.command = ["wl-copy", text];
        copyProc.running = true;

        if (sendNotification) {
            notifyProc.command = [
                "notify-send",
                "-a", "PowerToys Color Picker",
                `Copied ${label || "Color"}`,
                text
            ];
            notifyProc.running = true;
        }
    }

    function toggleFormatEnabled(fmtName, isEnabled) {
        let copy = Object.assign({}, enabledFormats);
        copy[fmtName] = isEnabled;
        enabledFormats = copy;
        saveSettings();
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
            defaultFormat: defaultFormat,
            showColorName: showColorName,
            enabledFormats: enabledFormats,
            autoCopy: autoCopy,
            sendNotification: sendNotification,
            openEditorOnPick: openEditorOnPick,
            zoomLens: zoomLens,
            zoomScale: zoomScale,
            circleRadius: circleRadius,
            maxHistory: maxHistory,
            history: history
        };

        const jsonStr = JSON.stringify(data, null, 4);
        saveProc.command = ["bash", "-c", `cat << 'EOF' > "${settingsFilePath}"\n${jsonStr}\nEOF`];
        saveProc.running = true;
    }

    // Process: Hyprpicker
    property var _pickerProc: Process {
        id: pickerProc
        command: ["hyprpicker", "-b"]
        stdout: StdioCollector {
            id: pickerOut
            onStreamFinished: {
                const raw = pickerOut.text ? pickerOut.text.trim() : "";
                const hex = ColorUtils.extractHex(raw);
                if (hex) {
                    root.setColor(hex);
                    if (root.autoCopy) {
                        root.copyFormatted(root.defaultFormat);
                    }
                    root.colorPicked(hex);
                    // Determine whether to open editor based on activationBehavior or openEditorOnPick
                    if (root.activationBehavior === "editor" || root.activationBehavior === "pick_and_editor" || root.openEditorOnPick) {
                        root.editorVisible = true;
                        root.requestOpenEditor();
                    }
                }
                root.isPicking = false;
            }
        }
        stderr: StdioCollector {
            id: pickerErr
            onStreamFinished: {
                if (pickerErr.text && pickerErr.text.trim().length > 0) {
                    console.warn("[ColorService] pickerProc stderr:", pickerErr.text.trim());
                }
            }
        }
        onRunningChanged: {
            if (!running) {
                root.isPicking = false;
            }
        }
        onExited: (code, status) => {
            root.isPicking = false;
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
                if (parsed.defaultFormat !== undefined) root.defaultFormat = parsed.defaultFormat;
                if (parsed.showColorName !== undefined) root.showColorName = parsed.showColorName;
                if (parsed.enabledFormats !== undefined) root.enabledFormats = Object.assign({}, root.enabledFormats, parsed.enabledFormats);
                if (parsed.autoCopy !== undefined) root.autoCopy = parsed.autoCopy;
                if (parsed.sendNotification !== undefined) root.sendNotification = parsed.sendNotification;
                if (parsed.openEditorOnPick !== undefined) root.openEditorOnPick = parsed.openEditorOnPick;
                if (parsed.zoomLens !== undefined) root.zoomLens = parsed.zoomLens;
                if (parsed.zoomScale !== undefined) root.zoomScale = parsed.zoomScale;
                if (parsed.circleRadius !== undefined) root.circleRadius = parsed.circleRadius;
                if (parsed.maxHistory !== undefined) root.maxHistory = parsed.maxHistory;
                if (Array.isArray(parsed.history)) root.history = parsed.history;

                if (root.history.length > 0 && root.history[0].hex) {
                    const f = ColorUtils.formatColor(root.history[0].hex);
                    if (f) root.currentColor = f;
                }
            } catch (err) {
                console.warn("[ColorService] Error loading settings.json:", err);
            }
        }
    }
}
