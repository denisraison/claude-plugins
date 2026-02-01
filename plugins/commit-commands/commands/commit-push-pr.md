---
description: Commit, push, and open a PR
---

## Current State

Branch: !`git branch --show-current`
Remote: !`git remote -v | head -1`
Staged: !`git diff --cached --stat`
Unstaged: !`git diff --stat`

## Recent Commits (for style reference)

!`git log --oneline -5 2>/dev/null`

## Task

1. If there are uncommitted changes, create a commit first (follow the same rules as /commit)
2. Push the branch to origin (with -u if needed)
3. Open a PR using `gh pr create`

If already on main/master, warn and stop.
If PR already exists, show its URL instead.
