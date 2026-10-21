#!/usr/bin/env bash
# ==============================================================================
# Caelestia Plugins Suite - Universal Master Installer
# Installs and configures productivity plugins on ANY device running Caelestia Shell
#
# Supported Plugins:
#   1. color-picker   - Windows PowerToys-inspired Color Picker & format inspector
#   2. text-extractor - Windows PowerToys-inspired Screen OCR text extractor
#   3. news-feed      - RSS & Atom news feed manager and live reader
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/caelestia"
PLUGINS_ROOT="$CONFIG_DIR/plugins"
QS_ROOT="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/caelestia"
BIN_DIR="$HOME/.local/bin"

# ANSI styling
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m' # No Color

AVAILABLE_PLUGINS=("color-picker" "text-extractor" "news-feed")

log_info()  { echo -e "${CYAN}ℹ${NC} $1"; }
log_ok()    { echo -e "${GREEN}✔${NC} $1"; }
log_warn()  { echo -e "${YELLOW}⚠${NC} $1"; }
log_error() { echo -e "${RED}✖${NC} $1"; }
log_title() { echo -e "\n${BOLD}${BLUE}=== $1 ===${NC}\n"; }

print_banner() {
    echo -e "${MAGENTA}${BOLD}"
    echo "  ╔═══════════════════════════════════════════════════════════╗"
    echo "  ║                CAELESTIA PLUGINS SUITE                   ║"
    echo "  ║       PowerToys-Inspired Productivity for Hyprland        ║"
    echo "  ╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

show_help() {
    print_banner
    echo "Usage: ./install.sh [COMMAND|PLUGIN] [OPTIONS]"
    echo ""
    echo "Commands / Target Plugins:"
    echo "  all                  Install all available plugins (default)"
    echo "  color-picker         Install only the Color Picker plugin"
    echo "  text-extractor       Install only the Text Extractor (OCR) plugin"
    echo "  news-feed            Install only the News Feed plugin"
    echo "  --check, -s          Check dependencies and status of all plugins"
    echo "  --uninstall, -u      Uninstall one or all plugins (e.g. ./install.sh -u all)"
    echo ""
    echo "Options:"
    echo "  --link, -l           Symlink plugin folders instead of copying (best for git repos)"
    echo "  --copy, -c           Copy plugin files (default, standalone on any device)"
    echo "  --yes, -y            Non-interactive mode; auto-accept dependency installations"
    echo "  --help, -h           Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./install.sh                     # Install all plugins"
    echo "  ./install.sh text-extractor      # Install only Text Extractor"
    echo "  ./install.sh -y all              # Install all without prompts"
    echo "  ./install.sh --uninstall all     # Cleanly uninstall all plugins"
    echo "  ./install.sh --check             # Check system status"
    echo ""
}

# ==============================================================================
# STATUS CHECK
# ==============================================================================
check_status() {
    print_banner
    log_title "System & Plugins Status"

    echo -e "${BOLD}Checking System Tools & Binaries:${NC}"
    check_bin() {
        local name="$1"
        local pkg="$2"
        if command -v "$name" >/dev/null 2>&1; then
            echo -e "  [${GREEN}OK${NC}] $name ($(command -v "$name"))"
        else
            echo -e "  [${RED}MISSING${NC}] $name (Package: ${YELLOW}$pkg${NC})"
        fi
    }

    check_bin "hyprpicker" "hyprpicker"
    check_bin "grim" "grim"
    check_bin "slurp" "slurp"
    check_bin "tesseract" "tesseract"
    check_bin "wl-copy" "wl-clipboard"
    check_bin "notify-send" "libnotify"
    check_bin "curl" "curl"
    check_bin "xdg-open" "xdg-utils"
    check_bin "caelestia" "caelestia"
    check_bin "qs" "quickshell"

    echo ""
    echo -e "${BOLD}Checking Plugin Installations in ~/.config/caelestia/plugins:${NC}"
    for p in "${AVAILABLE_PLUGINS[@]}"; do
        if [ -d "$PLUGINS_ROOT/$p" ]; then
            if [ -L "$PLUGINS_ROOT/$p" ]; then
                echo -e "  [${GREEN}INSTALLED${NC}] $p ${DIM}(symlink -> $(readlink "$PLUGINS_ROOT/$p"))${NC}"
            else
                echo -e "  [${GREEN}INSTALLED${NC}] $p (standalone copy)"
            fi
        else
            echo -e "  [${YELLOW}NOT INSTALLED${NC}] $p"
        fi
    done

    echo ""
    echo -e "${BOLD}Checking CLI Launchers in ~/.local/bin:${NC}"
    for b in "caelestia-color-picker" "caelestia-text-extractor" "caelestia-news-feed"; do
        if [ -x "$BIN_DIR/$b" ]; then
            echo -e "  [${GREEN}OK${NC}] $b"
        else
            echo -e "  [${YELLOW}NOT FOUND${NC}] $b"
        fi
    done
    echo ""
}

# ==============================================================================
# SHELL.QML INTEGRATION HELPER
# Ensures Quickshell shell.qml has required plugin imports & IPC handlers
# ==============================================================================
patch_shell_qml() {
    local shell_qml="$QS_ROOT/shell.qml"
    if [ ! -f "$shell_qml" ]; then
        return 0
    fi

    local modified=false

    # Check and add imports
    if ! grep -q 'modules/colorpicker' "$shell_qml" || ! grep -q 'modules/textextractor' "$shell_qml" || ! grep -q 'modules/newsfeed' "$shell_qml"; then
        log_info "Ensuring plugin modules are imported in $shell_qml..."
        cp "$shell_qml" "$shell_qml.bak.$(date +%s)"
        
        # Insert module imports right before Quickshell.Services or ShellRoot
        python3 -c "
import sys, re
path = '$shell_qml'
with open(path, 'r') as f:
    content = f.read()

imports = [
    'import \"modules/colorpicker\"',
    'import \"modules/textextractor\"',
    'import \"modules/newsfeed\"'
]

for imp in imports:
    if imp not in content:
        # insert after last import
        m = re.findall(r'^import\s+.*$', content, re.MULTILINE)
        if m:
            last_imp = m[-1]
            content = content.replace(last_imp, last_imp + '\n' + imp, 1)

with open(path, 'w') as f:
    f.write(content)
" 2>/dev/null || true
        modified=true
    fi

    # Check and add IPC handlers & Window declarations before final closing brace
    if ! grep -q 'target: "colorPicker"' "$shell_qml" || ! grep -q 'target: "textExtractor"' "$shell_qml" || ! grep -q 'target: "newsFeed"' "$shell_qml"; then
        log_info "Adding plugin IPC handlers to $shell_qml..."
        [ "$modified" = false ] && cp "$shell_qml" "$shell_qml.bak.$(date +%s)"

        python3 -c "
import sys
path = '$shell_qml'
with open(path, 'r') as f:
    content = f.read()

last_brace = content.rfind('}')
if last_brace != -1:
    snippet = '''
    // ==========================================
    // Caelestia Plugins Suite IPC Handlers
    // ==========================================
    ColorEditorWindow {
        id: colorPickerWindow
        colorService: ColorService
    }

    IpcHandler {
        target: \"colorPicker\"

        function open(hex: string): void {
            if (hex && hex.length > 0) {
                ColorService.setColor(hex);
            }
            ColorService.editorVisible = true;
        }

        function close(): void {
            ColorService.editorVisible = false;
        }

        function toggle(): void {
            ColorService.editorVisible = !ColorService.editorVisible;
        }

        function pick(): void {
            ColorService.pickColor();
        }

        function trigger(): void {
            ColorService.triggerActivation();
        }
    }

    TextExtractorWindow {
        id: textExtractorWindow
        textService: TextService
    }

    IpcHandler {
        target: \"textExtractor\"

        function open(text: string): void {
            if (text && text.length > 0) {
                TextService.setText(text);
            }
            TextService.windowVisible = true;
        }

        function update(text: string): void {
            if (text && text.length > 0) {
                TextService.setText(text);
            }
            if (TextService.activationBehavior === \"extract_and_window\" || (TextService.openWindowOnExtract && TextService.activationBehavior !== \"extract_only\")) {
                TextService.windowVisible = true;
            }
        }

        function close(): void {
            TextService.windowVisible = false;
        }

        function toggle(): void {
            TextService.windowVisible = !TextService.windowVisible;
        }

        function extract(): void {
            TextService.extractText();
        }

        function trigger(): void {
            TextService.triggerActivation();
        }
    }

    Process {
        id: caelestiaPluginShellProc
        command: [\"true\"]
    }

    IpcHandler {
        target: \"newsFeed\"

        function reload(): void {
            NewsService.reloadFeeds();
        }

        function next(): void {
            NewsService.nextFeed();
        }

        function open(): void {
            caelestiaPluginShellProc.command = [\"caelestia\", \"shell\", \"drawers\", \"toggleTab\", \"sidebar\", \"news\"];
            caelestiaPluginShellProc.running = true;
        }
    }
'''
    new_content = content[:last_brace] + snippet + content[last_brace:]
    with open(path, 'w') as f:
        f.write(new_content)
" 2>/dev/null || true
        log_ok "Injected IPC handlers into $shell_qml"
    fi
}

# ==============================================================================
# MAIN INSTALL LOGIC
# ==============================================================================
MODE="copy"
UNINSTALL=false
ASSUME_YES=false
TARGETS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        all)
            TARGETS=("${AVAILABLE_PLUGINS[@]}")
            shift
            ;;
        color-picker|text-extractor|news-feed)
            TARGETS+=("$1")
            shift
            ;;
        --check|-s|status|check)
            check_status
            exit 0
            ;;
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
            show_help
            exit 0
            ;;
        *)
            log_warn "Unknown argument: $1"
            shift
            ;;
    esac
