#!/usr/bin/env bash
# Detached background review worker.
# Args: <transcript_path> <session_id> <cwd>
#
# Extracts the conversation from the JSONL transcript, invokes `claude -p`
# with a restricted tool allowlist, and points it at the Hermes-style
# combined review prompt. The review agent decides whether to update
# memory or skills, then exits.

set -u

TRANSCRIPT_PATH="${1:-}"
SESSION_ID="${2:-unknown}"
CWD="${3:-$PWD}"

if [ -z "$TRANSCRIPT_PATH" ] || [ ! -f "$TRANSCRIPT_PATH" ]; then
  exit 0
fi

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROMPT_FILE="$PLUGIN_DIR/skills/background-review/references/combined-review-prompt.md"

LOG_DIR="${AUTO_IMPROVE_LOG_DIR:-${CLAUDE_CONFIG_DIR:-$HOME/.claude}/auto-improve}"
mkdir -p "$LOG_DIR"
TS=$(date -u +%Y%m%dT%H%M%SZ)
LOG_FILE="$LOG_DIR/${TS}_${SESSION_ID}.log"

# Threshold: skip very short sessions (less than 4 user turns produces noise).
USER_TURNS=$(jq -s 'map(select(.type == "user")) | length' "$TRANSCRIPT_PATH" 2>/dev/null || echo 0)
if [ "${USER_TURNS:-0}" -lt 4 ]; then
  echo "[skip] only ${USER_TURNS} user turns in $TRANSCRIPT_PATH" > "$LOG_FILE"
  exit 0
fi

# Build a plain-text transcript snippet. Strip tool calls / tool results to
# keep the review focused on the user-assistant dialogue. Truncate to keep
# the prompt manageable.
TRANSCRIPT_TEXT=$(jq -r '
  select(.type == "user" or .type == "assistant")
  | .message
  | select(. != null)
  | (
      if (.content | type) == "string" then
        "[" + (.role // "?") + "]\n" + .content
      elif (.content | type) == "array" then
        "[" + (.role // "?") + "]\n" + ([.content[] | select(.type == "text") | .text] | join("\n"))
      else
        empty
      end
    )
' "$TRANSCRIPT_PATH" 2>/dev/null | tail -c 200000)

if [ -z "$TRANSCRIPT_TEXT" ]; then
  echo "[skip] empty transcript text" > "$LOG_FILE"
  exit 0
fi

REVIEW_PROMPT=$(cat "$PROMPT_FILE")

# Resolve the active Claude Code home. Falls back to ~/.claude if unset.
CLAUDE_HOME="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
MEMORY_SLUG=$(printf '%s' "$CWD" | sed 's|/|-|g')
MEMORY_DIR="$CLAUDE_HOME/projects/${MEMORY_SLUG}/memory"
SKILLS_DIR="$CLAUDE_HOME/skills"

FULL_INPUT=$(cat <<EOF
You are a background review agent. The conversation below just ended in working directory: $CWD

Session id: $SESSION_ID

Write locations for this run (use these exact paths, do not improvise):
- Memory:  $MEMORY_DIR
- Skills:  $SKILLS_DIR/<skill-name>/

Create the memory or skills directory if it does not exist. For memory, update $MEMORY_DIR/MEMORY.md to index any new file.

--- CONVERSATION ---
$TRANSCRIPT_TEXT
--- END CONVERSATION ---

$REVIEW_PROMPT
EOF
)

# Restricted tool allowlist: read/write/edit files only. No bash, no agent,
# no web. The review agent should not run commands or fetch URLs.
ALLOWED_TOOLS="Read,Write,Edit,Glob,LS"

# Review model. Haiku is the right grade for "read transcript, decide,
# write structured markdown" — ~10-15x cheaper than Opus, fast enough that
# even long transcripts finish in well under a minute. Override with
# AUTO_IMPROVE_MODEL if you want to dial it up.
REVIEW_MODEL="${AUTO_IMPROVE_MODEL:-haiku}"

{
  echo "=== auto-improve review @ $TS ==="
  echo "session_id: $SESSION_ID"
  echo "cwd: $CWD"
  echo "claude_home: $CLAUDE_HOME"
  echo "memory_dir: $MEMORY_DIR"
  echo "skills_dir: $SKILLS_DIR"
  echo "transcript: $TRANSCRIPT_PATH"
  echo "user_turns: $USER_TURNS"
  echo "model: $REVIEW_MODEL"
  echo "---"
} > "$LOG_FILE"

# Run the review. Append both stdout and stderr.
printf '%s' "$FULL_INPUT" \
  | AUTO_IMPROVE_IS_REVIEW=1 claude -p \
      --model "$REVIEW_MODEL" \
      --allowed-tools "$ALLOWED_TOOLS" \
      --permission-mode acceptEdits \
  >> "$LOG_FILE" 2>&1

echo "---" >> "$LOG_FILE"
echo "=== done @ $(date -u +%Y%m%dT%H%M%SZ) ===" >> "$LOG_FILE"
