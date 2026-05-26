# auto-improve

Background review hook that learns from each Claude Code session. Ports the self-improvement loop from [NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent).

## What it does

The Claude Code `Stop` hook fires at the end of every assistant response (per-turn, not just session end). After each turn, this plugin runs a cheap decision script to decide whether to actually fire a review, then if so spawns a detached headless `claude -p` process that:

1. Replays the conversation
2. Decides whether anything from the session is worth persisting as **memory** (who the user is, durable preferences) or as a **skill** (how to do this class of task)
3. Writes updates straight to `$CLAUDE_CONFIG_DIR/projects/<slug>/memory/` and/or `$CLAUDE_CONFIG_DIR/skills/<name>/` (resolves against whichever Claude home is active)
4. Logs the decision to `$CLAUDE_CONFIG_DIR/auto-improve/<timestamp>_<session-id>.log` (override with `AUTO_IMPROVE_LOG_DIR`)

The review runs detached and never delays the main session.

## Design choices ported from Hermes

- **Verbatim combined prompt** (`skills/background-review/references/combined-review-prompt.md`) covers both memory and skill review in one pass, with the "preference order" (patch loaded skill > update umbrella > add support file > create new umbrella) intact.
- **Anti-capture list**: environment-dependent failures, negative tool claims, transient errors, and one-off task narratives are explicitly forbidden, they harden into self-imposed constraints.
- **Skill directory contract**: skills are directories (`SKILL.md` + `references/` + `templates/` + `scripts/`), not flat markdown.
- **Declarative-not-imperative** memory phrasing.
- **Protected skills**: anything under a plugin directory (`plugins/*/skills/`) is never edited; only `$CLAUDE_CONFIG_DIR/skills/` (the active Claude home's user-level skills) is writable.
- **Provenance tag**: every skill auto-improve creates carries `created_by: auto-improve` in its frontmatter. User-authored skills (no tag, or `created_by: user`) are still patchable for obvious bugs / missing steps, but never restructured. This is what lets a future curator know which skills it owns.

## Configuration

- `AUTO_IMPROVE_DISABLED=1` to disable the auto trigger without uninstalling
- `AUTO_IMPROVE_LOG_DIR=<path>` to redirect logs (default `$CLAUDE_CONFIG_DIR/auto-improve/`)
- `AUTO_IMPROVE_MODEL=<alias>` to override the review model (default `haiku`). Use `sonnet` for better reasoning, `opus` if cost is no concern.
- `AUTO_IMPROVE_INTERVAL=<N>` user turns between routine reviews (default 5). Lower = more reviews, higher cost.
- `AUTO_IMPROVE_MIN_TURNS=<N>` minimum user turns before any review fires (default 4).

## Cost

The review fires Haiku 4.5 by default. Per session-end: ~$0.03–$0.20 depending on transcript length (`tail -c 200000` cap = ~50K tokens max). Reviews run detached so they never delay your session.

If you want to compare against the original Hermes design: Hermes forks the agent in-process and reuses the parent's prompt cache, so each review only pays for new tokens. We can't do in-process forking in Claude Code, so we spawn a fresh `claude -p`. Picking Haiku closes most of the cost gap.

## Throttling (Hermes-inspired)

A review fires only if one of these is true:
- **Interval reached**: at least `AUTO_IMPROVE_INTERVAL` user turns (default 5) since the last review for this session, OR
- **Signal override**: the last user turn contains
  - frustration markers (`stop doing X`, `don't Y`, `I hate`, `that's wrong`, `you always`, `I told you`)
  - explicit save requests (`remember this`, `save this`, `don't forget`, `note this`)
  - error+correction pattern (assistant's last message contained an error AND user's reply contains corrective language)

A review is always skipped if:
- Fewer than `AUTO_IMPROVE_MIN_TURNS` user turns (default 4)
- Last user message is a trivial follow-up (`ok`, `thanks`, `continue`, `yes`, etc.)
- Recursive invocation (`AUTO_IMPROVE_IS_REVIEW=1` set, or hook-loop detected)

Per-session state lives at `$AUTO_IMPROVE_LOG_DIR/state/<session_id>.json`.

## Manual invocation

The `/background-review` skill runs the same logic mid-session for ad-hoc use.

## Roadmap

Not in v0.1, may add later:
- Curator pass (weekly consolidation of skills into class-level umbrellas)
- Skill bundles (YAML grouping multiple skills under one trigger)
- Backup-before-mutation
