#!/usr/bin/env bash
# ==============================================================================
# Caelestia News Feed Plugin Installer
# Live RSS/Atom News Reader & Aggregator for Caelestia Shell
# ==============================================================================

set -e

PLUGIN_NAME="news-feed"
PLUGIN_ID="caelestia-news-feed"
MODULE_NAME="newsfeed"
CLI_NAME="caelestia-news-feed"

# Resolve directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/caelestia"
PLUGINS_ROOT="$CONFIG_DIR/plugins"
PLUGIN_DEST="$PLUGINS_ROOT/$PLUGIN_NAME"
QS_ROOT="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/caelestia"
QS_MODULES="$QS_ROOT/modules"
QS_MODULE_DEST="$QS_MODULES/$MODULE_NAME"
QS_SIDEBAR="$QS_MODULES/sidebar"
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
    log_title "Uninstalling Caelestia News Feed"

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

    log_ok "News Feed plugin uninstalled successfully."
    exit 0
fi

# ==============================================================================
# INSTALLATION
# ==============================================================================
log_title "Installing Caelestia News Feed Plugin"

# Step 1: Check & install system dependencies
log_info "Checking system dependencies..."
DEPS_MISSING=()

command -v curl >/dev/null 2>&1 || DEPS_MISSING+=("curl")
command -v notify-send >/dev/null 2>&1 || DEPS_MISSING+=("libnotify")
command -v xdg-open >/dev/null 2>&1 || DEPS_MISSING+=("xdg-utils")

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
        INSTALL_CMD="sudo apt-get install -y ${DEPS_MISSING[*]}"
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
    log_ok "All system dependencies satisfied (curl, libnotify, xdg-utils)."
fi

# Step 2: Ensure destination directories exist
mkdir -p "$PLUGINS_ROOT"
mkdir -p "$QS_MODULES"
mkdir -p "$BIN_DIR"
mkdir -p "$CONFIG_DIR"

# Step 3: Deploy plugin folder
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
log_ok "Plugin deployed to $PLUGIN_DEST"

# Step 4: Link Quickshell module
log_info "Configuring Quickshell module link..."
ln -sfn "$PLUGIN_DEST" "$QS_MODULE_DEST"
log_ok "Quickshell module linked: $QS_MODULE_DEST -> $PLUGIN_DEST"

# Ensure QS plugins folder is linked to Caelestia plugins folder
if [ ! -e "$QS_ROOT/plugins" ]; then
    ln -sfn "$PLUGINS_ROOT" "$QS_ROOT/plugins"
    log_ok "Linked Quickshell plugins directory to $PLUGINS_ROOT"
fi

# Step 5: Check and install Sidebar News component if needed
if [ -d "$QS_SIDEBAR" ] && [ -f "$SCRIPT_DIR/News.qml" ]; then
    if [ ! -f "$QS_SIDEBAR/News.qml" ] || [ "$MODE" = "link" ]; then
        if [ "$MODE" = "link" ]; then
            ln -sfn "$PLUGIN_DEST/News.qml" "$QS_SIDEBAR/News.qml"
        else
            cp "$SCRIPT_DIR/News.qml" "$QS_SIDEBAR/News.qml"
        fi
        log_ok "Configured Sidebar News component: $QS_SIDEBAR/News.qml"
    fi
fi

# Step 6: Install CLI launcher
log_info "Installing CLI launcher: $BIN_DIR/$CLI_NAME..."
if [ -f "$SCRIPT_DIR/$CLI_NAME" ]; then
    cp "$SCRIPT_DIR/$CLI_NAME" "$BIN_DIR/$CLI_NAME"
else
    cat << 'EOF' > "$BIN_DIR/$CLI_NAME"
#!/bin/bash
ACTION="${1:-open}"
case "$ACTION" in
    open|toggle)
        qs -c caelestia ipc call newsFeed open 2>/dev/null || caelestia shell drawers toggleTab sidebar news 2>/dev/null || true
        ;;
    next)
        qs -c caelestia ipc call newsFeed next 2>/dev/null || true
        ;;
    reload)
        qs -c caelestia ipc call newsFeed reload 2>/dev/null || true
        ;;
    *)
        echo "Usage: $(basename "$0") [open|toggle|next|reload]"
        exit 1
        ;;
esac
EOF
fi
chmod +x "$BIN_DIR/$CLI_NAME"
log_ok "CLI launcher installed to $BIN_DIR/$CLI_NAME"

# Step 7: Initialize default news.json if missing
NEWS_JSON="$CONFIG_DIR/news.json"
if [ ! -f "$NEWS_JSON" ]; then
    cat << 'EOF' > "$NEWS_JSON"
[
  {
    "name": "Arch Linux News",
    "url": "https://archlinux.org/feeds/news/",
    "enabled": true,
    "icon": "terminal"
  },
  {
    "name": "Insider Gaming",
    "url": "https://insider-gaming.com/feed/",
    "enabled": true,
    "icon": "sports_esports"
  },
  {
    "name": "Android Authority",
    "url": "https://www.androidauthority.com/feed/",
    "enabled": true,
    "icon": "smartphone"
  },
  {
    "name": "GSMArena",
    "url": "https://www.gsmarena.com/rss-news-reviews.php3",
    "enabled": true,
    "icon": "phone_android"
  }
]
EOF
    log_ok "Initialized default feeds in $NEWS_JSON"
fi

# Step 8: Initialize default settings if missing
SETTINGS_DEST="$CONFIG_DIR/news-feed-settings.json"
if [ ! -f "$SETTINGS_DEST" ] && [ -f "$SCRIPT_DIR/settings.json" ]; then
    cp "$SCRIPT_DIR/settings.json" "$SETTINGS_DEST"
    log_ok "Initialized settings: $SETTINGS_DEST"
fi

# Step 9: Update plugins-state.json
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

# Step 10: Ensure scan-plugins.py exists in config
if [ ! -f "$CONFIG_DIR/scan-plugins.py" ] && [ -f "$SCRIPT_DIR/../scan-plugins.py" ]; then
    cp "$SCRIPT_DIR/../scan-plugins.py" "$CONFIG_DIR/scan-plugins.py"
    chmod +x "$CONFIG_DIR/scan-plugins.py"
fi

echo ""
log_ok "${BOLD}News Feed Plugin is now ready and installed!${NC}"
echo -e "  - CLI Command: ${CYAN}$CLI_NAME [open|next|reload]${NC}"
echo -e "  - Sidebar:     Open Caelestia Sidebar -> News Tab"
echo -e "  - Settings:    Open Caelestia Nexus Settings -> System -> Plugins"
echo ""
