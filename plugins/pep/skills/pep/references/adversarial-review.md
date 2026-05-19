# Adversarial Review

Run this immediately after writing or iterating a PEP plan, before presenting to the human. Planning and review are paired. No exceptions.

## Step 1: Challenge the Plan

Read the repo's `agent-constraints/adversarial-dimensions.md` if it exists. If not, evaluate across these defaults:

- **Architecture**: Are domain boundaries correct? Right abstraction level? Better patterns available?
- **Scope**: Doing too much or too little? Matches the stated context? Scope creep?
- **Risk**: All failure modes identified? Edge cases, race conditions, backwards compatibility? What could go wrong that isn't listed?
- **Testing**: Strategy sufficient? Edge cases covered? Integration test gaps?
- **Complexity**: Over-engineered? Could be simpler? Unnecessary abstractions?
- **Correctness**: Will it solve the actual problem? Logical gaps? Matches established patterns?
- **Documentation**: Does this change anything described in repo docs, CLAUDE.md, or skills? If so, the plan must include a step to update them.
- **Invariants**: Are the PEP's Invariants well-stated and complete? Are there cross-wave contracts (deploy ordering, public API stability, "must not break X") that aren't yet captured? Each invariant should be enforceable by an Invariant Gate somewhere downstream.

## Step 2: Verify Against the Codebase

For every wave in the plan:

- **Open every file in the wave's `Files` list.** Confirm it exists, or mark it as net-new. Net-new files must say `(new)` next to the path.
- **Confirm functions, classes, types referenced in the plan exist where claimed.** Grep for them.
- **Look for code that already does what a step proposes.** Duplication risk.
- **Trace existing execution paths.** When the plan adds a new entry point to an existing capability (a new way to send notifications, persist data, hit an external API), find how existing callers do it and verify the plan routes through the same shared code. New entry points that reimplement existing logic are a high-severity finding.
- **Check for stale docs** that describe behaviour the plan changes.

If a wave references files that don't exist and aren't marked `(new)`, that's a finding. Fix the plan, don't paper over it.

## Step 3: Record Findings (with audit trail)

Write findings inline in the PEP under a `## Review Findings` section. The section has two mandatory parts:

**(a) Files opened during review** - one path per line. This is the audit trail. A reviewer scanning the PEP later must be able to see which files the review actually looked at. If you didn't open a file, don't list it. Pasting paths you didn't read is fabrication.

**(b) Findings** - list, with severity and category.

```
## Review Findings

Files opened during review:
- src/messaging/service.rs
- src/auth/rate_limit.rs
- src/http/routes.rs
- Justfile
- docs/auth.md

Findings:
- **F1** (high, architecture): Wave 2 adds `OtpService` but doesn't route through the existing `MessagingService` boundary. Existing WhatsApp callers go through `MessagingService.send()` (src/messaging/service.rs:42). Plan should reuse that path.
- **F2** (medium, testing): Wave 3 spec gate lists 5 test cases but skips the rate-limit edge case. Given the throttle middleware exists, add a 6th case.
- **F3** (low, docs): src/auth/README.md describes the old OTP flow. Plan should add a step to update it.
```

If no findings: keep the "Files opened" list and write `Findings: none. Reviewed across <N> dimensions.`

Severity: high (blocks approval), medium (must be addressed before that wave starts), low (track but don't block).

## Step 4: Present to Human

Present the plan and the findings together. Never present a plan without findings. If findings is empty, say so explicitly ("Reviewed across 7 dimensions, no findings") so the human knows the review actually ran.

## Step 5: When to Re-Review

Re-run adversarial review whenever:

- A wave's `Files` list changes during execution (new file discovered, scope shifted)
- A finding from a previous round is addressed and the plan changed structurally
- The work surfaces an assumption the plan made that turned out wrong

Cheap to re-run, expensive to skip.
