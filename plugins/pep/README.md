# pep

PEPs are markdown files at `docs/peps/PEP-NNN-slug.md`. One document handles both
investigation ("I don't know the shape yet") and execution ("here's the plan").

This plugin ships:

- The `grill` skill (the planning front door): an alignment interview that
  resolves what you actually want before any plan exists, challenges it against
  the repo's domain glossary (`CONTEXT.md`) and decisions (`docs/adr/`), and
  hands off to the `pep` skill when the decision tree is settled.
- The `pep` skill (auto-invoked on plan/document/investigate/explore/spike triggers).
- A PostToolUse audit hook that writes `Bash|Edit|Write` payloads to
  `.pep/audit.log` (plain JSONL). The skill greps the log to verify that gate
  commands actually ran in-session before claiming green.

The intended flow is `grill` → `pep`: grill closes the alignment gap, then PEP
plans and ships. Grill is optional for tiny known changes; reach for it
whenever the *intent* is fuzzy. See [WORKFLOW.md](../../WORKFLOW.md) for how
these fit with the other plugins and the repo-root files they read.

No CLI, no state engine, no schema migrations. The markdown is the source of
truth. The audit hook is the only piece of code.

## Install

```bash
/plugin marketplace add ~/workspace/claude-plugins
/plugin install pep@santos
```

## Triggers

`pep` activates on: create PEP, document this, update PEP, PEP status, spike,
investigate, explore, look into, scout, research, scope out, figure out.

`grill` activates on: grill me, grill with docs, stress-test this plan,
interview me, interrogate this design, poke holes in this, am I missing
anything.

## Per-repo overrides

Files at the consumer repo root override skill defaults:

- `agent-constraints/planning-conventions.md`
- `agent-constraints/adversarial-dimensions.md`
- `agent-constraints/implementation-conventions.md`
- `agent-constraints/triage-conventions.md`

The skill cites which override applied under the PEP's `Conventions applied`
line.

Both skills also read, if present, `CONTEXT.md` (the domain glossary, which
`grill` maintains) and `docs/adr/` (recorded decisions), so plans use
consistent names and don't relitigate settled choices.
