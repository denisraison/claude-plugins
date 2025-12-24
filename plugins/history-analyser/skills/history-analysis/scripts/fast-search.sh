#!/bin/bash
# Optimised search: rg for speed, jq for parsing
# Usage: fast-search.sh "pattern" [limit]

set -uo pipefail

CLAUDE_DIR="$HOME/.claude"
PROJECTS_DIR="$CLAUDE_DIR/projects"

query="${1:-}"
limit="${2:-20}"

if [[ -z "$query" ]]; then
    echo '{"error": "Usage: fast-search.sh pattern [limit]"}'
    exit 1
fi

# rg --json gives structured output we can parse
rg -i --json "$query" "$PROJECTS_DIR" 2>/dev/null | \
jq -s --arg q "$query" --argjson limit "$limit" '
    # Filter to match lines only
    [.[] | select(.type == "match")] |

    # Parse the JSON content of each matching line
    [.[] | .data | {
        file: .path.text,
        line_num: .line_number,
        raw: .lines.text
    }] |

    # Parse the JSONL content and extract useful info
    [.[] | . as $meta | try (
        .raw | fromjson |
        select(.type == "user" or .type == "assistant") |
        {
            file: $meta.file,
            line: $meta.line_num,
            type: .type,
            timestamp: .timestamp,
            project: (.cwd | split("/") | last),
            session: .sessionId[0:8],
            content: (
                if .type == "user" then
                    (.message.content | if type == "string" then .[0:200] else "" end) //
                    .display[0:200] // ""
                else
                    # Assistant: extract text blocks
                    [.message.content[]? | select(.type == "text") | .text[0:100]] | join(" ")[0:200]
                end
            )
        } | select(.content != "" and (.content | length) > 10)
    ) catch empty] |

    # Dedupe by content similarity, keep first occurrence
    unique_by(.content[0:50]) |

    # Sort by timestamp desc
    sort_by(.timestamp) | reverse |

    {
        query: $q,
        total_matches: length,
        matches: .[:$limit]
    }
'
