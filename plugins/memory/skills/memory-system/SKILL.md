---
name: memory-system
description: Multi-layer memory system for sessions, daily rollups, and per-project knowledge via /recall, /rollup-day, /note-session commands
created_by: auto-improve
---

# Claude Memory System

A three-layer memory architecture for capturing session work, distilling daily patterns, and querying across projects.

## The three layers

| Layer | What's stored | Writer | Reader | Grain |
|---|---|---|---|---|
| **Raw sessions** | All turn-by-turn conversation, unchanged | `/note-session` (auto on PreCompact + SessionEnd via the memory plugin hook) | Raw JSONL grep (fallback in `/recall`) | Per-session |
| **Daily distilled** | Did/Decided/Open/Touched/Worth-remembering, deduplicated | `/rollup-day` (daily at 09:00 via launchd) | `/recall` (preferred for date ranges) | Per-day |
| **Per-project topical** | Class-level knowledge, setup docs, debugging guides | Auto-improve background review + user hand-written | `/recall` (project-scoped queries) | Class-level (umbrella skills) |

## Commands

### `/note-session` — checkpoint the current session

Runs automatically on `PreCompact` and `SessionEnd` via the memory plugin's hook (`hooks/checkpoint-session.sh`). Trivial `SessionEnd` events (under 50 new transcript lines) are skipped, and the checkpoint summarizes on Haiku by default. Appends a summary to `$CLAUDE_CONFIG_DIR/memory/sessions/<YYYY-MM-DD>.md` with:
- Timestamp (HH:MM)
- Project tag (`[project-name]`)
- Session title
- Did / Decided / Open / Touched sections
- Worth remembering bullet points (preserved verbatim)

No args. Re-runs are idempotent (appends to the daily file, don't overwrite).

### `/rollup-day [YYYY-MM-DD | yesterday | today]` — distill a full day

Compresses a day's raw session log into curated form. Defaults to yesterday.

Input: `$CLAUDE_CONFIG_DIR/memory/sessions/2026-05-25.md` (or whatever date you pass)
Output: `$CLAUDE_CONFIG_DIR/memory/daily/2026-05-25.md`

Format: By-project grouping, deduped Opens, worth-remembering excerpts (verbatim), high-level Touched list.

Compression: typically 4-6x (22KB session log → 7.6KB rollup).

Model: Sonnet (preserves idempotency, respects anti-capture rules). Fires idempotently (always overwrites, even if file exists).

**Scheduling:** Can fire daily (e.g. 09:00 local time) via launchd.

### `/recall [natural language question]` — search memory

Queries all three layers:
1. Daily distilled (preferred if available)
2. Raw session logs (fallback if no rollup exists for the date)
3. Per-project memory files (MEMORY.md + topical files)

Examples:
- `/recall "what was I doing yesterday in claude-plugins"`
- `/recall "what did we decide about JWT tokens"`
- `/recall "open items this week"`

Output: quoted excerpts with dates/project context.

## Anti-capture rules

`/rollup-day` and auto-improve's background review refuse to capture:

- **Negative tool claims** ("X tool is broken", "can't use Y") — these harden into self-imposed refusals that persist months after the tool is fixed
- **Session-specific one-off narratives** (summaries, analyses, task descriptions) — these decay fast and pollute the memory
- **Environment failures** (missing binaries, "command not found", unconfigured credentials) — the user can fix these; they're not durable rules
- **Transient errors that resolved before session end** — if retrying worked, the lesson is the retry pattern, not the original failure

What DOES get captured:
- Techniques (non-obvious workflows, tricky fixes)
- User preferences and frustrations (correct approach after user feedback)
- Decisions (why something was done a certain way)
- Lessons from errors (the insight gained, not the error itself)
- Worth-remembering insights (preserved verbatim from the raw session)

## Per-project isolation

Memory writes go to project-specific directories:
```
$CLAUDE_CONFIG_DIR/projects/<slug>/memory/
├── MEMORY.md          (index of all per-project topical files)
├── feedback_*.md      (lessons from user corrections)
├── project_*.md       (state of ongoing work)
└── user_*.md          (who this user is in this context)
```

The `/recall` command searches all projects and returns project-tagged results. Auto-improve and the background review write to the same dirs, so learned skills and memories integrate cleanly.

## Integration with auto-improve

The background review agent (from `auto-improve` plugin) writes to these same memory directories after every session. The review:
- Checks anti-capture rules (skips noisy one-offs, environment errors)
- Writes class-level skills to `$CLAUDE_CONFIG_DIR/skills/<name>/` (tagged `created_by: auto-improve`)
- Updates project memory files with durable lessons
- Respects per-project isolation

So memory and skills are two faces of the same system: memory captures who and what, skills capture how.

## See also

- `references/architecture.md` — detailed layer breakdown, directory structure, `/recall` search order
- `references/recall-search-patterns.md` — how `/recall` queries the three layers
