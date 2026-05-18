# workflow-tools

Code quality tools for Claude Code.

> **Breaking change in 3.0.0**: the PEP workflow (skill + `/run-pep` command + gate-keeper agent flow against PEP markdown) moved out of this plugin and into its own marketplace at the [`pep`](https://github.com/denisl-raison/pep) repo. PEPs are now driven by the `pep` CLI with SQLite-backed state instead of hand-edited markdown. Install via `/plugin marketplace add <path-or-url-to-pep>` then `/plugin install pep@pep`.

## Components

### Skills (auto-discovered)

| Skill | Trigger | What it does |
|-------|---------|-------------|
| `code-review` | "review my changes" | Reviews uncommitted changes against a quality checklist |
| `code-cleanup` | "clean up tests" | Batch removal of dead tests and code |
| `code-refactor` | "refactor this" | Restructures code for clarity (Go, TypeScript, Python) |
| `trim-context` | "trim our context files" | Prunes CLAUDE.md files based on empirical research |

### Agents (invoked explicitly)

| Agent | Trigger | What it does |
|-------|---------|-------------|
| `browser-tester` | "check if my changes look right" | Visual frontend testing via claude-in-chrome |
| `gate-keeper` | "gate-check my changes against the PEP" | Evaluates wave completion with per-criterion PASS/FAIL verdict. Still useful with the pep CLI: invoke it on a wave's gate evidence and paste its verdict into a `pep gate-wave --gate gate-keeper` row. |

### Commands (slash commands)

| Command | What it does |
|---------|-------------|
| `/catchup` | Restores context after `/clear` |
