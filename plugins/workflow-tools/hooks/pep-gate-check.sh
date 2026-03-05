#!/usr/bin/env bash
# Stop hook for PEP wave verification.
# Only activates when .pep-gate exists (created by /run-pep).
# Zero overhead on normal sessions.

GATE_FILE=".pep-gate"

# No state file = no PEP implementation active, allow stop
test -f "$GATE_FILE" || exit 0

PEP_INFO=$(cat "$GATE_FILE")

cat >&2 <<EOF
Active PEP implementation: $PEP_INFO

Before stopping, verify all gate criteria from the PEP:
1. Run every deterministic gate command (tests, type checks, linters)
2. Check each requirement against the actual code
3. If ALL gates pass: delete the .pep-gate file, then stop
4. If ANY gate fails: fix the issue and try again
EOF

exit 2
