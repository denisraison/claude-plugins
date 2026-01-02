---
description: Fast commit with smart staging and multi-commit support
---

# Commit Command

Fast, intelligent commit workflow.

## Steps (run in parallel where possible)

1. Run these commands IN PARALLEL:
   - `git status --porcelain`
   - `git diff`
   - `git diff --cached`

2. If nothing is staged, run `git add -A` to stage all changes

3. Analyze the changes - if they touch unrelated areas (different features, fixes, etc.), propose splitting into multiple commits

## Multi-Commit Flow

When changes should be split:
1. Present the proposed commits to the user (e.g., "I see 3 logical changes: feat for auth, fix for navbar, docs update")
2. For each commit, use `git add -p` or specific file paths to stage only relevant changes
3. Commit each group separately

## Commit Message Format

Single line only, no body:

```
<type>(<scope>): <short summary>
<type>!: <breaking change summary>
```

- **type**: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `style`, `perf`
- **scope** (optional): area affected in parentheses
- **!** (optional): indicates breaking change

## Examples

```
feat(auth): add JWT token validation
fix(navbar): resolve dropdown z-index issue
refactor(api): extract validation into middleware
feat!: remove deprecated v1 endpoints
chore: upgrade dependencies
```

## Rules

- Single line only, never add a body
- Keep under 72 characters
- Never commit secrets (.env, credentials, keys)
- Prefer multiple focused commits over one large commit
- Do NOT add any footer (no "Generated with Claude Code", no Co-Authored-By)
