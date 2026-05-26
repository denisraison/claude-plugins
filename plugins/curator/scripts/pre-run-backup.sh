#!/usr/bin/env bash
# Snapshot ~/.claude-work/skills/ to a timestamped tar.gz before a curator pass.
# Prune to the newest KEEP backups. Idempotent: safe to call from /curate or manually.
set -euo pipefail

KEEP="${CURATOR_BACKUP_KEEP:-5}"
ROOT="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
SKILLS_DIR="$ROOT/skills"
BACKUP_ROOT="$ROOT/curator/backups"
REASON="${1:-pre-run}"

if [[ ! -d "$SKILLS_DIR" ]]; then
  echo "curator: no skills dir at $SKILLS_DIR — nothing to back up" >&2
  exit 0
fi

TS="$(date -u +%Y%m%dT%H%M%SZ)"
DEST="$BACKUP_ROOT/$TS"
mkdir -p "$DEST"

tar -czf "$DEST/skills.tar.gz" -C "$ROOT" skills
SIZE="$(stat -f%z "$DEST/skills.tar.gz" 2>/dev/null || stat -c%s "$DEST/skills.tar.gz")"

cat > "$DEST/manifest.json" <<EOF
{
  "ts": "$TS",
  "reason": "$REASON",
  "size_bytes": $SIZE,
  "source": "$SKILLS_DIR"
}
EOF

# Prune oldest beyond KEEP (BSD/GNU head differ — count then drop)
ALL=()
while IFS= read -r line; do ALL+=("$line"); done < <(ls -1 "$BACKUP_ROOT" 2>/dev/null | sort)
COUNT=${#ALL[@]}
if (( COUNT > KEEP )); then
  DROP=$(( COUNT - KEEP ))
  for ((i=0; i<DROP; i++)); do
    rm -rf "$BACKUP_ROOT/${ALL[$i]}"
  done
fi

echo "$DEST/skills.tar.gz"
