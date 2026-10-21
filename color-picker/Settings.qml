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

    title: Tr.tr("Color Picker")
    isSubPage: true

    readonly property ColorService service: ColorService

    readonly property list<MenuItem> behaviorItems: [
        MenuItem { text: Tr.tr("Open editor"); value: "editor" },
        MenuItem { text: Tr.tr("Pick a color and open editor"); value: "pick_and_editor" },
        MenuItem { text: Tr.tr("Pick a color only"); value: "pick_only" }
    ]

    readonly property list<MenuItem> formatItems: [
        MenuItem { text: "HEX"; value: "HEX" },
        MenuItem { text: "HEX (no #)"; value: "HEX (no #)" },
        MenuItem { text: "RGB"; value: "RGB" },
        MenuItem { text: "HSL"; value: "HSL" },
        MenuItem { text: "HSV"; value: "HSV" },
        MenuItem { text: "CMYK"; value: "CMYK" }
    ]

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.medium

        // ==========================================
        // 1. Top Card: Enable Color Picker
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
                    implicitWidth: enablePipetteIcon.implicitWidth + Tokens.padding.small * 2
                    implicitHeight: implicitWidth
                    radius: Tokens.rounding.small
                    color: Colours.palette.m3primary

                    MaterialIcon {
                        id: enablePipetteIcon
                        anchors.centerIn: parent
                        text: "colorize"
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
                            text: Tr.tr("Enable Color Picker")
                            font: Tokens.font.body.medium
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: root.service.pluginEnabled ? Tr.tr("Color picker is active and ready") : Tr.tr("Color picker is disabled")
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
                        PluginManager.togglePlugin("caelestia-color-picker", checked);
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

        // Row 1: Activation shortcut
        ConnectedRect {
            first: true
            Layout.fillWidth: true
            implicitHeight: shortcutRowLayout.implicitHeight + Tokens.padding.medium * 2

            RowLayout {
                id: shortcutRowLayout
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
                            text: Tr.tr("Customize the shortcut to activate this module")
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
                        type: IconButton.Text
                        font: Tokens.font.icon.small
                        onClicked: {
                            root.service.copyText(root.service.activationShortcut, "Shortcut");
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

            onSelected: item => {
                if (item && item.value) {
                    root.service.activationBehavior = item.value;
                    root.service.openEditorOnPick = (item.value !== "pick_only");
                    root.service.saveSettings();
                }
            }
        }

        // ==========================================
        // 3. Section: Picker behavior
        // ==========================================
        SectionHeader {
            text: Tr.tr("Picker behavior")
        }

        // Row 1: Default color format
        SelectRow {
            first: true
            label: Tr.tr("Default color format")
            subtext: Tr.tr("This format will be copied to your clipboard")
            menuItems: root.formatItems
            active: root.formatItems.find(i => i.value === root.service.defaultFormat) ?? root.formatItems[0]

            onSelected: item => {
                if (item && item.value) {
                    root.service.defaultFormat = item.value;
                    root.service.saveSettings();
                }
            }
        }

        // Row 2: Show color name
        ToggleRow {
            last: true
            text: Tr.tr("Show color name")
            subtext: Tr.tr("This will show the name of the color when picking a color")
            checked: root.service.showColorName
            onToggled: {
                root.service.showColorName = checked;
                root.service.saveSettings();
            }
        }

        // ==========================================
        // 4. Section: Color formats
        // ==========================================
        SectionHeader {
            text: Tr.tr("Color formats")
        }

        // Formats Header Card with "Add new format"
        ConnectedRect {
            first: true
            Layout.fillWidth: true
            implicitHeight: formatsHeaderRow.implicitHeight + Tokens.padding.medium * 2

            RowLayout {
                id: formatsHeaderRow
                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.medium

                MaterialIcon {
                    text: "format_list_bulleted"
                    color: Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.small
                }

                Item {
                    Layout.fillWidth: true
                    implicitHeight: formatsHeaderCol.implicitHeight

                    ColumnLayout {
                        id: formatsHeaderCol
                        anchors.fill: parent
                        spacing: 0

                        StyledText {
                            Layout.fillWidth: true
                            text: Tr.tr("Color formats")
                            font: Tokens.font.body.small
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: Tr.tr("Configure the color formats (edit, delete, hide, reorder them)")
                            color: Colours.palette.m3outline
                            font: Tokens.font.label.small
                        }
                    }
                }

                IconTextButton {
                    text: Tr.tr("Add new format")
                    icon: "add"
                    type: ButtonBase.Tonal
                    onClicked: {
                        root.service.copyText("rgba(%r, %g, %b, 1.0)", "Format Template");
                    }
                }
            }
        }

        // Format Rows (Dynamically bound to formatItems with dynamic 'last' connector)
        Repeater {
            id: fmtRepeater
            model: root.formatItems

            delegate: ConnectedRect {
                id: fmtRow
                required property var modelData
                required property int index

                last: index === fmtRepeater.count - 1
                Layout.fillWidth: true
                implicitHeight: fmtRowLayout.implicitHeight + Tokens.padding.medium * 2

                RowLayout {
                    id: fmtRowLayout
                    anchors.fill: parent
                    anchors.margins: Tokens.padding.medium
                    anchors.leftMargin: Tokens.padding.largeIncreased
                    anchors.rightMargin: Tokens.padding.largeIncreased
                    spacing: Tokens.spacing.medium

                    Item {
                        Layout.fillWidth: true
                        implicitHeight: fmtCol.implicitHeight

                        ColumnLayout {
                            id: fmtCol
                            anchors.fill: parent
                            spacing: Tokens.spacing.extraSmall / 2

                            StyledText {
                                Layout.fillWidth: true
                                text: fmtRow.modelData.value
                                font: Tokens.font.body.small
                                elide: Text.ElideRight
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: root.service.formatValue(fmtRow.modelData.value, root.service.currentColor)
                                color: Colours.palette.m3outline
                                font: Tokens.font.mono.small
                                elide: Text.ElideRight
                            }
                        }
                    }

                    IconButton {
                        icon: "more_horiz"
                        type: IconButton.Text
                        font: Tokens.font.icon.small
                        Layout.alignment: Qt.AlignVCenter
                        onClicked: {
                            root.service.copyFormatted(fmtRow.modelData.value);
                        }
                    }

                    StyledSwitch {
                        checked: root.service.enabledFormats[fmtRow.modelData.value] ?? true
                        Layout.alignment: Qt.AlignVCenter
                        onToggled: {
                            root.service.toggleFormatEnabled(fmtRow.modelData.value, checked);
                        }
                    }
                }
            }
        }

        // ==========================================
        // 5. Section: Hyprpicker Lens
        // ==========================================
        SectionHeader {
            text: Tr.tr("Hyprpicker Lens")
        }

        ToggleRow {
            first: true
            text: Tr.tr("Magnifying zoom lens")
            subtext: Tr.tr("Shows a magnified circular pixel preview around the cursor")
            checked: root.service.zoomLens
            onToggled: {
                root.service.zoomLens = checked;
                root.service.saveSettings();
            }
        }

        StepperRow {
            label: Tr.tr("Zoom Scale")
            subtext: Tr.tr("Magnifier factor (%1x)").arg(Math.round(root.service.zoomScale))
            value: root.service.zoomScale
            from: 1
            to: 10
            stepSize: 1
            onMoved: val => {
                root.service.zoomScale = Math.round(val);
                root.service.saveSettings();
            }
        }

        StepperRow {
            last: true
            label: Tr.tr("Circle Radius")
            subtext: Tr.tr("Pixel preview circle radius (%1 px)").arg(Math.round(root.service.circleRadius))
            value: root.service.circleRadius
            from: 10
            to: 100
            stepSize: 5
            onMoved: val => {
                root.service.circleRadius = Math.round(val);
                root.service.saveSettings();
            }
        }

        // ==========================================
        // 6. Section: History
        // ==========================================
        SectionHeader {
            text: Tr.tr("History")
        }

        StepperRow {
            first: true
            label: Tr.tr("Maximum History Items")
            subtext: Tr.tr("Max recent colors stored")
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
            text: Tr.tr("Clear Color History")
            subtext: Tr.tr("%1 color(s) stored in history").arg(root.service.history.length)
            onClicked: root.service.clearHistory()
        }

        // ==========================================
        // 7. Section: Live Color Inspector
        // ==========================================
        SectionHeader {
            text: Tr.tr("Live Color Inspector")
        }

        ColorEditorCard {
            Layout.fillWidth: true
            colorService: root.service
            showCloseButton: false
        }
    }
}
