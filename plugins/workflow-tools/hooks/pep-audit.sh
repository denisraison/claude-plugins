#!/usr/bin/env bash
# PostToolUse hook: pipes the payload to `pep audit record` when the
# current working directory has a `.pep/state.db`. Silent no-op otherwise
# so repos without pep set up don't accrete `.pep/audit-*.jsonl` files.
#
# Never blocks the session: exits 0 even on parse errors or write failures
# (`pep audit record` already swallows malformed payloads, and we trap any
# unexpected exit code to keep PostToolUse non-blocking).

set -u

if [[ ! -f .pep/state.db ]]; then
  exit 0
fi

if ! command -v pep >/dev/null 2>&1; then
  echo "pep-audit: 'pep' CLI not on PATH; skipping" >&2
  exit 0
fi

if ! pep audit record 2>/tmp/pep-audit-err.log; then
  echo "pep-audit: record failed, see /tmp/pep-audit-err.log" >&2
fi

exit 0
