#!/usr/bin/env bash
# Parallel research launcher
# Usage: ./research.sh "<topic>" <intensity> [output-dir]
# Intensity: quick (5), standard (15), extensive (40)

set -euo pipefail

TOPIC="${1:-}"
INTENSITY="${2:-standard}"
OUTPUT_DIR="${3:-}"

if [[ -z "$TOPIC" ]]; then
    echo "Usage: ./research.sh \"<topic>\" <intensity> [output-dir]" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -z "$OUTPUT_DIR" ]]; then
    OUTPUT_DIR="./scratch/research-$(date +%s)"
fi

case "$INTENSITY" in
    quick)     AGENTS_PER_MODEL=1 ;;
    standard)  AGENTS_PER_MODEL=3 ;;
    extensive) AGENTS_PER_MODEL=8 ;;
    *)         AGENTS_PER_MODEL=3 ;;
esac

mkdir -p "$OUTPUT_DIR"

MODELS=()
while IFS='|' read -r alias model desc; do
    [[ "$alias" =~ ^#.*$ || -z "$alias" ]] && continue
    MODELS+=("$alias")
done < "${SCRIPT_DIR}/models.conf"

PIDS=()
for model in "${MODELS[@]}"; do
    for i in $(seq 1 $AGENTS_PER_MODEL); do
        OUTPUT_FILE="${OUTPUT_DIR}/${model}-${i}.txt"
        "${SCRIPT_DIR}/consult.sh" "$model" "$TOPIC" "$OUTPUT_FILE" &
        PIDS+=($!)
    done
done

for pid in "${PIDS[@]}"; do
    wait "$pid" 2>/dev/null || true
done

echo "Results written to: $OUTPUT_DIR"
echo "Total agents: $((${#MODELS[@]} * AGENTS_PER_MODEL))"
