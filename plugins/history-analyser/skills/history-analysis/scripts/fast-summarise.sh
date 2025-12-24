#!/bin/bash
# Fast summarisation using jq
# Usage: fast-summarise.sh [days] [file_limit]

set -uo pipefail

CLAUDE_DIR="$HOME/.claude"
PROJECTS_DIR="$CLAUDE_DIR/projects"

days="7"
file_limit="0"  # 0 = no limit

# Parse args (support both positional and --flags)
while [[ $# -gt 0 ]]; do
    case "$1" in
        --days) days="$2"; shift 2 ;;
        --limit) file_limit="$2"; shift 2 ;;
        [0-9]*) days="$1"; shift ;;
        *) shift ;;
    esac
done

# Find recent files and aggregate with jq
if [[ "$file_limit" -gt 0 ]]; then
    files=$(find "$PROJECTS_DIR" -name "*.jsonl" -type f -mtime -"$days" 2>/dev/null | head -n "$file_limit")
else
    files=$(find "$PROJECTS_DIR" -name "*.jsonl" -type f -mtime -"$days" 2>/dev/null)
fi

echo "$files" | \
    xargs cat 2>/dev/null | \
    jq -s '
        # Filter to user/assistant messages
        [.[] | select(.type == "user" or .type == "assistant")] |

        {
            message_count: length,
            user_count: [.[] | select(.type == "user")] | length,
            assistant_count: [.[] | select(.type == "assistant")] | length,

            # Top projects by message count
            projects: (
                [.[] | .cwd // "" | split("/") | last | select(. != "")] |
                group_by(.) |
                map({project: .[0], count: length}) |
                sort_by(-.count) |
                .[0:10]
            ),

            # Top tools used
            tools_used: (
                [.[] | .message.content // [] | .[]? | select(.type == "tool_use") | .name] |
                group_by(.) |
                map({tool: .[0], count: length}) |
                sort_by(-.count) |
                .[0:10]
            ),

            # Recent user queries (filtered for real questions)
            recent_queries: (
                [.[] | select(.type == "user") | {
                    query: (
                        (.message.content | if type == "string" then .[0:150] else "" end) //
                        .display[0:150] // ""
                    ),
                    timestamp: .timestamp,
                    project: (.cwd // "" | split("/") | last)
                }] |
                # Filter out noise: system messages, commands, notifications
                [.[] | select(
                    .query != "" and
                    (.query | length) > 15 and
                    (.query | startswith("<") | not) and
                    (.query | startswith("Caveat:") | not) and
                    (.query | contains("<command-name>") | not) and
                    (.query | contains("<local-command") | not) and
                    (.query | contains("<bash-notification>") | not) and
                    (.query | contains("<system-reminder>") | not)
                )] |
                sort_by(.timestamp) | reverse |
                .[0:15]
            )
        }
    '
