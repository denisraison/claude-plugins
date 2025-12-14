#!/usr/bin/env bash
# Single model consultation
# Usage: ./consult.sh <model-alias> "<prompt>" [output-file]

set -euo pipefail

MODEL_ALIAS="${1:-sonnet}"
PROMPT="${2:-}"
OUTPUT_FILE="${3:-}"

if [[ -z "$PROMPT" ]]; then
    echo "Usage: ./consult.sh <model-alias> \"<prompt>\" [output-file]" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

resolve_model() {
    local alias="$1"
    while IFS='|' read -r a model desc; do
        [[ "$a" =~ ^#.*$ || -z "$a" ]] && continue
        [[ "$a" == "$alias" ]] && echo "$model" && return 0
    done < "${SCRIPT_DIR}/models.conf"
    echo "$alias"
}

MODEL_ID=$(resolve_model "$MODEL_ALIAS")

if [[ -n "$OUTPUT_FILE" ]]; then
    cursor-agent -p "$PROMPT" --model "$MODEL_ID" --output-format text > "$OUTPUT_FILE"
else
    cursor-agent -p "$PROMPT" --model "$MODEL_ID" --output-format text
fi
