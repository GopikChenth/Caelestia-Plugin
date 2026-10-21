// TextUtils.js
// Text manipulation and formatting utilities for Text Extractor plugin
// Pure JavaScript implementation compatible with QML QtQuick / Quickshell runtime.

.pragma library

function cleanWhitespace(text) {
    if (!text) return "";
    return text.trim();
}

function toSingleLine(text) {
    if (!text) return "";
    return text
        .replace(/[\r\n]+/g, " ")
        .replace(/[ \t]+/g, " ")
        .trim();
}

function cleanLines(text) {
    if (!text) return "";
    return text
        .split(/\r?\n/)
        .map(line => line.trimEnd())
        .join("\n")
        .trim();
}

function toUppercase(text) {
    if (!text) return "";
    return text.toUpperCase();
}

function toLowercase(text) {
    if (!text) return "";
    return text.toLowerCase();
}

function toTitleCase(text) {
    if (!text) return "";
    return text.replace(/\w\S*/g, function(txt) {
        return txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase();
    });
}

function toMarkdownCode(text, lang) {
    if (!text) return "";
    const l = lang || "";
    return "```" + l + "\n" + text + "\n```";
}

function toJsonString(text) {
    if (!text) return '""';
    return JSON.stringify(text);
}

function countWords(text) {
    if (!text || text.trim().length === 0) return 0;
    const matches = text.trim().match(/\S+/g);
    return matches ? matches.length : 0;
}

function countChars(text) {
    if (!text) return 0;
    return text.length;
}

function countLines(text) {
    if (!text || text.length === 0) return 0;
    return text.split(/\r?\n/).length;
}

function snippet(text, maxLen) {
    if (!text) return "";
    const clean = toSingleLine(text);
    const limit = maxLen || 60;
    if (clean.length <= limit) return clean;
    return clean.substring(0, limit) + "...";
}

function formatText(formatType, text) {
    if (!text) return "";
    switch (formatType) {
        case "RAW":
            return text;
        case "SINGLE_LINE":
            return toSingleLine(text);
        case "MARKDOWN":
            return toMarkdownCode(text);
        case "UPPERCASE":
            return toUppercase(text);
        case "LOWERCASE":
            return toLowercase(text);
        case "TITLECASE":
            return toTitleCase(text);
        case "JSON":
            return toJsonString(text);
        default:
            return text;
    }
}
