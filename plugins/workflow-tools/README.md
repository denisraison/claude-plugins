# workflow-tools

Code quality and project management tools for Claude Code.

## Components

### Skills (auto-discovered)

| Skill | Trigger | What it does |
|-------|---------|-------------|
| `pep` | "create a PEP", "update PEP" | Creates and tracks Project Enhancement Proposals with waves and gates |
| `code-review` | "review my changes" | Reviews uncommitted changes against a quality checklist |
| `code-cleanup` | "clean up tests" | Batch removal of dead tests and code |
| `code-refactor` | "refactor this" | Restructures code for clarity (Go, TypeScript, Python) |
| `trim-context` | "trim our context files" | Prunes CLAUDE.md files based on empirical research |

### Agents (invoked explicitly)

| Agent | Trigger | What it does |
|-------|---------|-------------|
| `gate-keeper` | "gate-check my changes against the PEP" | Evaluates PEP wave completion with per-criterion PASS/FAIL verdict |
| `browser-tester` | "check if my changes look right" | Visual frontend testing via claude-in-chrome |

### Commands (slash commands)

| Command | What it does |
|---------|-------------|
| `/catchup` | Restores context after `/clear` |
| `/run-pep` | Generates a headless `claude -p` command to autonomously implement a PEP wave |

## The PEP Workflow

Write a PEP, implement it wave by wave, verify each wave with the gate-keeper.

```
/pep "add auth middleware"       -- create the PEP with waves and gates
                                    implement wave 1
"gate-check my changes"          -- gate-keeper verifies each criterion
                                    fix if HOLD, proceed if PROCEED
```

### Autonomous mode

Use `/run-pep` to generate a headless command you can run in another terminal:

```
/run-pep PEP-003 wave 2          -- creates .pep-gate, outputs two options:
                                    A) single-shot with built-in Stop hook
                                    B) fresh-context loop (restarts per attempt)
```

The plugin includes a built-in Stop hook that activates when a `.pep-gate` file exists. `/run-pep` creates this file. The hook blocks Claude from stopping until all gate criteria pass, then Claude deletes `.pep-gate` and exits. No manual settings configuration needed.

Option A keeps context across fix cycles, good for straightforward waves. Option B restarts with clean context each attempt, better for complex waves where context degradation is a risk.

## Gates

Gates are the proof that a wave is done. Start with at least one deterministic check (test suite, type check, linter) that produces a pass/fail exit code. Then add judgement-based checks if needed (behavioural verification, structural assertions, before/after comparisons).

The gate-keeper runs deterministic gates first. If those fail, it's an immediate HOLD without further evaluation. If they pass, it checks the remaining criteria. The verdict is derived mechanically from the per-criterion results, not from a gestalt score.
