#!/usr/bin/env bash
# Decide whether this turn warrants a review.
#
# Exits 0 = run review. Exits 1 = skip.
#
# Logic (ported from Hermes' _skill_nudge_interval + signal triggers):
#   1. Minimum user-turn floor: skip if < AUTO_IMPROVE_MIN_TURNS (default 4).
#   2. No-op skip: if last user message is "ok"/"thanks"/"continue"/empty.
#   3. Signal override: fire immediately on frustration markers, explicit
#      "remember this" requests, or assistant tool errors followed by a
#      user correction. Bypasses the interval.
#   4. Interval gating: otherwise only fire every AUTO_IMPROVE_INTERVAL
#      user turns since the last review (default 5).
#
# State lives at $STATE_DIR/<session_id>.json with shape:
#   {"last_reviewed_turn": <int>}

set -u

TRANSCRIPT_PATH="${1:-}"
SESSION_ID="${2:-unknown}"

[ -z "$TRANSCRIPT_PATH" ] || [ ! -f "$TRANSCRIPT_PATH" ] && exit 1

MIN_TURNS="${AUTO_IMPROVE_MIN_TURNS:-4}"
INTERVAL="${AUTO_IMPROVE_INTERVAL:-5}"

STATE_DIR="${AUTO_IMPROVE_LOG_DIR:-${CLAUDE_CONFIG_DIR:-$HOME/.claude}/auto-improve}/state"
mkdir -p "$STATE_DIR"
STATE_FILE="$STATE_DIR/${SESSION_ID}.json"

USER_TURNS=$(jq -s 'map(select(.type == "user")) | length' "$TRANSCRIPT_PATH" 2>/dev/null || echo 0)

# (1) Minimum turn floor.
if [ "${USER_TURNS:-0}" -lt "$MIN_TURNS" ]; then
  exit 1
fi

# Pull the last user message text for signal detection.
LAST_USER_TEXT=$(jq -r '
  select(.type == "user")
  | .message | select(. != null)
  | (
      if (.content | type) == "string" then .content
      elif (.content | type) == "array" then
        ([.content[] | select(.type == "text") | .text] | join("\n"))
      else "" end
    )
' "$TRANSCRIPT_PATH" 2>/dev/null | tail -c 8000)

# (2) No-op skip. Trim whitespace and check trivial follow-ups.
LAST_TRIMMED=$(printf '%s' "$LAST_USER_TEXT" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
case "$LAST_TRIMMED" in
  ""|"ok"|"okay"|"thanks"|"thank you"|"thx"|"ty"|"continue"|"go"|"go on"|"yes"|"yeah"|"yep"|"yup"|"no"|"nope"|"sure"|"k")
    exit 1
    ;;
esac

# (3) Signal override — fire immediately.
LAST_LOWER=$(printf '%s' "$LAST_USER_TEXT" | tr '[:upper:]' '[:lower:]')

is_signal=0

# Frustration markers
if printf '%s' "$LAST_LOWER" | grep -Eq "stop (doing|saying|using|that)|don'?t (do|say|use|format)|why are you|just give me|i hate|that'?s wrong|no,?\s+(thats|that is|that's)\s+(wrong|not right)|you always|i told you|i said"; then
  is_signal=1
fi

# Explicit save signals
if printf '%s' "$LAST_LOWER" | grep -Eq "remember (this|that)|save (this|that)|don'?t forget|please remember|note this|write this down|add to (memory|skill)"; then
  is_signal=1
fi

# Error+correction: did the assistant's last message contain a tool error
# AND the user's last message contain a corrective marker?
if [ "$is_signal" = "0" ]; then
  LAST_ASSISTANT_TEXT=$(jq -r '
    select(.type == "assistant")
    | .message | select(. != null)
    | (
        if (.content | type) == "array" then
          ([.content[] | select(.type == "text") | .text] | join("\n"))
        else "" end
      )
  ' "$TRANSCRIPT_PATH" 2>/dev/null | tail -c 4000 | tr '[:upper:]' '[:lower:]')
  if printf '%s' "$LAST_ASSISTANT_TEXT" | grep -Eq "error|failed|exception|cannot|could not" && \
     printf '%s' "$LAST_LOWER" | grep -Eq "no|wrong|actually|instead|try|the issue|the problem"; then
    is_signal=1
  fi
fi

if [ "$is_signal" = "1" ]; then
  # Record this turn as the new baseline so the interval restarts here.
  printf '{"last_reviewed_turn": %s}\n' "$USER_TURNS" > "$STATE_FILE"
  exit 0
fi

# (4) Interval gating.
LAST_REVIEWED=0
if [ -f "$STATE_FILE" ]; then
  LAST_REVIEWED=$(jq -r '.last_reviewed_turn // 0' "$STATE_FILE" 2>/dev/null || echo 0)
fi

DELTA=$((USER_TURNS - LAST_REVIEWED))
if [ "$DELTA" -lt "$INTERVAL" ]; then
  exit 1
fi

printf '{"last_reviewed_turn": %s}\n' "$USER_TURNS" > "$STATE_FILE"
exit 0
