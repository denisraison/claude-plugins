---
name: diagnose
description: This skill should be used when the user says "diagnose this", "debug this", "why is this failing", "this is broken", "track down this bug", or reports something throwing, crashing, returning wrong output, or a performance regression. A disciplined diagnosis loop for hard bugs: build a feedback loop, reproduce, hypothesise, instrument, fix, regression-test. The feedback loop is the skill; everything else is mechanical.
---

# Diagnose

A discipline for hard bugs. Skip phases only when explicitly justified.

If the repo has a domain glossary (`CONTEXT.md`) or decision records
(`docs/adr/`), skim the ones relevant to the area you're touching first, for a
clear mental model and to avoid re-litigating settled decisions.

## Phase 1 — Build a feedback loop

**This is the skill.** Everything else is mechanical. If you have a fast,
deterministic, agent-runnable pass/fail signal for the bug, you will find the
cause: bisection, hypothesis-testing, and instrumentation all just consume that
signal. If you don't have one, no amount of staring at code will save you.

Spend disproportionate effort here. **Be aggressive. Be creative. Refuse to
give up.**

### Ways to construct one — try in roughly this order

1. **Failing test** at whatever seam reaches the bug (unit, integration, e2e).
2. **Curl / HTTP script** against a running dev server.
3. **CLI invocation** with a fixture input, diffing stdout against known-good.
4. **Headless browser script** (use `agent-browser` or Playwright) driving the
   UI, asserting on DOM/console/network.
5. **Replay a captured trace.** Save a real request/payload/event log to disk;
   replay it through the code path in isolation.
6. **Throwaway harness.** Spin up a minimal subset of the system (one service,
   mocked deps) exercising the bug path with a single function call.
7. **Property / fuzz loop.** For "sometimes wrong output", run 1000 random
   inputs and look for the failure mode.
8. **Bisection harness.** If the bug appeared between two known states (commit,
   dataset, version), automate "boot at state X, check, repeat" for
   `git bisect run`.
9. **Differential loop.** Run the same input through old-vs-new (or two
   configs) and diff outputs.
10. **HITL loop.** Last resort. If a human must click, structure the loop so
    their captured output feeds back to you.

Build the right loop and the bug is 90% fixed.

### Iterate on the loop itself

Treat the loop as a product. Once you have one, ask:

- Faster? (Cache setup, skip unrelated init, narrow scope.)
- Sharper signal? (Assert on the specific symptom, not "didn't crash".)
- More deterministic? (Pin time, seed RNG, isolate filesystem, freeze network.)

A 30-second flaky loop is barely better than none. A 2-second deterministic
loop is a debugging superpower.

### Non-deterministic bugs

The goal is not a clean repro but a **higher reproduction rate**. Loop the
trigger 100×, parallelise, add stress, narrow timing windows, inject sleeps. A
50%-flake bug is debuggable; 1% is not, keep raising the rate.

### When you genuinely cannot build a loop

Stop and say so explicitly. List what you tried. Ask the user for: (a) access
to the environment that reproduces it, (b) a captured artifact (HAR, log dump,
core dump, screen recording with timestamps), or (c) permission to add
temporary production instrumentation. Do **not** hypothesise without a loop.

Do not proceed to Phase 2 until you have a loop you believe in.

## Phase 2 — Reproduce

Run the loop. Watch the bug appear. Confirm:

- The loop produces the failure the **user** described, not a nearby one. Wrong
  bug = wrong fix.
- Reproducible across runs (or, for flaky bugs, at a high enough rate).
- You captured the exact symptom (error, wrong output, timing) so later phases
  can verify the fix addresses it.

## Phase 3 — Hypothesise

Generate **3–5 ranked, falsifiable hypotheses** before testing any. Single-
hypothesis generation anchors on the first plausible idea.

Each must state its prediction:

> "If X is the cause, then changing Y makes the bug disappear / changing Z
> makes it worse."

If you can't state the prediction, it's a vibe, sharpen or discard it.

Show the ranked list to the user before testing. They often re-rank instantly
("we just deployed a change to #3") or know what's already ruled out. Cheap
checkpoint. Don't block on it if they're AFK, proceed with your ranking.

## Phase 4 — Instrument

Each probe maps to a specific prediction from Phase 3. **Change one variable at
a time.**

1. **Debugger / REPL** if the env supports it. One breakpoint beats ten logs.
2. **Targeted logs** at the boundaries that distinguish hypotheses.
3. Never "log everything and grep".

**Tag every debug log** with a unique prefix, e.g. `[DEBUG-a4f2]`, so cleanup is
one grep. Untagged logs survive; tagged logs die.

**Performance regressions:** logs are usually wrong. Establish a baseline
measurement (timing harness, profiler, query plan), then bisect. Measure first,
fix second.

## Phase 5 — Fix + regression test

Write the regression test **before the fix**, but only if a **correct seam**
exists, one where the test exercises the real bug pattern as it occurs at the
call site. A too-shallow seam (single-caller test for a multi-caller bug) gives
false confidence.

**If no correct seam exists, that itself is the finding.** Note it: the
architecture is preventing the bug from being locked down.

With a correct seam:

1. Turn the minimised repro into a failing test there.
2. Watch it fail.
3. Apply the fix.
4. Watch it pass.
5. Re-run the Phase 1 loop against the original (un-minimised) scenario.

## Phase 6 — Cleanup + post-mortem

Required before declaring done:

- Original repro no longer reproduces (re-run the Phase 1 loop).
- Regression test passes (or absence of seam is documented).
- All `[DEBUG-...]` instrumentation removed (grep the prefix).
- Throwaway harnesses deleted (or moved to a clearly-marked debug location).
- The hypothesis that turned out correct is stated in the commit/PR message, so
  the next debugger learns.

**Then ask: what would have prevented this bug?** If the answer is
architectural (no good test seam, tangled callers, hidden coupling), recommend
a follow-up after the fix is in, not before, you know more now than at the
start.
