# Caelestia Color Picker Plugin

A **Windows PowerToys-inspired Color Picker** plugin for **Caelestia Shell** on **Hyprland**, powered by `hyprpicker`, `Quickshell`, and QtQuick.

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
./uninstall.sh   # or: ./install.sh --uninstall
```

The installer automatically:
- Detects missing dependencies (`hyprpicker`, `wl-clipboard`, `libnotify`) and offers to install them via your package manager (`pacman`, `dnf`, `apt`, `zypper`).
- Deploys the plugin to `~/.config/caelestia/plugins/color-picker`.
- Sets up the Quickshell module link in `~/.config/quickshell/caelestia/modules/colorpicker`.
- Installs the CLI trigger `caelestia-color-picker` into `~/.local/bin/`.
- Enables the plugin in `~/.config/caelestia/plugins-state.json`.
- Configures keybindings (`SUPER + SHIFT + C`) and floating window rules in `~/.config/caelestia/hypr-user.lua` or `~/.config/hypr/hyprland.conf`.

---

## ✨ Features

- 🎯 **Screen Color Picking**: Uses `hyprpicker` to capture any pixel on screen with optional zoom lens and custom radius.
- 🎨 **Multi-Format Inspector**:
  - **HEX**: `#3B82F6` (and clean `#`-free format)
  - **RGB**: `rgb(59, 130, 246)`
  - **HSL**: `hsl(217, 91%, 60%)`
  - **HSV**: `hsv(217, 76%, 96%)`
  - **CMYK**: `cmyk(76%, 47%, 0%, 4%)`
  - One-click copy for every format with visual checkmark feedback.
- 🏷️ **Color Name Identification**: Automatically identifies nearest color name using Euclidean RGB distance over a 100+ color dictionary.
- 🌓 **Shades & Tints Generator**: Generates 4 step tints and shades (2 lighter, 2 darker) matching PowerToys' luminance formula.
- 🎛️ **HSV / RGB Fine-Tuning**: Interactive sliders for Hue ($0^\circ-360^\circ$), Saturation ($0\%-100\%$), Value ($0\%-100\%$), and direct numeric inputs for Red, Green, and Blue channels.
- 📜 **Color History**: Remembers your recent colors, stored persistently in `color-picker-settings.json`. Click any swatch to inspect or re-copy.
- ⚙️ **Caelestia Settings Integration**: Native `Settings.qml` designed to plug directly into Caelestia's Nexus Settings app using `PageBase`, `ToggleRow`, `SliderRow`, and `SelectRow`.
- 🧩 **Multiple Shell Entry Points**:
  - **`Settings.qml`**: Nexus settings page.
  - **`ColorEditorWindow.qml`**: Floating desktop window / popup inspector.
  - **`BarWidget.qml`**: Compact taskbar component showing the active color swatch.
  - **`QuickToggle.qml`**: Caelestia Utilities drawer button for 1-click picking.

---

## 📁 File Structure

```text
color-picker/
├── manifest.json              # Caelestia plugin metadata & entry points
├── settings.json              # Default user config & color history
├── ColorUtils.js              # Pure JS color conversions & name lookup
├── ColorService.qml           # Core service (hyprpicker, wl-copy, notifications)
├── ColorEditorCard.qml        # PowerToys Inspector UI component
├── ColorEditorWindow.qml      # Floating desktop window
├── Settings.qml               # Caelestia Nexus Settings page
├── BarWidget.qml              # Taskbar swatch widget
├── QuickToggle.qml            # Utilities drawer quick toggle
├── caelestia-color-picker     # CLI launcher script
├── install.sh                 # Standalone installer for any Caelestia device
├── main.qml                   # Standalone test runner with Quickshell
├── qmldir                     # QML module definition
└── README.md                  # This documentation
```

---

## 🚀 Testing & Running

### 1. Standalone Preview
Preview the Color Picker inspector immediately with Quickshell:

```bash
qs -p main.qml
```

### 2. CLI Activation
Trigger picking or open the inspector anytime:

```bash
caelestia-color-picker
```

### 3. Hyprland Keybinding
Press `SUPER + SHIFT + C` (or configured shortcut).
