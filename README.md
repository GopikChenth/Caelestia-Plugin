# Caelestia Plugins Suite

A collection of **Windows PowerToys-inspired** productivity plugins for **Caelestia Shell** on **Hyprland** (Wayland), built with Quickshell, QtQuick, and native Wayland utilities.

Each plugin is completely self-contained in its own separate directory with its own manifest, settings, service, UI components, CLI launcher, and standalone installer.

---

## ⚡ 1-Command Installation On Any Device

To install and implement the entire plugin suite on **any device with Caelestia Shell**, run:

```bash
./install.sh
```

Or clone and install in one step:
```bash
git clone https://github.com/<user>/caelestia-plugins.git ~/.config/caelestia/plugins-repo && ~/.config/caelestia/plugins-repo/install.sh all
```

### Advanced Installation Options:
```bash
./install.sh all                 # Install all plugins (default)
./install.sh color-picker        # Install only Color Picker
./install.sh text-extractor      # Install only Text Extractor (OCR)
./install.sh news-feed           # Install only News Feed
./install.sh --link              # Symlink files instead of copying (for development)
./install.sh -y all              # Non-interactive mode (auto-accepts package install)
./install.sh --check             # Check status of system dependencies & plugins
./uninstall.sh [all|plugin]      # Clean uninstaller (or: ./install.sh --uninstall all)
```

---

## 📦 Included Plugins

