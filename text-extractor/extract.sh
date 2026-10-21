#!/usr/bin/env bash
# extract.sh - Native Wayland Screen OCR Pipeline for Caelestia Shell
# Components: slurp + grim + tesseract 5.5 + wl-copy + notify-send

set -eo pipefail

# Guard: Single instance lock to prevent duplicate overlays if key is repeated or pressed rapidly
LOCK_FILE="/tmp/caelestia-ocr.lock"
exec 200>"$LOCK_FILE"
if ! flock -n 200; then
    exit 0
fi

if pidof slurp >/dev/null 2>&1; then
    exec 200>&-
    exit 0
fi

# Default configuration (can be overridden via environment variables or CLI flags)
LANG_CODE="${OCR_LANG:-eng}"
PSM_MODE="${OCR_PSM:-3}"
SINGLE_LINE="${OCR_SINGLE_LINE:-false}"
AUTO_COPY="${OCR_AUTO_COPY:-true}"
SEND_NOTIFY="${OCR_NOTIFY:-true}"
BORDER_COLOR="${SLURP_BORDER:-#89B4FAff}"
BG_COLOR="${SLURP_BG:-#0000002b}"
SELECTION_COLOR="${SLURP_SELECTION:-#89B4FA22}"

# Parse command line flags
while [[ $# -gt 0 ]]; do
    case "$1" in
        -l|--lang)
            LANG_CODE="$2"
            shift 2
            ;;
        -p|--psm)
            PSM_MODE="$2"
            shift 2
            ;;
        -s|--single-line)
            SINGLE_LINE="true"
            shift
            ;;
        -m|--multi-line)
            SINGLE_LINE="false"
            shift
            ;;
        --no-copy)
            AUTO_COPY="false"
            shift
            ;;
        --no-notify)
            SEND_NOTIFY="false"
            shift
            ;;
        -g|--geometry)
            GEOMETRY="$2"
            shift 2
            ;;
        --border)
            BORDER_COLOR="$2"
            shift 2
            ;;
        --bg)
            BG_COLOR="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

# Normalize color hex codes to #rrggbbaa for slurp compatibility
if [[ "$BORDER_COLOR" =~ ^#[0-9a-fA-F]{6}$ ]]; then
    BORDER_COLOR="${BORDER_COLOR}ff"
fi
if [[ "$BG_COLOR" =~ ^#[0-9a-fA-F]{6}$ ]]; then
    BG_COLOR="${BG_COLOR}44"
fi
if [[ "$SELECTION_COLOR" =~ ^#[0-9a-fA-F]{6}$ ]]; then
    SELECTION_COLOR="${SELECTION_COLOR}22"
fi

# Step 1: Area Selection via slurp (if geometry not already provided)
if [ -z "$GEOMETRY" ]; then
    GEOMETRY=$(slurp -d -b "$BG_COLOR" -c "$BORDER_COLOR" -s "$SELECTION_COLOR" -w 2 2>/dev/null) || {
        # User cancelled selection (e.g. pressed Escape or clicked outside)
        flock -u 200 2>/dev/null || true
        exec 200>&-
        exit 0
    }
fi

# Release selection lock immediately so subsequent child processes never inherit it
flock -u 200 2>/dev/null || true
exec 200>&-

if [ -z "$GEOMETRY" ]; then
    exit 0
fi

# Step 2: Screen Capture via grim
TMP_DIR=$(mktemp -d /tmp/caelestia-ocr.XXXXXX)
trap 'rm -rf "$TMP_DIR"' EXIT INT TERM

IMG_FILE="$TMP_DIR/capture.png"
if ! grim -g "$GEOMETRY" "$IMG_FILE" 2>/dev/null; then
    echo "ERROR: grim failed to capture screen" >&2
    exit 3
fi

# Check if Tesseract is installed
if ! command -v tesseract >/dev/null 2>&1; then
    # Copy captured image to clipboard as fallback so user doesn't lose their selection
    wl-copy -t image/png < "$IMG_FILE" 2>/dev/null || true
    MSG="Area captured. Tesseract OCR is not installed. Run: sudo pacman -S tesseract tesseract-data-eng"
    echo "ERROR: $MSG" >&2
    command -v notify-send >/dev/null 2>&1 && notify-send -a "Text Extractor" -u critical "Tesseract OCR Missing" "Selected area copied as image. To enable text extraction run:\nsudo pacman -S tesseract tesseract-data-eng"
    exit 2
fi

# Step 3: OCR via tesseract
RAW_TEXT=$(tesseract "$IMG_FILE" stdout -l "$LANG_CODE" --psm "$PSM_MODE" 2>/dev/null) || {
    echo "ERROR: tesseract failed to parse image" >&2
    exit 4
}

# Post-processing: trim leading/trailing whitespace
CLEANED_TEXT=$(echo "$RAW_TEXT" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

# Condense newlines if single-line mode is active
if [ "$SINGLE_LINE" = "true" ]; then
    CLEANED_TEXT=$(echo "$CLEANED_TEXT" | tr '\n' ' ' | tr -s ' ' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
fi

# Check if text was found
if [ -z "$CLEANED_TEXT" ]; then
    if [ "$SEND_NOTIFY" = "true" ]; then
        notify-send -a "Text Extractor" -u low "No Text Found" "No readable text detected in the selected area."
    fi
    exit 0
fi

# Step 4: Wayland Clipboard synchronization via wl-copy
if [ "$AUTO_COPY" = "true" ]; then
    printf "%s" "$CLEANED_TEXT" | wl-copy
    printf "%s" "$CLEANED_TEXT" | wl-copy -p 2>/dev/null || true
fi

# Step 5: Desktop notification via notify-send with snippet preview
if [ "$SEND_NOTIFY" = "true" ]; then
    SNIPPET="${CLEANED_TEXT:0:80}"
    if [ ${#CLEANED_TEXT} -gt 80 ]; then
        SNIPPET="${SNIPPET}..."
    fi
    SNIPPET_ONE_LINE=$(echo "$SNIPPET" | tr '\n' ' ' | tr -s ' ')
    notify-send -a "Text Extractor" -i "edit-copy" "Text Extracted & Copied" "$SNIPPET_ONE_LINE"
fi

# Step 6: Synchronize with running Caelestia Shell daemon (if active)
qs -c caelestia ipc call textExtractor update "$CLEANED_TEXT" 2>/dev/null || true

# Emit full cleaned text to stdout for callers
printf "%s" "$CLEANED_TEXT"
