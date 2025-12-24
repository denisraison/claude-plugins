#!/bin/bash
# Fast chunk manifest using find + jq
# Usage: chunk.sh [days]

set -uo pipefail

CLAUDE_DIR="$HOME/.claude"
PROJECTS_DIR="$CLAUDE_DIR/projects"
MAX_FILES=5
MAX_BYTES=200000  # ~50k tokens at 4 chars/token

days="${1:-7}"

# Collect files with sizes (compatible with GNU and BSD stat)
find "$PROJECTS_DIR" -name "*.jsonl" -type f -mtime -"$days" 2>/dev/null | \
    while IFS= read -r f; do
        size=$(stat -c %s "$f" 2>/dev/null || stat -f %z "$f" 2>/dev/null || echo 0)
        printf '{"path":"%s","size":%s}\n' "$f" "$size"
    done | \
    jq -s --argjson max_files "$MAX_FILES" --argjson max_bytes "$MAX_BYTES" '
        def chunk_files:
            reduce .[] as $f (
                {chunks: [], current: {files: [], total_bytes: 0}};
                if (.current.files | length) >= $max_files or (.current.total_bytes + $f.size) > $max_bytes then
                    if .current.files | length > 0 then
                        .chunks += [.current] | .current = {files: [$f.path], total_bytes: $f.size}
                    else
                        .current.files += [$f.path] | .current.total_bytes += $f.size
                    end
                else
                    .current.files += [$f.path] | .current.total_bytes += $f.size
                end
            ) | if .current.files | length > 0 then .chunks += [.current] else . end | .chunks;

        {
            total_files: length,
            total_bytes: (map(.size) | add // 0),
            estimated_tokens: ((map(.size) | add // 0) / 4 | floor),
            needs_parallel: (length > $max_files),
            chunk_count: (chunk_files | length),
            chunks: chunk_files
        }
    '