### 1. 🎨 [`color-picker`](./color-picker/)
A Windows PowerToys-inspired Color Picker with a multi-format inspector, luminance shade generator, and color history.
- **Engine**: `hyprpicker`, `wl-copy`, `notify-send`
- **Formats**: HEX, HEX (no #), RGB, HSL, HSV, CMYK
- **Features**: Live magnifier zoom lens, Euclidean color name matching, 5-tier shades generator, HSV/RGB sliders, persistent color history.
- **Entry Points**: Nexus Settings (`Settings.qml`), Bar Widget (`BarWidget.qml`), Drawer Quick Toggle (`QuickToggle.qml`), Floating Window (`ColorEditorWindow.qml`), CLI (`caelestia-color-picker`).
- **Individual Installer**: `./color-picker/install.sh` (Uninstall: `./color-picker/uninstall.sh`)

### 2. 🔍 [`text-extractor`](./text-extractor/)
A Windows PowerToys-inspired Screen OCR Text Extractor for instant optical character recognition from any screen area.
- **Engine**: `slurp` + `grim` (Wayland capture) + `tesseract 5.5` (LSTM neural OCR) + `wl-copy` + `notify-send`
- **Features**: Interactive region selection with custom crosshair styling, instant in-memory capture, multi-language recognition (`eng`, `spa`, `fra`, `deu`, `jpn`, etc.), single-line cleaner, multi-format copy toolbar (Plain, Single-line, Markdown, UPPERCASE, lowercase, JSON), and persistent history.
- **Entry Points**: Nexus Settings (`Settings.qml`), Bar Widget (`BarWidget.qml`), Drawer Quick Toggle (`QuickToggle.qml`), Floating Window (`TextExtractorWindow.qml`), CLI (`caelestia-text-extractor`), Script (`extract.sh`).
- **Individual Installer**: `./text-extractor/install.sh` (Uninstall: `./text-extractor/uninstall.sh`)

### 3. 📰 [`news-feed`](./news-feed/)
A customizable RSS & Atom news feed manager and live reader for Midnight Shell.
- **Engine**: Native Quickshell XML/JSON networking (`XMLHttpRequest`, `FileView`, `xdg-open`)
- **Features**: Multi-feed aggregation, live feed testing & validation, 1-click curated presets library (Arch Linux, CachyOS, Phoronix, Hacker News, GamingOnLinux, etc.), reordering, persistent sync with `~/.config/caelestia/news.json`, and dynamic sidebar reader.
- **Entry Points**: Nexus Settings (`Settings.qml`), Bar Widget (`BarWidget.qml`), Drawer Quick Toggle (`QuickToggle.qml`), Sidebar Reader (`News.qml`), CLI (`caelestia-news-feed`), Singleton Service (`NewsService.qml`).
- **Individual Installer**: `./news-feed/install.sh` (Uninstall: `./news-feed/uninstall.sh`)

---

## 📁 Repository Structure

```text
Caelestia Plugins/
├── color-picker/                  # Color Picker Plugin (Self-contained)
│   ├── manifest.json              # Plugin manifest
│   ├── settings.json              # Default preferences & history
│   ├── ColorUtils.js              # Color conversion & math utilities
│   ├── ColorService.qml           # Core process & state singleton
│   ├── ColorEditorCard.qml        # Color inspector card UI
│   ├── ColorEditorWindow.qml      # Floating window component
│   ├── Settings.qml               # Nexus Settings page
│   ├── QuickToggle.qml            # Utilities drawer toggle
│   ├── BarWidget.qml              # Status bar widget
│   ├── caelestia-color-picker     # CLI activation launcher
│   ├── install.sh                 # Individual plugin installer
│   ├── uninstall.sh               # Individual plugin uninstaller
│   ├── main.qml                   # Quickshell standalone runner
│   ├── qmldir                     # QML module export definitions
│   └── README.md                  # Documentation
│
├── news-feed/                     # News Feed Plugin (Self-contained)
│   ├── manifest.json              # Plugin manifest
│   ├── settings.json              # Initial preferences
│   ├── News.qml                   # Live sidebar reader component
│   ├── NewsUtils.js               # RSS/Atom XML parser & presets catalog
│   ├── NewsService.qml            # Feed caching & networking singleton
│   ├── Settings.qml               # Nexus Settings feed manager
│   ├── QuickToggle.qml            # Drawer quick toggle
│   ├── BarWidget.qml              # Status bar widget
│   ├── caelestia-news-feed        # CLI activation launcher
│   ├── install.sh                 # Individual plugin installer
│   ├── uninstall.sh               # Individual plugin uninstaller
│   ├── main.qml                   # Quickshell standalone runner
│   ├── qmldir                     # QML module export definitions
│   └── README.md                  # Documentation
│
├── text-extractor/                # Text Extractor OCR Plugin (Self-contained)
│   ├── manifest.json              # Plugin manifest
│   ├── settings.json              # User preferences & OCR history
│   ├── extract.sh                 # Native Wayland OCR pipeline runner
│   ├── caelestia-text-extractor   # CLI activation launcher
│   ├── TextUtils.js               # String formatting utilities
│   ├── TextService.qml            # OCR process & state singleton
│   ├── TextExtractorCard.qml      # OCR inspector card UI
│   ├── TextExtractorWindow.qml    # Floating window component
│   ├── Settings.qml               # Nexus Settings page
│   ├── QuickToggle.qml            # Drawer quick toggle
│   ├── BarWidget.qml              # Status bar widget
│   ├── install.sh                 # Individual plugin installer
│   ├── uninstall.sh               # Individual plugin uninstaller
│   ├── main.qml                   # Quickshell standalone runner
│   ├── qmldir                     # QML module export definitions
│   └── README.md                  # Documentation
│
├── install.sh                     # Master universal installer for any device
├── uninstall.sh                   # Master universal uninstaller
├── scan-plugins.py                # Dynamic multi-path plugin discovery scanner
├── .gitignore                     # Git ignore rules
└── README.md                      # Suite overview & installation guide
```

---

## ⌨️ Shortcuts & CLI Commands

| Plugin | Keybinding | CLI Trigger | Description |
| :--- | :--- | :--- | :--- |
| **Color Picker** | `SUPER + SHIFT + C` | `caelestia-color-picker` | Pick color on screen & open inspector |
| **Text Extractor** | `SHIFT + SUPER + T` | `caelestia-text-extractor` | Drag region & extract OCR text |
| **News Feed** | — | `caelestia-news-feed` | Open news sidebar (`open`, `next`, `reload`) |

---

## 🛠️ Automated Device Implementation

When `install.sh` runs on any device, it automatically handles:
1. **Dependency Resolution**: Checks and auto-installs missing packages using `pacman`, `dnf`, `apt`, or `zypper`.
2. **Directory Resolution**: Creates standard `~/.config/caelestia/plugins/` and `~/.config/quickshell/caelestia/modules/`.
3. **Module Symlinks**: Connects Quickshell modules so `shell.qml` imports work immediately.
4. **CLI Launchers**: Copies executables to `~/.local/bin/` so they can be run from terminal or keybindings.
5. **State Activation**: Registers all plugins in `~/.config/caelestia/plugins-state.json`.
6. **Hyprland Rules**: Injects keybindings and floating/pinned window rules into `~/.config/caelestia/hypr-user.lua` or `~/.config/hypr/hyprland.conf`.
7. **Shell Integration**: Ensures IPC handlers and window wrappers in `shell.qml` are present.
8. **Nexus Settings**: Enables immediate management through **Nexus Settings -> System -> Plugins**.
