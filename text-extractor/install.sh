#!/usr/bin/env bash
# ==============================================================================
# Caelestia Text Extractor (OCR) Plugin Installer
# Windows PowerToys-inspired Optical Character Recognition for Caelestia Shell
# ==============================================================================

set -e

PLUGIN_NAME="text-extractor"
PLUGIN_ID="caelestia-text-extractor"
MODULE_NAME="textextractor"
CLI_NAME="caelestia-text-extractor"
DEFAULT_SHORTCUT="SHIFT + SUPER + T"

# Resolve directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/caelestia"
PLUGINS_ROOT="$CONFIG_DIR/plugins"
PLUGIN_DEST="$PLUGINS_ROOT/$PLUGIN_NAME"
QS_ROOT="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/caelestia"
QS_MODULES="$QS_ROOT/modules"
QS_MODULE_DEST="$QS_MODULES/$MODULE_NAME"
BIN_DIR="$HOME/.local/bin"

# ANSI colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

log_info()  { echo -e "${CYAN}ℹ${NC} $1"; }
log_ok()    { echo -e "${GREEN}✔${NC} $1"; }
log_warn()  { echo -e "${YELLOW}⚠${NC} $1"; }
log_error() { echo -e "${RED}✖${NC} $1"; }
log_title() { echo -e "\n${BOLD}${BLUE}=== $1 ===${NC}\n"; }

MODE="copy"
UNINSTALL=false
ASSUME_YES=false

# Parse flags
while [[ $# -gt 0 ]]; do
    case "$1" in
        --link|-l)
            MODE="link"
            shift
            ;;
        --copy|-c)
            MODE="copy"
            shift
            ;;
        --uninstall|-u)
            UNINSTALL=true
            shift
            ;;
        --yes|-y)
            ASSUME_YES=true
            shift
            ;;
        --help|-h)
            echo "Usage: ./install.sh [OPTIONS]"
            echo "Options:"
            echo "  --link, -l       Symlink plugin files instead of copying (best for active development)"
            echo "  --copy, -c       Copy plugin files to Caelestia plugins dir (default, standalone)"
            echo "  --uninstall, -u  Uninstall the plugin completely"
            echo "  --yes, -y        Non-interactive mode; auto-accept prompts"
            echo "  --help, -h       Display this help message"
            exit 0
            ;;
        *)
            log_warn "Unknown option: $1"
            shift
            ;;
    esac
done

# ==============================================================================
# UNINSTALLATION
# ==============================================================================
if [ "$UNINSTALL" = true ]; then
    log_title "Uninstalling Caelestia Text Extractor"

    if [ -e "$PLUGIN_DEST" ]; then
        rm -rf "$PLUGIN_DEST"
        log_ok "Removed plugin directory: $PLUGIN_DEST"
    fi

    if [ -L "$QS_MODULE_DEST" ] || [ -d "$QS_MODULE_DEST" ]; then
        rm -rf "$QS_MODULE_DEST"
        log_ok "Removed Quickshell module: $QS_MODULE_DEST"
    fi

    if [ -f "$BIN_DIR/$CLI_NAME" ]; then
        rm -f "$BIN_DIR/$CLI_NAME"
        log_ok "Removed CLI launcher: $BIN_DIR/$CLI_NAME"
    fi

    # Update state file
    STATE_FILE="$CONFIG_DIR/plugins-state.json"
    if [ -f "$STATE_FILE" ]; then
        python3 -c "import json
try:
    p = '$STATE_FILE'
    with open(p, 'r') as f:
        d = json.load(f)
    if '$PLUGIN_ID' in d:
        del d['$PLUGIN_ID']
        with open(p, 'w') as f:
            json.dump(d, f, indent=2)
except Exception:
    pass" 2>/dev/null || true
        log_ok "Updated plugins-state.json"
    fi

    log_ok "Text Extractor plugin uninstalled successfully."
    exit 0
fi

# ==============================================================================
# INSTALLATION
# ==============================================================================
log_title "Installing Caelestia Text Extractor Plugin"

# Step 1: Check & install system dependencies
log_info "Checking system dependencies..."
DEPS_MISSING=()

command -v slurp >/dev/null 2>&1 || DEPS_MISSING+=("slurp")
command -v grim >/dev/null 2>&1 || DEPS_MISSING+=("grim")
command -v tesseract >/dev/null 2>&1 || DEPS_MISSING+=("tesseract")
command -v wl-copy >/dev/null 2>&1 || DEPS_MISSING+=("wl-clipboard")
command -v notify-send >/dev/null 2>&1 || DEPS_MISSING+=("libnotify")

