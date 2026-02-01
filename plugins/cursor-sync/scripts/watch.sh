#!/usr/bin/env bash
set -euo pipefail

# Watches for changes to installed_plugins.json and triggers sync.
# Uses fswatch for efficient file system monitoring.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYNC_SCRIPT="$SCRIPT_DIR/sync.sh"
WATCH_FILE="$HOME/.claude/plugins/installed_plugins.json"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

error() {
    log "ERROR: $*" >&2
}

# Check dependencies
if ! command -v fswatch &>/dev/null; then
    error "fswatch is required. Install with: brew install fswatch"
    exit 1
fi

if [[ ! -x "$SYNC_SCRIPT" ]]; then
    error "sync.sh not found or not executable at $SYNC_SCRIPT"
    exit 1
fi

# Initial sync
log "Running initial sync..."
"$SYNC_SCRIPT"

log "Watching $WATCH_FILE for changes..."
log "Press Ctrl+C to stop"

# Watch for changes and trigger sync
# -o outputs a single line per batch of changes (not per file)
# -l 2 sets latency to 2 seconds to batch rapid changes
fswatch -o -l 2 "$WATCH_FILE" | while read -r _; do
    log "Change detected, syncing..."
    "$SYNC_SCRIPT" || error "Sync failed"
done
