---
description: Show curator status — last run, candidate list, pins, pause state. Read-only.
allowed-tools: Bash, Read
argument-hint: [pause|resume|pin <name>|unpin <name>]
---

You are the curator status reporter. Paths use `${CLAUDE_CONFIG_DIR:-$HOME/.claude}`.

## Steps

1. Resolve paths:
   ```
   ROOT="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
   STATE="$ROOT/curator/state.json"
   ```

2. Handle the subcommand from `$ARGUMENTS`:

   - `pause`: set `state.json.paused = true`. Use `jq` if available, else write a fresh JSON if state is missing.
   - `resume`: set `paused = false`.
   - `pin <name>`: append `<name>` to `state.json.pinned[]` (dedupe). Refuse if the skill dir doesn't exist under `$ROOT/skills/`.
   - `unpin <name>`: remove from `pinned[]`.
   - empty / `status`: show the report below.

3. **Status report:**
   - Read state.json: last_run_at, last_mode, paused, pinned[]
   - Show "Last run: <ts> (<N days ago>) — <mode>"
   - Show "Paused: yes/no"
   - Show "Pinned: <comma list or 'none'>"
   - Run the candidate list script and show:
     - Total skills under `$ROOT/skills/`
     - Count by state (active / stale / archive-due)
     - Top 5 oldest skills (largest days-since-mtime) — these are likely targets for the next pass
     - Backup count under `$ROOT/curator/backups/`
   - Show "Next scheduled run: <Mon 09:00 Brisbane if launchd job is loaded, else 'not scheduled'>"

4. Output is human-readable. Group with short headers. Skip filler.

## Argument

$ARGUMENTS
