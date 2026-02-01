---
name: pep
description: Manages PEP (Project Enhancement Proposal) documents. Use when user says "create a PEP", "update PEP", "PEP status", "document this", or references PEP-*.md files.
---

# PEP Workflow

PEPs document decisions and implementation plans. Can be architecture-focused, implementation-focused, or both.

## Determine Action

- **"create PEP"** or **"document this"** -> Create new PEP
- **"update PEP"** or **"mark done"** -> Update existing PEP
- **"PEP status"** -> Show status

## Create PEP

1. Find next number: `scripts/find-peps.sh next`
2. Use template from [template.md](references/template.md)
3. Write to `docs/PEP-XXX-<slug>.md`

**Adapt to context:**
- Small task? Keep phases minimal, maybe just one
- Pure architecture decision? Phases section can be brief or omitted
- Implementation heavy? Focus on phases, keep decision section short

## Update PEP

1. Read the PEP file
2. Update Status if needed
3. Check off completed tasks (- [x])

## Status Check

1. Find all PEPs: `scripts/find-peps.sh list`
2. Extract Status and pending task count
3. Report: filename, status, pending count
