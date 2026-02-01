#!/usr/bin/env bash
set -euo pipefail

# Syncs Claude Code plugins to Cursor skills directory by copying files.
# Reads installed_plugins.json to find installed plugins and their skill paths.

CLAUDE_PLUGINS_DIR="$HOME/.claude/plugins"
CURSOR_SKILLS_DIR="$HOME/.cursor/skills"
INSTALLED_PLUGINS_FILE="$CLAUDE_PLUGINS_DIR/installed_plugins.json"
SYNC_MARKER=".cursor-sync"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

error() {
    log "ERROR: $*" >&2
}

# Check dependencies
if ! command -v jq &>/dev/null; then
    error "jq is required. Install with: brew install jq"
    exit 1
fi

# Check Cursor is installed
if [[ ! -d "$HOME/.cursor" ]]; then
    error "Cursor not installed (~/.cursor not found)"
    exit 1
fi

# Create skills directory if needed
mkdir -p "$CURSOR_SKILLS_DIR"

# Track managed skills in a temp file
managed_file=$(mktemp)
trap "rm -f $managed_file" EXIT

# Read installed plugins
if [[ ! -f "$INSTALLED_PLUGINS_FILE" ]]; then
    log "No installed plugins found"
    exit 0
fi

# Parse installed plugins and find skills
# Format: plugin_key = "plugin@marketplace", value = array of installs
log "Reading installed plugins..."
plugins=$(jq -r '.plugins | to_entries[] | .key as $key | .value[0] | "\($key)|\(.installPath)"' "$INSTALLED_PLUGINS_FILE" 2>/dev/null) || {
    error "Failed to parse $INSTALLED_PLUGINS_FILE"
    exit 1
}

while IFS='|' read -r plugin_key install_path; do
    [[ -z "$plugin_key" ]] && continue
    [[ -z "$install_path" ]] && continue

    skills_dir="$install_path/skills"
    [[ ! -d "$skills_dir" ]] && continue

    # Extract plugin name and marketplace from key (format: plugin@marketplace)
    plugin_name=$(echo "$plugin_key" | cut -d'@' -f1)
    marketplace=$(echo "$plugin_key" | cut -d'@' -f2)

    # Find all skills in this plugin
    for skill_dir in "$skills_dir"/*/; do
        [[ ! -d "$skill_dir" ]] && continue

        skill_name=$(basename "$skill_dir")
        target_dir="$CURSOR_SKILLS_DIR/$skill_name"

        # Handle naming conflicts with non-managed directories
        if [[ -d "$target_dir" ]] && [[ ! -f "$target_dir/$SYNC_MARKER" ]]; then
            # Use prefixed name for conflicts with user-created skills
            target_dir="$CURSOR_SKILLS_DIR/${marketplace}-${plugin_name}-${skill_name}"
            log "Conflict for $skill_name, using prefixed name"
        fi

        # Check if we need to update (source newer than marker)
        marker_file="$target_dir/$SYNC_MARKER"
        needs_update=false

        if [[ ! -d "$target_dir" ]]; then
            needs_update=true
        elif [[ ! -f "$marker_file" ]]; then
            needs_update=true
        else
            # Check if any source file is newer than marker
            if find "$skill_dir" -newer "$marker_file" -type f | grep -q .; then
                needs_update=true
            fi
        fi

        if $needs_update; then
            # Remove old copy if exists
            [[ -d "$target_dir" ]] && rm -rf "$target_dir"

            # Copy skill directory
            cp -R "$skill_dir" "$target_dir"

            # Create marker with source path for tracking
            echo "$skill_dir" > "$target_dir/$SYNC_MARKER"

            log "Copied: $skill_name <- $skill_dir"
        fi

        # Track managed skill
        echo "$target_dir" >> "$managed_file"
    done
done <<< "$plugins"

# Clean up orphaned copies (only those we created)
log "Cleaning orphaned skills..."
for dir in "$CURSOR_SKILLS_DIR"/*/; do
    [[ ! -d "$dir" ]] && continue

    dir="${dir%/}"
    dir_name=$(basename "$dir")
    marker_file="$dir/$SYNC_MARKER"

    # Only remove if it has our marker and we're not managing it anymore
    if [[ -f "$marker_file" ]]; then
        if ! grep -qx "$dir" "$managed_file" 2>/dev/null; then
            log "Removing orphaned skill: $dir_name"
            rm -rf "$dir"
        fi
    fi
done

log "Sync complete"
