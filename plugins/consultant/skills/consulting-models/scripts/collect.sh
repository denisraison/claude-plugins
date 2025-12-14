#!/usr/bin/env bash
# Collect and format research results
# Usage: ./collect.sh <output-dir>

set -euo pipefail

OUTPUT_DIR="${1:-}"

if [[ -z "$OUTPUT_DIR" || ! -d "$OUTPUT_DIR" ]]; then
    echo "Error: Output directory not found: $OUTPUT_DIR" >&2
    exit 1
fi

echo "=== RESEARCH RESULTS ==="
echo ""

for file in "$OUTPUT_DIR"/*.txt; do
    [[ -f "$file" ]] || continue
    BASENAME=$(basename "$file" .txt)
    echo "--- ${BASENAME} ---"
    cat "$file"
    echo ""
done
