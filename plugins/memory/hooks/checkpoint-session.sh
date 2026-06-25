#!/usr/bin/env bash
# Auto-checkpoint a Claude Code session into the global daily session log.
# Wired to PreCompact and SessionEnd via hooks.json. Reads JSON from stdin.
#
# Receives (PreCompact / SessionEnd):
#   { session_id, transcript_path, cwd, hook_event_name, trigger?|reason? }
#
# Spawns claude -p in background to do the summarization + append.
# Returns immediately so it never blocks compact/session-exit.

set -u

INPUT=$(cat)
TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // empty')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // empty')
REASON=$(echo "$INPUT" | jq -r '.reason // .trigger // empty')

# Resolve the same memory root the note-session command uses, so checkpoints and /recall
# read/write the same dir on any machine. Honors CLAUDE_CONFIG_DIR if set.
MEM_ROOT="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/memory"
LOG_DIR="$MEM_ROOT/sessions"
HOOK_LOG="$LOG_DIR/.hook.log"
mkdir -p "$LOG_DIR"

# Recursion guard: if this hook fired from a subprocess we spawned, bail.
if [ "${MEMORY_CHECKPOINT_SUBPROCESS:-}" = "1" ]; then
  echo "$(date -Iseconds) skipped (subprocess) event=$EVENT" >> "$HOOK_LOG"
  exit 0
fi

# No transcript, nothing to summarize.
if [ -z "$TRANSCRIPT" ] || [ ! -f "$TRANSCRIPT" ]; then
  echo "$(date -Iseconds) skipped (no transcript) event=$EVENT session=$SESSION_ID" >> "$HOOK_LOG"
  exit 0
fi

# Cheap gate: each spawned checkpoint loads ~20-25k tokens of fixed context (CLAUDE.md,
# MEMORY.md, skills list) before reading the transcript, so trivial sessions aren't worth it.
# Compute new lines vs the command's watermark in pure bash and skip the subprocess for tiny
# SessionEnd events. PreCompact is unconditional since that's when context is about to be lost.
SESSION_END_MIN_LINES="${SESSION_END_MIN_LINES:-50}"
if [ "$EVENT" = "SessionEnd" ]; then
  WM_ID=$(basename "$TRANSCRIPT" .jsonl)
  WATERMARK="$LOG_DIR/.watermark-$WM_ID"
  PREV=$(cat "$WATERMARK" 2>/dev/null || echo 0)
  CUR=$(wc -l < "$TRANSCRIPT" 2>/dev/null || echo 0)
  NEW=$(( CUR - PREV ))
  if [ "$NEW" -lt "$SESSION_END_MIN_LINES" ]; then
    echo "$(date -Iseconds) skipped (only $NEW new lines, <$SESSION_END_MIN_LINES) event=$EVENT session=$SESSION_ID" >> "$HOOK_LOG"
    exit 0
  fi
fi

# Spawn the actual checkpoint work in background, detached. Hook returns instantly.
(
  export MEMORY_CHECKPOINT_SUBPROCESS=1
  PROMPT="Run /note-session for transcript path: $TRANSCRIPT (session $SESSION_ID, cwd $CWD, event $EVENT, reason $REASON). Use that exact transcript file, not the most-recent in the cwd dir, since this is being invoked from a subprocess."
  # Haiku is plenty for this structured summarization and ~10x cheaper than Sonnet.
  # Override via CHECKPOINT_MODEL (e.g. CHECKPOINT_MODEL=sonnet for sharper "Worth remembering").
  MODEL="${CHECKPOINT_MODEL:-haiku}"
  # bypassPermissions: headless subprocess can't answer permission prompts, so without this the
  # /note-session skill invocation silently fails ("requires permission") and writes nothing.
  # Prompt must come BEFORE --allowedTools: that flag is variadic (<tools...>) and would otherwise
  # swallow the prompt string as a tool name.
  claude -p "$PROMPT" \
    --model "$MODEL" \
    --permission-mode bypassPermissions \
    --allowedTools Bash Read Write Edit Skill >> "$HOOK_LOG" 2>&1
  RC=$?
  if [ "$RC" -eq 0 ]; then
    echo "$(date -Iseconds) done event=$EVENT session=$SESSION_ID reason=$REASON" >> "$HOOK_LOG"
  else
    echo "$(date -Iseconds) FAILED (rc=$RC) event=$EVENT session=$SESSION_ID reason=$REASON" >> "$HOOK_LOG"
  fi
) </dev/null >/dev/null 2>&1 &

disown 2>/dev/null || true
exit 0
