#!/usr/bin/env bash
# ==============================================================================
# Caelestia Plugins Suite - Universal Uninstaller
# Cleanly uninstalls Caelestia productivity plugins from this device
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/install.sh" --uninstall "$@"
