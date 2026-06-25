# Verification

Before marking any wave done, run its gate and paste evidence into the PEP. "Should work" is not done.

## The Process

1. **Re-read the wave's context.** What did the wave commit to?
2. **Run the gate command in the shell.** Capture exit code and output.
3. **Paste evidence into the PEP** under the wave's `Gate Result` subsection. Evidence MUST include:
   - The literal command line that was run, with a `$` prefix (e.g. `$ just verify`). Lets a reviewer mentally re-run it.
   - The exit code on its own line (e.g. `exit code: 0`).
   - A short excerpt of the relevant output (test counts, lint summary, row counts, health body, port binding line).
4. **For Code (TDD) waves: cross-check the test count.** The spec gate listed N test cases. The implementation gate output must show at least N new tests passing. Mismatch is a finding, not a green.
5. **For composite gates: paste each command, exit code, and excerpt.** Every line green or the wave is not done.
6. **Only then flip the checkbox to `[x]`.**

## Strong vs Weak

Strong:

- "All 69 tests passing, exit code 0. `cargo test otp` output: 6 new tests passed, no existing tests broken."
- "Migration ran on staging copy. Before: 12,400 rows. After: 12,400 rows, 0 nulls in new column. Sample of 1000 rows matches legacy derivation exactly."
- "Replication lag p95 during backfill: 800ms (threshold 2s). 0 errors. Wall time 14 min."
- "`tailscale ping node-1` returned `pong from node-1 via DIRECT in 12ms`. Mesh is direct, not relayed."

Weak (do not do this):

- "Should work now." (Untested.)
- "Added tests." (How many? Did they pass?)
- "Fixed the bug." (Which bug? Did you verify the fix?)

## Evidence by Wave Shape

| Shape         | What "running the gate" looks like                                                          |
| ------------- | ------------------------------------------------------------------------------------------- |
| Code (TDD)    | Spec gate: tests exist + human approval noted. Impl gate: exit 0, test count >= spec count |
| Code (no TDD) | Exit 0 from verify command, plus task-specific check output                                 |
| Config        | Composite: apply command exit 0, plus service health / port binding / cert chain / DNS resolution output as appropriate |
| Documentation | Links resolve, examples ran, prose approved by human                                        |
| Refactor      | Full suite passes (exit 0, test count >= prior), plus Invariant Gate (e.g. `rg` returning empty) |
| Migration     | Dry-Run: row counts, sample diff. Stage-Load: lock duration, replication lag, p95. Apply: same metrics on prod + abort criteria honoured |
| Invariant     | Command whose expected exit is non-zero (no matches) or whose output is asserted-empty      |

## Non-Test Evidence

Plenty of gates produce no test output. They still need pasted evidence. Examples:

- **Row counts**: `$ psql -c 'select count(*) from accounts'` -> `50000123`. Before and after.
- **Replication lag**: `$ psql -c 'select pg_last_xact_replay_timestamp()'` sampled at intervals during the run. Paste min/p95/max.
- **Health endpoint**: `$ curl -sf http://node-1:8090/api/health` -> `{"code":200,...}`. Paste the body.
- **Port binding**: `$ ss -tlnp | grep 5000` -> `LISTEN ... 100.64.1.5:5000 ...`. Paste the line.
- **Cert chain / renewal**: subject + `notBefore` from `openssl x509`. Paste both, and confirm `notBefore` advanced after forced renewal.
- **Mesh reachability**: `$ tailscale ping <host> | head -1` -> contains `via DIRECT`. Relayed is not direct, that's a finding.
- **Structural / Invariant**: `$ rg "auth::infra" src/auth/domain/` -> exit 1, no output. Paste the command and the exit code.
- **Column semantics (ORDER BY / filter / tier waves)**: a wave that ranks, filters, or tiers on a data-backed term ("most recent", "active", "worked together") needs evidence the chosen column *means* that, not just that the query runs. Paste two things against real data: the write-path check (which column the event actually stamps, e.g. accept lands on `updatedAt` not `createdAt`) and a distribution/rank-stability query (`$ ... SELECT count(*) FILTER (WHERE rank_a != rank_b) ...` -> how many rows reorder under the alternative column). A fast, well-formed query that sorts on a semantically wrong column is a finding, not a green.

The pattern is always the same: command, exit code, the few lines that matter. Not the full log.

## What Counts as "Running the Gate"

The gate is a command you ran in the shell. You have the exit code. You have output. Reading the code and concluding it should work is not running the gate.

If the gate involves a browser, use a browser tool (Playwright, agent-browser) and capture the result. "I looked at the code, it should render" is not running a UI gate.

If the gate involves a remote system (staging, prod), the command and its output must show that target. `$ curl -sf https://staging.example.test/health` is evidence; `$ curl -sf http://localhost/health` against your dev box is not.

## When the Gate Fails

1. Do not flip the checkbox.
2. Capture the failure output into the PEP under the wave (briefly, not the whole stack trace).
3. Fix the underlying problem. Do not bypass the gate by relaxing it.
4. Re-run the gate. Re-capture exit code.
5. If the gate itself was wrong (the test was wrong, not the code), update the test in a way that's still meaningful, note it as a Session Learning, and re-run.

Bypassing a gate to mark a wave done is the most expensive shortcut available. It silently moves the project into the "looks done but isn't" pile.

## Session Learnings

If you hit a non-obvious problem during a wave that wasted time or revealed a convention not documented in `CLAUDE.md` or `agent-constraints/`, add it to the PEP's `Session Learnings` section. After the PEP is Done, propose those learnings as updates to `CLAUDE.md` or the relevant skill. Frame as positive conventions (what to do).
