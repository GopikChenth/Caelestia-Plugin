pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus
import qs.modules.nexus.common
import qs.utils

import "."

PageBase {
    id: root

    title: Tr.tr("Text Extractor")
    isSubPage: true

    readonly property TextService service: TextService

    property bool isCustomizingShortcut: false
    property string editedShortcut: root.service.activationShortcut

    readonly property list<MenuItem> behaviorItems: [
        MenuItem { text: Tr.tr("Extract text and open window"); value: "extract_and_window" },
        MenuItem { text: Tr.tr("Extract text only"); value: "extract_only" },
        MenuItem { text: Tr.tr("Open window only"); value: "window_only" }
    ]

    readonly property list<MenuItem> langItems: [
        MenuItem { text: Tr.tr("English (eng)"); value: "eng" },
        MenuItem { text: Tr.tr("Spanish (spa)"); value: "spa" },
        MenuItem { text: Tr.tr("French (fra)"); value: "fra" },
        MenuItem { text: Tr.tr("German (deu)"); value: "deu" },
        MenuItem { text: Tr.tr("Italian (ita)"); value: "ita" },
        MenuItem { text: Tr.tr("Japanese (jpn)"); value: "jpn" },
        MenuItem { text: Tr.tr("Chinese Simplified (chi_sim)"); value: "chi_sim" }
    ]

    readonly property list<MenuItem> psmItems: [
        MenuItem { text: Tr.tr("Automatic (PSM 3)"); value: 3 },
        MenuItem { text: Tr.tr("Single text block (PSM 6)"); value: 6 },
        MenuItem { text: Tr.tr("Single line (PSM 7)"); value: 7 },
        MenuItem { text: Tr.tr("Auto with OSD (PSM 1)"); value: 1 }
    ]

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.medium

        // ==========================================
        // 1. Top Card: Enable Text Extractor
        // ==========================================
        ConnectedRect {
            first: true
            last: true
            Layout.fillWidth: true
            implicitHeight: enableRowLayout.implicitHeight + Tokens.padding.medium * 2

            RowLayout {
                id: enableRowLayout
                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.medium

                Rectangle {
                    implicitWidth: enableIcon.implicitWidth + Tokens.padding.small * 2
                    implicitHeight: implicitWidth
                    radius: Tokens.rounding.small
                    color: Colours.palette.m3primary

                    MaterialIcon {
                        id: enableIcon
                        anchors.centerIn: parent
                        text: "document_scanner"
                        color: Colours.palette.m3onPrimary
                        fontStyle: Tokens.font.icon.small
                    }
                }

                Item {
                    Layout.fillWidth: true
                    implicitHeight: enableCol.implicitHeight

                    ColumnLayout {
                        id: enableCol
                        anchors.fill: parent
                        spacing: 0

                        StyledText {
                            Layout.fillWidth: true
                            text: Tr.tr("Enable Text Extractor")
                            font: Tokens.font.body.medium
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: root.service.pluginEnabled ? Tr.tr("Text Extractor is active and ready") : Tr.tr("Text Extractor is disabled")
                            color: Colours.palette.m3outline
                            font: Tokens.font.label.small
                        }
                    }
                }

                StyledText {
                    text: root.service.pluginEnabled ? Tr.tr("On") : Tr.tr("Off")
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.small
                }

                StyledSwitch {
                    checked: root.service.pluginEnabled
                    onToggled: {
                        root.service.pluginEnabled = checked;
                        root.service.saveSettings();
                        PluginManager.togglePlugin("caelestia-text-extractor", checked);
                    }
                }
            }
        }

        // ==========================================
        // 2. Section: Shortcut
        // ==========================================
        SectionHeader {
            text: Tr.tr("Shortcut")
        }

        // Row 1: Activation shortcut (Customizable)
        ConnectedRect {
            first: true
            Layout.fillWidth: true
            implicitHeight: (root.isCustomizingShortcut ? editShortcutLayout.implicitHeight : shortcutRowLayout.implicitHeight) + Tokens.padding.medium * 2

            // Normal Display View
            RowLayout {
                id: shortcutRowLayout
                visible: !root.isCustomizingShortcut
                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.medium

                MaterialIcon {
                    text: "keyboard"
                    color: Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.small
                }

                Item {
                    Layout.fillWidth: true
                    implicitHeight: shortcutCol.implicitHeight

                    ColumnLayout {
                        id: shortcutCol
                        anchors.fill: parent
                        spacing: 0

                        StyledText {
                            Layout.fillWidth: true
                            text: Tr.tr("Activation shortcut")
                            font: Tokens.font.body.small
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: Tr.tr("Customizable shortcut to trigger screen capture and OCR")
                            color: Colours.palette.m3outline
                            font: Tokens.font.label.small
                        }
                    }
                }

                // Dynamic Keycaps Display
                RowLayout {
                    spacing: Tokens.spacing.extraSmall

                    component KeyBadge: Rectangle {
                        id: badge
                        property string text
                        property string icon
                        property bool isIcon: false

                        implicitWidth: Math.max(
                            badgeContent.implicitHeight,
                            badgeContent.implicitWidth + Tokens.padding.medium * 2
                        )
                        implicitHeight: badgeContent.implicitHeight + Tokens.padding.extraSmall * 2
                        radius: Tokens.rounding.extraSmall
                        color: Colours.palette.m3primary
                        border.color: Colours.layer(Colours.palette.m3onPrimary, 2)
                        border.width: 1

                        Item {
                            id: badgeContent
                            anchors.centerIn: parent
                            implicitWidth: badge.isIcon ? badgeIcon.implicitWidth : badgeLabel.implicitWidth
                            implicitHeight: badge.isIcon ? badgeIcon.implicitHeight : badgeLabel.implicitHeight

                            MaterialIcon {
                                id: badgeIcon
                                visible: badge.isIcon
                                anchors.centerIn: parent
                                text: badge.icon
                                color: Colours.palette.m3onPrimary
                                fontStyle: Tokens.font.icon.small
                            }

                            StyledText {
                                id: badgeLabel
                                visible: !badge.isIcon
                                anchors.centerIn: parent
                                text: badge.text
                                color: Colours.palette.m3onPrimary
                                font: Tokens.font.body.small
                            }
                        }
                    }

                    Repeater {
                        model: root.service.activationShortcut.split("+").map(s => s.trim()).filter(s => s.length > 0)

                        delegate: KeyBadge {
                            required property string modelData
                            required property int index

                            readonly property bool isSuperKey: modelData.toUpperCase() === "SUPER" || modelData.toUpperCase() === "WIN" || modelData.toUpperCase() === "MOD4"
                            isIcon: isSuperKey
                            icon: isSuperKey ? "grid_view" : ""
                            text: isSuperKey ? "" : (modelData.charAt(0).toUpperCase() + modelData.slice(1).toLowerCase())
                        }
                    }

                    IconButton {
                        icon: "edit"
                        type: IconButton.Tonal
                        font: Tokens.font.icon.small
                        onClicked: {
                            root.editedShortcut = root.service.activationShortcut;
                            root.isCustomizingShortcut = true;
                        }
                    }
                }
            }

            // Inline Customization View
            ColumnLayout {
                id: editShortcutLayout
                visible: root.isCustomizingShortcut
                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.small

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.medium

                    MaterialIcon {
                        text: "tune"
                        color: Colours.palette.m3primary
                        fontStyle: Tokens.font.icon.small
                    }

                    StyledText {
                        text: Tr.tr("Customize Activation Shortcut")
                        font: Tokens.font.body.small
                        color: Colours.palette.m3onSurface
                        Layout.fillWidth: true
                    }

                    // Preset buttons
                    RowLayout {
                        spacing: Tokens.spacing.extraSmall

                        component ShortcutChip: Rectangle {
                            id: scChip
                            required property string shortcutValue
                            required property string chipText

                            implicitWidth: chipLabel.implicitWidth + Tokens.padding.small * 2
                            implicitHeight: chipLabel.implicitHeight + Tokens.padding.extraSmall * 2
                            radius: Tokens.rounding.extraSmall
                            color: root.editedShortcut.toUpperCase() === scChip.shortcutValue.toUpperCase() ? Colours.palette.m3primary : Colours.palette.m3surfaceContainerHigh
                            border.color: Colours.palette.m3outlineVariant
                            border.width: 1

                            StyledText {
                                id: chipLabel
                                anchors.centerIn: parent
                                text: scChip.chipText
                                font: Tokens.font.label.small
                                color: root.editedShortcut.toUpperCase() === scChip.shortcutValue.toUpperCase() ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.editedShortcut = scChip.shortcutValue;
                                }
                            }
                        }

                        ShortcutChip {
                            shortcutValue: "SHIFT + SUPER + T"
                            chipText: "Shift+Super+T"
                        }

                        ShortcutChip {
                            shortcutValue: "SUPER + SHIFT + T"
                            chipText: "Super+Shift+T"
                        }

                        ShortcutChip {
                            shortcutValue: "SUPER + T"
                            chipText: "Super+T"
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small

                    // Input Box
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: scInput.implicitHeight + Tokens.padding.small * 2
                        radius: Tokens.rounding.small
                        color: Colours.palette.m3surfaceContainerLowest
                        border.color: Colours.palette.m3primary
                        border.width: 1

                        TextInput {
                            id: scInput
                            anchors.fill: parent
                            anchors.leftMargin: Tokens.padding.medium
                            anchors.rightMargin: Tokens.padding.medium
                            verticalAlignment: Text.AlignVCenter
                            font: Tokens.font.mono.small
                            color: Colours.palette.m3onSurface
                            text: root.editedShortcut
                            selectByMouse: true
                            onTextChanged: {
                                root.editedShortcut = text;
                            }
                            onAccepted: {
                                if (root.editedShortcut.trim().length > 0) {
                                    root.service.activationShortcut = root.editedShortcut.trim().toUpperCase();
                                    root.service.saveSettings();
                                    root.isCustomizingShortcut = false;
                                }
                            }
                        }
                    }

                    // Save Button
                    IconTextButton {
                        text: Tr.tr("Save")
                        icon: "check"
                        type: ButtonBase.Filled
                        onClicked: {
                            if (root.editedShortcut.trim().length > 0) {
                                root.service.activationShortcut = root.editedShortcut.trim().toUpperCase();
                                root.service.saveSettings();
                                root.isCustomizingShortcut = false;
                            }
                        }
                    }

                    // Cancel Button
                    IconButton {
                        icon: "close"
                        type: IconButton.Tonal
                        onClicked: {
                            root.isCustomizingShortcut = false;
                        }
                    }
                }
            }
        }

        // Row 2: Activation behavior
        SelectRow {
            last: true
            label: Tr.tr("Activation behavior")
            subtext: Tr.tr("Action triggered when activation shortcut is pressed")
            menuItems: root.behaviorItems
            active: root.behaviorItems.find(i => i.value === root.service.activationBehavior) ?? root.behaviorItems[0]
            fallbackText: active ? active.text : Tr.tr("Extract text and open window")

            onSelected: item => {
                if (item && item.value) {
                    root.service.activationBehavior = item.value;
                    if (item.value === "extract_only") {
                        root.service.autoCopy = true;
                        root.service.openWindowOnExtract = false;
                    } else if (item.value === "extract_and_window") {
                        root.service.openWindowOnExtract = true;
                    }
                    root.service.saveSettings();
                }
            }
        }

        // ==========================================
        // 3. Section: OCR Engine Settings
        // ==========================================
        SectionHeader {
            text: Tr.tr("OCR Engine Settings")
        }

        // Language Select
        SelectRow {
            first: true
            label: Tr.tr("Recognition language")
            subtext: Tr.tr("Tesseract OCR trained dataset to use")
            menuItems: root.langItems
            active: root.langItems.find(i => i.value === root.service.ocrLanguage) ?? root.langItems[0]
            fallbackText: active ? active.text : Tr.tr("English (eng)")

            onSelected: item => {
                if (item && item.value) {
                    root.service.ocrLanguage = item.value;
                    root.service.saveSettings();
                }
            }
        }

        // Page Segmentation Mode (PSM)
        SelectRow {
            label: Tr.tr("Segmentation mode (PSM)")
            subtext: Tr.tr("Layout analysis method for the captured image")
            menuItems: root.psmItems
            active: root.psmItems.find(i => i.value === root.service.psmMode) ?? root.psmItems[0]
            fallbackText: active ? active.text : Tr.tr("Automatic (PSM 3)")

            onSelected: item => {
                if (item && item.value !== undefined) {
                    root.service.psmMode = item.value;
                    root.service.saveSettings();
                }
            }
        }

        // Single-line Mode
        ToggleRow {
            text: Tr.tr("Single-line output")
            subtext: Tr.tr("Strip line breaks into single continuous space-separated text")
            checked: root.service.singleLineMode
            onToggled: {
                root.service.singleLineMode = checked;
                root.service.saveSettings();
            }
        }

        // Auto-Copy
        ToggleRow {
            text: Tr.tr("Copy automatically to clipboard")
            subtext: Tr.tr("Automatically place extracted text onto Wayland clipboard")
            checked: root.service.autoCopy
            onToggled: {
                root.service.autoCopy = checked;
                root.service.saveSettings();
            }
        }

        // Send Notification
        ToggleRow {
            text: Tr.tr("Desktop notifications")
            subtext: Tr.tr("Show toast preview upon completing text recognition")
            checked: root.service.sendNotification
            onToggled: {
                root.service.sendNotification = checked;
                root.service.saveSettings();
            }
        }

        // Open Window on Extract
        ToggleRow {
            last: true
            text: Tr.tr("Open inspector window after extraction")
            subtext: Tr.tr("Automatically open the floating text inspector after selecting an area")
            checked: root.service.openWindowOnExtract
            onToggled: {
                root.service.openWindowOnExtract = checked;
                root.service.saveSettings();
            }
        }

        // ==========================================
        // 4. Section: History
        // ==========================================
        SectionHeader {
            text: Tr.tr("History")
        }

        StepperRow {
            first: true
            label: Tr.tr("Maximum History Items")
            subtext: Tr.tr("Number of recent OCR clips stored")
            value: root.service.maxHistory
            from: 5
            to: 50
            stepSize: 5
            onMoved: val => {
                root.service.maxHistory = Math.round(val);
                root.service.saveSettings();
            }
        }

        RowButton {
            last: true
            icon: "delete"
            text: Tr.tr("Clear Extraction History")
            subtext: Tr.tr("%1 text clip(s) stored in history").arg(root.service.history.length)
            onClicked: root.service.clearHistory()
        }

        // ==========================================
        // 5. Section: Live Text Inspector
        // ==========================================
        SectionHeader {
            text: Tr.tr("Live Text Inspector")
        }

        TextExtractorCard {
            Layout.fillWidth: true
            textService: root.service
            showCloseButton: false
        }
    }
}
