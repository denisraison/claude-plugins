# Memory System Architecture

## Directory structure

```
$CLAUDE_CONFIG_DIR/
├── memory/
│   ├── sessions/
│   │   └── 2026-05-25.md                    # Raw turn-by-turn, written by /note-session
│   │   └── 2026-05-26.md
│   └── daily/
│       └── 2026-05-25.md                    # Distilled, written by /rollup-day
│       └── 2026-05-26.md
│       └── .scheduler.log                   # Launchd output log
└── projects/
    ├── <slug-for-project-1>/
    │   └── memory/
    │       ├── MEMORY.md                    # Index of all topical files
    │       ├── feedback_*.md                # User-feedback lessons
    │       ├── project_*.md                 # Project state / milestones
    │       └── user_*.md                    # User profile / preferences in this context
    └── <slug-for-project-2>/
        └── memory/ [same structure]
```

## Layer details

### Raw sessions (per-day files)

**Path:** `$CLAUDE_CONFIG_DIR/memory/sessions/2026-05-25.md`

**Format:**
```
## 12:34 [project-name] — Session title
[raw text body with Did/Decided/Open/Touched/Worth-remembering sections]

## 15:20 [project-name] — Another session
[...]
```

**Writer:** `/note-session` — fires on `PreCompact` and `SessionEnd` via the plugin hook, appends to the day file. Trivial `SessionEnd` events (under 50 new transcript lines) are skipped.

**Size:** ~20-30KB per busy day, grows across the session.

**Reader:** `/recall` uses this as fallback when no distilled daily file exists. Also raw JSONL grep in the fallback path.

**Lifecycle:** Never deleted. Accumulate forever. Use `/rollup-day <date>` to create a distilled copy once a day is "done".

### Daily distilled (per-day files)

**Path:** `$CLAUDE_CONFIG_DIR/memory/daily/2026-05-25.md`

**Format:**
```markdown
# 2026-05-25 Rollup

## By project
- **project-1**
  - Sessions: N sessions, X hours
  - Did: [list]
  - Decided: [list]
  - Open at EOD: [list]
  - Touched: [high-level file/PR list]

- **project-2**
  - [same structure]

## Worth remembering (verbatim from today's sessions)
- Exact quote from session log, preserving original phrasing
- Another insight...

## (empty sections omitted)
```

**Writer:** `/rollup-day` — runs daily at 09:00 via launchd. Idempotent (always overwrites previous, even if file exists).

**Size:** ~7-10KB per day (4-6x compression of raw sessions).

**Reader:** `/recall` prefers this layer for date-range queries (much faster than grepping raw logs).

**Lifecycle:** One file per day. Manually created for past days via `cd ~ && for d in 2026-04-30 2026-05-01 ...; do /rollup-day $d; done` (backfill pattern).

### Per-project topical memory

**Path:** `$CLAUDE_CONFIG_DIR/projects/<slug>/memory/feedback_*.md` (etc.)

**Format:** YAML frontmatter (name, description, type: user/feedback/project/reference) + markdown body.

**Writers:**
- `/recall` slash command (when you explicitly `/recall "remember X"` or `/save-for-later`)
- Auto-improve background review (writes `created_by: auto-improve` skills + memories)
- User hand-written (via `/skill-creator` or manual file edits)

**Indexed by:** `MEMORY.md` in the same directory. One line per file: `- [Title](file.md) — short hook`.

**Reader:** `/recall` scopes queries to specific projects. Example: `/recall "what was I doing in project-X"`.

**Lifecycle:** Curated. Delete or consolidate as the project matures. Merging related files into umbrellas is encouraged (class-level skills, not narrow one-session entries).

## `/recall` search order

When you ask a question, `/recall`:

1. Checks if the query mentions a specific date or range (e.g., "yesterday", "last week", "2026-05-25")
   - If yes: search `memory/daily/` first, fall back to `memory/sessions/`
2. Checks if the query mentions a project name
   - If yes: search `projects/<slug>/memory/` first, then workspace-level memory
3. Otherwise: search all layers (daily distilled, then raw sessions, then per-project)

Output includes context tags (date, project, file) so you know where each result came from.

## Isolation and multi-project

Each project gets its own memory directory under `projects/<slug>/memory/`. Auto-improve and `/recall` both respect this isolation:

- Writes go to the project that triggered them (no cross-contamination)
- `/recall` returns project-tagged results so you know context
- You can query across projects ("what was I doing anywhere?") or within one ("what was I doing in this project?")

This prevents a busy project's memory from drowning out a quiet one.
