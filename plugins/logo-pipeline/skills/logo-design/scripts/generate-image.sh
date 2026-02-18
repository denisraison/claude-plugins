#!/usr/bin/env bash
# Generate or edit an image via Gemini API.
# Usage: generate-image.sh --prompt "..." --model flash|pro --output path.png [--aspect-ratio 1:1] [--image-size 1K|2K|4K] [--input-image source.png]

set -euo pipefail

# Defaults
ASPECT_RATIO="1:1"
IMAGE_SIZE=""
PROMPT=""
MODEL_ALIAS=""
OUTPUT=""
INPUT_IMAGE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --prompt)       PROMPT="$2"; shift 2 ;;
        --model)        MODEL_ALIAS="$2"; shift 2 ;;
        --output)       OUTPUT="$2"; shift 2 ;;
        --aspect-ratio) ASPECT_RATIO="$2"; shift 2 ;;
        --image-size)   IMAGE_SIZE="$2"; shift 2 ;;
        --input-image)  INPUT_IMAGE="$2"; shift 2 ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

if [[ -z "$PROMPT" || -z "$MODEL_ALIAS" || -z "$OUTPUT" ]]; then
    echo "Required: --prompt, --model (flash|pro), --output" >&2
    exit 1
fi

if [[ -n "$INPUT_IMAGE" && ! -f "$INPUT_IMAGE" ]]; then
    echo "Input image not found: $INPUT_IMAGE" >&2
    exit 1
fi

if [[ -z "${GEMINI_API_KEY:-}" ]]; then
    echo "GEMINI_API_KEY not set" >&2
    exit 1
fi

# Resolve model alias to full model ID
case "$MODEL_ALIAS" in
    flash) MODEL="gemini-2.5-flash-image" ;;
    pro)   MODEL="gemini-3-pro-image-preview" ;;
    *)     echo "Unknown model alias: $MODEL_ALIAS (use flash or pro)" >&2; exit 1 ;;
esac

URL="https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent?key=${GEMINI_API_KEY}"

# Build generation config
IMAGE_CONFIG=$(jq -n --arg ar "$ASPECT_RATIO" '{aspectRatio: $ar}')

if [[ -n "$IMAGE_SIZE" ]]; then
    IMAGE_CONFIG=$(echo "$IMAGE_CONFIG" | jq --arg sz "$IMAGE_SIZE" '. + {imageSize: $sz}')
fi

GEN_CONFIG=$(jq -n \
    --argjson ic "$IMAGE_CONFIG" \
    '{
        responseModalities: ["TEXT", "IMAGE"],
        responseMimeType: "text/plain",
        imageConfig: $ic
    }')

# Build request body
if [[ -n "$INPUT_IMAGE" ]]; then
    # Image editing: include source image + text prompt
    # Write base64 to temp file to avoid argument length limits
    INPUT_B64_FILE="/tmp/gemini-input-$$.b64"
    base64 -w0 "$INPUT_IMAGE" > "$INPUT_B64_FILE"
    trap 'rm -f "$TMPFILE" "$REQFILE" "$INPUT_B64_FILE"' EXIT
    INPUT_MIME="image/png"
    case "${INPUT_IMAGE,,}" in
        *.jpg|*.jpeg) INPUT_MIME="image/jpeg" ;;
        *.webp) INPUT_MIME="image/webp" ;;
    esac
    REQUEST=$(jq -n \
        --arg prompt "$PROMPT" \
        --rawfile img_data "$INPUT_B64_FILE" \
        --arg img_mime "$INPUT_MIME" \
        --argjson gen_config "$GEN_CONFIG" \
        '{
            contents: [{
                parts: [
                    {text: $prompt},
                    {inlineData: {mimeType: $img_mime, data: $img_data}}
                ]
            }],
            generationConfig: $gen_config
        }')
else
    # Text-to-image: prompt only
    REQUEST=$(jq -n \
        --arg prompt "$PROMPT" \
        --argjson gen_config "$GEN_CONFIG" \
        '{
            contents: [{
                parts: [{text: $prompt}]
            }],
            generationConfig: $gen_config
        }')
fi

# PID-based temp files for parallel safety
TMPFILE="/tmp/gemini-response-$$.json"
REQFILE="/tmp/gemini-request-$$.json"
trap 'rm -f "$TMPFILE" "$REQFILE"' EXIT

# Write request body to file (avoids argument length limits for large payloads)
echo "$REQUEST" > "$REQFILE"

# API call with single retry on 429
call_api() {
    local http_code
    http_code=$(curl -s -w "%{http_code}" -o "$TMPFILE" \
        -X POST "$URL" \
        -H "Content-Type: application/json" \
        -d @"$REQFILE")

    echo "$http_code"
}

HTTP_CODE=$(call_api)

if [[ "$HTTP_CODE" == "429" ]]; then
    echo "Rate limited, retrying in 30s..." >&2
    sleep 30
    HTTP_CODE=$(call_api)
fi

if [[ "$HTTP_CODE" != "200" ]]; then
    echo "API error (HTTP $HTTP_CODE):" >&2
    cat "$TMPFILE" >&2
    exit 1
fi

# Extract base64 image data and mime type from response
# Response structure: candidates[0].content.parts[] where part has inlineData.{data,mimeType}
IMAGE_DATA=$(jq -r '
    .candidates[0].content.parts[]
    | select(.inlineData != null)
    | .inlineData.data
' "$TMPFILE" | head -1)

RESPONSE_MIME=$(jq -r '
    .candidates[0].content.parts[]
    | select(.inlineData != null)
    | .inlineData.mimeType
' "$TMPFILE" | head -1)

if [[ -z "$IMAGE_DATA" || "$IMAGE_DATA" == "null" ]]; then
    echo "No image data in response. Response:" >&2
    jq . "$TMPFILE" >&2
    exit 1
fi

# Ensure output directory exists
mkdir -p "$(dirname "$OUTPUT")"

# Decode and convert to PNG if the API returned JPEG but output expects PNG
RAWTMP="/tmp/gemini-raw-$$.img"
echo "$IMAGE_DATA" | base64 -d > "$RAWTMP"

if [[ "$OUTPUT" == *.png && "$RESPONSE_MIME" == "image/jpeg" ]] && command -v magick &>/dev/null; then
    magick "$RAWTMP" "$OUTPUT"
    rm -f "$RAWTMP"
else
    mv "$RAWTMP" "$OUTPUT"
fi

echo "Saved: $OUTPUT ($(du -h "$OUTPUT" | cut -f1))"
