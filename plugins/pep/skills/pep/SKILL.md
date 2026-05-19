---
name: pep
description: This skill should be used when the user says "create a PEP", "update PEP", "PEP status", "document this", "spike", "investigate", "explore", "look into", "scout", "research", "scope out", "figure out", or references PEP-*.md files. Manages PEP (Project Enhancement Proposal) documents covering both investigation ("I don't know the shape yet") and execution ("here's the plan"). Wave shapes, mandatory adversarial review before execution, and evidence-required wave completion. The markdown file is the source of truth; an audit hook records what actually ran.
---

# PEP Workflow

A PEP is a markdown file at `docs/peps/PEP-NNN-slug.md`. One document covers two
modes: investigation (you don't know the shape yet) and execution (you do, and
here's the plan). Status line tracks which mode it's in. There is no engine, no
state.db, no separate "spike" document type. Same file, same skill, different
sections filled in.

The skill is generic. Per-repo specifics live in `agent-constraints/` at the
repo root.

## Determine Action

- **"spike <topic>"**, **"investigate <topic>"**, **"explore <topic>"**, **"look into <topic>"**, **"scout"**, **"research"**, **"scope out"**, **"figure out"** → Create in investigation mode (jump to Create)
- **"create PEP"** or **"document this"** → Create (jump to Create)
- **"update PEP"** or **"mark done"** → Update existing (jump to Update)
- **"PEP status"** → Show status (jump to Status)
- **"run PEP"** or **"run wave"** → Run Wave (jump to Run Wave)

## Repository Configuration

Before creating or executing a PEP, check for these files at the repo root and
read the ones that exist:

- `agent-constraints/planning-conventions.md` - analysis, documentation, and test strategy requirements
- `agent-constraints/adversarial-dimensions.md` - review criteria specific to this repo
- `agent-constraints/implementation-conventions.md` - build, verify, and PR conventions
- `agent-constraints/triage-conventions.md` - codebase exploration rules

Per-repo files win over skill defaults; partial existence is fine, fall back per
file. Always cite which override applied under the PEP's `Conventions applied`
line.

## Two Modes of the Same Document

A PEP can be in one of two modes at any moment. The status line says which.

**Investigation mode**: status is `Investigating`. The PEP has Context + Open
Questions + Findings. No waves yet. The deliverable is a decision, not a code
change. Closes as one of:
- `Inlined as <commit-sha>` (investigation produced a small fix, committed inline)
- `Parked` (worth doing later, here's why we stopped, here's the trigger for resuming)
- `Abandoned` (decided not to do it, here's why)
- `Resolved as <free-form>` (e.g. "spawned PEP-007", "answered in Decisions Log, no code change needed")

**Plan mode**: status is `Draft | In Review | Approved | In Progress | Done`.
The PEP has Invariants + Waves + Gates. Adversarial review is mandatory before
moving from `In Review` to `Approved`. The deliverable is shipped code.

A PEP can start in investigation and graduate to plan mode by adding Waves and
re-running adversarial review. Or stay in investigation forever and close as
Parked / Abandoned / Resolved. There is no formal "promotion" command; the
status line and the section content are the only signals.

## Create

1. Find the docs directory. Default is `docs/peps/` at the repo root. If the
   repo uses a different convention (read `CLAUDE.md`), use that.
2. Glob `<docs>/PEP-*.md` to find the highest number, increment for next. First
   PEP in a repo is `PEP-001`.
3. Read repo `CLAUDE.md` and any `agent-constraints/*.md` files that exist.
4. Decide mode from the user's trigger:
   - "spike / investigate / explore / scout / look into / scope out / figure out / research" → start in **investigation mode**, status `Investigating`.
   - "create PEP / document this" → start in **plan mode**, status `Draft`.
   If unclear, default to investigation mode. It's cheaper to add waves later
   than to over-commit early.
5. Write the PEP using the appropriate skeleton from [references/template.md](references/template.md). Do not improvise the markdown shape.
6. **If plan mode:** immediately run the adversarial review pass (see [references/adversarial-review.md](references/adversarial-review.md)) before presenting to the human. Never present an unreviewed plan.
7. **If investigation mode:** no adversarial review yet. Present the Context + Open Questions and ask the human what to investigate first.

## Investigation Mode Workflow

1. Read the relevant code, run reconnaissance commands, follow references.
2. Append entries under `## Findings` as you learn. Each finding cites a file
   path and line number where applicable.
3. Update the `## Open Questions` list: resolved questions move to Findings with
   the answer; new questions append.
4. When the investigation is conclusive, write a `## Recommendation` section
   stating what should happen next. Recommendations are one of:
   - **Promote to plan mode** (add Invariants + Waves, run adversarial review).
   - **Close as Inlined**: investigation surfaced a small fix that's already
     committed. Record the commit sha.
   - **Close as Parked**: not now, here's the trigger for resuming.
   - **Close as Abandoned**: not ever, here's why.
   - **Close as Resolved as <free-form>**: e.g. "spawned PEP-007 for the
     real work", "answered without code change, see Decisions Log".
5. Present the recommendation as a verdict (see [Presenting to the Human](#presenting-to-the-human)).
6. On human approval, update the status line accordingly. If promoting to plan
   mode, jump to Wave Authoring.

## Wave Authoring (plan mode)

A wave is a sweep of work followed by a gate. Each wave must have: a name
describing what it does (not a generic label), a primary Shape (see
[references/wave-shapes.md](references/wave-shapes.md)), Files, Risks, Rollback
(mandatory for Config and Migration shapes), and one or more Gates whose form
depends on the Shape.

Choose the right number of waves based on complexity. 1 wave for a config
change or simple fix. 2 for a new feature with tests. 3+ for cross-cutting
changes. Do not default to 3.

Cross-wave contracts ("public API stays unchanged", "old code keeps working
between deploys") go in the PEP's `Invariants` section, not buried in per-wave
Risks.

For browser/UI gates: make them executable. Specify the URL, the steps to
perform (click X, type Y), and the expected outcome. "Verify it works in the
browser" is not a gate.

## Adversarial Review (mandatory before approval)

After writing or iterating the plan, run adversarial review before presenting
to the human. See [references/adversarial-review.md](references/adversarial-review.md).
PEP status cannot advance from In Review to Approved without:

1. Files opened during review listed in the PEP (audit trail).
2. Findings written with severity and category.
3. Human explicit approval.

Planning and review are always paired. No exceptions.

If the plan changes structurally after review (a wave is added, files change,
scope shifts), re-run adversarial review. Stale reviews don't grant approval.

## Run Wave

Execute a wave inline in the current session. The wave is not done until the
gate produces real evidence AND that evidence cross-checks against the audit
log.

1. **Pick the wave.** If the user named a number, use it. Otherwise pick the
   first wave with status `[ ]`.
2. **Flip the wave's status to In Progress** by editing the PEP. (For the
   first wave, also flip the PEP status from `Approved` to `In Progress`.)
3. **Do the work** per the wave's primary Shape (see [references/wave-shapes.md](references/wave-shapes.md)).
   For Code (TDD): write failing tests first, present the spec, get human
   approval, then implement. For Refactor: characterise first, then move.
4. **Run each gate command for real** in the shell. Capture exit code and
   output.
5. **Paste evidence into the PEP** under the wave's `Gate Result` subsection.
   See [references/verification.md](references/verification.md) for what
   evidence looks like per shape.
6. **Cross-check against the audit log.** For every command in `Gate Result`,
   grep `.pep/audit.log` to confirm the command actually ran in this session.
   If a command isn't in the log, it didn't happen in-session — rerun it
   in-session and paste fresh evidence, or explicitly note "ran outside
   session: <reason>" and get human approval before flipping the checkbox.
7. **Auto-close the wave.** Flip the wave's checkbox to `[x]` yourself — do
   NOT stop and ask the human first. The gate is the gate, not the human.
   **Stop and ask the human ONLY when:**
   - The audit cross-check failed and you're about to accept "ran outside session".
   - A gate failed and you're considering recording a different command than the one that failed.
   - The wave touched anything outside the planned Files list.

   After auto-close, report the wave verdict (see [Presenting to the Human](#presenting-to-the-human)).
8. **Run `/simplify`** to review the changed code for reuse, quality, and
   efficiency. Fix any issues it finds. Then commit. Conventional commit, no
   `Co-Authored-By`, no `--no-verify`.
9. **If all waves are done:** present a ship verdict to the human. Final
   status flip to `Done` requires explicit human go.

## Update

1. Read the PEP file.
2. Update wave checkboxes only after `Gate Result` has real pasted evidence
   AND audit cross-check passes.
3. When all waves are done, flip PEP status to Done (with human approval).
4. If the work surfaced a non-obvious gotcha, add to Session Learnings.

## Status Check

1. Glob `<docs>/PEP-*.md`.
2. For each: filename, status, current wave (if plan mode), pending wave
   count, or investigation Open Questions count.

## Presenting to the Human

At every checkpoint where the human is in the loop, present a **verdict**, not
raw materials. The human's job is to decide; yours is to evaluate and
recommend. Dumping JSON, test files, or gate logs for them to read cold is a
failure of the skill.

A verdict has three parts:

1. **What changed** — one sentence summary of the work just done.
2. **Evidence** — bullet list of concrete results (N tests written, M
   findings, gate exit codes). Cite paths and line numbers, do not paste
   content.
3. **Recommendation + ask** — your read on what should happen next, ending in
   a single yes/no question.

The four checkpoints where this applies:

### After investigation (recommendation)

Bad: pasting the Findings list and saying "what now?"

Good:
> Spike done. 6 findings (3 in `internal/charges/`, 2 in `migrations/`, 1 in lefthook config). The actual shape: 2-wave PEP. Wave 1 is a refactor to extract the dedupe key generator; Wave 2 is the new state machine. The dedupe-key refactor is needed because the current call site is in the wrong layer (Finding F3). Recommendation: promote this to plan mode now, draft the two waves, you review. Sound right?

### After `## Review Findings` lands (plan approval)

Bad: pasting findings JSON and saying "thoughts?"

Good:
> Plan reviewed. 3 findings: 1 low (cosmetic), 2 medium (Wave 2 file list incomplete; Wave 3 missing rollback). No blockers. Recommendation: address the two mediums in-place, then approve. Want me to draft the fixes?

### After spec-gate (Code TDD wave)

Bad: pasting the failing test file and saying "look ok?"

Good:
> Wave 2 spec: 7 failing tests in `internal/charges/charges_test.go` covering refund flow, partial refund, idempotency, and the three error paths from Risks. Spec gate exits 1 as expected. One thing worth your eye: the idempotency test asserts on the dedupe key shape, not just behaviour — that's stricter than the plan said. OK to lock that contract, or relax?

### Ship verdict (final wave done)

Bad: "all waves done, ship?"

Good:
> All 4 waves closed. Spec + impl gates green on every wave. Audit cross-check clean. No "ran outside session" carve-outs used. Commits: a4f9c12..ef928676 (8 commits, conventional). Ship?

Per-repo `agent-constraints/planning-conventions.md` may add checkpoint-specific
verdict requirements. Honour those.

## When the Audit Cross-check Fails

The hook only fires when `.pep/` exists in CWD, and only logs `Bash|Edit|Write`.
If you ran a gate command outside Claude Code (manual terminal, sub-shell,
remote machine), there's no audit row.

- Default: rerun the command inside the session so the hook captures it, then
  paste fresh evidence.
- Escape hatch: paste evidence with a `Verified: outside session (<reason>)`
  line. Get human approval before flipping the checkbox. Use only when the
  gate genuinely can't be replayed in-session (e.g. staging system the agent
  can't reach).

## Spawning a Subagent for Execution

Default: inline. The current session reads the PEP, does the work, runs
gates, pastes evidence.

Spawn a subagent (e.g. `general-purpose` or the `gate-keeper` agent) for
execution only when:
- The wave touches files unrelated to the current conversation and pulling
  them in would bloat the planner's context.
- The session has accumulated noise (failed approaches, exploratory reads)
  that would mislead a clean executor.

When you do: pass the wave's full markdown (the file path is enough — the
subagent reads it) plus relevant `agent-constraints/*.md` excerpts. The
subagent runs gates and reports evidence; the planner (you) pastes the
evidence into the PEP and flips the checkbox. Spawning a subagent does NOT
delegate the gate-check.

## Key Rules

1. **Never present a plan without adversarial review.** Planning and review are paired.
2. **Never mark a wave done without pasted evidence AND audit cross-check.** See [references/verification.md](references/verification.md).
3. **Never run a wave on an unapproved PEP.** Status must be `Approved` or `In Progress`.
4. **File unrelated discoveries as new PEPs immediately.** A bug, smell, or gap surfaced during a wave that isn't part of this PEP becomes its own PEP. Do not scope-creep.
5. **Per-repo `agent-constraints/` wins over skill defaults.** Cite which override applied in `Conventions applied`.
6. **Rollback is mandatory for Config / Infrastructure and Migration shapes.** Skipping is a finding, not a green.
7. **Conventional Commits, no `Co-Authored-By`, no `--no-verify`.**
8. **Present verdicts, not raw materials.** At every human-in-the-loop checkpoint (investigation recommendation, plan review, spec sign-off, ship), evaluate first, then present verdict + recommendation + single ask. Dumping JSON, test files, or gate logs for the human to read cold is a skill failure. See [Presenting to the Human](#presenting-to-the-human).
9. **Auto-close waves; never auto-ship.** When gates pass + audit cross-check clean + no carve-outs, flip the checkbox without asking. Final ship (PEP status → Done) always requires explicit human go.
10. **Use issue-scoped filenames for temp files** (e.g. `/tmp/findings-pep-042.yaml`) to avoid leaking state between sessions.
