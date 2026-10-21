pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

import "ColorUtils.js" as ColorUtils

Rectangle {
    id: root

    property var colorService: ColorService
    property bool showCloseButton: false
    signal closeClicked

    // Dynamic Caelestia colours with safe fallbacks
    readonly property color bgSurface: typeof Colours !== "undefined" ? Colours.layer(Colours.palette.m3surfaceContainer, 1) : "#1E1E2E"
    readonly property color bgCard: typeof Colours !== "undefined" ? Colours.palette.m3surfaceContainerHigh : "#28283D"
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

    // Luminance-based contrast text color for swatches
    readonly property color heroTextColor: {
        const cur = root.activeColor;
        if (!cur) return "#FFFFFF";
        const lum = (cur.r * 0.299 + cur.g * 0.587 + cur.b * 0.114);
        return lum > 140 ? "#000000" : "#FFFFFF";
    }

    property bool adjustExpanded: false
    property string copiedFormat: ""
    property int selectedShadeIndex: 2

    // Dynamically resolved active inspected color based on current shade selection
    readonly property var activeColor: {
        const cur = root.colorService?.currentColor;
        if (!cur) return null;
        const shades = cur.shades;
        if (shades && shades.length > 0 && root.selectedShadeIndex >= 0 && root.selectedShadeIndex < shades.length) {
            const shade = shades[root.selectedShadeIndex];
            if (root.selectedShadeIndex === 2 || (shade && shade.hex.toLowerCase() === cur.hex.toLowerCase())) {
                return cur;
            }
            return ColorUtils.formatColor(shade.hex) || cur;
        }
        return cur;
    }

    Connections {
        target: root.colorService
        function onCurrentColorChanged() {
            root.selectedShadeIndex = 2;
        }
    }

    color: bgSurface
    radius: radiusMedium
    border.color: outlineColor
    border.width: 1

    implicitWidth: typeof Tokens !== "undefined" && Tokens.sizes?.nexus?.popupWidth ? Math.max(Tokens.sizes.nexus.popupWidth, 360) : 360
    implicitHeight: mainLayout.implicitHeight + paddingSmall * 2

    Timer {
        id: copyFeedbackTimer
        interval: 1500
        onTriggered: root.copiedFormat = ""
    }

    FontMetrics {
        id: formatFontMetrics
        font: root.fontLabelSmall
    }

    readonly property var activeFormatModels: [
        { name: "HEX", key: "HEX" },
        { name: "HEX (no #)", key: "HEX (no #)" },
        { name: "RGB", key: "RGB" },
        { name: "HSL", key: "HSL" },
        { name: "HSV", key: "HSV" },
        { name: "CMYK", key: "CMYK" }
    ]

    readonly property real maxFormatLabelWidth: {
        let maxW = 0;
        for (let i = 0; i < root.activeFormatModels.length; i++) {
            let w = formatFontMetrics.advanceWidth(root.activeFormatModels[i].name);
            if (w > maxW)
                maxW = w;
        }
        return Math.ceil(maxW);
    }

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.margins: root.paddingSmall
        spacing: root.spacingSmall

        // Header: Title, Pick Button & Optional Close
        RowLayout {
            Layout.fillWidth: true
            spacing: root.spacingSmall

            Rectangle {
                implicitWidth: headerPipetteIcon.implicitWidth + root.paddingExtraSmall * 2
                implicitHeight: implicitWidth
                radius: root.radiusFull
                color: root.accentColor

                MaterialIcon {
                    id: headerPipetteIcon
                    anchors.centerIn: parent
                    text: "colorize"
                    color: typeof Colours !== "undefined" ? Colours.palette.m3onPrimary : root.bgSurface
                    fontStyle: Tokens.font.icon.extraSmall ?? Tokens.font.icon.small
                }
            }

            StyledText {
                text: "Color Inspector"
                font: root.fontTitleSmall
                color: root.textPrimary
                elide: Text.ElideRight
                Layout.fillWidth: true
                Layout.minimumWidth: 0
            }

            // Quick "Pick Color" button
            Rectangle {
                implicitWidth: pickRow.implicitWidth + root.paddingSmall * 2
                implicitHeight: pickRow.implicitHeight + root.paddingExtraSmall * 2
                radius: root.radiusFull
                color: pickMouse.containsMouse ? (pickMouse.pressed ? root.accentColor : root.bgCard) : "transparent"
                border.color: root.accentColor
                border.width: 1

                RowLayout {
                    id: pickRow
                    anchors.centerIn: parent
                    spacing: root.spacingExtraSmall

                    MaterialIcon {
                        text: "colorize"
                        fontStyle: Tokens.font.icon.extraSmall ?? Tokens.font.icon.small
                        color: root.accentColor
                    }

                    StyledText {
                        text: "Pick New"
                        font: root.fontBodySmall
                        color: root.accentColor
                    }
                }

                MouseArea {
                    id: pickMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.colorService.pickColor()
                }
            }

            // Optional Close Button
            IconButton {
                visible: root.showCloseButton
                icon: "close"
                type: IconButton.Text
                font: Tokens.font.icon.extraSmall ?? Tokens.font.icon.small
                onClicked: root.closeClicked()
            }
        }

        // Hero Preview Swatch & Color Name
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: heroContentRow.implicitHeight + root.paddingSmall * 2
            radius: root.radiusSmall
            color: root.activeColor ? root.activeColor.hex : root.accentColor
            border.color: root.outlineColor
            border.width: 1

            Behavior on color {
                ColorAnimation { duration: 150 }
            }

            // Dark subtle overlay gradient for readable contrast
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.45) }
                    GradientStop { position: 0.6; color: Qt.rgba(0, 0, 0, 0.1) }
                    GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.4) }
                }

                RowLayout {
                    id: heroContentRow
                    anchors.fill: parent
                    anchors.margins: root.paddingSmall
                    spacing: root.spacingSmall

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: root.spacingExtraSmall / 2

                        Text {
                            visible: !root.colorService || root.colorService.showColorName
                            text: root.activeColor ? root.activeColor.colorName : "Custom"
                            font: root.fontTitleSmall
                            color: root.heroTextColor
                            elide: Text.ElideRight
                        }

                        Text {
                            text: root.activeColor ? root.activeColor.hex : "#3B82F6"
                            font: root.fontMonoSmall
                            color: root.heroTextColor
                        }
                    }

                    // Copy Primary button inside Hero
                    Rectangle {
                        implicitWidth: heroCopyIcon.implicitWidth + root.paddingExtraSmall * 2
                        implicitHeight: implicitWidth
                        radius: root.radiusFull
                        color: heroCopyMouse.containsMouse ? Colours.layer(Colours.palette.m3surface, 3) : Colours.layer(Colours.palette.m3surface, 2)

                        MaterialIcon {
                            id: heroCopyIcon
                            anchors.centerIn: parent
                            text: root.copiedFormat === "HERO" ? "check" : "content_copy"
                            fontStyle: Tokens.font.icon.extraSmall ?? Tokens.font.icon.small
                            color: root.heroTextColor
                        }

                        MouseArea {
                            id: heroCopyMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.colorService.copyFormatted(root.colorService.defaultFormat, root.activeColor);
                                root.copiedFormat = "HERO";
                                copyFeedbackTimer.restart();
                            }
                        }
                    }
                }
            }
        }

        // Shades Row (PowerToys Shades Generator)
        ColumnLayout {
            Layout.fillWidth: true
            spacing: root.spacingExtraSmall

            StyledText {
                text: "Color Shades & Tints"
                font: root.fontLabelSmall
                color: root.textSecondary
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: root.spacingExtraSmall

                Repeater {
                    model: root.colorService?.currentColor ? root.colorService.currentColor.shades : []

                    delegate: Rectangle {
                        id: shadeDelegate
                        required property var modelData
                        required property int index

                        Layout.fillWidth: true
                        implicitHeight: Math.round(shadeCheck.implicitHeight + root.paddingExtraSmall * 2)
                        radius: root.radiusExtraSmall
                        color: shadeDelegate.modelData.hex
                        border.color: shadeDelegate.index === root.selectedShadeIndex ? root.textPrimary : root.outlineColor
                        border.width: shadeDelegate.index === root.selectedShadeIndex ? 2 : 1

                        MaterialIcon {
                            id: shadeCheck
                            visible: shadeDelegate.index === root.selectedShadeIndex
                            anchors.centerIn: parent
                            text: "check"
                            fontStyle: Tokens.font.icon.extraSmall ?? Tokens.font.icon.small
                            color: (shadeDelegate.modelData.r * 0.299 + shadeDelegate.modelData.g * 0.587 + shadeDelegate.modelData.b * 0.114) > 140 ? "#000000" : "#FFFFFF"
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.selectedShadeIndex = shadeDelegate.index;
                                root.colorService.copyText(shadeDelegate.modelData.hex, "Shade " + (shadeDelegate.index + 1));
                            }
                        }
                    }
                }
            }
        }

        // Format Values List (Filtered by enabledFormats)
        ColumnLayout {
            Layout.fillWidth: true
            spacing: root.spacingExtraSmall

            StyledText {
                text: "Color Formats (Click to copy)"
                font: root.fontLabelSmall
                color: root.textSecondary
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: formatListLayout.implicitHeight + root.paddingExtraSmall * 2
                radius: root.radiusSmall
                color: root.bgCard
                border.color: root.outlineColor
                border.width: 1

                ColumnLayout {
                    id: formatListLayout
                    anchors.fill: parent
                    anchors.margins: root.paddingExtraSmall
                    spacing: 1

                    component FormatRow: Rectangle {
                        id: row
                        required property string formatName
                        required property string formatValue

                        Layout.fillWidth: true
                        implicitHeight: rowLayoutContent.implicitHeight + root.paddingExtraSmall
                        radius: root.radiusExtraSmall
                        color: rowMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"

                        RowLayout {
                            id: rowLayoutContent
                            anchors.fill: parent
                            anchors.leftMargin: Math.round(root.paddingExtraSmall * 1.5)
                            anchors.rightMargin: Math.round(root.paddingExtraSmall * 1.5)
                            spacing: root.spacingExtraSmall

                            StyledText {
                                text: row.formatName
                                font: root.fontLabelSmall
                                color: root.accentColor
                                Layout.preferredWidth: root.maxFormatLabelWidth
                            }

                            StyledText {
                                text: row.formatValue
                                font: root.fontMonoSmall
                                color: root.textPrimary
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            MaterialIcon {
                                text: root.copiedFormat === row.formatName ? "check" : "content_copy"
                                fontStyle: Tokens.font.icon.extraSmall ?? Tokens.font.icon.small
                                color: root.copiedFormat === row.formatName ? root.accentColor : root.textSecondary
                            }
                        }

                        MouseArea {
                            id: rowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.colorService.copyText(row.formatValue, row.formatName);
                                root.copiedFormat = row.formatName;
                                copyFeedbackTimer.restart();
                            }
                        }
                    }

                    Repeater {
                        model: root.activeFormatModels

                        delegate: FormatRow {
                            required property var modelData
                            visible: !root.colorService?.enabledFormats || (root.colorService.enabledFormats[modelData.key] ?? true)
                            formatName: modelData.name
                            formatValue: root.colorService ? root.colorService.formatValue(modelData.key, root.activeColor) : ""
                        }
                    }
                }
            }
        }

        // Adjust Color Toggle & Sliders (PowerToys Fine-Tuning)
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: adjustContent.implicitHeight + root.paddingSmall * 2
            radius: root.radiusSmall
            color: root.bgCard
            border.color: root.outlineColor
            border.width: 1

            ColumnLayout {
                id: adjustContent
                anchors.fill: parent
                anchors.margins: root.paddingSmall
                spacing: root.spacingSmall

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
                            fontStyle: Tokens.font.icon.extraSmall ?? Tokens.font.icon.small
                            color: root.accentColor
                        }

                        StyledText {
                            text: "Fine-tune Color (HSV / RGB)"
                            font: root.fontBodySmall
                            color: root.textPrimary
                            Layout.fillWidth: true
                        }

                        MaterialIcon {
                            text: root.adjustExpanded ? "expand_less" : "expand_more"
                            fontStyle: Tokens.font.icon.extraSmall ?? Tokens.font.icon.small
                            color: root.textSecondary
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.adjustExpanded = !root.adjustExpanded
                    }
                }

                // Expanded Adjuster Controls
                ColumnLayout {
                    visible: root.adjustExpanded
                    Layout.fillWidth: true
                    spacing: root.spacingSmall

                    // Hue Slider (0 - 360)
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: root.spacingExtraSmall / 2

                        RowLayout {
                            Layout.fillWidth: true
                            StyledText { text: "Hue"; font: root.fontLabelSmall; color: root.textSecondary; Layout.fillWidth: true }
                            StyledText {
                                text: Math.round(hueSlider.value) + "°"
                                font: root.fontMonoSmall
                                color: root.textPrimary
                            }
                        }

                        Slider {
                            id: hueSlider
                            Layout.fillWidth: true
                            from: 0
                            to: 360
                            value: root.activeColor ? root.activeColor.hDeg : 0
                            onMoved: {
                                root.colorService.setColorFromHsv(value, satSlider.value, valSlider.value);
                            }
                        }
                    }

                    // Saturation Slider (0 - 100)
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: root.spacingExtraSmall / 2

                        RowLayout {
                            Layout.fillWidth: true
                            StyledText { text: "Saturation"; font: root.fontLabelSmall; color: root.textSecondary; Layout.fillWidth: true }
                            StyledText {
                                text: Math.round(satSlider.value) + "%"
                                font: root.fontMonoSmall
                                color: root.textPrimary
                            }
                        }

                        Slider {
                            id: satSlider
                            Layout.fillWidth: true
                            from: 0
                            to: 100
                            value: root.activeColor ? root.activeColor.sPct : 0
                            onMoved: {
                                root.colorService.setColorFromHsv(hueSlider.value, value, valSlider.value);
                            }
                        }
                    }

                    // Value Slider (0 - 100)
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: root.spacingExtraSmall / 2

                        RowLayout {
                            Layout.fillWidth: true
                            StyledText { text: "Value / Brightness"; font: root.fontLabelSmall; color: root.textSecondary; Layout.fillWidth: true }
                            StyledText {
                                text: Math.round(valSlider.value) + "%"
                                font: root.fontMonoSmall
                                color: root.textPrimary
                            }
                        }

                        Slider {
                            id: valSlider
                            Layout.fillWidth: true
                            from: 0
                            to: 100
                            value: root.activeColor ? root.activeColor.vPct : 0
                            onMoved: {
                                root.colorService.setColorFromHsv(hueSlider.value, satSlider.value, value);
                            }
                        }
                    }

                    // Direct RGB Inputs
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: root.spacingSmall

                        component RgbInput: ColumnLayout {
                            required property string label
                            required property int val
                            signal accepted(int newVal)

                            Layout.fillWidth: true
                            spacing: root.spacingExtraSmall / 2

                            StyledText {
                                text: parent.label
                                font: root.fontLabelSmall
                                color: root.textSecondary
                                horizontalAlignment: Text.AlignHCenter
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: rgbField.implicitHeight + root.paddingExtraSmall
                                radius: root.radiusExtraSmall
                                color: root.bgSurface
                                border.color: root.outlineColor
                                border.width: 1

                                TextInput {
                                    id: rgbField
                                    anchors.fill: parent
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    font: root.fontMonoSmall
                                    color: root.textPrimary
                                    text: parent.parent.val.toString()
                                    maximumLength: 3
                                    validator: IntValidator { bottom: 0; top: 255 }
                                    onEditingFinished: {
                                        let num = parseInt(text);
                                        if (!isNaN(num)) {
                                            parent.parent.accepted(num);
                                        }
                                    }
                                }
                            }
                        }

                        RgbInput {
                            label: "Red (R)"
                            val: root.activeColor ? root.activeColor.r : 0
                            onAccepted: newVal => {
                                const cur = root.activeColor || root.colorService.currentColor;
                                root.colorService.setColorFromRgb(newVal, cur ? cur.g : 0, cur ? cur.b : 0);
                            }
                        }

                        RgbInput {
                            label: "Green (G)"
                            val: root.activeColor ? root.activeColor.g : 0
                            onAccepted: newVal => {
                                const cur = root.activeColor || root.colorService.currentColor;
                                root.colorService.setColorFromRgb(cur ? cur.r : 0, newVal, cur ? cur.b : 0);
                            }
                        }

                        RgbInput {
                            label: "Blue (B)"
                            val: root.activeColor ? root.activeColor.b : 0
                            onAccepted: newVal => {
                                const cur = root.activeColor || root.colorService.currentColor;
                                root.colorService.setColorFromRgb(cur ? cur.r : 0, cur ? cur.g : 0, newVal);
                            }
                        }
                    }
                }
            }
        }

        // Color History Row
        ColumnLayout {
            Layout.fillWidth: true
            spacing: root.spacingExtraSmall

            RowLayout {
                Layout.fillWidth: true

                StyledText {
                    text: "Recent History"
                    font: root.fontLabelSmall
                    color: root.textSecondary
                    Layout.fillWidth: true
                }

                StyledText {
                    visible: root.colorService?.history.length > 0
                    text: "Clear"
                    font: root.fontLabelSmall
                    color: root.accentColor

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.colorService.clearHistory()
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: historyRow.implicitHeight + root.paddingExtraSmall * 2
                radius: root.radiusSmall
                color: root.bgCard
                border.color: root.outlineColor
                border.width: 1

                Flickable {
                    anchors.fill: parent
                    anchors.margins: root.paddingExtraSmall
                    contentWidth: historyRow.implicitWidth
                    clip: true

                    RowLayout {
                        id: historyRow
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: root.spacingExtraSmall

                        Repeater {
                            model: root.colorService?.history ?? []

                            delegate: Rectangle {
                                id: historySwatchDelegate
                                required property var modelData
                                required property int index

                                implicitWidth: Math.round(root.fontLabelSmall.pixelSize * 1.8)
                                implicitHeight: implicitWidth
                                radius: root.radiusFull
                                color: modelData.hex
                                border.color: root.outlineColor
                                border.width: 1

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.colorService.setColor(parent.modelData.hex);
                                    }
                                }
                            }
                        }

                        StyledText {
                            visible: !root.colorService?.history || root.colorService.history.length === 0
                            text: "No colors picked yet"
                            font: root.fontBodySmall
                            color: root.textSecondary
                            leftPadding: root.paddingExtraSmall
                        }
                    }
                }
            }
        }
    }
}