done

# Default to 'all' if no specific plugin specified
if [ ${#TARGETS[@]} -eq 0 ]; then
    TARGETS=("${AVAILABLE_PLUGINS[@]}")
fi

print_banner

# ==============================================================================
# UNINSTALL MODE
# ==============================================================================
if [ "$UNINSTALL" = true ]; then
    log_title "Uninstalling Caelestia Plugins: ${TARGETS[*]}"
    for target in "${TARGETS[@]}"; do
        if [ -f "$SCRIPT_DIR/$target/install.sh" ]; then
            bash "$SCRIPT_DIR/$target/install.sh" --uninstall
        elif [ -d "$PLUGINS_ROOT/$target" ]; then
            rm -rf "$PLUGINS_ROOT/$target"
            log_ok "Removed $PLUGINS_ROOT/$target"
        fi
    done
    log_ok "Uninstall completed."
    exit 0
fi

# ==============================================================================
# PREPARE ENVIRONMENT
# ==============================================================================
log_title "Preparing Environment on this Device"

mkdir -p "$CONFIG_DIR"
mkdir -p "$PLUGINS_ROOT"
mkdir -p "$QS_ROOT/modules"
mkdir -p "$BIN_DIR"

# Link QS plugins to Caelestia plugins if not already present
if [ ! -e "$QS_ROOT/plugins" ]; then
    ln -sfn "$PLUGINS_ROOT" "$QS_ROOT/plugins"
    log_ok "Linked Quickshell plugins directory -> $PLUGINS_ROOT"
fi

# Link QS modules/plugins to Caelestia plugins
if [ ! -e "$QS_ROOT/modules/plugins" ]; then
    ln -sfn "$PLUGINS_ROOT" "$QS_ROOT/modules/plugins"
    log_ok "Linked Quickshell modules/plugins -> $PLUGINS_ROOT"
fi

# Ensure scan-plugins.py is deployed to ~/.config/caelestia/
if [ -f "$SCRIPT_DIR/scan-plugins.py" ]; then
    cp "$SCRIPT_DIR/scan-plugins.py" "$CONFIG_DIR/scan-plugins.py"
    chmod +x "$CONFIG_DIR/scan-plugins.py"
    log_ok "Deployed portable scan-plugins.py to $CONFIG_DIR/scan-plugins.py"
fi

# Check PATH for ~/.local/bin
if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    log_warn "$BIN_DIR is not currently in your PATH!"
    log_info "Add this line to your ~/.bashrc or ~/.zshrc: export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

# ==============================================================================
# INSTALL TARGET PLUGINS
# ==============================================================================
log_title "Installing Plugins: ${TARGETS[*]}"

PASSED_FLAGS=()
[ "$MODE" = "link" ] && PASSED_FLAGS+=("--link") || PASSED_FLAGS+=("--copy")
[ "$ASSUME_YES" = true ] && PASSED_FLAGS+=("--yes")

for target in "${TARGETS[@]}"; do
    log_info "--> Processing plugin: ${BOLD}$target${NC}"
    if [ -f "$SCRIPT_DIR/$target/install.sh" ]; then
        bash "$SCRIPT_DIR/$target/install.sh" "${PASSED_FLAGS[@]}"
    else
        log_error "Installer not found for $target at $SCRIPT_DIR/$target/install.sh"
    fi
done

# Step: Ensure shell.qml integration
patch_shell_qml

# Step: Run plugin scanner to refresh registry
if [ -f "$CONFIG_DIR/scan-plugins.py" ]; then
    python3 "$CONFIG_DIR/scan-plugins.py" >/dev/null 2>&1 || true
    log_ok "Scanned and refreshed Caelestia plugin registry"
fi

# Step: Reload Hyprland and shell if active
if command -v hyprctl >/dev/null 2>&1; then
    hyprctl reload >/dev/null 2>&1 || true
    log_ok "Reloaded Hyprland configuration"
fi

echo ""
echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}       ALL REQUESTED CAELESTIA PLUGINS ARE INSTALLED & READY!           ${NC}"
echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${BOLD}Quick Access Shortcuts & Commands:${NC}"
echo -e "  🎨 ${BOLD}Color Picker:${NC}        ${CYAN}SUPER + SHIFT + C${NC}  or  ${YELLOW}caelestia-color-picker${NC}"
echo -e "  🔍 ${BOLD}Text Extractor:${NC}      ${CYAN}SHIFT + SUPER + T${NC}  or  ${YELLOW}caelestia-text-extractor${NC}"
echo -e "  📰 ${BOLD}News Feed:${NC}           ${CYAN}caelestia-news-feed${NC}  or  Sidebar -> News tab"
echo ""
echo -e "${BOLD}Nexus Settings Management:${NC}"
echo -e "  Open settings via sidebar or:  ${CYAN}caelestia shell nexus open${NC}"
echo -e "  Navigate to:                   ${BOLD}System${NC} -> ${BOLD}Plugins${NC}"
echo ""
