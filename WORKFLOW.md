# Workflow

How the skills in this repo fit together. The short version: **grill to align,
pep to plan and ship, diagnose to debug, and feed the glossary as you go.**

## The spine (building something)

```
/grill         figure out what you actually want
               one question at a time, recommends an answer each time,
               challenges against CONTEXT.md + docs/adr/, sharpens the glossary
                    │ "turn this into a PEP?"
                    ▼
/pep           plan mode: waves + gates + adversarial review (self-run before
               you see it). Or investigation mode first if the shape is unknown.
                    │ approve
                    ▼
run wave       execute inline, TDD per wave, gates produce real evidence,
               audit hook cross-checks that commands actually ran in-session.
               Auto-calls /simplify before each commit.
                    │ all waves green
                    ▼
ship verdict   you give the final go; status → Done
```

Grill is where misalignment dies before it costs a wave. For anything
non-trivial, grill first.

## When to skip parts

- **Tiny known change** (config tweak, one-liner): skip grill and pep, just do
  it and `/commit`.
- **Don't know the shape yet**: `/pep spike X` → investigation mode. Grill if
  the unknown is about *intent*; spike if it's about *the code*. Grill
  interrogates you; spike interrogates the codebase.
- **Already talked it through this session**: skip grill, `/pep create`
  synthesizes from context.

## Escape hatches (unplanned work)

- **Something's broken** → `/diagnose`. No PEP file. Build a feedback loop,
  reproduce, hypothesise, fix, regression-test. Recommends a follow-up PEP only
  if the cause turns out to be architectural.
- **Code's a mess** → `/refactor` (restructure) or `/cleanup` (dead code/tests).
- **Sanity-check a diff** → `/review`.

## Example: adding "saved searches"

A condensed run through the spine. Note what happens before any code.

**1. `/grill` — align first**

> **You:** grill me on adding saved searches
>
> **Claude:** Your `CONTEXT.md` defines **Query** ("a user's search with
> filters") but no "search". Do you mean a saved **Query**? I'd reuse it,
> calling it a **Saved Query** — otherwise two words for one thing.
>
> **You:** yeah saved query
>
> **Claude:** *(updates `CONTEXT.md`)* Added: **Saved Query** — a Query a
> Customer persisted to re-run. _Avoid_: saved search, bookmark.
> Next: per-Customer-private or shareable across an Org? Code has no owner field
> today, so either way it's a schema change. Recommend private for v1.
>
> **You:** private
>
> **Claude:** Last branch: re-run live, or snapshot results at save time? Live
> matches how Query works today. Recommend live.
>
> **You:** live
>
> **Claude:** Tree resolved (reuse Query, private-only, live). Private-vs-shared
> is hard to reverse — record an ADR? And turn this into a PEP?
>
> **You:** yes both

Jargon collapsed, scope pinned, one ADR, richer glossary — zero code yet.

**2. `/pep` — plan, self-reviewed**

> **Claude:** `PEP-012-saved-queries.md`, 2 waves (Migration, then Code/TDD).
> Self-reviewed: 1 medium (Wave 2 missed the route layer — fixed), 1 low (no
> index on `owner_id` — added). Invariant: existing Query path unchanged.
> Approve?

**3. Run waves — evidence, not vibes**

> **Claude:** Wave 1 done. `make migrate` exit 0, `make migrate-down` exit 0,
> reapply exit 0. Audit cross-check: all 3 in `.pep/audit.log` this session. ✓
> Auto-closed, committed `feat(db): add saved_queries table`.
>
> Wave 2 spec: 6 failing tests (persist, list-own, re-run-live, 3 error paths).
> One for your eye: not-owner asserts 404 not 403, hides existence. Lock it in?
>
> **You:** yes 404

**4. Ship**

> **Claude:** Both waves green, audit clean, no carve-outs. Commits a1f9..ef92.
> Invariant held. Ship?

**Escape hatch — a bug later**

> **You:** /diagnose saved queries return stale results sometimes
>
> **Claude:** "Sometimes" = non-deterministic — raising repro rate, not chasing
> one clean repro. 30/100 stale, debuggable. Top hypothesis: cache keyed by
> query id, not data version. Testable: disable cache, staleness should vanish.
> Your read before I instrument?

By Wave 2 nobody types "saved search" — table, tests, and routes all say
`SavedQuery`, and the next feature here starts from a glossary, not scratch.

## The four repo-root files (and how they differ)

These get confused because they're neighbors at the repo root. They hold
different *kinds* of content:

| File | Answers | Mood | Maintained by |
|---|---|---|---|
| `CLAUDE.md` / `AGENTS.md` | How should you *behave*? | Instructions | Hand-curated, kept lean (`/trim-context`) |
| `agent-constraints/*.md` | How to run the *PEP workflow* here? | Process rules | Hand-curated per repo |
| `CONTEXT.md` | What do the *words* mean? | Vocabulary | `grill`, a line at a time |
| `docs/adr/` | *Why* did we choose this? | Decisions | `grill` / `pep`, when a real trade-off is made |

Quick test for where a line belongs:

- A command or rule you'd *obey* → `CLAUDE.md`
- A noun you'd *look up* → `CONTEXT.md`
- A choice a future reader would *question* → an ADR

`CONTEXT.md` is a glossary and nothing else: define what a term **is** in one or
two sentences, not what it does, and only domain-specific terms (not "timeout"
or "retry"). It's created lazily, the first time grill resolves a term, and
grows as you build. `grill` writes it; `pep` and `diagnose` read it.

## The one habit worth forming

The glossary only pays off if it accumulates. When you grill, let it update
`CONTEXT.md`. That's what makes the *next* session cheaper, the agent stops
re-deriving your jargon. Skip it and you've just got a fancier grill-me.
