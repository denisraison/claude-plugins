---
description: Sync current branch with main - stash, pull, merge, resolve conflicts, pop
---

## Current State

Branch: !`git branch --show-current`
Status: !`git status --short`
Default branch: !`git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main"`

## Task

1. If there are uncommitted changes, stash them with a descriptive message
2. Fetch origin
3. If on the default branch, just pull
4. If on a feature branch, merge the default branch into the current branch
5. If there are merge conflicts:
   - Show the conflicting files
   - Resolve each conflict by reading both sides and picking the correct resolution
   - If a conflict is ambiguous (both sides changed the same logic in incompatible ways), explain the tradeoff and ask before resolving
   - After resolving, run any available test/build commands to verify the resolution is correct
   - Complete the merge commit
6. If changes were stashed in step 1, pop the stash
7. If stash pop has conflicts, resolve them the same way
