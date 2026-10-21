# 📰 News Feed Plugin for Caelestia Shell (Midnight Shell)

A comprehensive RSS & Atom news feed manager and live reader plugin for **Caelestia Shell** on **Hyprland** (Wayland).

Allows configuring, testing, reordering, and customizing news sources directly through **Nexus Settings -> System -> Plugins -> News Feed**, seamlessly syncing with the desktop sidebar and top bar.

---

## ⚡ Instant Installation (1 Command)

To install this plugin onto **any device with Caelestia**, run:

```bash
./install.sh
```

Or for development (symlinking):
```bash
./install.sh --link
```

To uninstall:
```bash
./install.sh --uninstall
```

The installer automatically:
- Detects missing dependencies (`curl`, `libnotify`, `xdg-utils`) and offers to install them via your package manager (`pacman`, `dnf`, `apt`, `zypper`).
- Deploys the plugin to `~/.config/caelestia/plugins/news-feed`.
- Sets up the Quickshell module link in `~/.config/quickshell/caelestia/modules/newsfeed`.
- Configures the Sidebar News component `~/.config/quickshell/caelestia/modules/sidebar/News.qml`.
- Installs the CLI trigger `caelestia-news-feed` into `~/.local/bin/`.
- Initializes `~/.config/caelestia/news.json` with curated feeds if missing.
- Enables the plugin in `~/.config/caelestia/plugins-state.json`.

---

## 🌟 Key Features

- **Integrated Nexus Settings Management**:
  - Add custom RSS 2.0 or Atom feeds by URL.
  - Live feed validator tool with real-time XML verification, item counts, and title detection.
  - Reorder feeds up/down to customize sidebar tab display priority.
  - Enable/disable individual feeds without deleting them.
  - Inline editing of feed titles and URLs.
  - 1-click curated Presets library (Arch Linux News, CachyOS News, Phoronix, Hacker News, GamingOnLinux, Insider Gaming, Android Authority, GSMArena, Ars Technica, GitHub Blog, The Verge, Linux Weekly News).
- **Live Sync & Hot Reload**:
  - Automatically writes and watches `~/.config/caelestia/news.json`.
  - Immediate hot-reload across all shell elements without restarting Quickshell.
- **Multi-Feed Sidebar Reader**:
  - Horizontal feed switcher chips in the sidebar News tab.
  - Relative publication date formatting ("Just now", "2h ago", "Yesterday").
  - Hover highlights and click-to-open in your default web browser.
  - Direct shortcut button to open the News Feed plugin manager.
- **Bar Widget & Quick Toggle**:
  - Quick Toggle for the drawer to jump directly to the News feed.
  - Bar status widget with left-click to toggle sidebar and right-click to open Nexus Settings.

---

## 📁 Plugin File Structure

```text
news-feed/
├── manifest.json              # Plugin metadata and Nexus entry points
├── settings.json              # Initial default preferences
├── News.qml                   # Sidebar live news reader component
├── NewsUtils.js               # RSS/Atom XML parser, HTML entity decoder & presets catalog
├── NewsService.qml            # Singleton feed manager, atomic persistence & networking
├── Settings.qml               # Nexus Settings configuration interface
├── QuickToggle.qml            # Drawer quick-toggle widget
├── BarWidget.qml              # Panel bar indicator widget
├── caelestia-news-feed        # CLI launcher script
├── install.sh                 # Standalone installer for any Caelestia device
├── main.qml                   # Standalone shell runner
├── qmldir                     # QML module export definitions
└── README.md                  # Documentation
```

---

## 🚀 Usage & Commands

### CLI Launcher
```bash
caelestia-news-feed          # Open sidebar to News tab
caelestia-news-feed next     # Cycle to next feed
caelestia-news-feed reload   # Force reload feed articles
```

### Access in Nexus Settings
Open Nexus Settings:
- Click the settings icon in the sidebar or run:
  ```bash
  caelestia shell nexus open
  ```
- Navigate to **Plugins** -> **News Feed** to customize your feeds.
