pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell

import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.components.effects
import qs.services
import qs.modules.nexus
import qs.modules.nexus.common
import qs.utils

import "."
import "NewsUtils.js" as NewsUtils

PageBase {
    id: root

    title: Tr.tr("News Feed")
    isSubPage: true

    readonly property NewsService service: NewsService

    // Form state for adding custom feed
    property string newFeedName: ""
    property string newFeedUrl: ""
    property string testStatusText: ""
    property bool testStatusSuccess: false
    property bool isTesting: false

    // State for editing existing feed
    property int editingIndex: -1
    property string editName: ""
    property string editUrl: ""

    readonly property list<MenuItem> intervalItems: [
        MenuItem { text: Tr.tr("Manual refresh only"); value: 0 },
        MenuItem { text: Tr.tr("Every 15 minutes"); value: 15 },
        MenuItem { text: Tr.tr("Every 30 minutes"); value: 30 },
        MenuItem { text: Tr.tr("Every 1 hour"); value: 60 },
        MenuItem { text: Tr.tr("Every 2 hours"); value: 120 }
    ]

    readonly property list<MenuItem> maxArticleItems: [
        MenuItem { text: Tr.tr("10 articles"); value: 10 },
        MenuItem { text: Tr.tr("20 articles (Default)"); value: 20 },
        MenuItem { text: Tr.tr("30 articles"); value: 30 },
        MenuItem { text: Tr.tr("50 articles"); value: 50 }
    ]

    function isPresetAdded(url: string): bool {
        if (!root.service.feeds) return false;
        for (var i = 0; i < root.service.feeds.length; i++) {
            if (root.service.feeds[i].url === url) return true;
        }
        return false;
    }

    component FeedListRow: Item {
        id: item

        required property var modelData
        property bool held: false
        property real startSlotY: 0
        property real startCursorWindowY: 0
        property int pressIndex: -1

        width: feedListView ? feedListView.width : root.cappedWidth
        implicitHeight: itemContent.implicitHeight
        z: held || returnAnim.running ? 2 : 0

        // Soft placeholder in slot while dragging
        StyledRect {
            id: placeholder
            anchors.fill: parent
            color: Colours.palette.m3primary
            radius: Tokens.rounding.large
            opacity: item.held ? 0.12 : 0

            Behavior on opacity {
                Anim { type: Anim.DefaultEffects }
            }
        }

        Anim {
            id: returnAnim
            target: itemContent
            properties: "y"
            to: 0
            type: Anim.DefaultEffects
        }

        Item {
            id: itemContent
            width: parent.width
            implicitHeight: feedCard.implicitHeight

            Elevation {
                anchors.fill: parent
                radius: feedCard.radius
                level: item.held ? 3 : 0
                opacity: item.held ? 1 : 0

                Behavior on opacity {
                    Anim { type: Anim.DefaultEffects }
                }
            }

            ConnectedRect {
                id: feedCard
                anchors.fill: parent
                first: item.DelegateModel.itemsIndex === 0
                last: item.DelegateModel.itemsIndex === (root.service.feeds ? root.service.feeds.length - 1 : 0)
                implicitHeight: feedMainCol.implicitHeight + Tokens.padding.medium * 2
                color: item.held ? Colours.layer(Colours.palette.m3surfaceContainerHighest, 3) : Colours.layer(Colours.palette.m3surfaceContainer, 1)

                Behavior on color {
                    CAnim {}
                }

                ColumnLayout {
                    id: feedMainCol
                    anchors.fill: parent
                    anchors.margins: Tokens.padding.medium
                    anchors.leftMargin: Tokens.padding.largeIncreased
                    anchors.rightMargin: Tokens.padding.largeIncreased
                    spacing: Tokens.spacing.small

                    // Main Row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.medium

                        // Feed Icon
                        Rectangle {
                            width: 36
                            height: 36
                            radius: Tokens.rounding.full
                            color: (item.modelData.enabled ?? true)
                                ? Colours.palette.m3secondaryContainer
                                : Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)

                            MaterialIcon {
                                anchors.centerIn: parent
                                text: item.modelData.icon || "feed"
                                color: (item.modelData.enabled ?? true)
                                    ? Colours.palette.m3onSecondaryContainer
                                    : Colours.palette.m3outline
                                fontStyle: Tokens.font.icon.small
                            }
                        }

                        // Feed Info
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            RowLayout {
                                spacing: Tokens.spacing.small

                                StyledText {
                                    text: item.modelData.name || "Unnamed Feed"
                                    font: Tokens.font.body.medium
                                    elide: Text.ElideRight
                                }

                                Rectangle {
                                    implicitWidth: hostLabel.implicitWidth + 8
                                    implicitHeight: 18
                                    radius: 4
                                    color: Colours.layer(Colours.palette.m3surfaceContainerLowest, 1)

                                    StyledText {
                                        id: hostLabel
                                        anchors.centerIn: parent
                                        text: NewsUtils.getDomain(item.modelData.url)
                                        font: Tokens.font.label.small
                                        color: Colours.palette.m3outline
                                    }
                                }
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: item.modelData.url
                                color: Colours.palette.m3onSurfaceVariant
                                font: Tokens.font.label.small
                                elide: Text.ElideMiddle
                            }
                        }

                        // Draggable Reorder Handle Button
                        Item {
                            id: dragButton
                            implicitWidth: 36
                            implicitHeight: 36

                            Rectangle {
                                id: dragBtnBg
                                anchors.fill: parent
                                radius: Tokens.rounding.full
                                color: item.held
                                    ? Colours.palette.m3primaryContainer
                                    : (dragMouse.containsMouse ? Colours.layer(Colours.palette.m3surfaceContainerHighest, 2) : Colours.layer(Colours.palette.m3surfaceContainerHighest, 1))

                                Behavior on color {
                                    CAnim {}
                                }

                                MaterialIcon {
                                    anchors.centerIn: parent
                                    text: "drag_indicator"
                                    fontStyle: Tokens.font.icon.small
                                    color: item.held ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3outline
                                }
                            }

                            MouseArea {
                                id: dragMouse
                                anchors.fill: parent
                                cursorShape: item.held ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                                preventStealing: true
                                hoverEnabled: true

                                onPressed: e => {
                                    returnAnim.stop();
                                    item.pressIndex = item.DelegateModel.itemsIndex;
                                    item.startSlotY = item.y;
                                    item.startCursorWindowY = dragMouse.mapToItem(null, 0, e.y).y;
                                    item.held = true;
                                    root.scrollable = false;
                                }

                                onPositionChanged: e => {
                                    if (!item.held) return;
                                    const currentCursorWindowY = dragMouse.mapToItem(null, 0, e.y).y;
                                    const totalDragDistance = currentCursorWindowY - item.startCursorWindowY;
                                    const desiredTopInList = feedListView.clampDesiredTop(item.startSlotY + totalDragDistance, item.implicitHeight);
                                    itemContent.y = desiredTopInList - item.y;

                                    const checkY = desiredTopInList + item.implicitHeight / 2;
                                    const swap = feedListView.itemAt(0, checkY);
                                    if (swap && swap !== item) {
                                        const fromIdx = item.DelegateModel.itemsIndex;
                                        const toIdx = swap.DelegateModel.itemsIndex;
                                        visualModel.items.move(fromIdx, toIdx);
                                    }
                                }

                                onReleased: e => {
                                    if (!item.held) return;
                                    item.held = false;
                                    root.scrollable = true;

                                    returnAnim.to = 0;
                                    returnAnim.start();

                                    const idx = item.DelegateModel.itemsIndex;
                                    if (idx !== item.pressIndex) {
                                        root.service.moveFeed(item.pressIndex, idx);
                                    }
                                }

                                onCanceled: {
                                    if (!item.held) return;
                                    item.held = false;
                                    root.scrollable = true;
                                    returnAnim.to = 0;
                                    returnAnim.start();
                                }
                            }
                        }

                        // Edit Button
                        IconButton {
                            icon: "edit"
                            type: IconButton.Tonal
                            isRound: true
                            onClicked: {
                                const curIdx = item.DelegateModel.itemsIndex;
                                if (root.editingIndex === curIdx) {
                                    root.editingIndex = -1;
                                } else {
                                    root.editingIndex = curIdx;
                                    root.editName = item.modelData.name;
                                    root.editUrl = item.modelData.url;
                                }
                            }
                        }

                        // Toggle Active Switch
                        StyledSwitch {
                            checked: item.modelData.enabled ?? true
                            onToggled: root.service.toggleFeed(item.DelegateModel.itemsIndex, checked)
                        }

                        // Delete Button
                        IconButton {
                            icon: "delete"
                            type: IconButton.Standard
                            isRound: true
                            onClicked: root.service.removeFeed(item.DelegateModel.itemsIndex)
                        }
                    }

                    // Inline Edit Panel (Expanded when editing)
                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: root.editingIndex === item.DelegateModel.itemsIndex
                        spacing: Tokens.spacing.small

                        StyledRect {
                            Layout.fillWidth: true
                            implicitHeight: 1
                            color: Colours.palette.m3outlineVariant
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Tokens.spacing.medium

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                StyledText {
                                    text: Tr.tr("Edit Feed Name")
                                    font: Tokens.font.label.small
                                    color: Colours.palette.m3outline
                                }

                                StyledTextField {
                                    Layout.fillWidth: true
                                    text: root.editName
                                    onTextChanged: root.editName = text
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                StyledText {
                                    text: Tr.tr("Edit Feed URL")
                                    font: Tokens.font.label.small
                                    color: Colours.palette.m3outline
                                }

                                StyledTextField {
                                    Layout.fillWidth: true
                                    text: root.editUrl
                                    onTextChanged: root.editUrl = text
                                }
                            }
                        }

                        RowLayout {
                            Layout.alignment: Qt.AlignRight
                            spacing: Tokens.spacing.small

                            TextButton {
                                text: Tr.tr("Cancel")
                                type: ButtonBase.Text
                                onClicked: root.editingIndex = -1
                            }

                            TextButton {
                                text: Tr.tr("Save Changes")
                                type: ButtonBase.Filled
                                onClicked: {
                                    if (root.editName.trim().length > 0 && root.editUrl.trim().length > 0) {
                                        root.service.updateFeed(
                                            item.DelegateModel.itemsIndex,
                                            root.editName,
                                            root.editUrl,
                                            item.modelData.icon,
                                            item.modelData.enabled
                                        );
                                        root.editingIndex = -1;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.medium

        // ==========================================
        // 1. Top Card: Enable News Feed & Status
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
                    implicitWidth: enableFeedIcon.implicitWidth + Tokens.padding.small * 2
                    implicitHeight: implicitWidth
                    radius: Tokens.rounding.small
                    color: Colours.palette.m3primary

                    MaterialIcon {
                        id: enableFeedIcon
                        anchors.centerIn: parent
                        text: "feed"
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
                            text: Tr.tr("Enable News Feed")
                            font: Tokens.font.body.medium
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: root.service.pluginEnabled
                                ? Tr.tr("%1 feed(s) configured • Live sync with sidebar").arg(root.service.feeds ? root.service.feeds.length : 0)
                                : Tr.tr("News feed plugin is disabled")
                            color: Colours.palette.m3outline
                            font: Tokens.font.label.small
                        }
                    }
                }

                IconTextButton {
                    text: Tr.tr("Open news.json")
                    icon: "file_open"
                    type: ButtonBase.Tonal
                    onClicked: root.service.openNewsFile()
                }

                StyledSwitch {
                    checked: root.service.pluginEnabled
                    onToggled: {
                        root.service.pluginEnabled = checked;
                        root.service.saveSettings();
                    }
                }
            }
        }

        // ==========================================
        // 2. Section: Configured Feeds
        // ==========================================
        SectionHeader {
            text: Tr.tr("Active Feeds (%1)").arg(root.service.feeds ? root.service.feeds.length : 0)
        }

        // Empty state
        ConnectedRect {
            visible: !root.service.feeds || root.service.feeds.length === 0
            first: true
            last: true
            Layout.fillWidth: true
            implicitHeight: emptyFeedCol.implicitHeight + Tokens.padding.extraLarge * 2

            ColumnLayout {
                id: emptyFeedCol
                anchors.centerIn: parent
                spacing: Tokens.spacing.small

                MaterialIcon {
                    Layout.alignment: Qt.AlignHCenter
                    text: "rss_feed"
                    color: Colours.palette.m3outline
                    fontStyle: Tokens.font.icon.large
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: Tr.tr("No news feeds configured")
                    font: Tokens.font.body.medium
                    color: Colours.palette.m3onSurfaceVariant
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: Tr.tr("Add a custom RSS/Atom URL below or pick from presets")
                    font: Tokens.font.label.small
                    color: Colours.palette.m3outline
                }

                TextButton {
                    Layout.alignment: Qt.AlignHCenter
                    text: Tr.tr("Restore Default Feeds")
                    type: ButtonBase.Tonal
                    onClicked: root.service.resetToDefaults()
                }
            }
        }

        // Feeds List (Draggable Reorderable ListView)
        ListView {
            id: feedListView
            visible: root.service.feeds && root.service.feeds.length > 0
            Layout.fillWidth: true
            implicitHeight: contentHeight
            spacing: Tokens.spacing.extraSmall / 2
            interactive: false

            function dampOvershoot(overshoot: real, maxOvershoot: real): real {
                return overshoot / (1 + Math.abs(overshoot) / maxOvershoot);
            }

            function clampDesiredTop(topY: real, itemHeight: real): real {
                const maxOvershoot = Tokens.padding.extraLarge;
                if (topY < 0) {
                    return dampOvershoot(topY, maxOvershoot);
                }
                const maxTop = Math.max(0, feedListView.contentHeight - itemHeight);
                if (topY > maxTop) {
                    return maxTop + dampOvershoot(topY - maxTop, maxOvershoot);
                }
                return topY;
            }

            model: DelegateModel {
                id: visualModel

                model: ScriptModel {
                    id: valuesModel
                    values: root.service.feeds
                }

                delegate: FeedListRow {}
            }

            add: Transition {
                Anim { properties: "opacity"; type: Anim.DefaultEffects; from: 0; to: 1 }
            }
            remove: Transition {
                Anim { properties: "opacity"; type: Anim.DefaultEffects; to: 0 }
            }
            move: Transition {
                Anim { properties: "opacity"; type: Anim.DefaultEffects; to: 1 }
                Anim { properties: "y" }
            }
            displaced: Transition {
                Anim { properties: "opacity"; type: Anim.DefaultEffects; to: 1 }
                Anim { properties: "y" }
            }

            Behavior on implicitHeight {
                Anim {}
            }
        }

        // ==========================================
        // 3. Section: Add Custom Feed
        // ==========================================
        SectionHeader {
            text: Tr.tr("Add Custom Feed")
        }

        ConnectedRect {
            first: true
            last: true
            Layout.fillWidth: true
            implicitHeight: addCol.implicitHeight + Tokens.padding.large * 2

            ColumnLayout {
                id: addCol
                anchors.fill: parent
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.medium

                StyledText {
                    text: Tr.tr("Connect any RSS 2.0 or Atom feed by URL")
                    font: Tokens.font.body.small
                    color: Colours.palette.m3onSurfaceVariant
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.medium

                    ColumnLayout {
                        Layout.preferredWidth: parent.width * 0.35
                        spacing: 4

                        StyledText {
                            text: Tr.tr("Feed Name")
                            font: Tokens.font.label.small
                            color: Colours.palette.m3outline
                        }

                        StyledTextField {
                            id: nameInput
                            Layout.fillWidth: true
                            placeholderText: Tr.tr("e.g., Phoronix, Hacker News")
                            text: root.newFeedName
                            onTextChanged: root.newFeedName = text
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        StyledText {
                            text: Tr.tr("RSS / Atom Feed URL")
                            font: Tokens.font.label.small
                            color: Colours.palette.m3outline
                        }

                        StyledTextField {
                            id: urlInput
                            Layout.fillWidth: true
                            placeholderText: Tr.tr("https://example.com/feed.xml")
                            text: root.newFeedUrl
                            onTextChanged: {
                                root.newFeedUrl = text;
                                root.testStatusText = "";
                            }
                        }
                    }
                }

                // Test Status Feedback Banner
                StyledRect {
                    visible: root.testStatusText.length > 0 || root.isTesting
                    Layout.fillWidth: true
                    implicitHeight: testFeedbackRow.implicitHeight + Tokens.padding.small * 2
                    radius: Tokens.rounding.small
                    color: root.isTesting
                        ? Colours.palette.m3surfaceContainerHighest
                        : (root.testStatusSuccess ? Qt.rgba(0.2, 0.7, 0.3, 0.2) : Qt.rgba(0.9, 0.2, 0.2, 0.2))

                    RowLayout {
                        id: testFeedbackRow
                        anchors.fill: parent
                        anchors.margins: Tokens.padding.small
                        spacing: Tokens.spacing.small

                        MaterialIcon {
                            text: root.isTesting ? "hourglass_empty" : (root.testStatusSuccess ? "check_circle" : "error")
                            color: root.isTesting
                                ? Colours.palette.m3primary
                                : (root.testStatusSuccess ? "#4CAF50" : Colours.palette.m3error)
                            fontStyle: Tokens.font.icon.small
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: root.isTesting ? Tr.tr("Testing feed URL and validating XML...") : root.testStatusText
                            font: Tokens.font.label.small
                            color: root.isTesting
                                ? Colours.palette.m3onSurface
                                : (root.testStatusSuccess ? Colours.palette.m3onSurface : Colours.palette.m3error)
                            wrapMode: Text.WordWrap
                        }
                    }
                }

                // Action Buttons
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small

                    Item {
                        Layout.fillWidth: true
                    }

                    IconTextButton {
                        text: Tr.tr("Test Feed URL")
                        icon: "network_check"
                        type: ButtonBase.Tonal
                        enabled: !root.isTesting && root.newFeedUrl.trim().length > 0
                        onClicked: {
                            root.isTesting = true;
                            root.testStatusText = "";
                            root.service.testFeedUrl(root.newFeedUrl, function(res) {
                                root.isTesting = false;
                                if (res.success) {
                                    root.testStatusSuccess = true;
                                    root.testStatusText = Tr.tr("✓ Valid feed! \"%1\" (%2 articles found)").arg(res.title).arg(res.count);
                                    if (root.newFeedName.trim().length === 0 && res.title) {
                                        root.newFeedName = res.title;
                                    }
                                } else {
                                    root.testStatusSuccess = false;
                                    root.testStatusText = Tr.tr("✕ Validation failed: %1").arg(res.error);
                                }
                            });
                        }
                    }

                    IconTextButton {
                        text: Tr.tr("Add Feed")
                        icon: "add"
                        type: ButtonBase.Filled
                        enabled: root.newFeedName.trim().length > 0 && root.newFeedUrl.trim().length > 0
                        onClicked: {
                            var added = root.service.addFeed(root.newFeedName, root.newFeedUrl, "feed");
                            if (added) {
                                root.newFeedName = "";
                                root.newFeedUrl = "";
                                root.testStatusText = "";
                            }
                        }
                    }
                }
            }
        }

        // ==========================================
        // 4. Section: Popular Feeds Presets Library
        // ==========================================
        SectionHeader {
            text: Tr.tr("Popular Presets Library")
        }

        ConnectedRect {
            first: true
            last: true
            Layout.fillWidth: true
            implicitHeight: presetsCol.implicitHeight + Tokens.padding.large * 2

            ColumnLayout {
                id: presetsCol
                anchors.fill: parent
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.medium

                StyledText {
                    text: Tr.tr("Add curated Linux, tech, hardware, and gaming news feeds with a single click")
                    font: Tokens.font.body.small
                    color: Colours.palette.m3onSurfaceVariant
                }

                Repeater {
                    model: NewsUtils.PRESETS

                    delegate: ConnectedRect {
                        id: presetCard
                        required property var modelData
                        required property int index

                        readonly property bool alreadyAdded: root.isPresetAdded(presetCard.modelData.url)

                        Layout.fillWidth: true
                        implicitHeight: presetRow.implicitHeight + Tokens.padding.medium * 2
                        color: Colours.layer(Colours.palette.m3surfaceContainerHigh, 1)
                        radius: Tokens.rounding.medium

                        RowLayout {
                            id: presetRow
                            anchors.fill: parent
                            anchors.margins: Tokens.padding.medium
                            spacing: Tokens.spacing.medium

                            // Icon
                            Rectangle {
                                width: 36
                                height: 36
                                radius: Tokens.rounding.full
                                color: presetCard.alreadyAdded
                                    ? Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)
                                    : Colours.palette.m3secondaryContainer

                                MaterialIcon {
                                    anchors.centerIn: parent
                                    text: presetCard.modelData.icon || "newspaper"
                                    color: presetCard.alreadyAdded
                                        ? Colours.palette.m3outline
                                        : Colours.palette.m3onSecondaryContainer
                                    fontStyle: Tokens.font.icon.small
                                }
                            }

                            // Details
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                RowLayout {
                                    spacing: Tokens.spacing.small

                                    StyledText {
                                        text: presetCard.modelData.name
                                        font: Tokens.font.body.medium
                                    }

                                    // Category Pill
                                    Rectangle {
                                        implicitWidth: catLabel.implicitWidth + 8
                                        implicitHeight: 18
                                        radius: 4
                                        color: Colours.layer(Colours.palette.m3surfaceContainerLowest, 1)

                                        StyledText {
                                            id: catLabel
                                            anchors.centerIn: parent
                                            text: presetCard.modelData.category
                                            font: Tokens.font.label.small
                                            color: Colours.palette.m3primary
                                        }
                                    }
                                }

                                StyledText {
                                    Layout.fillWidth: true
                                    text: presetCard.modelData.description
                                    color: Colours.palette.m3onSurfaceVariant
                                    font: Tokens.font.label.small
                                    elide: Text.ElideRight
                                }
                            }

                            // Add / Added status button
                            IconTextButton {
                                text: presetCard.alreadyAdded ? Tr.tr("Added") : Tr.tr("Add")
                                icon: presetCard.alreadyAdded ? "check" : "add"
                                type: presetCard.alreadyAdded ? ButtonBase.Text : ButtonBase.Tonal
                                enabled: !presetCard.alreadyAdded
                                onClicked: {
                                    root.service.addFeed(
                                        presetCard.modelData.name,
                                        presetCard.modelData.url,
                                        presetCard.modelData.icon
                                    );
                                }
                            }
                        }
                    }
                }
            }
        }

        // ==========================================
        // 5. Section: Preferences & Options
        // ==========================================
        SectionHeader {
            text: Tr.tr("Feed Preferences")
        }

        SelectRow {
            first: true
            label: Tr.tr("Refresh interval")
            subtext: Tr.tr("How frequently the sidebar background updates news feeds")
            menuItems: root.intervalItems
            active: root.intervalItems.find(i => i.value === root.service.refreshInterval) ?? root.intervalItems[2]
            onSelected: item => {
                if (item && item.value !== undefined) {
                    root.service.refreshInterval = item.value;
                    root.service.saveSettings();
                }
            }
        }

        SelectRow {
            label: Tr.tr("Maximum articles per feed")
            subtext: Tr.tr("Limit the number of headlines displayed in the sidebar")
            menuItems: root.maxArticleItems
            active: root.maxArticleItems.find(i => i.value === root.service.maxArticles) ?? root.maxArticleItems[1]
            onSelected: item => {
                if (item && item.value !== undefined) {
                    root.service.maxArticles = item.value;
                    root.service.saveSettings();
                }
            }
        }

        ToggleRow {
            text: Tr.tr("Open articles in default browser")
            subtext: Tr.tr("Launch link using system default web browser on click")
            checked: root.service.openInBrowser
            onToggled: {
                root.service.openInBrowser = checked;
                root.service.saveSettings();
            }
        }

        RowButton {
            icon: "restart_alt"
            text: Tr.tr("Reset feeds to defaults")
            subtext: Tr.tr("Restore standard Arch Linux, Gaming, and Tech news feeds")
            last: true
            onClicked: root.service.resetToDefaults()
        }

        Item {
            implicitHeight: Tokens.spacing.large
        }
    }
}
