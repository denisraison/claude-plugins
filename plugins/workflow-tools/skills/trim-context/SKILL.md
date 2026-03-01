---
name: trim-context
description: Trim CLAUDE.md and AGENTS.md files to reduce context cost. Apply the "less is more" finding from empirical research on agentic coding context files. Use when user says "trim our context files", "lean up CLAUDE.md", "optimize our agents.md", "reduce context", "our CLAUDE.md is too long", or asks to audit instruction files for bloat.
---

# Context File Trimmer

Apply research-backed pruning to CLAUDE.md and AGENTS.md files. The core finding from ETH Zurich / LogicStar.ai (2025): LLM-generated context files reduce task success by ~3% and increase inference cost by 20%+. Agents treat every instruction as a constraint, making tasks harder. The fix is ruthless removal.

See [references/research.md](references/research.md) for the evidence base.

## The Rule

**Only include what the agent cannot discover by reading the codebase.**

If the agent can find it in `package.json`, `go.mod`, a README, directory listing, or any committed file, it does not belong in CLAUDE.md.

## Step 1: Find all context files

```bash
find . -name "CLAUDE.md" -o -name "AGENTS.md" -o -name ".claude.local.md" 2>/dev/null | grep -v node_modules | grep -v ".git"
```

Also check `~/.claude/CLAUDE.md` for the global file.

## Step 2: Classify each section

For every section in every file, ask: **can the agent discover this from the repo?**

| Category | Discoverable? | Action |
|---|---|---|
| Stack / tech descriptions ("Go + PocketBase", "SvelteKit 2 + Svelte 5") | Yes, from go.mod / package.json | Remove |
| Project structure / directory listing | Yes, by listing dirs | Remove |
| Product description / what the app does | Yes, from README | Remove |
| Conventions that duplicate another CLAUDE.md | Yes, from parent file | Remove |
| Build and run commands | No | Keep |
| Tooling quirks and non-obvious constraints | No | Keep |
| Non-obvious naming conventions / patterns | No | Keep |
| Environment variable requirements | No | Keep |
| Things the agent repeatedly gets wrong | No | Keep |

## Step 3: Flag duplicates across files

Check whether conventions in a project CLAUDE.md duplicate those in `~/.claude/CLAUDE.md`. If they're already in the global file, remove from the project file.

## Step 4: Report before cutting

Present a list of proposed removals with one-line justifications:

```
REMOVE: Stack section (go.mod + package.json already tell the agent this)
REMOVE: Project structure (agent lists dirs autonomously)
REMOVE: Conventions section (duplicates ~/.claude/CLAUDE.md lines 18-24)
CONDENSE: Playwright warning → 1 line (full detail only needed when bumping versions)
KEEP: Commands section (not discoverable)
KEEP: Nix quirks (not discoverable from any file)
```

Show estimated token savings.

## Step 5: Apply after approval

Use the Edit tool to apply each cut. Preserve structure and order of what remains.

## What lean looks like

A well-trimmed CLAUDE.md typically contains:
- Commands (build, test, dev, eval)
- One-liner warnings for non-obvious tooling constraints
- Workflow steps the agent cannot infer (optimization loops, release steps)
- Specific env vars or config paths that aren't in .env.example

It does NOT contain: stack overview, directory map, product description, generic coding conventions.
