#!/usr/bin/env bash
set -euo pipefail

# Installs or uninstalls the cursor-sync launchd service.
# Usage: install-service.sh [install|uninstall|status]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WATCH_SCRIPT="$SCRIPT_DIR/watch.sh"
SERVICE_NAME="com.santos.cursor-sync"
PLIST_PATH="$HOME/Library/LaunchAgents/$SERVICE_NAME.plist"
LOG_DIR="$HOME/Library/Logs"

log() {
    echo "[cursor-sync] $*"
}

error() {
    log "ERROR: $*" >&2
}

install_service() {
    # Check dependencies
    if ! command -v fswatch &>/dev/null; then
        error "fswatch is required. Install with: brew install fswatch"
        exit 1
    fi

    if ! command -v jq &>/dev/null; then
        error "jq is required. Install with: brew install jq"
        exit 1
    fi

    # Ensure watch script is executable
    chmod +x "$WATCH_SCRIPT"
    chmod +x "$SCRIPT_DIR/sync.sh"

    # Create LaunchAgents directory if needed
    mkdir -p "$HOME/Library/LaunchAgents"
    mkdir -p "$LOG_DIR"

    # Unload existing service if present
    if launchctl list | grep -q "$SERVICE_NAME"; then
        log "Stopping existing service..."
        launchctl unload "$PLIST_PATH" 2>/dev/null || true
    fi

    # Generate plist with absolute paths
    cat > "$PLIST_PATH" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$SERVICE_NAME</string>
    <key>ProgramArguments</key>
    <array>
        <string>$WATCH_SCRIPT</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$LOG_DIR/cursor-sync.log</string>
    <key>StandardErrorPath</key>
    <string>$LOG_DIR/cursor-sync.log</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin</string>
    </dict>
</dict>
</plist>
EOF

    # Load service
    launchctl load "$PLIST_PATH"

    log "Service installed and started"
    log "Logs: $LOG_DIR/cursor-sync.log"
    log "To check status: $0 status"
    log "To uninstall: $0 uninstall"
}

uninstall_service() {
    if [[ -f "$PLIST_PATH" ]]; then
        log "Stopping service..."
        launchctl unload "$PLIST_PATH" 2>/dev/null || true
        rm "$PLIST_PATH"
        log "Service uninstalled"
    else
        log "Service not installed"
    fi
}

show_status() {
    if launchctl list | grep -q "$SERVICE_NAME"; then
        log "Service is running"
        launchctl list "$SERVICE_NAME"

        log ""
        log "Recent logs:"
        tail -10 "$LOG_DIR/cursor-sync.log" 2>/dev/null || log "No logs yet"
    else
        log "Service is not running"
        [[ -f "$PLIST_PATH" ]] && log "Plist exists but service not loaded"
    fi
}

case "${1:-install}" in
    install)
        install_service
        ;;
    uninstall)
        uninstall_service
        ;;
    status)
        show_status
        ;;
    *)
        echo "Usage: $0 [install|uninstall|status]"
        exit 1
        ;;
esac
