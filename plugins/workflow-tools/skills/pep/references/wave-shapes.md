# Wave Shapes

A wave has a shape based on what it produces. The shape determines how many gates it has and what they look like. The repo's `agent-constraints/implementation-conventions.md` can override or add shapes.

A wave may have a primary shape and secondary aspects (Migration + Code (TDD), Refactor + Documentation). The primary shape's gates dominate. See "Wave-shape composition" in [template.md](template.md).

## Shape: Code (TDD)

For waves that produce production code in a repo where `CLAUDE.md` declares TDD, or the change handles money, auth, or anything regression-sensitive.

Two gates, sequential:

**Spec Gate**: failing tests exist at the named paths, human has read and approved them. Approving tests is approving the spec, and it's cheap. The wave cannot advance to implementation until the spec gate passes.

**Implementation Gate**: tests pass + the repo's verify command exits zero. Cross-check: the implementation gate must show at least as many new tests passing as the spec gate listed.

Example:

```
Wave 2: WhatsApp OTP send-and-verify
Files:
  - src/auth/otp.rs          (new)
  - src/auth/otp_test.rs     (new)
Risks: rate-limit interaction with existing throttle middleware
Rollback: revert commit + redeploy. No DB or external state to unwind.
Spec Gate: src/auth/otp_test.rs exists with the 5 cases listed below, human approved
Implementation Gate: `$ just verify` exits 0, paste exit code + `$ cargo test otp` output showing 5+ new tests pass
```

## Shape: Code (non-TDD)

For waves that produce code in repos where TDD isn't declared (homelab scripts, throwaway tooling, exploratory work).

**Implementation Gate**: the repo's verify command exits zero, plus any task-specific check. Composite gates allowed (see below).

## Shape: Config / Infrastructure

For waves that change config, infra-as-code, CI files, or similar. Rollback is mandatory.

**Apply Gate**: composite. Typical pattern:

1. Apply the change to a test branch / staging target.
2. Capture the system's response: service health endpoint, port binding scope, cert chain, DNS resolution, whatever the change touches.
3. Paste exit codes and the relevant output lines.

Canned recipes for the common cases:

- **Service restart + health check**: `$ systemctl restart svc && curl -sf http://localhost:PORT/health` returns expected JSON.
- **DNS / mesh reachability**: `$ tailscale ping <host>` shows `via DIRECT` (not relayed); `$ getent hosts <name>` resolves.
- **Cert issuance + renewal**: cert chain check (`$ openssl s_client ... | openssl x509 -noout -subject -dates`); force renewal and confirm `notBefore` advanced.
- **Port binding scope**: `$ ss -tlnp | grep PORT` shows the bind address matches intent (loopback only, tailnet only, all interfaces).
- **Backup/restore**: backup ran, restore on a copy reproduces expected row counts or file digests.

Never accept "the YAML parses" as a gate. Parsing is not behaviour.

Secrets handling: if the wave introduces credentials (auth keys, tokens, certs), the Risks must say how they're stored (agenix, sops, vault, etc.). Hard-coded secrets in committed files are a high-severity finding.

## Shape: Documentation

For waves that only change docs.

