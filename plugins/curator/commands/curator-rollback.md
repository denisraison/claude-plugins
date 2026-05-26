---
description: Restore the skill library from a curator snapshot. Defaults to newest. Use --list to see available snapshots.
allowed-tools: Bash, Read
argument-hint: [--list|--id <ts>|-y]
---

You are the curator rollback handler. Paths use `${CLAUDE_CONFIG_DIR:-$HOME/.claude}`.

## Steps

1. Resolve paths:
   ```
   ROOT="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
   BACKUP_ROOT="$ROOT/curator/backups"
   SKILLS_DIR="$ROOT/skills"
   ```

2. Parse `$ARGUMENTS`:
   - `--list`: list every dir under `$BACKUP_ROOT`, newest first. For each: timestamp, reason (from manifest.json), size_bytes. Then stop.
   - `--id <ts>`: target that specific snapshot.
   - empty: target newest.
   - `-y`: skip confirmation prompt.

3. If no snapshots exist: report "no curator backups under $BACKUP_ROOT" and stop.

4. Show what's about to happen:
   - Target snapshot path
   - Reason from manifest.json
   - Current `$SKILLS_DIR` size vs snapshot size
   - "This will replace `$SKILLS_DIR` with the snapshot. The current tree will be snapshotted first as 'pre-rollback to <target-id>' so this is reversible."
   - Wait for explicit "yes" unless `-y` was passed.

5. On confirmation, in order:
   ```
   # Snapshot the current state first (so rollback is reversible)
   bash <plugin>/scripts/pre-run-backup.sh "pre-rollback to $TARGET_ID"

   # Replace
   rm -rf "$SKILLS_DIR.rolling"
   mkdir -p "$SKILLS_DIR.rolling"
   tar -xzf "$BACKUP_ROOT/$TARGET_ID/skills.tar.gz" -C "$SKILLS_DIR.rolling"
   # tar archive contains a top-level "skills/" entry
   rm -rf "$SKILLS_DIR"
   mv "$SKILLS_DIR.rolling/skills" "$SKILLS_DIR"
   rmdir "$SKILLS_DIR.rolling"
   ```

6. Confirm: `Restored from $TARGET_ID. Previous state snapshotted as 'pre-rollback to $TARGET_ID' — restore that to roll forward again.`

## Safety

- Never delete `$SKILLS_DIR` without first taking the pre-rollback snapshot.
- Never rollback a snapshot that doesn't have a `manifest.json` — that's not a curator backup, treat as foreign.
- If the user passes a path instead of an id, refuse. Only accept ids that exist under `$BACKUP_ROOT/`.

## Argument

$ARGUMENTS
