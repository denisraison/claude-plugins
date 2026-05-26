#!/usr/bin/env bash
# Print the candidate skill list for the curator review pass.
# One skill per line, format: <state>\t<days-since-mtime>\t<pinned>\t<name>\t<one-line-desc>
# Only includes skills under ~/.claude-work/skills/. Never touches plugins/*/skills/.
set -euo pipefail

ROOT="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
SKILLS_DIR="$ROOT/skills"
STATE="$ROOT/curator/state.json"
NOW="$(date -u +%s)"

if [[ ! -d "$SKILLS_DIR" ]]; then
  exit 0
fi

# Load pin list (jq optional — fall back to empty)
PINS=""
if command -v jq >/dev/null 2>&1 && [[ -f "$STATE" ]]; then
  PINS="$(jq -r '.pinned[]? // empty' "$STATE" 2>/dev/null || true)"
fi
is_pinned() {
  local name="$1"
  [[ -z "$PINS" ]] && { echo "no"; return; }
  grep -qx "$name" <<< "$PINS" && echo "yes" || echo "no"
}

for d in "$SKILLS_DIR"/*/; do
  [[ -d "$d" ]] || continue
  name="$(basename "$d")"
  # Skip archive and hidden dirs
  [[ "$name" == .* ]] && continue
  skill_md="$d/SKILL.md"
  [[ -f "$skill_md" ]] || continue

  mtime="$(stat -f%m "$skill_md" 2>/dev/null || stat -c%Y "$skill_md")"
  days=$(( (NOW - mtime) / 86400 ))

  if (( days >= 90 )); then
    state="archive-due"
  elif (( days >= 30 )); then
    state="stale"
  else
    state="active"
  fi

  desc="$(awk '/^description:/{sub(/^description:[[:space:]]*/,""); print; exit}' "$skill_md" 2>/dev/null || echo "")"
  [[ -z "$desc" ]] && desc="$(awk 'NR<=20 && /^[^#-]/ && NF{print; exit}' "$skill_md" 2>/dev/null || echo "")"
  desc="$(echo "$desc" | tr -d '\t' | cut -c1-120)"

  pinned="$(is_pinned "$name")"
  printf '%s\t%d\t%s\t%s\t%s\n' "$state" "$days" "$pinned" "$name" "$desc"
done | sort
