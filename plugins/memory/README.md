# memory

Three slash commands for persistent, searchable Claude Code session memory. No external deps, just bash + claude.

## Commands

- `/note-session` — checkpoint the current session into `$CLAUDE_CONFIG_DIR/memory/sessions/<date>.md` (global, all projects, one file per day). Idempotent via per-transcript watermark. Run before `/compact` to preserve context.
- `/rollup-day [date]` — distill a day's session log into `$CLAUDE_CONFIG_DIR/memory/daily/<date>.md`. Default: yesterday. Always overwrites. Safe to schedule daily.
- `/recall <question>` — search the curated memory (sessions + rollups + per-project memory) for an answer. Falls back to raw JSONL grep when curated misses it.

## How it fits together

```
claude session (live)
   │
   │  /note-session  (manual or hook)
   ▼
sessions/<date>.md  (raw, append-only)
   │
   │  /rollup-day yesterday  (manual or launchd)
   ▼
daily/<date>.md  (distilled, overwrite)
   │
   │  /recall "what did we decide about X?"
   ▼
answer
```

## Scheduling the rollup

On macOS via home-manager, drop this in your config:

```nix
launchd.agents.claude-rollup = {
  enable = true;
  config = {
    Label = "claude.rollup";
    ProgramArguments = [
      "/bin/zsh" "-lc"
      "claude -p '/rollup-day yesterday' --permission-mode acceptEdits --allowed-tools 'Bash,Read,Write'"
    ];
    EnvironmentVariables.CLAUDE_CONFIG_DIR = "/Users/you/.claude-work";
    StartCalendarInterval = [{ Hour = 9; Minute = 0; }];
    RunAtLoad = true;
  };
};
```

`RunAtLoad = true` catches missed runs after boot. Pick a time when the machine is usually on.

## Paths

All paths resolve via `${CLAUDE_CONFIG_DIR:-$HOME/.claude}`. If you use a custom config dir (e.g. `~/.claude-work`), set the env var and everything follows.
