---
description: Restore context after /clear - shows git state and active PEPs
---

## Current State

Git status: !`git status --short`
Recent changes: !`git diff --stat HEAD~5 2>/dev/null || git diff --stat`
Branch: !`git branch --show-current`
Recent commits: !`git log --oneline -5 2>/dev/null`

## Active PEPs

!`find . -path "*/docs/*" -name "PEP-*.md" -mtime -14 2>/dev/null | head -5 || echo "No recent PEPs found"`

## Task

Summarise current state. What was I working on? Any active PEPs with pending tasks?
