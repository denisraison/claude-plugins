---
name: grill
description: This skill should be used when the user says "grill me", "grill with docs", "stress-test this plan", "interview me", "interrogate this design", "poke holes in this", "am I missing anything", or wants to align on what to build before building it. Interviews the user one question at a time until every branch of the design tree is resolved, challenging the plan against the repo's domain glossary (CONTEXT.md) and recorded decisions (docs/adr/). Sharpens terminology and maintains the glossary inline. Front door to the PEP workflow.
---

# Grill

Close the gap between what the user wants and what the agent thinks they want.
The fix is interrogation: walk down each branch of the design tree, resolving
dependencies one decision at a time, until you reach shared understanding.

This is the intake step before planning. When the grilling is done, offer to
hand off to the PEP workflow (the resolved questions become the PEP's Context
and Open Questions, pre-grilled).

## How to interview

1. **One question at a time.** Ask, wait for the answer, then ask the next.
   Never batch questions. A wall of questions gets a wall of half-answers.
2. **Recommend an answer with every question.** Don't just ask "how should
   auth work?" Ask, then give your recommended answer and why. The user
   corrects faster than they specify from scratch.
3. **Explore the codebase instead of asking when you can.** If a question is
   answerable by reading code, read it. Only ask the user things the code
   can't tell you (intent, trade-offs, priorities, constraints not in the
   repo).
4. **Resolve dependencies in order.** Decisions depend on each other. Resolve
   the upstream one before the downstream one, or you'll re-litigate.
5. **Stop when the tree is resolved**, not when you run out of questions.
   When every branch that affects the build is settled, stop and summarise.

## Read the repo's documented context first

Before grilling, read what the repo already knows, so you challenge against it
rather than re-deriving it:

- `CONTEXT.md` at the repo root (the domain glossary). If a `CONTEXT-MAP.md`
  exists instead, the repo has multiple contexts, infer which one applies.
- `docs/adr/` (recorded architectural decisions). Don't re-litigate decisions
  already settled here, reference them.
- `agent-constraints/*.md` if present (this repo's per-repo conventions, same
  files the PEP skill reads).

Files are lazy. If none exist, that's fine, create them only when you have
something to write (see below).

## During the session

**Challenge against the glossary.** When the user uses a term that conflicts
with `CONTEXT.md`, call it out: "Your glossary defines 'cancellation' as X, but
you seem to mean Y, which is it?"

**Sharpen fuzzy language.** When a term is vague or overloaded, propose a
precise canonical one: "You're saying 'account', do you mean the Customer or
the User? Those are different things."

**Discuss concrete scenarios.** When domain relationships come up, invent
specific edge-case scenarios that force the user to be precise about
boundaries.

**Cross-reference with code.** When the user states how something works, check
whether the code agrees. Surface contradictions: "Your code cancels entire
Orders, but you just said partial cancellation is possible, which is right?"

**Resolve data-backed terms to the column, not just the read.** When a term
will drive an ORDER BY, filter, or tier ("most recent", "active", "worked
together", "owner"), reading the query that *consumes* the column isn't enough,
the query can be well-formed and fast and still mean the wrong thing. Resolve
the term to (1) which column backs it, (2) what writes that column and when
(read the persistency write path, not just the SELECT), and (3) what the real
data looks like. A column named `createdAt` may be stamped at row creation while
the event you mean (an accept, a status change) lands on `updatedAt`; a
`startDate` may include future-scheduled rows; a join row may exist in a draft
state you didn't intend to count. The term is fuzzy language until those
resolve. Verify (2) and (3) empirically against real data before baking the
column into the spec.

## Maintain the glossary inline

When a term resolves, update `CONTEXT.md` right then, don't batch. Use the
format in [references/glossary-and-adr.md](references/glossary-and-adr.md).

`CONTEXT.md` is a glossary and nothing else. No implementation details, no
specs, no scratch notes. Define what a term IS, not what it does. Only terms
specific to this project's domain, general programming concepts don't belong.

## Offer ADRs sparingly

Offer to record an ADR only when all three are true:

1. **Hard to reverse** — changing your mind later costs something real.
2. **Surprising without context** — a future reader will wonder "why this way?"
3. **A real trade-off** — there were genuine alternatives and you picked one
   for specific reasons.

If any is missing, skip it. Format in [references/glossary-and-adr.md](references/glossary-and-adr.md).

## When the grilling is done

Summarise the resolved decision tree, then offer the handoff:

> Tree's resolved. {N decisions settled}. Want me to turn this into a PEP? The
> Context and Open Questions are already worked out, I'd draft the waves from
> here.

If the user says yes, invoke the `pep` skill in "create PEP" mode, feeding the
resolved questions as Context. If no, leave the glossary/ADR updates in place
and stop.
