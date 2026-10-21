pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

import "TextUtils.js" as TextUtils

Rectangle {
    id: root

    property var textService: TextService
    property bool showCloseButton: false
    signal closeClicked

    // Dynamic Caelestia colors with safe fallbacks
    readonly property color bgSurface: typeof Colours !== "undefined" ? Colours.layer(Colours.palette.m3surfaceContainer, 1) : "#1E1E2E"
    readonly property color bgCard: typeof Colours !== "undefined" ? Colours.palette.m3surfaceContainerHigh : "#28283D"
    readonly property color bgCardInput: typeof Colours !== "undefined" ? Colours.palette.m3surfaceContainerLowest : "#181825"
    readonly property color textPrimary: typeof Colours !== "undefined" ? Colours.palette.m3onSurface : "#CDD6F4"
    readonly property color textSecondary: typeof Colours !== "undefined" ? Colours.palette.m3onSurfaceVariant : "#A6ADC8"
    readonly property color accentColor: typeof Colours !== "undefined" ? Colours.palette.m3primary : "#89B4FA"
    readonly property color outlineColor: typeof Colours !== "undefined" ? Colours.palette.m3outlineVariant : "#45475A"

    readonly property int radiusLarge: typeof Tokens !== "undefined" ? Tokens.rounding.large : 16
    readonly property int radiusMedium: typeof Tokens !== "undefined" ? Tokens.rounding.medium : 12
    readonly property int radiusSmall: typeof Tokens !== "undefined" ? Tokens.rounding.small : 8
    readonly property int radiusExtraSmall: typeof Tokens !== "undefined" ? Tokens.rounding.extraSmall : 4
    readonly property int radiusFull: typeof Tokens !== "undefined" ? Tokens.rounding.full : 9999

    readonly property int paddingLarge: typeof Tokens !== "undefined" ? Tokens.padding.large : 16
    readonly property int paddingMedium: typeof Tokens !== "undefined" ? Tokens.padding.medium : 12
    readonly property int paddingSmall: typeof Tokens !== "undefined" ? Tokens.padding.small : 8
    readonly property int paddingExtraSmall: typeof Tokens !== "undefined" ? Tokens.padding.extraSmall : 4

    readonly property int spacingMedium: typeof Tokens !== "undefined" ? Tokens.spacing.medium : 12
    readonly property int spacingSmall: typeof Tokens !== "undefined" ? Tokens.spacing.small : 8
    readonly property int spacingExtraSmall: typeof Tokens !== "undefined" ? Tokens.spacing.extraSmall : 4

    readonly property font fontTitleLarge: typeof Tokens !== "undefined" ? Tokens.font.title.large : Qt.font({ pixelSize: 18, bold: true })
    readonly property font fontTitleSmall: typeof Tokens !== "undefined" ? Tokens.font.title.small : Qt.font({ pixelSize: 14, bold: true })
    readonly property font fontBodyMedium: typeof Tokens !== "undefined" ? Tokens.font.body.medium : Qt.font({ pixelSize: 12 })
    readonly property font fontBodySmall: typeof Tokens !== "undefined" ? Tokens.font.body.small : Qt.font({ pixelSize: 11 })
    readonly property font fontLabelSmall: typeof Tokens !== "undefined" ? Tokens.font.label.small : Qt.font({ pixelSize: 10, bold: true })
    readonly property font fontMonoMedium: typeof Tokens !== "undefined" ? Tokens.font.mono.medium : Qt.font({ family: "monospace", pixelSize: 12 })
    readonly property font fontMonoSmall: typeof Tokens !== "undefined" ? Tokens.font.mono.small : Qt.font({ family: "monospace", pixelSize: 11 })

    property bool adjustExpanded: false
    property string copiedFormat: ""

    color: bgSurface
    radius: radiusLarge
    border.color: outlineColor
    border.width: 1

    implicitWidth: typeof Tokens !== "undefined" ? Math.min(Tokens.sizes.nexus.minWidth, 460) : 420
    implicitHeight: mainLayout.implicitHeight + paddingLarge * 2

    Timer {
        id: copyFeedbackTimer
        interval: 1500
        onTriggered: root.copiedFormat = ""
    }

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.margins: root.paddingLarge
        spacing: root.spacingMedium

        // Header: Title, Extract Button, and Optional Close
        RowLayout {
            Layout.fillWidth: true
            spacing: root.spacingSmall

            Rectangle {
                implicitWidth: headerIcon.implicitWidth + root.paddingSmall * 2
                implicitHeight: implicitWidth
                radius: root.radiusFull
                color: root.accentColor

                MaterialIcon {
                    id: headerIcon
                    anchors.centerIn: parent
                    text: "document_scanner"
                    color: typeof Colours !== "undefined" ? Colours.palette.m3onPrimary : root.bgSurface
                    fontStyle: Tokens.font.icon.small
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    text: "Text Extractor"
                    font: root.fontTitleSmall
                    color: root.textPrimary
                }

                StyledText {
                    text: root.textService?.isExtracting ? "Extracting from screen..." : "Ready to capture"
                    font: root.fontLabelSmall
                    color: root.textService?.isExtracting ? root.accentColor : root.textSecondary
                }
            }

            // Quick "Extract Now" button
            Rectangle {
                implicitWidth: extractBtnRow.implicitWidth + root.paddingMedium * 2
                implicitHeight: extractBtnRow.implicitHeight + root.paddingSmall * 2
                radius: root.radiusFull
                color: extractMouse.containsMouse ? (extractMouse.pressed ? root.accentColor : root.bgCard) : "transparent"
                border.color: root.accentColor
                border.width: 1

                RowLayout {
                    id: extractBtnRow
                    anchors.centerIn: parent
                    spacing: root.spacingExtraSmall

                    MaterialIcon {
                        text: root.textService?.isExtracting ? "hourglass_empty" : "crop_free"
                        fontStyle: Tokens.font.icon.small
                        color: root.accentColor
                    }

                    StyledText {
                        text: root.textService?.isExtracting ? "Selecting..." : "Extract New"
                        font: root.fontBodySmall
                        color: root.accentColor
                    }
                }

                MouseArea {
                    id: extractMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.textService.extractText()
                }
            }

            // Optional Close Button
            IconButton {
                visible: root.showCloseButton
                icon: "close"
                type: IconButton.Text
                font: Tokens.font.icon.small
                onClicked: root.closeClicked()
            }
        }

        // Hero Extracted Text Card & Editor
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: Math.max(160, textAreaLayout.implicitHeight + root.paddingMedium * 2)
            radius: root.radiusMedium
            color: root.bgCardInput
            border.color: root.outlineColor
            border.width: 1

            ColumnLayout {
                id: textAreaLayout
                anchors.fill: parent
                anchors.margins: root.paddingMedium
                spacing: root.spacingSmall

                // Sub-header inside Card: Stats & Quick Actions
                RowLayout {
                    Layout.fillWidth: true
                    spacing: root.spacingSmall

                    MaterialIcon {
                        text: "description"
                        fontStyle: Tokens.font.icon.small
                        color: root.textSecondary
                    }

                    StyledText {
                        text: {
                            const txt = editArea.text;
                            const chars = TextUtils.countChars(txt);
                            const words = TextUtils.countWords(txt);
                            const lines = TextUtils.countLines(txt);
                            return `${chars} chars • ${words} words • ${lines} line${lines === 1 ? '' : 's'}`;
                        }
                        font: root.fontLabelSmall
                        color: root.textSecondary
                        Layout.fillWidth: true
                    }

                    // Copy Primary button in Hero
                    Rectangle {
                        implicitWidth: heroCopyRow.implicitWidth + root.paddingSmall * 2
                        implicitHeight: heroCopyRow.implicitHeight + root.paddingExtraSmall * 2
                        radius: root.radiusSmall
                        color: heroCopyMouse.containsMouse ? Colours.layer(Colours.palette.m3primary, 2) : root.accentColor

                        RowLayout {
                            id: heroCopyRow
                            anchors.centerIn: parent
                            spacing: root.spacingExtraSmall

                            MaterialIcon {
                                text: root.copiedFormat === "HERO" ? "check" : "content_copy"
                                fontStyle: Tokens.font.icon.small
                                color: typeof Colours !== "undefined" ? Colours.palette.m3onPrimary : "#FFFFFF"
                            }

                            StyledText {
                                text: root.copiedFormat === "HERO" ? "Copied!" : "Copy"
                                font: root.fontBodySmall
                                color: typeof Colours !== "undefined" ? Colours.palette.m3onPrimary : "#FFFFFF"
                            }
                        }

                        MouseArea {
                            id: heroCopyMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.textService.copyText(editArea.text, "Text");
                                root.copiedFormat = "HERO";
                                copyFeedbackTimer.restart();
                            }
                        }
                    }
                }

                // Scrollable & Editable Text View
                Flickable {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 110
                    Layout.maximumHeight: 180
                    contentWidth: width
                    contentHeight: editArea.paintedHeight + 10
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    TextArea {
                        id: editArea
                        width: parent.width
                        wrapMode: TextEdit.Wrap
                        selectByMouse: true
                        color: root.textPrimary
                        font: root.fontMonoSmall
                        background: null
                        padding: 0
                        text: root.textService?.currentText ?? ""
                        onTextChanged: {
                            if (root.textService && text !== root.textService.currentText) {
                                root.textService.currentText = text;
                            }
                        }
                    }

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                    }
                }
            }
        }

        // Format Copiers Row (PowerToys Quick Formats)
        ColumnLayout {
            Layout.fillWidth: true
            spacing: root.spacingExtraSmall

            StyledText {
                text: "Copy in Format"
                font: root.fontLabelSmall
                color: root.textSecondary
            }

            Flow {
                Layout.fillWidth: true
                spacing: root.spacingSmall

                component FormatChip: Rectangle {
                    id: chip
                    required property string formatKey
                    required property string label
                    required property string iconName

                    implicitWidth: chipRow.implicitWidth + root.paddingMedium * 2
                    implicitHeight: chipRow.implicitHeight + root.paddingSmall * 2
                    radius: root.radiusSmall
                    color: root.copiedFormat === chip.formatKey ? root.accentColor : (chipMouse.containsMouse ? root.bgCard : "transparent")
                    border.color: root.copiedFormat === chip.formatKey ? root.accentColor : root.outlineColor
                    border.width: 1

                    RowLayout {
                        id: chipRow
                        anchors.centerIn: parent
                        spacing: root.spacingExtraSmall

                        MaterialIcon {
                            text: root.copiedFormat === chip.formatKey ? "check" : chip.iconName
                            fontStyle: Tokens.font.icon.small
                            color: root.copiedFormat === chip.formatKey ? (typeof Colours !== "undefined" ? Colours.palette.m3onPrimary : "#FFFFFF") : root.accentColor
                        }

                        StyledText {
                            text: root.copiedFormat === chip.formatKey ? "Copied!" : chip.label
                            font: root.fontBodySmall
                            color: root.copiedFormat === chip.formatKey ? (typeof Colours !== "undefined" ? Colours.palette.m3onPrimary : "#FFFFFF") : root.textPrimary
                        }
                    }

                    MouseArea {
                        id: chipMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.textService.copyFormatted(chip.formatKey);
                            root.copiedFormat = chip.formatKey;
                            copyFeedbackTimer.restart();
                        }
                    }
                }

                FormatChip {
                    formatKey: "RAW"
                    label: "Plain Text"
                    iconName: "notes"
                }

                FormatChip {
                    formatKey: "SINGLE_LINE"
                    label: "Single Line"
                    iconName: "format_align_left"
                }

                FormatChip {
                    formatKey: "MARKDOWN"
                    label: "Markdown"
                    iconName: "code"
                }

                FormatChip {
                    formatKey: "UPPERCASE"
                    label: "UPPERCASE"
                    iconName: "keyboard_capslock_badge"
                }

                FormatChip {
                    formatKey: "LOWERCASE"
                    label: "lowercase"
                    iconName: "text_format"
                }

                FormatChip {
                    formatKey: "JSON"
                    label: "JSON Escaped"
                    iconName: "data_object"
                }
            }
        }

        // Quick OCR Settings Accordion
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: adjustContent.implicitHeight + (root.adjustExpanded ? root.paddingLarge : root.paddingMedium)
            radius: root.radiusMedium
            color: root.bgCard
            border.color: root.outlineColor
            border.width: 1

            ColumnLayout {
                id: adjustContent
                anchors.fill: parent
                anchors.margins: root.paddingMedium
                spacing: root.spacingMedium

                // Accordion header
                Item {
                    Layout.fillWidth: true
                    implicitHeight: headerRow.implicitHeight

                    RowLayout {
                        id: headerRow
                        anchors.fill: parent
                        spacing: root.spacingSmall

                        MaterialIcon {
                            text: "tune"
                            fontStyle: Tokens.font.icon.small
                            color: root.accentColor
                        }

                        StyledText {
                            text: "Quick OCR Settings"
                            font: root.fontBodySmall
                            color: root.textPrimary
                            Layout.fillWidth: true
                        }

                        StyledText {
                            text: `Lang: ${root.textService?.ocrLanguage.toUpperCase()} • PSM: ${root.textService?.psmMode}`
                            font: root.fontLabelSmall
                            color: root.textSecondary
                        }

                        MaterialIcon {
                            text: root.adjustExpanded ? "expand_less" : "expand_more"
                            fontStyle: Tokens.font.icon.small
                            color: root.textSecondary
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.adjustExpanded = !root.adjustExpanded
                    }
                }

                // Expanded OCR Controls
                ColumnLayout {
                    visible: root.adjustExpanded
                    Layout.fillWidth: true
                    spacing: root.spacingSmall

                    // Language Chips
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: root.spacingExtraSmall / 2

                        StyledText {
                            text: "Recognition Language"
                            font: root.fontLabelSmall
                            color: root.textSecondary
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: root.spacingExtraSmall

                            Repeater {
                                model: [
                                    { id: "eng", label: "English" },
                                    { id: "fra", label: "French" },
                                    { id: "deu", label: "German" },
                                    { id: "spa", label: "Spanish" },
                                    { id: "jpn", label: "Japanese" }
                                ]

                                delegate: Rectangle {
                                    required property var modelData

                                    implicitWidth: langLabel.implicitWidth + root.paddingMedium * 2
                                    implicitHeight: langLabel.implicitHeight + root.paddingSmall * 2
                                    radius: root.radiusSmall
                                    color: root.textService?.ocrLanguage === modelData.id ? root.accentColor : root.bgSurface
                                    border.color: root.textService?.ocrLanguage === modelData.id ? root.accentColor : root.outlineColor
                                    border.width: 1

                                    StyledText {
                                        id: langLabel
                                        anchors.centerIn: parent
                                        text: parent.modelData.label
                                        font: root.fontBodySmall
                                        color: root.textService?.ocrLanguage === parent.modelData.id ? (typeof Colours !== "undefined" ? Colours.palette.m3onPrimary : "#FFFFFF") : root.textPrimary
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.textService.ocrLanguage = parent.modelData.id;
                                            root.textService.saveSettings();
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Single-line Toggle Row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: root.spacingSmall

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            StyledText {
                                text: "Single-line output mode"
                                font: root.fontBodySmall
                                color: root.textPrimary
                            }

                            StyledText {
                                text: "Remove newlines and condense spaces"
                                font: root.fontLabelSmall
                                color: root.textSecondary
                            }
                        }

                        StyledSwitch {
                            checked: root.textService?.singleLineMode ?? false
                            onToggled: {
                                root.textService.singleLineMode = checked;
                                root.textService.saveSettings();
                            }
                        }
                    }
                }
            }
        }

        // Recent Extraction History
        ColumnLayout {
            Layout.fillWidth: true
            spacing: root.spacingSmall

            RowLayout {
                Layout.fillWidth: true

                StyledText {
                    text: "Extraction History"
                    font: root.fontLabelSmall
                    color: root.textSecondary
                    Layout.fillWidth: true
                }

                StyledText {
                    visible: (root.textService?.history?.length ?? 0) > 0
                    text: "Clear All"
                    font: root.fontLabelSmall
                    color: root.accentColor

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.textService.clearHistory()
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: Math.min(180, historyListCol.implicitHeight + root.paddingSmall * 2)
                radius: root.radiusMedium
                color: root.bgCard
                border.color: root.outlineColor
                border.width: 1

                Flickable {
                    anchors.fill: parent
                    anchors.margins: root.paddingSmall
                    contentWidth: width
                    contentHeight: historyListCol.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    ColumnLayout {
                        id: historyListCol
                        width: parent.width
                        spacing: root.spacingExtraSmall

                        Repeater {
                            model: root.textService?.history ?? []

                            delegate: Rectangle {
                                required property var modelData
                                required property int index

                                Layout.fillWidth: true
                                implicitHeight: histRow.implicitHeight + root.paddingSmall * 2
                                radius: root.radiusSmall
                                color: histMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"

                                RowLayout {
                                    id: histRow
                                    anchors.fill: parent
                                    anchors.leftMargin: root.paddingSmall
                                    anchors.rightMargin: root.paddingSmall
                                    spacing: root.spacingSmall

                                    MaterialIcon {
                                        text: "history"
                                        fontStyle: Tokens.font.icon.small
                                        color: root.accentColor
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 1

                                        StyledText {
                                            text: modelData.snippet || ""
                                            font: root.fontBodySmall
                                            color: root.textPrimary
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                        }

                                        StyledText {
                                            text: `${modelData.timestamp || ""} • ${modelData.wordCount || 0} words`
                                            font: root.fontLabelSmall
                                            color: root.textSecondary
                                        }
                                    }

                                    IconButton {
                                        icon: "content_copy"
                                        type: IconButton.Text
                                        font: Tokens.font.icon.small
                                        onClicked: {
                                            root.textService.copyText(modelData.text, "History Clip");
                                        }
                                    }

                                    IconButton {
                                        icon: "delete"
                                        type: IconButton.Text
                                        font: Tokens.font.icon.small
                                        onClicked: {
                                            root.textService.removeHistoryItem(index);
                                        }
                                    }
                                }

                                MouseArea {
                                    id: histMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.textService.currentText = modelData.text;
                                    }
                                }
                            }
                        }

                        StyledText {
                            visible: !root.textService?.history || root.textService.history.length === 0
                            text: "No previous extractions yet"
                            font: root.fontBodySmall
                            color: root.textSecondary
                            leftPadding: root.paddingSmall
                        }
                    }

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                    }
                }
            }
        }
    }
}
