#!/usr/bin/env bash
set -euo pipefail

# Syncs Claude Code plugins to Cursor by copying skills and commands.
# Reads installed_plugins.json to find installed plugins.

CLAUDE_PLUGINS_DIR="$HOME/.claude/plugins"
CURSOR_SKILLS_DIR="$HOME/.cursor/skills"
CURSOR_COMMANDS_DIR="$HOME/.cursor/commands"
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

# Create target directories if needed
mkdir -p "$CURSOR_SKILLS_DIR"
mkdir -p "$CURSOR_COMMANDS_DIR"

# Track managed items in temp files
managed_skills=$(mktemp)
managed_commands=$(mktemp)
trap "rm -f $managed_skills $managed_commands" EXIT

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

    # Extract plugin name and marketplace from key (format: plugin@marketplace)
    plugin_name=$(echo "$plugin_key" | cut -d'@' -f1)
    marketplace=$(echo "$plugin_key" | cut -d'@' -f2)

    # Sync skills (directories)
    skills_dir="$install_path/skills"
    if [[ -d "$skills_dir" ]]; then
        for skill_dir in "$skills_dir"/*/; do
            [[ ! -d "$skill_dir" ]] && continue

            skill_name=$(basename "$skill_dir")
            target_dir="$CURSOR_SKILLS_DIR/$skill_name"

            # Handle naming conflicts with non-managed directories
            if [[ -d "$target_dir" ]] && [[ ! -f "$target_dir/$SYNC_MARKER" ]]; then
                target_dir="$CURSOR_SKILLS_DIR/${marketplace}-${plugin_name}-${skill_name}"
                log "Conflict for skill $skill_name, using prefixed name"
            fi

            # Check if we need to update (source newer than marker)
            marker_file="$target_dir/$SYNC_MARKER"
            needs_update=false

            if [[ ! -d "$target_dir" ]]; then
                needs_update=true
            elif [[ ! -f "$marker_file" ]]; then
                needs_update=true
            else
                if find "$skill_dir" -newer "$marker_file" -type f | grep -q .; then
                    needs_update=true
                fi
            fi

            if $needs_update; then
                [[ -d "$target_dir" ]] && rm -rf "$target_dir"
                cp -R "$skill_dir" "$target_dir"
                echo "$skill_dir" > "$target_dir/$SYNC_MARKER"
                log "Copied skill: $skill_name <- $skill_dir"
            fi

            echo "$target_dir" >> "$managed_skills"
        done
    fi

    # Sync commands (markdown files)
    commands_dir="$install_path/commands"
    if [[ -d "$commands_dir" ]]; then
        for cmd_file in "$commands_dir"/*.md; do
            [[ ! -f "$cmd_file" ]] && continue

            cmd_name=$(basename "$cmd_file")
            target_file="$CURSOR_COMMANDS_DIR/$cmd_name"

            # Handle naming conflicts with non-managed files
            if [[ -f "$target_file" ]]; then
                # Check if it's one we manage by looking for marker comment
                if ! head -1 "$target_file" 2>/dev/null | grep -q "^<!-- cursor-sync:"; then
                    target_file="$CURSOR_COMMANDS_DIR/${plugin_name}-${cmd_name}"
                    log "Conflict for command $cmd_name, using prefixed name"
                fi
            fi

            # Check if we need to update
            needs_update=false
            if [[ ! -f "$target_file" ]]; then
                needs_update=true
            elif [[ "$cmd_file" -nt "$target_file" ]]; then
                needs_update=true
            fi

            if $needs_update; then
                # Add marker comment and copy content
                {
                    echo "<!-- cursor-sync: $cmd_file -->"
                    cat "$cmd_file"
                } > "$target_file"
                log "Copied command: $cmd_name <- $cmd_file"
            fi

            echo "$target_file" >> "$managed_commands"
        done
    fi
done <<< "$plugins"

# Clean up orphaned skills (only those we created)
log "Cleaning orphaned skills..."
for dir in "$CURSOR_SKILLS_DIR"/*/; do
    [[ ! -d "$dir" ]] && continue

    dir="${dir%/}"
    dir_name=$(basename "$dir")
    marker_file="$dir/$SYNC_MARKER"

    if [[ -f "$marker_file" ]]; then
        if ! grep -qx "$dir" "$managed_skills" 2>/dev/null; then
            log "Removing orphaned skill: $dir_name"
            rm -rf "$dir"
        fi
    fi
done

# Clean up orphaned commands (only those we created)
log "Cleaning orphaned commands..."
for file in "$CURSOR_COMMANDS_DIR"/*.md; do
    [[ ! -f "$file" ]] && continue

    file_name=$(basename "$file")

    # Only remove if it has our marker and we're not managing it anymore
    if head -1 "$file" 2>/dev/null | grep -q "^<!-- cursor-sync:"; then
        if ! grep -qx "$file" "$managed_commands" 2>/dev/null; then
            log "Removing orphaned command: $file_name"
            rm -f "$file"
        fi
    fi
done

log "Sync complete"
