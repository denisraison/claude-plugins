# curator

Background skill-library maintenance. Weekly idle-gated pass that consolidates near-duplicate skills into umbrella skills with `references/`, `templates/`, and `scripts/` subfiles. Ported from [Hermes](https://github.com/NousResearch/hermes-agent)'s curator (proven pattern, MIT).

## Why

The auto-improve loop writes new skills as you work. Over weeks you end up with N narrow siblings that should have been one umbrella skill with N labeled subsections. An agent searching skills matches on descriptions, not names — discoverability dies as the library grows.

The curator runs a weekly pass that consolidates aggressively, with safety rails (pre-run tar.gz snapshot, one-command rollback, pin to protect, dry-run by default).

## Commands

- `/curate` — dry-run review. Writes a report describing what would change. No mutations.
- `/curate live` — live pass. Takes a snapshot first. Consolidates per the report.
- `/curator-status` — last run, candidate counts, pins, pause state.
- `/curator-status pause` / `resume` — toggle the scheduler gate.
- `/curator-status pin <name>` / `unpin <name>` — protect specific skills.
- `/curator-rollback` — restore newest snapshot. `--list` to inspect. `--id <ts>` for specific.

## What it touches

**Only** `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills/`. Never `plugins/*/skills/`. Never `.archive/`.

## State layout

```
$CLAUDE_CONFIG_DIR/curator/
├── state.json              # last_run_at, paused, pinned[]
├── backups/<UTC-ISO>/      # pre-run snapshots, kept to 5
│   ├── skills.tar.gz
│   └── manifest.json
└── reports/<UTC-ISO>/
    ├── REPORT.md           # human-readable
    └── run.json            # structured
```

## Safety contract

- **Dry-run by default.** `/curate` with no args is read-only. You must pass `live` to mutate.
- **Pre-run snapshot.** Live passes always tar.gz the skills tree before touching anything. Pruned to 5.
- **Never deletes.** Archiving (move to `.archive/<name>.<ts>`) is the maximum destructive action.
- **First run defers mutation.** If `state.json` has no `last_run_at`, `live` is refused. Run dry-run, review, then live.
- **Pinned skills are off-limits** to both auto-transitions and the LLM pass.
- **Rollback is reversible.** Rolling back snapshots the current state first, so you can roll forward.

## Scheduling

On macOS via home-manager (Monday 09:00 Brisbane):

```nix
launchd.agents.claude-curator = {
  enable = true;
  config = {
    Label = "claude.curator";
    ProgramArguments = [
      "/bin/zsh" "-lc"
      "claude -p '/curate' --permission-mode acceptEdits --allowed-tools 'Bash,Read,Write,Edit,Glob,Grep'"
    ];
    EnvironmentVariables.CLAUDE_CONFIG_DIR = "/Users/you/.claude-work";
    StartCalendarInterval = [{ Weekday = 1; Hour = 9; Minute = 0; }];
    RunAtLoad = false;
  };
};
```

Note: scheduled job runs **dry-run only**. Live passes require an explicit human `/curate live` after reading the report. This is intentional — destructive autonomous skill maintenance is opt-in per pass, not blanket.

`Weekday = 1` is Monday in launchd. `RunAtLoad = false` because a missed weekly run isn't urgent — wait for next Monday.

## Activity signal

Uses `SKILL.md` mtime as the activity proxy. Auto-transitions:

- unused 30d → marked stale (`.stale` sentinel inside the skill dir)
- unused 90d → archived (`mv` to `.archive/<name>.<ts>`)

Curator's own edits leave a `.curator-touch` sentinel so they're not mistaken for user activity.

## Ported from

Hermes' [`agent/curator.py`](https://github.com/NousResearch/hermes-agent) — the review prompt (umbrella-building framing), idle-gated cadence, first-run defer, snapshot/rollback contract, and pin mechanism are all proven there.

What's different here: bash + slash commands instead of a Python daemon, mtime instead of usage counters, scheduled job is dry-run only (mutation requires explicit human turn).
