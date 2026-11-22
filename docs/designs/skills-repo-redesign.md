# Skills repo redesign

*   **Author:** Denis Santos
*   **Status:** Proposed
*   **Date:** 2026-11-22

## Overview

This repo (`denisraison/claude-plugins`, renamed to `denisraison/skills` by this design) holds Denis's personal agent skills. It has grown to 13 plugins. 6 skills were called at all in about 9.5 weeks, and two hooks started 96% of all sessions in the last 30 days.

This design shrinks the repo to one plugin, `skills@dnix` (`dnix` is Denis's own brand name, used here for the marketplace), holding the skills with recorded use plus two on probation. The skills are portable by construction: plain Agent Skills folders with no harness- or model-specific names.

EGM (Google's Elephant-Goldfish Model plugin: a long-context agent drafts a design doc, and fresh reviewers that never saw the conversation review it) stays installed for specs and review. Matt Pocock's skills are kept as a local reference to learn from, not installed or copied: Denis writes his own version of a skill the first time a task needs it. The repo's own rules (size, portability, no version field) are enforced by a check script in CI.

## The Problem

**Most of the repo is unused.** Over the transcripts on disk (2026-09-16 to 2026-11-22, about 9.5 weeks, 5,070 sessions), the agent called `pep` 23 times, `writing-naturally` 7, `catchup` 4, `logo-design` 2, and `grill` and `commit` once each. Every other skill was called 0 times. `catchup` overlaps with the built-in `/recap`, which had 60 uses. `/recall`, the `memory` plugin's command for reading its logs, was never used.

**Two hooks started 96% of sessions.** In the 30 days from 2026-10-23, about 4,533 sessions ran. 4,344 of them were started by hooks: 2,356 by `auto-improve` and 1,988 by `note-session` (the `memory` plugin's hook). They used about 1.5 billion Haiku tokens. Of the other 189, 135 were Denis working, and most of the rest were his brain repo's curator timer (39), which is not part of this repo. Both hooks were added in May 2026, and transcripts before 2026-09-16 are no longer on disk, which is why most of the 5,070 sessions fall in the last 30 days.

**Prose piles up.** `auto-improve` keeps adding text and nothing removes it: the uncommitted `pep` change from 2026-11-22 is about 80 lines of Solid and Playwright notes appended to a general planning skill.

**Copied ideas went stale.** `pep`, `grill` and `diagnose` were built upfront from early versions of ideas in Matt Pocock's skills. They got 23, 1 and 0 calls, and they missed upstream changes ([Matt's repo](https://github.com/mattpocock/skills) renamed `CONTEXT.md` to `GLOSSARY.md`; these copies still use the old name). `writing-naturally` and `logo-design`, the two kept skills with recorded use, were written for a task Denis had, not copied in advance.

**What Denis corrects is judgement, not mechanics.** In those 135 sessions Denis corrected the agent 148 times. The largest groups were voice (31: "doesn't sound like me", too AI), unverified claims (27: "did you check?") and plain words (24: jargon, unexplained terms). None of the 148 concerned em dashes or bare IDs. So this redesign adds no prose-checking script. Mechanical checks are kept for the repo's own rules, where they apply.

**The repo only works in Claude Code.** 9 of the 13 plugins reference Claude-only features: `${CLAUDE_PLUGIN_ROOT}`, Claude tool names, Claude hook events. A whole plugin (`cursor-sync`) exists only to copy skills into Cursor. The repo's name says Claude.

## Goals

1.  **Portable by construction.** Every skill is a plain folder in the Agent Skills format, installable into any agent with `npx skills add denisraison/skills -g`. No skill names a harness-specific tool, variable or model. Checked by CI for known harness- and model-specific tokens; tested end to end in Claude Code only.
2.  **One plugin, updated by commit.** The repo ships one plugin, `skills`, from one marketplace, `dnix`, with skills in flat `skills/<name>/` folders. Neither `plugin.json` nor the marketplace entry has a `version`, so Claude Code keys the plugin to the git commit and every push is an update.
3.  **Only skills with recorded use, plus two on probation.** The plugin keeps `writing-naturally` and `logo-design`, carries `excalidraw-diagrams` and `qa-scenarios` on probation until the goal 6 review, and retires the rest. Each `SKILL.md` stays at or under 500 lines, the limit in Claude Code's skill guidance, checked by CI.
4.  **Repo rules are checks, not instructions.** A `check-skills` script enforces the line cap, the portability tokens (goal 1) and the absence of a `version` field (goal 2). `claude plugin validate .` checks frontmatter. Both run in CI. The repo ships no Claude hooks.
5.  **No background sessions from this repo.** The `auto-improve`, `memory` and `curator` plugins are retired, along with any scheduled jobs they set up. Hook-started sessions from this repo go from 4,344 a month to 0.
6.  **Skills are reviewed on use.** 90 days after shipping, any skill of Denis's with 0 uses (Skill tool calls plus typed slash commands, counted in Claude Code transcripts only) is retired.
7.  **Learn from upstream, write from a task.** EGM stays installed as a Claude Code plugin. Matt Pocock's skills are kept as a local reference clone in the gitignored `scratch/`, not installed and not copied. A new skill is written only when a task needs it, in Denis's own words, with a one-line credit naming the upstream skill path that inspired it.

## Non-Goals

*   **Testing on other harnesses for now.** Portability is built in and checked by CI, but end-to-end runs on OpenCode, Codex and others are deferred.
*   **Installing Matt Pocock's skills, or copying upstream skills in bulk.** Ideas are borrowed one skill at a time, when a task needs it.
*   **Anything from work.** Skills and workflows built for Denis's employer stay out of this repo. Anything similar here is written from scratch on his own time, and nothing derived from work is published before he has checked his employment contract.
*   **The local sandbox and permissions gap.** That belongs in `~/workspace/dot` and Claude settings.
*   **Project-local skills and agents in other repos** (`500k` and others).
*   **Improving the agent's writing voice.** Voice and plain-words corrections are judgement calls. `writing-naturally` stays, but changing how often Denis corrects voice is not a goal here.
*   **Fixing unverified claims.** "Did you check?" corrections (27) are the second-largest group, but this design does not address them.

## Open Questions

*   **Which source does the homeserver use for `dnix`?** A folder source at `~/workspace/skills` loads edits at every session start with no push, as `santos` does today. A GitHub source matches the work Mac. Decided in phase 5.

## Critical User Journeys (CUJs)

### CUJ 1: A skill breaks a repo rule

*   **Given**: A change adds a skill that is 600 lines long and tells the agent to use `AskUserQuestion`.
*   **When**: CI runs on the push.
*   **Then**: `check-skills` fails, printing the file, the line limit and the harness-specific token.

### CUJ 2: Installing on a new machine or harness

*   **Given**: A machine with Claude Code, or another agent that reads Agent Skills.
*   **When**: Denis rebuilds the machine from `~/workspace/dot`, which declares the `dnix` and `egm` marketplaces and enables `skills@dnix` and `egm@egm`; or, in any other agent, runs `npx skills add denisraison/skills -g`.
*   **Then**: Denis's skills are available, plus EGM in Claude Code. Nothing from this repo starts background sessions.

### CUJ 3: A skill edit reaches every machine

*   **Given**: Denis edits a skill and pushes to the default branch.
*   **When**: Claude Code starts on either machine.
*   **Then**: Because the plugin has no `version` and the `dnix` marketplace has auto-update on, the new commit is picked up without a version bump.

### CUJ 4: Writing a new skill from a task

*   **Given**: Denis is stuck on a hard bug, and the model's default approach is not working.
*   **When**: He writes a debugging skill in `skills/<name>/`, using `scratch/mattpocock-skills/repo/skills/engineering/diagnosing-bugs/` as a reference.
*   **Then**: The skill is in his own words, at or under 500 lines, credits the upstream path in one line, passes CI, and faces the goal 6 review like every other skill.

## Technical Plan (Architecture)

### Repo layout

The repo moves from 13 plugin folders to one plugin with flat skill folders:

```text
/
├── .claude-plugin/
│   ├── plugin.json         plugin "skills", no version
│   └── marketplace.json    marketplace "dnix", lists the one plugin, no version
├── skills/
│   └── <name>/
│       ├── SKILL.md        at most 500 lines
│       ├── references/     detail loaded only when the skill points at it
│       └── scripts/        called by relative path
├── checks/
│   ├── check-skills        bash: line cap, portability tokens, no version field
│   └── test/               one pass and one fail fixture per rule, plus a runner
├── .github/workflows/
│   └── check.yml           CI: check-skills, its tests, claude plugin validate
├── docs/designs/           this design and later ones
├── scratch/                gitignored: reference clones, baseline data
├── AGENTS.md               repo instructions for any agent
├── CLAUDE.md               one line that imports AGENTS.md
├── README.md               what is here, how to install, which tool for which job
├── LICENSE                 MIT
├── .gitignore
└── flake.nix               dev shell with bash and jq
```

Layout decisions:

*   **Flat skill folders.** With 4 skills, Matt's groups (`engineering/`, `productivity/`) add a directory level with no navigation benefit.
*   **No `version` anywhere.** Per Claude Code's plugin docs, with no `version` in either manifest a GitHub-sourced plugin is keyed to its commit SHA, and a fixed version keeps users on the cached copy however many commits are pushed. That is what left EGM's installed copy without `egm-lite`.
*   **No skill list in `plugin.json`.** Claude Code scans a plugin's `skills/` folder by default.
*   **`AGENTS.md` holds the repo instructions**, because Codex, OpenCode and Cursor read it. `CLAUDE.md` only imports it, so there is one copy.
*   **`WORKFLOW.md` is replaced by a section of `README.md`**: which tool for which job (EGM's `egm-brainstorm`, `egm-draft`, `egm-review` and `egm-lite` for specs and review, the built-in review commands, the model's defaults elsewhere).
*   **Reference clones live in `scratch/`**, which is already gitignored. Matt's repo is already cloned there. EGM's source is the installed plugin cache, so it needs no clone. The existing `nicknisi-claude-plugins/` moves into `scratch/` too.
*   **CI is the only enforcement point.** No pre-commit hook, so nothing depends on how the dev shell is entered.

### Skills

All four kept skills are model-invoked: the agent can pick them up when a task fits.

| Skill | Change |
| --- | --- |
| `writing-naturally` | Moved as is (76 lines). It stays self-contained, since in another harness Denis's global instructions are not loaded. |
| `logo-design` | Moved as is (308 lines). Its description gains "Needs an agent that can view images." It names Gemini because it calls the Gemini API. |
| `excalidraw-diagrams` | Moved with four wording edits to remove Claude-specific names (plan item 5). On probation: added in October with 0 calls since, retired at the goal 6 review if still unused. |
| `qa-scenarios` | Moved as is (140 lines). On probation: 0 calls, same rule. |

These 13 plugins are retired in full: `auto-improve`, `commit-commands`, `consultant`, `curator`, `cursor-sync`, `history-analyser`, `memory`, `pep`, `skill-utils`, and the parts of `excalidraw-diagrams`, `logo-pipeline`, `qa` and `workflow-tools` not listed above. `curator` merged near-duplicate skills on a weekly run. Git history keeps them all.

### Checks

`check-skills` is a bash script with no harness inside it. For every `skills/*/SKILL.md` and its `references/*.md`, it flags:

*   a `SKILL.md` over 500 lines
*   the tokens `CLAUDE_PLUGIN_ROOT`, `AskUserQuestion` and `TodoWrite`
*   versioned model IDs: `claude-`, `gpt-` or `gemini-` followed by a digit

It also flags any `version` key in `.claude-plugin/plugin.json` or `.claude-plugin/marketplace.json`, using `jq '[paths | select(.[-1] == "version")] | length'`. Scripts are not scanned: a script may call a specific API model, as `logo-design` calls Gemini. The token list is kept to strings that cannot be ordinary words, so `Read`, `Write`, `opus` and `haiku` are not flagged.

It prints `file:line: reason` for every problem and exits 1 if it finds any. Frontmatter is checked by `claude plugin validate .`, which parses it.

Tests live in `checks/test/`: one pass fixture and one fail fixture per rule. The runner checks that each fail fixture prints the expected reason, not only that it exits 1, so a fixture failing for the wrong reason is caught. Fixtures sit outside `skills/`, so no installer finds them.

```text
     push or pull request
              │
              ▼
       GitHub Actions
              │
   ┌──────────┼──────────────────┐
   ▼          ▼                  ▼
check-skills  checks/test/run    claude plugin validate .
   └──────────┴──────────┬───────┘
                         ▼
        file:line: reason, exit 1 on any problem
```

### Upstream

*   **EGM** (`egm@egm`) is refreshed so the installed copy includes `egm-lite`. Its upstream version is still 0.1.1 although `egm-lite` was added later, and the cache is keyed by that version, so a plain update reuses the stale copy (phase 5 has the commands).
*   **Matt Pocock's skills** stay in `scratch/mattpocock-skills/repo` (a shallow clone). A `git pull` there shows what changed upstream.
*   **Built-in review:** `/simplify` covers clean-up. The exact name of the built-in code review command is checked before it goes into the README.

### Migration

The work runs in phases. Each phase ends on a checkpoint before the next starts.

1.  **Build** (one branch; moves committed separately from edits so `git log --follow` can trace them). Plan items 1 to 21. Checkpoint: the checks pass locally, and `claude --plugin-dir . -p` lists exactly the four `skills:` skills (`claude plugin marketplace add ./` is refused here, because the folder is already registered as `santos`).
2.  **Switch over** (this machine). `santos` (today's marketplace) is a folder marketplace pointing at this working directory, so once the build branch is checked out its plugins no longer load at the next session start. Run the teardown below, remove the `santos` marketplace, and add the folder back as `dnix` (`claude plugin marketplace add ~/workspace/claude-plugins`, then `claude plugin install skills@dnix`). Checkpoint: `claude plugin list` shows `skills@dnix` and no `@santos` entry.
3.  **Publish.** Merge, push, then `gh repo rename skills`. Checkpoint: with a throwaway `HOME`, `npx skills add denisraison/skills -g -y --agent claude-code` installs exactly the four skills into `$HOME/.claude/skills/`.
4.  **Move.** Close every session in the repo. Move `~/workspace/claude-plugins` to `~/workspace/skills`, and `~/.claude/projects/-home-denis-workspace-claude-plugins` to `~/.claude/projects/-home-denis-workspace-skills`. Update `~/workspace/brain/projects.md` (plan item 23).
5.  **Declare.** Plan item 22 in dot. Rebuild the homeserver, then the work Mac. Refresh EGM on each: `claude plugin marketplace update egm`, `claude plugin uninstall egm@egm`, delete `~/.claude/plugins/cache/egm/egm/0.1.1`, `claude plugin install egm@egm`. Checkpoint: both machines show `skills@dnix` and `egm@egm`, and `egm-lite` is in the EGM skill list.
6.  **Review.** Record the ship date. 90 days later, run the goal 6 review.

**Teardown** (phase 2):

*   On the work Mac, if `~/Library/LaunchAgents/com.santos.cursor-sync.plist` exists, run `scripts/install-service.sh uninstall` from the installed `cursor-sync` plugin's folder in `~/.claude/plugins/cache/santos/` before the plugin is uninstalled.
*   Confirm no `claude-rollup` or `claude-curator` launchd agents are loaded on the work Mac. Dot declares neither, and the homeserver has no matching timers.
*   Archive `~/.claude/memory` to `~/.claude/memory.archive-2026-11`, and delete curator snapshots.
*   List the skills `auto-improve` wrote into `~/.claude/skills/`, and remove the ones Denis does not want.

## Risks & Mitigations

*   **The rename breaks links or installs.** GitHub redirects the old URL. Phase 3 checks the `npx` install, and phase 5 re-declares the marketplace under the new name.
*   **The memory folder move loses project memory.** Phase 4 moves it while no session is open, before any new session starts in the new folder.
*   **Manual uninstalls clash with home-manager settings.** Dot is updated in phase 5, right after the switch-over, so the declared and installed sets match again.
*   **Skill scripts called by relative path may not resolve in other harnesses.** Claude Code tells the agent the skill's folder; other harnesses may not. Goal 1 is untested there.
*   **`excalidraw-diagrams` runs `npm install` on first use.** It needs Node and network access, and writes into the skill's folder.
*   **Checking out the build branch disables the old plugins on this machine.** `santos` is a folder marketplace on this working directory, so phase 2 follows phase 1 without a gap.
*   **Transcripts expire before the goal 6 review.** Plan item 22 sets `cleanupPeriodDays` to 120 so 90 days of transcripts stay on disk.
*   **Rollback.** Revert the build commit and reinstall `santos` from it through a local-path marketplace. A revert does not undo the GitHub rename (`gh repo rename claude-plugins`), the folder moves (move them back), or the dot and brain edits (revert those commits).

## Alternatives Considered

### Alternative A: Keep `pep` as the main workflow

*   **Pros**: Already built around Denis's habits: waves, gates, an audit hook that checks commands really ran. No new tools to learn.
*   **Cons**: 23 calls in about 9.5 weeks. Its audit hook uses a Claude hook event. It collects unrelated text over time, like the 80 lines of Solid and Playwright notes added on 2026-11-22. Denis has to maintain it alone.
*   **Reason for Rejection**: Low use, a Claude-only hook and unrelated text piling up mean upkeep costs more than it returns. Spec work has already moved to EGM.

### Alternative B: Adopt Matt Pocock's full flow

*   **Pros**: Actively maintained, short skills, works in many harnesses. Covers the whole path from idea to shipped code, including tickets and implementation.
*   **Cons**: Specs and tickets go into an issue tracker. Denis tracks work in `~/workspace/brain`, not GitHub issues. Its review step reads the code diff, so no fresh-context review of a design doc happens before code is written.
*   **Reason for Rejection**: Specs land in an issue tracker Denis does not use, and there is no fresh-context review of a design doc before code.

### Alternative C: Install chosen Matt Pocock skills from upstream

*   **Pros**: Eight small skills (`tdd`, `diagnosing-bugs`, `grill-with-docs`, `writing-for-agents`, `handoff`, and the `grilling`, `domain-modeling` and `codebase-design` skills they call) maintained by someone else.
*   **Cons**: Denis has not used any of them yet. Every install route had a defect: the whole Claude plugin brings all 27 skills, some of which trigger on their own; a project `skills-lock.json` installs only into that one project; a global `npx skills add -g` is machine state, not a declared list; a home-manager declaration in `dot` pins someone else's folder layout.
*   **Reason for Rejection**: None of the 8 skills has been used yet, and every install route has one of the defects above.

### Alternative D: Copy the chosen upstream skills into this repo now

*   **Pros**: A complete set from day one, in Denis's repo and his to change. Licences allow it (Matt's is MIT, EGM's is Apache 2.0, both with attribution).
*   **Cons**: The same pattern that produced `pep`, `grill` and `diagnose`: copied upfront, then unused and stale. Rebuilding EGM's reviewer subagents and rubrics is the largest piece of work, for something that already works installed.
*   **Reason for Rejection**: Copying unused skills upfront repeats what made `pep`, `grill` and `diagnose` stale, and rebuilding EGM's reviewers duplicates a working install.

### Alternative E: Keep the memory and auto-improve hooks, just tune them

*   **Pros**: Keeps a daily log of sessions and automatic suggestions for skill changes, with no new habits needed.
*   **Cons**: 4,344 hook-started sessions and about 1.5 billion tokens in 30 days. `/recall`, the only way to read the logs back, was never used. Both hooks are Claude-specific.
*   **Reason for Rejection**: 4,344 sessions and about 1.5 billion tokens a month for output nobody read, now covered by the built-in `/recap` and auto memory.

### Alternative F: Symlink skills into harness skill folders

*   **Pros**: Matt's `link-skills.sh` links each skill into `~/.claude/skills` and `~/.agents/skills`, so a `git pull` is the update and it works in any harness that reads those folders.
*   **Cons**: A per-machine script, with nothing declared in dot.
*   **Reason for Rejection**: A version-free GitHub marketplace with auto-update already delivers each commit to both machines (CUJ 3), declared in dot. Other agents use `npx skills add`.

## Non-Functional Requirements

*   **Security:** reference clones in `scratch/` are read, never run. No script, hook or skill executes anything from them.
*   **Token cost:** the redesign removes about 1.5 billion Haiku tokens a month of hook sessions, and adds nothing that runs a model.

## Future Improvements

*   **Test on OpenCode with an open model**, the setup Denis uses for his dnix videos, once the Claude Code version has run through its goal 6 review.
*   **A stop-and-spec skill for teams**: the agent stops and writes a short spec before a change touching a migration, money, authentication or a large blast radius. Written as its own design once Denis has checked his employment contract and a real team or workshop needs it. Draft notes, if any, stay in `scratch/`.

## Additional Resources

*   `scratch/baseline/`: the 30-day baseline data, rubric and results (gitignored).
*   `scratch/concepts_brief.md`: the brief this design was drafted from.
*   [mattpocock/skills](https://github.com/mattpocock/skills) and [google/elephant-goldfish-model](https://github.com/google/elephant-goldfish-model): the reference repos.
*   Claude Code plugin docs, [manifest reference](https://code.claude.com/docs/en/plugins/manifest-reference) and [loading and versions](https://code.claude.com/docs/en/plugins/loading): the basis for leaving out `version`.

## Detailed Implementation Plan

### Target Files

#### 1. `.claude-plugin/plugin.json` (Create)

*   **Type / Scope**: Plugin manifest.
*   **Proposed Changes**: `name: "skills"`, `description: "Denis's agent skills: writing, logo design, diagrams, QA scenarios."`, `author: {"name": "Denis Santos"}`, `repository: "https://github.com/denisraison/skills"`, `license: "MIT"`. No `version` and no `skills` array.

#### 2. `.claude-plugin/marketplace.json` (Modify)

*   **Type / Scope**: Marketplace manifest.
*   **Proposed Changes**: Rewrite. `name: "dnix"`, `owner: {"name": "Denis Santos"}`, and one entry in `plugins`: `{"name": "skills", "source": "./", "description": "Denis Santos's skills."}`, with no `version`. The 13 old entries and the whole `metadata` object go.

#### 3. `skills/writing-naturally/SKILL.md` (Move, from `plugins/workflow-tools/skills/writing-naturally/SKILL.md`)

*   **Type / Scope**: Skill.
*   **Proposed Changes**: None.

#### 4. `skills/logo-design/` (Move and modify, from `plugins/logo-pipeline/skills/logo-design/`)

*   **Type / Scope**: Skill.
*   **Proposed Changes**: `SKILL.md`, `references/evaluation-rubric.md`, `scripts/generate-image.sh` and `scripts/serve-gallery.sh` move. In the moved commit's follow-up edit, the frontmatter `description` gains the sentence "Needs an agent that can view images."

#### 5. `skills/excalidraw-diagrams/` (Move and modify, from `plugins/excalidraw-diagrams/skills/excalidraw-diagrams/`)

*   **Type / Scope**: Skill with Node scripts and tests.
*   **Proposed Changes**: Move `SKILL.md` and `scripts/` (`diagram.mjs`, `diagram.sh`, `diagram.test.mjs`, `graph.mjs`, `layout.mjs`, `package.json`, `package-lock.json`, `preview.html`, `viewer.html`). Then edit `SKILL.md`:
    *   line 8: "Claude only decides" becomes "the agent only decides"
    *   line 12: "that Claude edits" becomes "that the agent edits"
    *   line 37: "targeted Edit calls" becomes "targeted edits"
    *   line 45: "Read the" becomes "Open the"

#### 6. `skills/qa-scenarios/` (Move, from `plugins/qa/skills/qa-scenarios/`)

*   **Type / Scope**: Skill.
*   **Proposed Changes**: None. `SKILL.md` and `scripts/gather-qa.sh` move as is.

#### 7. `checks/check-skills` (Create)

*   **Type / Scope**: Bash script, executable.
*   **Proposed Changes**: Takes an optional root directory, defaulting to `git rev-parse --show-toplevel`, so the tests can point it at fixtures. Applies the rules in "Checks" above. If a root has no `.claude-plugin/` folder, the version rule is skipped. Prints `file:line: reason` per problem and exits 1 if it finds any.

#### 8. `checks/test/run` and `checks/test/fixtures/` (Create)

*   **Type / Scope**: Bash test runner and fixtures.
*   **Proposed Changes**: Each fixture is a root folder holding `skills/<name>/SKILL.md` and, where the rule needs it, `.claude-plugin/`. Each fail fixture has an `expected` file with the reason text. The runner fails if a pass fixture exits non-zero, a fail fixture exits zero, or a fail fixture's output lacks its expected text. Fixtures:
    *   `pass-minimal`, `pass-model-in-script` (a model ID inside `scripts/`)
    *   `fail-too-long` (501 lines)
    *   `fail-token` (`AskUserQuestion` in `SKILL.md`), `fail-token-in-references` (`CLAUDE_PLUGIN_ROOT` in `references/`)
    *   `fail-model-id` (`claude-3` in `SKILL.md`)
    *   `fail-version` (a `version` in `.claude-plugin/plugin.json`)

#### 9. `.github/workflows/check.yml` (Create)

*   **Type / Scope**: GitHub Actions.
*   **Proposed Changes**: On push and pull request, on `ubuntu-latest` (which has bash and jq): checkout, `checks/test/run`, `checks/check-skills`, then `npx -y @anthropic-ai/claude-code@<version pinned at build time> plugin validate .`. The last step depends on the open question.

#### 10. `AGENTS.md` (Create)

*   **Type / Scope**: Agent instructions for any harness. At most 60 lines.
*   **Proposed Changes**: The layout; the rules (500-line cap, no harness-specific tokens, flat `skills/<name>/`, no hooks, no `version` field); how a new skill comes in (only from a task, own words, a one-line credit naming the upstream path, `scratch/` holds the references); that `scratch/` is gitignored and holds the baseline data; how to run the checks; the goal 6 review rule and its counting command. Replaces the content of the current `CLAUDE.md`.

#### 11. `CLAUDE.md` (Modify)

*   **Type / Scope**: Claude Code instructions.
*   **Proposed Changes**: Replaced by one line, `@AGENTS.md`.

#### 12. `README.md` (Create)

*   **Type / Scope**: Docs.
*   **Proposed Changes**: The four skills, one line each; install for Claude Code (`claude plugin marketplace add denisraison/skills`, `claude plugin install skills@dnix`) and for other agents (`npx skills add denisraison/skills -g`); which tool for which job (EGM's skills for specs and review, the built-in review commands by their checked names, the model's defaults elsewhere); the `git clone --depth 50 https://github.com/mattpocock/skills scratch/mattpocock-skills/repo` command.

#### 13. `LICENSE` (Create)

*   **Type / Scope**: Licence.
*   **Proposed Changes**: MIT, "Copyright (c) 2026 Denis Santos", so others may reuse the skills.

#### 14. `flake.nix` and `flake.lock` (Modify)

*   **Type / Scope**: Nix dev shell.
*   **Proposed Changes**: `description = "skills dev shell"`. `devShells.default` gets `bash`, `jq` and `nodejs` (for `npx` and the `excalidraw-diagrams` scripts). `flake.lock` is regenerated.

#### 15. `.gitignore` (Modify)

*   **Type / Scope**: Git config.
*   **Proposed Changes**: Remove the `nicknisi-claude-plugins/` line, since that folder moves into `scratch/`. Add `/design_draft.md` and `/*_report.md` so EGM working files at the root are never committed.

#### 16. `docs/designs/skills-repo-redesign.md` (Add to git)

*   **Type / Scope**: Design doc.
*   **Proposed Changes**: This document, already on disk.

#### 17. Root working files (Delete)

*   **Type / Scope**: Untracked EGM files.
*   **Proposed Changes**: Delete `design_draft.md`, `zoom_out_report.md`, `comprehension_report.md`, `critic_report.md`, `intermediate_zoom_out_report.md`, `implementation_readiness_report.md`, `consolidated_review_report.md` and `goldfish_review_report.md` before the build commit, so they do not ship under `"source": "./"`.

#### 18. `plugins/` (Delete)

*   **Type / Scope**: Retired content, the files left under `plugins/` after items 3 to 6 move 17 files out (about 94).
*   **Proposed Changes**: First discard the uncommitted changes in `plugins/pep/skills/grill/SKILL.md` and `plugins/pep/skills/pep/SKILL.md` with `git checkout -- plugins/pep`. They are `auto-improve` output, already quoted in the Problem section. Then `git rm -r plugins/`. Git history keeps the rest.

#### 19. `WORKFLOW.md` (Delete)

*   **Type / Scope**: Docs.
*   **Proposed Changes**: Replaced by the README's "which tool for which job" section.

#### 20. `scratch/` (Move, local only)

*   **Type / Scope**: Gitignored reference folder.
*   **Proposed Changes**: Move `nicknisi-claude-plugins/` to `scratch/nicknisi-claude-plugins/`. `scratch/mattpocock-skills/repo` stays where it is.

#### 21. `skills/excalidraw-diagrams/scripts/` (Verify)

*   **Type / Scope**: Existing tests.
*   **Proposed Changes**: Run `npm test` there after the move. `diagram.sh` finds its folder from its own path, so the move should not break it.

#### 22. `~/workspace/dot/home/claude.nix` (Modify, in the dot repo)

*   **Type / Scope**: home-manager config.
*   **Proposed Changes**: Add `extraKnownMarketplaces` for `dnix` (GitHub `denisraison/skills`, `autoUpdate = true`) and `egm` (GitHub `google/elephant-goldfish-model`). In `enabledPlugins`, remove every `@santos` entry and add `skills@dnix` and `egm@egm`. Set `cleanupPeriodDays = 120`.

#### 23. `~/workspace/brain/projects.md` (Modify, in the brain repo)

*   **Type / Scope**: Notes.
*   **Proposed Changes**: Replace the two `claude-plugins` references (currently lines 120 and 154) with `skills` (`~/workspace/skills`), describing the new plugin. `mail/report.md` stays as is, since it logs old emails.

### Verification Plan

*   **Unit tests**: `checks/test/run` passes: pass fixtures pass, and each fail fixture fails with its expected reason.
*   **Repo check**: `checks/check-skills` exits 0, and `claude plugin validate .` passes.
*   **Install** (phase 1): `claude plugin details skills` lists exactly `writing-naturally`, `logo-design`, `excalidraw-diagrams` and `qa-scenarios`.
*   **Other agents** (phase 3): with a throwaway `HOME`, `npx skills add denisraison/skills -g -y --agent claude-code` leaves exactly the same four folders in `$HOME/.claude/skills/`.
*   **Excalidraw scripts**: `npm test` passes in `skills/excalidraw-diagrams/scripts/`.
*   **No hook sessions**: one day after phase 5, this returns nothing: `find ~/.claude/projects -name '*.jsonl' -newer <ship-marker> -print0 | xargs -0 grep -l -e '"You are a background review agent' -e '"Run /note-session for transcript path'`.
*   **Goal 6 review** (90 days after shipping): `find ~/.claude/projects -name '*.jsonl' -newer <ship-marker> -print0 | xargs -0 grep -ho -e '"name":"Skill","input":{"skill":"skills:[a-z-]*"' -e '<command-name>/skills:[a-z-]*' | grep -o 'skills:[a-z-]*' | sort | uniq -c`. Any of the four skills missing from the output had 0 uses and is retired. This counts Claude Code transcripts only.

*Drafted with EGM*
