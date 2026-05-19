# pep

PEPs are markdown files at `docs/peps/PEP-NNN-slug.md`. One document handles both
investigation ("I don't know the shape yet") and execution ("here's the plan").

This plugin ships:

- The `pep` skill (auto-invoked on plan/document/investigate/explore/spike triggers).
- A PostToolUse audit hook that writes `Bash|Edit|Write` payloads to
  `.pep/audit.log` (plain JSONL). The skill greps the log to verify that gate
  commands actually ran in-session before claiming green.

No CLI, no state engine, no schema migrations. The markdown is the source of
truth. The audit hook is the only piece of code.

## Install

```bash
/plugin marketplace add ~/workspace/claude-plugins
/plugin install pep@santos
```

## Triggers

The skill activates on: create PEP, document this, update PEP, PEP status,
spike, investigate, explore, look into, scout, research, scope out, figure out.

## Per-repo overrides

Files at the consumer repo root override skill defaults:

- `agent-constraints/planning-conventions.md`
- `agent-constraints/adversarial-dimensions.md`
- `agent-constraints/implementation-conventions.md`
- `agent-constraints/triage-conventions.md`

The skill cites which override applied under the PEP's `Conventions applied`
line.
