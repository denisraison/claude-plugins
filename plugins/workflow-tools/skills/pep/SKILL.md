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
2. Write to `docs/PEP-XXX-<slug>.md` using the template below

### Choosing Waves

Determine the right number of waves based on task complexity. A wave is a sweep of work followed by a gate (a concrete validation check). Examples:

- **1 wave:** Config change, simple bug fix, documentation update
- **2 waves:** New feature with tests, refactor with migration
- **3+ waves:** Large cross-cutting change, multi-system integration

Do not default to 3. Name each wave after what it actually does, not generic labels.

### Template

```markdown
# [Title]

**Status:** Draft | In Progress | Done
**Date:** YYYY-MM-DD

## Context

[What and why. What we're doing about it. 3-5 sentences max.]

## Waves

### Wave 1: [Name]
[Brief description of this wave's goal.]
- [ ] Task
- [ ] Task
- **Gate:** [Concrete check that this wave's work is valid.]

<!-- Add more waves only if the task warrants them. -->

## Consequences

[What changes as a result. Trade-offs accepted.]
```

## Update PEP

1. Read the PEP file
2. Check off completed tasks (`- [x]`)
3. When a wave's gate passes, update Status if needed

## Status Check

1. Glob for `**/docs/PEP-*.md`
2. Report each: filename, status, pending task count
