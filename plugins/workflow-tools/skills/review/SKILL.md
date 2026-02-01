---
name: code-review
description: Reviews code changes for quality issues. Use when user says "review my changes", "review the diff", "review my code", "check for issues", "sanity check", or asks to find holes, gaps, or simplification opportunities.
---

# Code Review

Review uncommitted changes against the checklist.

## Steps

1. Get changes: `git diff` and `git diff --cached`
2. Apply checklist from [checklist.md](references/checklist.md)
3. Report issues with file:line references

## Output Format

For each issue:
- **file:line** - Issue description
- Severity: MUST FIX | SHOULD FIX | CONSIDER

If no issues found, confirm the code looks solid.
