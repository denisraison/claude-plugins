---
name: code-cleanup
description: This skill should be used when the user asks to "clean up tests", "clean up code", "tidy up tests", "remove dead tests", "organize test files", "fix test structure", or mentions test hygiene, test bloat, removing temporary tests, or following test best practices. Unlike the code-review skill (which reviews a diff for quality), this skill performs batch cleanup across entire files or directories. Reports issues first, then applies fixes after confirmation.
---

# Code Cleanup

Review and clean up tests and code. Focused on removing bloat, enforcing structure, and following language best practices.

## Workflow

### 1. Determine Scope

Based on the user's request, determine what to review:

- **Uncommitted changes**: Run `git diff --name-only` and `git diff --cached --name-only` to get changed files.
- **Specific files/directories**: Use the paths the user provides.
- **Full scan**: Scan all test files in the repository using language-appropriate patterns:
  - Go: `**/*_test.go`
  - TypeScript/JavaScript: `**/*.test.{ts,tsx,js}`, `**/*.spec.{ts,tsx,js}`, `**/__tests__/**`
  - Python: `**/test_*.py`, `**/*_test.py`

### 2. Analyse

Read each file in scope. Apply the checklist from [checklist.md](references/checklist.md). For each issue found, record:

- **File and line reference** (file:line format)
- **Issue category** (from checklist)
- **What to do** (remove, move, rewrite, etc.)

### 3. Report

Present findings grouped by category. Use this format:

```
## Cleanup Report

### Tests to Remove
- **user_test.go:42** - Trivial test asserting getter returns field value
- **api.test.ts:88** - Empty test body, likely temporary

### Tests to Restructure
- **utils_test.go:15** - Test for `ParseConfig` belongs in `config_test.go`

### Comments to Remove
- **handler.py:23** - Stale TODO referencing resolved issue

### Code to Simplify
- **service.ts:67** - Dead code branch, condition is always false
```

End with a summary count: "Found X issues across Y files."

### 4. Fix

After the user confirms, apply fixes. For each fix:

1. Read the file (always re-read before editing).
2. Apply the change.
3. If moving a test, ensure imports are updated in both source and destination files.
4. Run the test suite after all changes to confirm nothing breaks. If tests fail, investigate and ask or fix it before continuing.

## Principles

- Only flag tests that genuinely add no value. A simple test for tricky logic is fine.
- "Tricky" means: edge cases, error paths, concurrency, parsing, math, state machines.
- Trivial means: testing a getter, testing a constructor sets fields, testing a wrapper that just delegates.
- When restructuring, prefer the convention of the language and project over personal preference.
- Do not add tests. This skill removes and reorganizes, it does not create.
