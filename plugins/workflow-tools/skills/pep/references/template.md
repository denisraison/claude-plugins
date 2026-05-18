# PEP Template

Use this skeleton verbatim. Fill the blanks. Do not skip sections.

Some lines are **shape-specific** and marked with `[shape: ...]`. Keep only those for your wave's shape; delete the rest. Wave shapes are defined in [wave-shapes.md](wave-shapes.md).

```markdown
# PEP-XXX: <Title>

Status: Draft | In Review | Approved | In Progress | Done
Date: YYYY-MM-DD
Conventions applied: <one of: "skill defaults" (no agent-constraints/ dir), "agent-constraints acknowledged, no overrides triggered" (files read, no conflicts), or "agent-constraints/X.md overrides <rule> for Wave N" (cite the override)>

## Context

<The why. The problem or decision, clear enough that someone unfamiliar could
argue for it. What you're doing about it. 1-4 paragraphs.>

## Invariants

<Cross-wave contracts that must hold throughout the work. Things like:
- "Public API of `src/auth/` stays unchanged across all waves."
- "Old code keeps working after Wave 1 ships, before Wave 2 ships."
- "RTSP stays LAN-local; never traverses the tailnet."
Empty section is valid for small PEPs (one short wave). Always include the
header so reviewers know it was considered.>

## Waves

### Wave 1: <name what it does, not a generic label> (<Shape>)

Files:
- `path/to/file_one.ext` (new | touch)
- `path/to/file_two.ext` (touch)

Risks:
- <inline, per-wave or per-step>

Rollback: <how to revert this wave if it goes wrong in production. Required
for Config / Infrastructure and Migration shapes. For Code / Refactor /
Documentation waves where rollback is trivially "revert commit + redeploy",
omit the line entirely. Only include it when there's external state to
unwind (DB, secrets, deployed config, files outside the repo).>

Spec Gate: <[shape: Code (TDD)] failing tests at the named paths exist, human approved>
Dry-Run Gate: <[shape: Migration] applied to staging copy, correctness verified>
Stage-Load Gate: <[shape: Migration, optional] staging under representative write load, ops metrics within thresholds. MUST include a Thresholds: sub-line pinning the numbers (e.g. "Thresholds: replication lag p95 < 2s, abort at 5s; QPS 800 (prod p50)")>
Apply Gate / Implementation Gate / Behaviour Gate / Render Gate: <single line or composite; see below>

Status: [ ]
Gate Result: <pasted during execution, not at creation>

### Wave 2: ...

(repeat structure)

## Review Findings

<Populated by the adversarial review pass before the PEP can be Approved.
Required: list of files opened during review, plus findings. See
[adversarial-review.md](adversarial-review.md) for the canonical format.>

Files opened during review:
- `path/one`
- `path/two`

Findings:
- **F1** (high|medium|low, architecture|scope|risk|testing|complexity|correctness|docs): <description>

(If no findings: "Findings: none. Reviewed across <N> dimensions.")

## Consequences

- <real trade-off, named>
- <what changes, downstream effects>
- <follow-up PEPs filed for out-of-scope discoveries>

## Session Learnings

<Added during execution if non-obvious gotchas surface. Empty at creation.>
```

## Notes on the template

- **Status: [ ]** on each wave. Flip to `[x]` only after Gate Result is pasted with real evidence.
- **Gate Result** is left blank at creation. The agent writes into it when running the gate.
- **Conventions applied** under Status: a one-liner citing which `agent-constraints/*.md` overrode skill defaults (or "skill defaults" if none). Lets a reviewer see where rules came from.
- **Invariants** section is always present. Empty body is fine, but the header forces the author to consider cross-wave contracts.
- **Rollback** is per-wave. Mandatory for Config / Infrastructure and Migration shapes. Skipping rollback on those is a finding, not a green.
- **Review Findings** is not optional. Empty findings is a valid outcome but the "Files opened" list must always be present.
- Net-new files marked `(new)`. Touched files marked `(touch)`. No third option.
- Composite gates are sanctioned: a single Gate line may contain multiple `$ command` invocations whose collective output is the evidence. See [verification.md](verification.md).

## First PEP in a repo

If no `docs/` directory exists, create `docs/` at the repo root and write `docs/PEP-001-<slug>.md`. If the repo has a different docs convention (e.g. `documentation/`, `notes/`), the user names it when triggering the skill or the agent reads `CLAUDE.md` for guidance. Do not invent a non-standard location silently.

## Wave-shape composition

A wave may have a primary shape and secondary aspects (e.g. a Migration wave that introduces a new backfill job is Migration + Code (TDD)). Rules:

- **Primary shape's gates dominate.** A Migration wave keeps Dry-Run / (Stage-Load) / Apply; the TDD-style spec gate for the backfill job's tests folds into the Dry-Run Gate as a sub-check ("backfill job's unit tests pass against staging").
- **Pick the primary shape by the wave's deliverable.** What is the wave for? A wave that exists to move data is Migration even if it ships new code. A wave that exists to refactor structure is Refactor even if it adds new test files.
- When in doubt, the shape with the strictest gate wins (Migration > Code (TDD) > Code (non-TDD) > Refactor > Config > Documentation).
