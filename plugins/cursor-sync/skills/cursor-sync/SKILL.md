---
name: cursor-sync
description: Syncs Claude Code plugins to Cursor skills directory. Manages symlinks and launchd watcher service.
---

# Cursor Sync

Syncs Claude Code plugins to Cursor's skills directory using symlinks. Changes to installed plugins are automatically detected and synced.

## Commands

Run these scripts from the plugin directory:

### Manual Sync
```bash
./scripts/sync.sh
```
Performs a one-time sync of all installed Claude Code plugins to `~/.cursor/skills/`.

### Start Watcher
```bash
./scripts/watch.sh
```
Watches for plugin changes and syncs automatically. Runs in foreground.

### Install as Service
```bash
./scripts/install-service.sh install
```
Installs a launchd service that starts on login and keeps syncing in the background.

### Check Service Status
```bash
./scripts/install-service.sh status
```

### Uninstall Service
```bash
./scripts/install-service.sh uninstall
```

## How It Works

1. Reads `~/.claude/plugins/installed_plugins.json` to find installed plugins
2. For each plugin, finds skills in `<install_path>/skills/`
3. Creates symlinks in `~/.cursor/skills/` pointing to the original skill directories
4. Handles naming conflicts by prefixing with `<marketplace>-<plugin>-<skill>`
5. Cleans up orphaned symlinks when plugins are uninstalled

## Dependencies

- `jq` for JSON parsing: `brew install jq`
- `fswatch` for file watching: `brew install fswatch`

## Logs

Service logs are written to `~/Library/Logs/cursor-sync.log`.
