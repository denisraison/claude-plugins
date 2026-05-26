#!/usr/bin/env bash
# Stop hook entrypoint. Fires after every assistant response (per-turn).
#
# Decides whether THIS turn warrants a review, then spawns the worker
# detached. Throttling is interval-based with signal-driven overrides,
# modelled on Hermes' _skill_nudge_interval + frustration-marker logic.

set -u

# Killswitch.
if [ "${AUTO_IMPROVE_DISABLED:-0}" = "1" ]; then
  exit 0
fi

# Recursion guard. The review agent itself is a Claude session whose
# own Stop event would otherwise fire this hook again.
if [ "${AUTO_IMPROVE_IS_REVIEW:-0}" = "1" ]; then
  exit 0
fi

INPUT=$(cat)

STOP_HOOK_ACTIVE=$(printf '%s' "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null)
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
  exit 0
fi

TRANSCRIPT_PATH=$(printf '%s' "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null)
SESSION_ID=$(printf '%s' "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
CWD=$(printf '%s' "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
[ -z "$CWD" ] && CWD="$PWD"

if [ -z "$TRANSCRIPT_PATH" ] || [ ! -f "$TRANSCRIPT_PATH" ]; then
  exit 0
fi

# Decide locally whether to fire. Cheap operations only here, the heavy
# review is spawned in the worker.
DECISION_SCRIPT="${CLAUDE_PLUGIN_ROOT}/hooks/should-review.sh"
if [ -x "$DECISION_SCRIPT" ]; then
  if ! "$DECISION_SCRIPT" "$TRANSCRIPT_PATH" "$SESSION_ID"; then
    exit 0
  fi
fi

# Spawn detached so the main session returns immediately.
RUN_SCRIPT="${CLAUDE_PLUGIN_ROOT}/hooks/run-review.sh"
nohup bash "$RUN_SCRIPT" "$TRANSCRIPT_PATH" "$SESSION_ID" "$CWD" >/dev/null 2>&1 &
disown

exit 0
