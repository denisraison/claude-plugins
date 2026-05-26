---
description: Distill a day's raw session log into a compact daily rollup that /recall prefers. Default target is yesterday. Idempotent, overwrites the rollup file each run.
allowed-tools: Bash, Read, Write
model: sonnet
argument-hint: [YYYY-MM-DD or "yesterday" or "today"]
---

You are distilling a daily session log into a compact rollup. Paths use `${CLAUDE_CONFIG_DIR:-$HOME/.claude}` (resolve via shell, do not hardcode).

The raw log lives at `$MEM_ROOT/sessions/<date>.md`; your output goes to `$MEM_ROOT/daily/<date>.md`.

`/recall` prefers rollup files over raw session logs because they're already distilled. Most of recall's "what was I doing on X" queries should land here.

## Hard rules

- **You must Write the rollup file every run.** It is overwrite mode. Do not Read the existing rollup. Do not check whether it "looks complete". Do not skip the Write because today is the same as last time. If the raw session log exists, you write the rollup from it.
- The only valid no-write case is "no raw session log for this date" (handled in Step 2 below).
- Skipping the Write is a bug. The confirmation line on stdout must reflect what you actually wrote this run.

## Steps

1. **Resolve target date** from `$ARGUMENTS`:
   - Empty or `"yesterday"`: `date -v-1d +%Y-%m-%d` (mac) / `date -d "yesterday" +%Y-%m-%d` (linux)
   - `"today"`: `date +%Y-%m-%d`
   - Otherwise: the literal date string (validate `^\d{4}-\d{2}-\d{2}$`, refuse anything else)

1b. **Delete any existing rollup for this date** so there is nothing to short-circuit on. Run via Bash:
   ```
   MEM_ROOT="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/memory"
   rm -f "$MEM_ROOT/daily/<date>.md"
   ```
   Do not Read the file first. Do not check whether it exists. Just `rm -f`.

2. **Read the raw session log** at `$MEM_ROOT/sessions/<date>.md`.
   - If the file doesn't exist: write a single line to the rollup (`# Daily rollup <date>\n\n_No session log for this date._\n`) and stop.
   - If the file exists but has zero session entries: same as above.

3. **Distill into this format**, writing to `$MEM_ROOT/daily/<date>.md`:

   ```markdown
   # Daily rollup <date>

   ## By project

   ### <project-tag>
   - HH:MM <one-line summary of what happened, action-focused>
   - HH:MM <next session in this project>

   ### <other-project-tag>
   - ...

   ## Worth remembering

   - <verbatim from any session's "Worth remembering" that isn't "nothing">
   - <one bullet per real entry>

   ## Open at end of day

   - <unresolved items from "Open" sections, deduped, scoped>

   ## Touched

   - Repos / PRs / PEPs that saw activity (compact list, not every file)
   ```

   Rules:
   - One bullet per session in the By-project section. Keep summaries to one short line.
   - "Worth remembering" preserves the gold verbatim. These are the durable lessons; do not paraphrase or compress them.
   - "Open" should dedupe within the day. If three sessions all flag "PR #909 needs review", say it once.
   - "Touched" is high-level (repos, PRs, PEPs). Don't list every file.
   - Skip filler. No emojis, no em-dashes, no AI vocabulary ("orchestrated", "leveraged", "facilitated").
   - If a section would be empty, write `_none_` (still keep the heading so the format is stable for `/recall` grepping).

4. **Confirm with one line**: `Rolled up <date> -> <path> (N sessions across M projects)`.

## Notes

- Overwrite mode (not append). Re-running the same date refreshes the rollup. Safe to schedule daily.
- Read-only on `sessions/`. Never edits the raw log.
- The daily file is the long-tail memory. The session log accumulates across all days; the rollup is per-day and stable.
- If invoked from a scheduler with no TTY, the only output should be the confirmation line so log files stay clean.
