---
name: history-analysis
description: Searches past Claude Code sessions stored in ~/.claude/. Use when user explicitly asks about previous sessions, chat history, or past conversations, such as "what did I work on last 2 weeks?", "search my history for X", "what projects did I touch last month?", or "show my Claude Code history".
---

# History Analysis

IMPORTANT: Always use the provided scripts. Do NOT improvise with raw bash commands.

## For Summary Requests ("what did I work on", "wrapped", "summarise")

Run this single command:

```bash
scripts/fast-summarise.sh [days]
```

Examples:
- Last 7 days: `scripts/fast-summarise.sh 7`
- Last 30 days: `scripts/fast-summarise.sh 30`
- Last 365 days: `scripts/fast-summarise.sh 365`

The output contains:
- `message_count`: Total messages
- `projects`: Top projects with message counts
- `tools_used`: Most used tools
- `recent_queries`: Recent user questions

## For Search Requests ("find", "search", "when did I")

Run this single command:

```bash
scripts/fast-search.sh "pattern" [limit]
```

Examples:
- `scripts/fast-search.sh "pocketbase" 20`
- `scripts/fast-search.sh "authentication" 30`

## For Date Range Parsing

Only use if you need specific timestamps:

```bash
python3 scripts/date_utils.py "last 2 weeks"
python3 scripts/date_utils.py "January 2025 to today"
```

## Output Format

The scripts return JSON. Present the results in a readable format:
- For summaries: List top projects, tools, and interesting queries
- For searches: Show relevant matches with context

## Do NOT

- Run raw `find`, `stat`, `ls` commands on ~/.claude
- Improvise your own parsing logic
- Use chunk.sh unless specifically debugging
