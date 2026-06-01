---
description: Checkpoint the current session into the global daily session log. Idempotent, append-only, safe to run multiple times and before /compact.
allowed-tools: Bash, Read, Write, Edit
---

You are checkpointing the current Claude Code session into a persistent global session log so context survives `/compact`, `/clear`, and session boundaries. ONE file per day, all projects merged, each entry tagged with its project.

Paths use `${CLAUDE_CONFIG_DIR:-$HOME/.claude}` (resolve via shell, do not hardcode).

## Steps

1. **Resolve paths**
   - `MEM_ROOT="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/memory"`
   - `LOG="$MEM_ROOT/sessions/$(date +%Y-%m-%d).md"` (GLOBAL, all projects)
   - Project tag: derive from `$PWD`. Use the basename of the workspace dir, e.g. `~/workspace/myapp` -> `myapp`, `~/workspace/myapp/api` -> `api`, `~/worktrees/<branch>/api` -> `api`. Take the deepest meaningful component (the actual repo or workspace name, not branch/worktree dir).

2. **Find the transcript file** for the current session.
   - **If the user message includes "transcript path: <path>"** (passed by the auto-checkpoint hook), use that exact path. Skip the discovery step. Also extract `cwd` from the message and use it for the project tag.
   - Otherwise, look in `~/.claude/projects/` and `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects/` under the encoded cwd directory (path with `/` replaced by `-`).
   - Pick the most recently modified `.jsonl` file in that directory; that's the current session.
   - The filename without `.jsonl` is the session id.
   - If you can't find a transcript, fall back to introspecting your own conversation context (lossy but better than nothing). Note this in the log entry.

3. **Per-transcript watermark**
   - `WATERMARK="$MEM_ROOT/sessions/.watermark-<session-id>"` (derived from transcript filename, NOT shared across sessions).
   - Read the integer line number from it (default 0 if missing).
   - Compute current line count via `wc -l < transcript`.
   - If no new lines, append `## HH:MM [<project>] — no-op (no new activity)` to `$LOG` and exit.

4. **Summarize the new content** into this exact format. Be terse. Pairing chat tone, no filler.

   ```
   ## HH:MM [<project>] — <3-7 word title>

   **Did:** <what actually happened, 1-3 bullets>
   **Decided:** <decisions or "none">
   **Open:** <unresolved questions / next step or "none">
   **Touched:** <files/repos changed or "none">
   **Worth remembering:** <one line that future-you would want, or "nothing">
   ```

   Rules:
   - Project tag in the header is mandatory. Use square brackets so it's grep-able: `grep '\[myapp\]' sessions/*.md`.
   - Skip filler ("we discussed", "the user asked"). Just facts.
   - If a section is empty, write "none" — don't omit the line.
   - "Worth remembering" is the signal for the daily rollup. Be ruthless: most sessions have nothing.
   - No emojis. No em-dashes.

5. **Append** the block to `$LOG` (create file with `# Sessions YYYY-MM-DD` header if missing).

6. **Update watermark** to the current last-line-number of the transcript.

7. Confirm with one line: `Logged to <path> [<project>] (N new lines processed)`.

## Notes

- Global log: one file per day at `$MEM_ROOT/sessions/<date>.md`, mixing all projects you worked on that day. Project tag in header keeps things separable.
- Per-transcript watermark prevents parallel sessions fighting each other.
- Safe to run multiple times in the same session. Run before `/compact` to preserve pre-compact context.
- The daily rollup (`/rollup-day`) consumes this and distills into `$MEM_ROOT/daily/`.
