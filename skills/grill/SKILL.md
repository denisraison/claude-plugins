---
name: grill
description: This skill should be used when the user says "grill me", "grill this", "stress-test this plan", "poke holes in this", "interview me", "am I missing anything", "help me think this through", or wants to settle what to build, or which way to go, before building it. Asks questions in rounds, each with a recommended answer, until every decision that affects the build is settled. Challenges terms against the repo's glossary (CONTEXT.md) and recorded decisions (docs/adr/).
---

# Grill

Inspired by mattpocock/skills: skills/productivity/grilling and skills/engineering/domain-modeling

Close the gap between what the user wants and what the agent thinks they want. Treat the plan as a tree of decisions, where each decision opens the ones that hang off it, and walk it until nothing that affects the build is left assumed.

## Before the first round

Read what the repo already knows, so you challenge against it instead of re-deriving it:

- `CONTEXT.md` at the repo root, the domain glossary. If `CONTEXT-MAP.md` exists instead, the repo has several contexts; work out which one applies.
- `docs/adr/`, the recorded decisions. Don't reopen a settled decision, cite it.
- `agent-constraints/*.md`, if present.

None of these existing is fine. Create them only when there is something to write.

## Rounds

The open questions are every decision whose prerequisites are already settled, the ones you can ask now without guessing at answers you haven't heard. Ask all of them in one round, then wait.

```
**Q1. <short title>**
<the question, with the options if there are any>
Recommended: <your answer and the one-line reason>

**Q2. <short title>**
...
```

- **Recommend an answer for every question.** The user corrects a recommendation faster than they specify from scratch.
- **Word each question so "yes" accepts the recommendation.** A round can then be answered with "yes, but Q3 the other way".
- **Facts are your job, decisions are the user's.** If the code, the data, or the docs can answer it, look it up instead of asking. Ask only what the repo can't tell you: intent, trade-offs, priorities, outside constraints. A lookup still running holds back only the questions that depend on it.
- **A question that depends on another open question waits for the next round.**

After each round, recompute what's open and ask the next round.

## While grilling

- **Challenge against the glossary.** "CONTEXT.md defines 'cancellation' as X, but you seem to mean Y. Which is it?"
- **Sharpen fuzzy words.** "By 'account' do you mean the Customer or the User? Those are different things."
- **Invent edge cases** that force a boundary to be precise.
- **Check claims against the code.** "The code cancels whole Orders, but you said partial cancellation works. Which is right?"
- **Resolve data-backed terms down to the column.** When a term drives a sort, filter or tier ("most recent", "active", "owner"), reading the query that uses the column isn't enough. Find which column backs the term, what writes it and when (read the write path, not just the SELECT), and what the real data looks like. A `createdAt` may be stamped at row creation while the event you mean lands on `updatedAt`. Check against real data before the column goes into a plan.

## Glossary and ADRs

When a term resolves, update `CONTEXT.md` right then. It holds domain terms only, defined by what they are, never implementation notes.

Offer an ADR only when all three hold: the decision is hard to reverse, it would surprise a future reader without context, and it was a real trade-off between genuine options.

Formats for both are in [references/glossary-and-adr.md](references/glossary-and-adr.md).

## Done

The grilling is done when nothing is open: every branch that affects the build is settled, and nothing is silently assumed. Summarise the decisions in a short list. Don't act on them until the user confirms the summary. Then offer the next step that fits the size of the work: a design doc for something large, a checklist for something small, or just starting.
