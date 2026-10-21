# Caelestia Text Extractor (OCR) Plugin

A **Windows PowerToys-inspired Optical Character Recognition (OCR) Text Extractor** for **Caelestia Shell** on **Hyprland** (Wayland), powered by `slurp`, `grim`, `tesseract 5.5`, and `Quickshell`.

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
- Detects missing dependencies (`slurp`, `grim`, `tesseract`, `tesseract-data-eng`, `wl-clipboard`, `libnotify`) and offers to install them via your package manager (`pacman`, `dnf`, `apt`, `zypper`).
- Deploys the plugin to `~/.config/caelestia/plugins/text-extractor`.
- Sets up the Quickshell module link in `~/.config/quickshell/caelestia/modules/textextractor`.
- Installs the CLI launcher `caelestia-text-extractor` into `~/.local/bin/`.
- Enables the plugin in `~/.config/caelestia/plugins-state.json`.
- Configures keybindings (`SHIFT + SUPER + T`) and floating window rules in `~/.config/caelestia/hypr-user.lua` or `~/.config/hypr/hyprland.conf`.

---

## ✨ Features

- 🎯 **Interactive Region Selection**: Drag a crosshair box over any screen area using `slurp` with customized translucent styling and smooth Wayland rendering.
- ⚡ **Instant In-Memory OCR Pipeline**: Screen snip captured via `grim` directly passed to `tesseract` with LSTM neural net models.
- 🌐 **Multi-Language OCR Support**: Compatible with English (`eng`), Spanish (`spa`), French (`fra`), German (`deu`), Japanese (`jpn`), Simplified Chinese (`chi_sim`), and all installed Tesseract tessdata languages.
- 📋 **Auto-Copy & Notifications**: Automatically copies extracted text to clipboard (`wl-copy`) and shows a notification banner (`notify-send`) with a snippet preview.
- 🛠️ **Multi-Format Formatter Toolbar**:
  - **Single Line**: Strips accidental OCR linebreaks and joins words with single spaces.
  - **Uppercase / Lowercase / Title Case**: Instant case normalization.
  - **JSON String Escaping**: Escapes quotes and special characters for code snippets.
  - **Markdown Code Block**: Wraps snippet in triple-backtick markdown blocks.
- 📜 **Extraction History**: Keeps your last 20 extractions with timestamp, character/word counters, and re-copy buttons.
- ⚙️ **Caelestia Settings Integration**: Native `Settings.qml` plugged directly into Caelestia's Nexus Settings app.
- 🧩 **Multiple Shell Entry Points**:
  - **`Settings.qml`**: Nexus settings page.
  - **`TextExtractorWindow.qml`**: Floating desktop window / popup inspector.
  - **`BarWidget.qml`**: Compact taskbar component with quick extract trigger.
  - **`QuickToggle.qml`**: Caelestia Utilities drawer button for 1-click OCR.
  - **`caelestia-text-extractor`**: Universal CLI launcher.

---

## 📁 File Structure

```text
text-extractor/
├── manifest.json              # Caelestia plugin metadata & entry points
├── settings.json              # Default user settings & OCR history
├── extract.sh                 # Standalone Wayland OCR runner script (executable)
├── caelestia-text-extractor   # CLI launcher script
├── TextUtils.js               # Pure JS formatting & case transformation
├── TextService.qml            # Core singleton service & process manager
├── TextExtractorCard.qml      # Main card component (toolbar, editor, history)
├── TextExtractorWindow.qml    # Floating desktop inspector window
├── Settings.qml               # Caelestia Nexus Settings page
├── BarWidget.qml              # Taskbar widget
├── QuickToggle.qml            # Utilities drawer quick toggle
├── install.sh                 # Standalone installer for any Caelestia device
├── main.qml                   # Standalone test runner with Quickshell
├── qmldir                     # QML module definition
└── README.md                  # This documentation
```

---

## 🚀 Testing & Running

### 1. Standalone Preview
Preview the Text Extractor inspector with Quickshell:

```bash
qs -p main.qml
```

### 2. Standalone CLI Extraction
Run the extraction pipeline directly from your terminal:

```bash
./extract.sh
```

Or with flags:
```bash
./extract.sh --single-line --lang eng
```

### 3. CLI Launcher
Trigger extraction or window toggle:

```bash
caelestia-text-extractor
```

### 4. Hyprland Keybinding
Press `SHIFT + SUPER + T` (or configured shortcut).
