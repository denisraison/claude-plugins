# Skills

Denis's agent skills, shipped as one plugin (`skills@dnix`) and installable into any agent that reads the Agent Skills format. The design and its reasoning are in `docs/designs/skills-repo-redesign.md`.

## Layout

- `skills/<name>/SKILL.md`: one folder per skill, flat. Detail goes in `references/`, scripts in `scripts/`, called by relative path.
- `.claude-plugin/`: `plugin.json` (the plugin) and `marketplace.json` (the `dnix` marketplace). Claude Code finds `skills/` on its own.
- `checks/`: `check-skills` and its tests in `checks/test/`.
- `scratch/`: gitignored. Reference clones (Matt Pocock's skills in `scratch/mattpocock-skills/repo`) and the usage baseline in `scratch/baseline/`.

## Rules

- A `SKILL.md` stays at or under 500 lines.
- No harness-specific tokens in a `SKILL.md` or its `references/`: no `CLAUDE_PLUGIN_ROOT`, no `AskUserQuestion` or `TodoWrite`, no versioned model IDs. Say "the agent", not a product name. Scripts may call a specific API model.
- No `version` field in `plugin.json` or `marketplace.json`. Claude Code then keys the plugin to the git commit, so every push is an update.
- No hooks. Nothing in this repo starts background sessions.

## Adding a skill

Write one only when a real task needs it, in Denis's own words. If an upstream skill inspired it, credit it in one line naming the upstream path, for example `Inspired by mattpocock/skills: skills/engineering/diagnosing-bugs`. Do not copy upstream skills in.

## Checks

Run `checks/test/run` and `checks/check-skills` before pushing. CI runs both, plus `claude plugin validate .` for frontmatter.

## Usage review

90 days after shipping, retire any skill with 0 uses. Count uses in Claude Code transcripts (Skill tool calls plus typed slash commands), from a marker file touched on the ship date:

```sh
find ~/.claude/projects -name '*.jsonl' -newer <ship-marker> -print0 \
  | xargs -0 grep -ho -e '"name":"Skill","input":{"skill":"skills:[a-z-]*"' -e '<command-name>/skills:[a-z-]*' \
  | grep -o 'skills:[a-z-]*' | sort | uniq -c
```

A skill missing from the output had 0 uses.
