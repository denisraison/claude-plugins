---
name: pep
description: This skill should be used when the user says "create a PEP", "update PEP", "PEP status", "document this", or references PEP-*.md files. Manages PEP (Project Enhancement Proposal) documents for tracking decisions and implementation plans, with files-per-step waves, mandatory adversarial review, and evidence-required wave completion.
---

# PEP Workflow

PEPs are the decision artifact and the execution plan in one document. A PEP is approved by the human, reviewed adversarially before execution starts, and updated with real evidence as each wave completes. The skill is generic; per-repo specifics live in `agent-constraints/` at the repo root.

## Determine Action

- **"create PEP"** or **"document this"** -> Create new PEP (jump to Create)
- **"update PEP"** or **"mark done"** -> Update existing PEP (jump to Update)
- **"PEP status"** -> Show status (jump to Status)

## Repository Configuration

Before creating or executing a PEP, check for these files at the repo root and read the ones that exist:

- `agent-constraints/planning-conventions.md` - analysis, documentation, and test strategy requirements for this repo
- `agent-constraints/adversarial-dimensions.md` - review criteria specific to this repo
- `agent-constraints/implementation-conventions.md` - build, verify, and PR conventions
- `agent-constraints/triage-conventions.md` - codebase exploration rules

Per-repo files win over skill defaults; partial existence is fine, fall back per file. Always cite which override applied under the PEP's `Conventions applied` line.

## Create PEP

1. Find the docs directory. Default is `docs/` at the repo root. If the repo is a monorepo or the user names a different location, use that. If no `docs/` exists, create one (or use the repo's convention from `CLAUDE.md`).
2. Glob `<docs>/PEP-*.md` (not repo-wide) to find the highest number, increment for next. First PEP in a repo is `PEP-001`.
3. Read repo `CLAUDE.md` and any `agent-constraints/*.md` files that exist.
4. Write the PEP to `<docs>/PEP-XXX-<slug>.md` using the template at [references/template.md](references/template.md). Do not improvise the markdown shape.
5. Immediately run the adversarial review pass (see [references/adversarial-review.md](references/adversarial-review.md)) before presenting to the human.
6. Present the plan and the review findings together. Never present a plan that hasn't been adversarially reviewed.

## Wave Authoring

A wave is a sweep of work followed by a gate. Each wave must have: a name describing what it does (not a generic label), a primary Shape (see [references/wave-shapes.md](references/wave-shapes.md)), Files, Risks, Rollback (mandatory for Config and Migration shapes), and one or more Gates whose form depends on the Shape.

Choose the right number of waves based on complexity. 1 wave for a config change or simple fix. 2 for a new feature with tests. 3+ for cross-cutting changes. Do not default to 3.

Cross-wave contracts ("public API stays unchanged", "old code keeps working between deploys") go in the PEP's `Invariants` section, not buried in per-wave Risks.

## Adversarial Review (mandatory before execution)

After writing or iterating the plan, run the adversarial review pass before presenting to the human. See [references/adversarial-review.md](references/adversarial-review.md). PEP status cannot advance from In Review to Approved without:

1. Files opened during review listed in the PEP (audit trail)
2. Findings written with severity and category
3. Human explicit approval

Planning and review are always paired, no exceptions.

## Wave Execution

When a wave starts, flip PEP status to In Progress. Follow the wave's Shape. When the gate is reached, paste evidence into `Gate Result` per [references/verification.md](references/verification.md), then flip the wave's checkbox to `[x]`.

## Update PEP

1. Read the PEP file
2. Update wave checkboxes only after Gate Result has real pasted evidence
3. When all waves are done, flip PEP status to Done
4. If the work surfaced a non-obvious gotcha, add to Session Learnings

## Status Check

1. Glob `<docs>/PEP-*.md`
2. For each: filename, status, current wave, pending wave count

## Key Rules

1. **Never present a plan without adversarial review.** Planning and review are paired.
2. **Never mark a wave done without pasted evidence.** See [references/verification.md](references/verification.md).
3. **File unrelated discoveries as new PEPs immediately.** A bug, smell, or gap surfaced during work that isn't part of this PEP becomes its own PEP. Do not scope-creep.
4. **Per-repo `agent-constraints/` wins over skill defaults.** Cite which override applied in `Conventions applied`.
5. **Rollback is mandatory for Config / Infrastructure and Migration shapes.** Skipping it is a finding, not a green.
6. **Use issue-scoped filenames for temp files** (e.g. `/tmp/findings-pep-042.yaml`) to avoid leaking state between sessions.
