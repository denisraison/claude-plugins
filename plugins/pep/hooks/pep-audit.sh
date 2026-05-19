#!/usr/bin/env bash
# PostToolUse hook: append Bash|Edit|Write payloads to .pep/audit.log as
# JSONL. Silent no-op when CWD has no .pep/ directory (so repos without a
# PEP in flight don't accumulate audit files).
#
# Each line is one JSON object: {ts, tool, command|file_path, exit_code?}.
# The skill greps this log before claiming a gate command ran in-session.
#
# Never blocks the session: exits 0 on any error.

set -u

if [[ ! -d .pep ]]; then
  exit 0
fi

payload=$(cat)
ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# The payload is the full tool-use JSON. Extract the fields we care about
# with jq if available; otherwise write a minimal raw line.
if command -v jq >/dev/null 2>&1; then
  printf '%s' "$payload" | jq -c \
    --arg ts "$ts" \
    '{
      ts: $ts,
      tool: (.tool_name // .tool // "unknown"),
      command: (.tool_input.command // null),
      file_path: (.tool_input.file_path // null),
      exit_code: (.tool_response.exit_code // .tool_result.exit_code // null)
    }' >> .pep/audit.log 2>/dev/null || true
else
  printf '{"ts":"%s","raw":%s}\n' "$ts" "$(printf '%s' "$payload" | head -c 4096 | tr -d '\n' | sed 's/"/\\"/g' | awk '{print "\""$0"\""}')" >> .pep/audit.log 2>/dev/null || true
fi

exit 0
