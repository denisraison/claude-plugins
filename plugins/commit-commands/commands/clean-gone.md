---
description: Cleans up all git branches marked as [gone] (deleted on remote but still exist locally)
---

## Branches with [gone] tracking

!`git branch -vv | grep ': gone]' || echo "No branches marked [gone]"`

## Task

1. Show branches that have been deleted on remote but exist locally
2. Ask for confirmation before deleting
3. Delete confirmed branches and their worktrees if any

Use `git branch -d` for safe deletion. If a branch has unmerged changes, warn and skip unless user confirms force delete.
