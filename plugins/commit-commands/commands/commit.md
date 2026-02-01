---
description: Create a git commit
---

## Changes

Staged: !`git diff --cached --stat`
Unstaged: !`git diff --stat`
Untracked: !`git ls-files --others --exclude-standard`

## Recent Commits (for style reference)

!`git log --oneline -5 2>/dev/null`

## Task

1. Review all changes (staged, unstaged, untracked)
2. If changes span multiple unrelated features, suggest splitting into separate commits
3. Stage relevant files if needed (prefer specific files over `git add -A`)
4. Generate a commit message following the repository's style
5. Create the commit

Rules:
- Keep commit messages objective and factual
- No Co-Authored-By lines (not even for Claude or Cursor)
- If no changes to commit, say so
