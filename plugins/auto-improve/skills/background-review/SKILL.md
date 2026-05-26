---
name: background-review
description: Manually trigger a Hermes-style review of the current session to consider memory and skill updates. Use when the user says "review this session", "what should we learn from this", "save what we learned", "improve from this conversation", or "run the review". The same review fires automatically on Stop, this is for ad-hoc invocation mid-session.
---

# Background Review

This skill runs the same review pass that the `Stop` hook fires in the background. Use it when the user wants to consolidate learnings mid-session, or to dry-run the review prompt against the current conversation without ending the session.

## What it does

Reads the combined review prompt at `references/combined-review-prompt.md` and applies it to the conversation so far. Outputs either:
- One or more memory writes under `$CLAUDE_CONFIG_DIR/projects/<slug>/memory/`
- One or more skill writes under `$CLAUDE_CONFIG_DIR/skills/<name>/`
- The literal string `Nothing to save.` if neither dimension has signal

## How to run it

1. Read `references/combined-review-prompt.md`
2. Apply the prompt to the current conversation (treat the visible context as the input)
3. Follow the preference order strictly: update loaded skill > update umbrella > add support file > create new umbrella
4. Respect the "Do NOT capture" list. Environment-dependent failures, negative tool claims, and one-off task narratives never become persistent learnings
5. Write memory as declarative facts, never imperatives

## Locations

Resolve against the active Claude home (`$CLAUDE_CONFIG_DIR`, the env var your Claude was launched with):

- **Memory**: `$CLAUDE_CONFIG_DIR/projects/<slug>/memory/` where slug is the project cwd with `/` swapped for `-`. Update `MEMORY.md` index for any new file.
- **Skills**: `$CLAUDE_CONFIG_DIR/skills/<skill-name>/`. Each skill is a directory with `SKILL.md`, optional `references/`, `templates/`, `scripts/`. Agent-created skills must include `created_by: auto-improve` in frontmatter. User-authored skills (no `created_by` or `created_by: user`) should be patched conservatively, never restructured.

If multiple Claude config dirs exist (e.g. one per workspace profile), `CLAUDE_CONFIG_DIR` points at whichever one launched the current session, and that's the only one this skill touches.

## Protected (never edit)

- Anything under a plugin directory (`plugins/*/skills/<name>/`, including under the Claude config dir's plugin cache)
- Anything outside `$CLAUDE_CONFIG_DIR/skills/`

## Automatic trigger

The `Stop` hook in this plugin fires the same review automatically after each session. Logs land in `$CLAUDE_CONFIG_DIR/auto-improve/`. Set `AUTO_IMPROVE_DISABLED=1` to kill the auto trigger without uninstalling.