**Render Gate**: the doc renders (links resolve, code blocks valid, examples actually run if they're meant to). For prose-only docs: explicit human approval after reading.

## Shape: Refactor

For waves that change structure without changing behaviour. The deliverable is the absence of regression, which is harder to verify than a positive deliverable.

**Behaviour Gate**: the full test suite passes (not just the affected module). Test count must not drop. Plus an **Invariant Gate** (see below) for structural constraints the refactor introduces.

Repeatable across waves: a multi-step refactor uses one Refactor wave per move (characterise -> extract traits -> extract infra), each with its own Behaviour Gate + Invariant Gate.

If coverage is thin, the first wave is "characterisation": add tests against current behaviour as a tripwire before any structural moves. The characterisation wave has only a Behaviour Gate (the new tests pass against current code) plus a note that they're the safety net for following waves.

## Shape: Migration

For waves that move data, rename schemas, or change file layout. Rollback is mandatory.

**Dry-Run Gate**: the migration runs against a staging copy. Output: row counts before/after, error count, correctness sample (e.g. 1000 rows hand-checked or compared against the legacy derivation). Paste a before/after summary.

**Stage-Load Gate (optional but recommended for online migrations)**: the migration runs against staging under representative write load. Output: lock duration, replication lag, p95 latency, error count. This is the gate that catches "correct on a copy, dies under load." MUST include pre-pinned `Thresholds:` (e.g. `replication lag p95 < 2s, abort at 5s; QPS 800 = prod p50`). Pin the numbers at planning time, not during execution.

**Apply Gate**: the migration runs against the real target. Output: same metrics as Stage-Load, plus the verify command still passes against the new state. If lock duration or lag exceed thresholds defined in Risks, abort and roll back.

Backfills are a sub-shape: the same three gates, but the Stage-Load Gate must include batching, sleep, and replication-lag circuit-breaker evidence.

## Invariant Gate (cross-shape)

For waves where the deliverable includes a "this must NOT exist" constraint, or "this must be unchanged between two snapshots." Use alongside the wave's primary gate, not instead of it.

Two patterns:

**Exit-1 invariant** (must-not-exist). The gate is a command whose expected exit code is non-zero (no matches) or whose output is asserted-empty.

- **No wrong-direction dependency**: `$ rg "infra::" src/domain/` returns exit 1.
- **No duplication**: `$ git diff --stat src/auth/` shows logic moved, not duplicated.
- **No secrets leakage**: `$ grep -r "BEGIN PRIVATE KEY" .` returns exit 1.

Paste the command and the exit code.

**Diff invariant** (must-be-unchanged). The gate is a snapshot captured before the wave and a diff at gate time.

- **Public API stable**: snapshot `$ rg "^pub " src/auth/ > /tmp/api-before` at the prior wave's gate, then at this gate `$ rg "^pub " src/auth/ > /tmp/api-after && diff /tmp/api-before /tmp/api-after` returns exit 0.
- **Route surface unchanged**: same pattern over `routes!` macro calls or OpenAPI spec.
- **Schema unchanged**: pg_dump --schema-only diff.

Paste the diff command and confirm it's empty (or the expected delta is the only one).

**Demonstrate against a known-positive case before trusting an Exit-1 gate.** A pattern-matching gate that has never been shown to match real violating code is a finding, not a gate. Run it against a stash/branch/commit where the violation exists, confirm exit 0 + the expected match, then assert it on clean code. Silent false-clean is worse than no gate.

**Recipe: Go cross-domain imports**

Go's `import` keyword appears once at the top of a block; paths sit on their own lines without it. Regexes that anchor on `import.*` will silently never match block imports.

```
$ rg -n '"<module>/internal/(forbidden_a|forbidden_b)"' <wave-package>/ --glob '!*_test.go'
# expect exit 1 (no matches in production code)
```

Carve out `*_test.go` when tests legitimately import sibling domains for seeding (mirror existing test patterns in the repo before assuming this applies).

## Composite Gates

A single gate line may contain multiple `$ command` invocations whose collective outcome is the gate. Use when no single command captures the proof.

Example:

```
Apply Gate (composite):
  $ nixos-rebuild switch --flake .#node-0 --target-host node-0   # exit 0
  $ curl -sfI https://pb.example.test/api/health                  # exit 0, returns 200
  $ tailscale ping node-1 | head -1                               # contains "via DIRECT"
  $ ss -tlnp | grep 5000                                          # shows tailnet bind only
```

Paste each command, its exit code, and the relevant output line. The wave is not done until every line is green.

If a composite gate has more than ~5 commands, consider whether the wave is doing two things and should split.

## Choosing a Shape

If a wave doesn't fit a shape above, default to the closest match and document the gate explicitly. Never invent a wave with no gate. A wave without a gate is a wish.
