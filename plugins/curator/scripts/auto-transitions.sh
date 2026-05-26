#!/usr/bin/env bash
# Deterministic state pass — no LLM. Move skills based on SKILL.md mtime:
#   - unused 90d -> archive (mv to .archive/)
#   - unused 30d -> mark stale (touch .stale sentinel)
#   - touched since stale -> unmark
# Pinned skills are skipped. Curator-touch exclusion: a sentinel file
# .curator-touch keeps mtime bumps from curator edits from re-activating skills.
set -euo pipefail

ROOT="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
SKILLS_DIR="$ROOT/skills"
ARCHIVE_DIR="$SKILLS_DIR/.archive"
STATE="$ROOT/curator/state.json"
NOW="$(date -u +%s)"
STALE_DAYS="${CURATOR_STALE_DAYS:-30}"
ARCHIVE_DAYS="${CURATOR_ARCHIVE_DAYS:-90}"
DRY_RUN="${1:-}"

mkdir -p "$ARCHIVE_DIR"

PINS=""
if command -v jq >/dev/null 2>&1 && [[ -f "$STATE" ]]; then
  PINS="$(jq -r '.pinned[]? // empty' "$STATE" 2>/dev/null || true)"
fi
is_pinned() {
  [[ -z "$PINS" ]] && return 1
  grep -qx "$1" <<< "$PINS"
}

stale_count=0
archive_count=0
reactivated=0

for d in "$SKILLS_DIR"/*/; do
  [[ -d "$d" ]] || continue
  name="$(basename "$d")"
  [[ "$name" == .* ]] && continue
  skill_md="$d/SKILL.md"
  [[ -f "$skill_md" ]] || continue
  is_pinned "$name" && continue

  # Activity anchor: max of SKILL.md mtime and any non-curator touch file
  mtime="$(stat -f%m "$skill_md" 2>/dev/null || stat -c%Y "$skill_md")"
  # If the only recent change was a curator touch, exclude that
  if [[ -f "$d/.curator-touch" ]]; then
    ct="$(stat -f%m "$d/.curator-touch" 2>/dev/null || stat -c%Y "$d/.curator-touch")"
    if [[ "$mtime" -le "$ct" ]]; then
      # SKILL.md was last touched by curator — fall back to created sentinel if present
      if [[ -f "$d/.curator-created" ]]; then
        mtime="$(stat -f%m "$d/.curator-created" 2>/dev/null || stat -c%Y "$d/.curator-created")"
      fi
    fi
  fi

  age_days=$(( (NOW - mtime) / 86400 ))
  stale_sentinel="$d/.stale"

  if (( age_days >= ARCHIVE_DAYS )); then
    if [[ "$DRY_RUN" == "--dry-run" ]]; then
      echo "would-archive: $name (age=${age_days}d)"
    else
      mv "$d" "$ARCHIVE_DIR/$name.$(date -u +%Y%m%dT%H%M%SZ)"
      echo "archived: $name (age=${age_days}d)"
    fi
    archive_count=$((archive_count + 1))
  elif (( age_days >= STALE_DAYS )); then
    if [[ ! -f "$stale_sentinel" ]]; then
      if [[ "$DRY_RUN" == "--dry-run" ]]; then
        echo "would-mark-stale: $name (age=${age_days}d)"
      else
        touch "$stale_sentinel"
        echo "stale: $name (age=${age_days}d)"
      fi
      stale_count=$((stale_count + 1))
    fi
  else
    if [[ -f "$stale_sentinel" ]]; then
      if [[ "$DRY_RUN" == "--dry-run" ]]; then
        echo "would-reactivate: $name (age=${age_days}d)"
      else
        rm -f "$stale_sentinel"
        echo "reactivated: $name (age=${age_days}d)"
      fi
      reactivated=$((reactivated + 1))
    fi
  fi
done

echo "---"
echo "summary: stale=$stale_count archived=$archive_count reactivated=$reactivated"
