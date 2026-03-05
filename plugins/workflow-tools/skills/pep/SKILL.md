---
name: pep
description: This skill should be used when the user says "create a PEP", "update PEP", "PEP status", "document this", or references PEP-*.md files. Manages PEP (Project Enhancement Proposal) documents for tracking decisions and implementation plans.
---

# PEP Workflow

PEPs document decisions and implementation plans.

## Determine Action

- **"create PEP"** or **"document this"** -> Create new PEP
- **"update PEP"** or **"mark done"** -> Update existing PEP
- **"PEP status"** -> Show status

## Create PEP

1. Glob for `**/docs/PEP-*.md` to find the highest number, increment for next
2. Write to `docs/PEP-XXX-<slug>.md`

### Structure

Every PEP needs these sections. There is no fixed template — adapt the depth and format to the task:

- **Title, Status** (Draft | In Progress | Done), **Date**
- **Context** — The why. Explain the problem or decision clearly enough that someone unfamiliar could argue for it. Include what you're doing about it.
- **Waves** — The work, broken into sweeps. See guidelines below.
- **Consequences** — What changes as a result. Name real trade-offs, not just "things improve."

### Waves

A wave is a sweep of work followed by a gate. Choose the right number based on complexity:

- **1 wave:** Config change, simple bug fix, documentation update
- **2 waves:** New feature with tests, refactor with migration
- **3+ waves:** Large cross-cutting change, multi-system integration

Do not default to 3. Name each wave after what it actually does, not generic labels.

### What Makes a Good Wave

A wave must give enough context that someone unfamiliar with the codebase — including an AI — could start working without asking clarifying questions. Each wave should:

- Name the specific files or areas affected and what changes in them
- Explain approach decisions when there are multiple valid options
- Include what tests need to be created or updated and how to handle edge cases
- End with a gate: the proof that the wave is done. Start with at least one deterministic check (a command, test suite, type check, linter) that produces a pass/fail exit code. Then add judgement-based checks if needed (behavioural verification, structural assertions, before/after comparisons). The PEP author decides what proof looks like for their domain, but deterministic checks catch the obvious failures before anything else runs. For browser/UI gates, make them executable: specify the URL, the steps to perform (click X, type Y), and the expected outcome. "Verify it works in the browser" is not a gate. "Navigate to localhost:3000, click the Submit button, verify the success toast appears" is.

Don't over-specify. The goal is a clear picture of *what* needs to happen and *why*, not line-by-line instructions. Tasks should describe outcomes, not dictate implementation steps.

## Update PEP

1. Read the PEP file
2. Check off completed tasks (`- [x]`)
3. When a wave's gate passes, update Status if needed

## Status Check

1. Glob for `**/docs/PEP-*.md`
2. Report each: filename, status, pending task count