# Check tesseract language data
if command -v tesseract >/dev/null 2>&1; then
    if ! tesseract --list-langs 2>&1 | grep -q "eng"; then
        DEPS_MISSING+=("tesseract-data-eng")
    fi
else
    DEPS_MISSING+=("tesseract-data-eng")
fi

if [ ${#DEPS_MISSING[@]} -gt 0 ]; then
    log_warn "Missing dependencies: ${DEPS_MISSING[*]}"
    
    # Detect package manager
    PKG_MGR=""
    INSTALL_CMD=""
    if command -v pacman >/dev/null 2>&1; then
        PKG_MGR="pacman"
        INSTALL_CMD="sudo pacman -S --needed ${DEPS_MISSING[*]}"
    elif command -v dnf >/dev/null 2>&1; then
        PKG_MGR="dnf"
        INSTALL_CMD="sudo dnf install -y ${DEPS_MISSING[*]}"
    elif command -v apt-get >/dev/null 2>&1; then
        PKG_MGR="apt"
        # Map tesseract-data-eng to tesseract-ocr-eng for Debian/Ubuntu
        APT_PKGS=()
        for p in "${DEPS_MISSING[@]}"; do
            [ "$p" = "tesseract-data-eng" ] && APT_PKGS+=("tesseract-ocr-eng") || APT_PKGS+=("$p")
        done
        INSTALL_CMD="sudo apt-get install -y ${APT_PKGS[*]}"
    elif command -v zypper >/dev/null 2>&1; then
        PKG_MGR="zypper"
        INSTALL_CMD="sudo zypper install -y ${DEPS_MISSING[*]}"
    fi

    if [ -n "$INSTALL_CMD" ]; then
        DO_INSTALL=false
        if [ "$ASSUME_YES" = true ]; then
            DO_INSTALL=true
        else
            read -p "Would you like to install missing dependencies now? [Y/n] " -r REPLY
            [[ "$REPLY" =~ ^[Yy]$ || -z "$REPLY" ]] && DO_INSTALL=true
        fi

        if [ "$DO_INSTALL" = true ]; then
            log_info "Running: $INSTALL_CMD"
            eval "$INSTALL_CMD" || log_warn "Package installation returned non-zero. Please install manually if needed."
        fi
    else
        log_warn "Could not auto-detect package manager. Please install: ${DEPS_MISSING[*]}"
    fi
else
    log_ok "All system dependencies satisfied (slurp, grim, tesseract, wl-clipboard, libnotify)."
fi

# Step 2: Ensure executable scripts
chmod +x "$SCRIPT_DIR/extract.sh" 2>/dev/null || true
[ -f "$SCRIPT_DIR/caelestia-text-extractor" ] && chmod +x "$SCRIPT_DIR/caelestia-text-extractor"

# Step 3: Ensure destination directories exist
mkdir -p "$PLUGINS_ROOT"
mkdir -p "$QS_MODULES"
mkdir -p "$BIN_DIR"
mkdir -p "$CONFIG_DIR"

# Step 4: Deploy plugin folder
if [ "$MODE" = "link" ]; then
    log_info "Symlinking plugin to $PLUGIN_DEST..."
    rm -rf "$PLUGIN_DEST"
    ln -sfn "$SCRIPT_DIR" "$PLUGIN_DEST"
else
    log_info "Copying plugin to $PLUGIN_DEST..."
    if [ "$SCRIPT_DIR" != "$PLUGIN_DEST" ]; then
        rm -rf "$PLUGIN_DEST"
        mkdir -p "$PLUGIN_DEST"
        cp -r "$SCRIPT_DIR"/* "$PLUGIN_DEST"/
    fi
fi
chmod +x "$PLUGIN_DEST/extract.sh" 2>/dev/null || true
log_ok "Plugin deployed to $PLUGIN_DEST"

# Step 5: Link Quickshell module
log_info "Configuring Quickshell module link..."
ln -sfn "$PLUGIN_DEST" "$QS_MODULE_DEST"
log_ok "Quickshell module linked: $QS_MODULE_DEST -> $PLUGIN_DEST"

# Ensure QS plugins folder is linked to Caelestia plugins folder
if [ ! -e "$QS_ROOT/plugins" ]; then
    ln -sfn "$PLUGINS_ROOT" "$QS_ROOT/plugins"
    log_ok "Linked Quickshell plugins directory to $PLUGINS_ROOT"
fi

# Step 6: Install CLI launcher
log_info "Installing CLI launcher: $BIN_DIR/$CLI_NAME..."
if [ -f "$SCRIPT_DIR/$CLI_NAME" ]; then
    cp "$SCRIPT_DIR/$CLI_NAME" "$BIN_DIR/$CLI_NAME"
else
    cat << 'EOF' > "$BIN_DIR/$CLI_NAME"
#!/bin/bash
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/caelestia"
SETTINGS_FILE="$CONFIG_DIR/text-extractor-settings.json"
SCRIPT_PATH="$CONFIG_DIR/plugins/text-extractor/extract.sh"

BEHAVIOR="extract_only"
if [ -f "$SETTINGS_FILE" ]; then
    VAL=$(grep -o '"activationBehavior"[[:space:]]*:[[:space:]]*"[^"]*"' "$SETTINGS_FILE" | head -1 | cut -d'"' -f4)
    [ -n "$VAL" ] && BEHAVIOR="$VAL"
fi

if [ "$BEHAVIOR" = "window_only" ]; then
    exec qs -c caelestia ipc call textExtractor toggle
else
    exec "$SCRIPT_PATH" "$@"
fi
EOF
fi
chmod +x "$BIN_DIR/$CLI_NAME"
log_ok "CLI launcher installed to $BIN_DIR/$CLI_NAME"

# Step 7: Initialize default settings if missing
SETTINGS_DEST="$CONFIG_DIR/text-extractor-settings.json"
if [ ! -f "$SETTINGS_DEST" ] && [ -f "$SCRIPT_DIR/settings.json" ]; then
    cp "$SCRIPT_DIR/settings.json" "$SETTINGS_DEST"
    log_ok "Initialized settings: $SETTINGS_DEST"
fi

# Step 8: Update plugins-state.json
STATE_FILE="$CONFIG_DIR/plugins-state.json"
python3 -c "import json
p = '$STATE_FILE'
try:
    with open(p, 'r') as f:
        d = json.load(f)
except Exception:
    d = {}
d['$PLUGIN_ID'] = True
with open(p, 'w') as f:
    json.dump(d, f, indent=2)
" 2>/dev/null || true
log_ok "Registered and enabled in $STATE_FILE"

# Step 9: Configure Hyprland keybinding & window rules
LUA_FILE="$CONFIG_DIR/hypr-user.lua"
HYPR_CONF="$HOME/.config/hypr/hyprland.conf"

if [ -f "$LUA_FILE" ]; then
    if ! grep -q "caelestia-text-extractor" "$LUA_FILE"; then
        log_info "Adding keybind & window rule to $LUA_FILE..."
        cat << 'EOF' >> "$LUA_FILE"

-- Caelestia Text Extractor Plugin
hl.bind("SHIFT + SUPER + T", hl.dsp.exec_cmd("caelestia-text-extractor"))
hl.window_rule({
    match = { title = "Caelestia Text Extractor" },
    float = true,
    pin = true,
    center = true,
})
EOF
        log_ok "Added keybinding ($DEFAULT_SHORTCUT) and window rule to $LUA_FILE"
    else
        log_ok "Keybind already present in $LUA_FILE"
    fi
elif [ -f "$HYPR_CONF" ]; then
    if ! grep -q "caelestia-text-extractor" "$HYPR_CONF"; then
        log_info "Adding keybind & window rule to $HYPR_CONF..."
        cat << 'EOF' >> "$HYPR_CONF"

# Caelestia Text Extractor Plugin
bind = SHIFT SUPER, T, exec, caelestia-text-extractor
windowrulev2 = float, title:^(Caelestia Text Extractor)$
windowrulev2 = pin, title:^(Caelestia Text Extractor)$
windowrulev2 = center, title:^(Caelestia Text Extractor)$
EOF
        log_ok "Added keybinding ($DEFAULT_SHORTCUT) and window rule to $HYPR_CONF"
    else
        log_ok "Keybind already present in $HYPR_CONF"
    fi
fi

# Step 10: Reload environment
if command -v hyprctl >/dev/null 2>&1; then
    hyprctl reload >/dev/null 2>&1 || true
fi

# Ensure scan-plugins.py exists in config
if [ ! -f "$CONFIG_DIR/scan-plugins.py" ] && [ -f "$SCRIPT_DIR/../scan-plugins.py" ]; then
    cp "$SCRIPT_DIR/../scan-plugins.py" "$CONFIG_DIR/scan-plugins.py"
    chmod +x "$CONFIG_DIR/scan-plugins.py"
fi

echo ""
log_ok "${BOLD}Text Extractor Plugin is now ready and installed!${NC}"
echo -e "  - Shortcut:    ${CYAN}$DEFAULT_SHORTCUT${NC}"
echo -e "  - CLI Command: ${CYAN}$CLI_NAME${NC}"
echo -e "  - Direct OCR:  ${CYAN}$PLUGIN_DEST/extract.sh${NC}"
echo -e "  - Settings:    Open Caelestia Nexus Settings -> System -> Plugins"
echo ""
