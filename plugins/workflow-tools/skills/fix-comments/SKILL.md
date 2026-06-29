---
name: fix-comments
description: Review code comments in a diff and remove or trim AI slop, bloat, and noise, keeping only comments that earn their place. Use when the user says "review the comments", "remove slop comments", "deslop the branch", "trim the comments", "do we need this comment", "we added too many comments", "can we cleanup comments", or asks to strip obvious/redundant/will-drift comments from changed code. This is about comments IN THE CODE, not PR review comments.
---

# Fix Comments

Strip slop and bloat from code comments. Keep only comments that survive time and add context the code itself cannot show.

This is a recurring ask. The same job every time: review the comments we touched, drop the noise, trim the rest, keep the few that earn their place.

## Scope

Pick the narrowest scope that has changes, in this order:

1. **Named files**: if the user points at files (e.g. "review our comments on posthog.js"), scope to those whole files. Judge every comment in them, not just changed lines.
2. **Uncommitted work**: `git diff` + `git diff --cached`. If either has changes, that is the scope. This is the common case ("you added a bunch of slop, remove it").
3. **Else the branch's own commits**: `git diff <default>...HEAD` (three-dot diffs from the fork point, so it ignores everything already on the default branch). This is "deslop the branch before I push".
4. Only sweep the whole repo if the user explicitly asks ("review all comments everywhere").

For a diff scope (2 and 3), judge comments on **changed or added lines**, plus any comment block directly attached to a changed line (the comment above/beside a line you edited). Don't reach into unrelated untouched code.

**Don't silently undershoot.** A diff can be tiny while the surrounding file is full of slop the user can plainly see. If the changed lines are clean or nearly so but there's obvious slop on adjacent untouched lines, say so and offer to widen scope to the whole file, rather than reporting two verdicts and going quiet on the visible mess. When the user says "deslop the file" or names a file, they mean the file, not just their last edit.

Default branch: try `git symbolic-ref --short refs/remotes/origin/HEAD` (strip the `origin/` prefix); if that fails, assume `main`.

Read the surrounding code before judging a comment. A comment that looks redundant in isolation may be load-bearing in context, and vice versa.

## The rule

Default to **no comment**. A comment has to justify its existence. From the user's CLAUDE.md: comments only for workarounds, magic values, and surprising defaults.

A good comment **survives time** and adds real context, the why the code can't express. A bad comment restates the code, will drift when the code changes, or carries information that belongs somewhere else.

### Remove

- **AI slop**: comments that narrate the obvious. `// Market country,`, `// loop over the items`, `// return the result`. If the line reads the same with the comment deleted, delete it.
- **Restating the code**: `// set the campaign id` above `campaign.id = x`.
- **Will drift**: comments describing current behavior of code that will change, e.g. `// Features serve on pubfeed either via the Linkby...`, `// Nothing else refreshes the pubfeed`. When the code moves, the comment lies.
- **Too much information / internal**: `(per the URL conventions doc)`, standalone ticket numbers (`// ENG-831`), internal back-references, framework trivia like `(opposite of MSW's server.use(...))`. The reader doesn't need it and it dates the code. Exception: a ticket ref that is the provenance of a real workaround (the why lives in that ticket) stays. Drop ticket refs that just date the code; keep ticket refs that source a workaround.
- **Noise that confuses more than it solves**: comments that raise questions instead of answering them.

### Trim

- **Giant block where one line does**: collapse a paragraph to a single direct line if a comment is genuinely warranted.
- **Hedging and over-explaining**: cut to the load-bearing clause.
- **Keep the substance, drop the cruft**: a comment that's a genuine keeper but carries a datestamp, ticket ref, or aside. This is a TRIM, not a KEEP. List it once under Trim and say what survives ("keep the workaround reason, drop the ENG-xxx ref"). Never list the same comment under two verdicts.

### Keep

- Workarounds and the reason for them.
- Magic values and where they come from.
- Surprising defaults and non-obvious gotchas.
- The genuine *why* behind a non-obvious decision.

When unsure whether a comment survives time and adds context: it probably doesn't. Lean toward removing.

## Workflow

1. **Scope** the diff (above).
2. **Judge** each comment in scope. Record `file:line`, the comment, a verdict (REMOVE / TRIM / KEEP), and a one-line reason.
3. **Report** before touching anything:

The header states the scope: "N comments on changed lines" for a diff scope, or "N comments in <file>" for a named-file scope.

```
## Comment Review (N comments on changed lines)

### Remove (M)
- **posthog.js:42** `// set the user id` — restates the code
- **handler.ts:88** `// Features serve on pubfeed...` — will drift when serving changes

### Trim (K)
- **query.ts:30** 6-line block explaining the join — collapse to one line on the non-obvious bit

### Keep (J)
- **client.ts:12** `// retry: vendor returns 503 under load, see ENG-xxx` — workaround + why
```

4. **Apply** the REMOVE and TRIM verdicts to the working tree after the user confirms. Leave KEEP untouched. If the user said "just deslop it" / "remove the slop", skip the confirm and apply directly, then summarize what changed.

If no slop is found, say so plainly. Don't invent verdicts to look busy.

## Note

This skill judges comments only. For broader quality cleanup use `/simplify` or `/code-review`; for dead test removal use the cleanup skill. They compose: it's common to run this alongside `/simplify` on the same diff.
