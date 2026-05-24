# Glossary (CONTEXT.md) and ADR formats

Two artifacts the grilling session maintains. Both are created lazily, only
when there is something to write.

## CONTEXT.md (the domain glossary)

A glossary of the project's domain terms. Lives at the repo root for a
single-context repo.

```md
# {Context Name}

{One or two sentences: what this context is and why it exists.}

## Language

**Order**:
A customer's request to buy goods, before payment is taken.
_Avoid_: Purchase, transaction

**Invoice**:
A request for payment sent to a customer after delivery.
_Avoid_: Bill, payment request

**Customer**:
A person or organization that places Orders.
_Avoid_: Client, buyer, account

## Flagged ambiguities

- "account" was used to mean both Customer and User. Resolved: Customer is the
  buying organization; User is a login identity. "account" is no longer a term.
```

Rules:

- **Be opinionated.** When several words mean the same thing, pick one and list
  the rest as aliases to avoid.
- **Keep definitions tight.** One or two sentences. Define what it IS, not what
  it does.
- **Only domain-specific terms.** General programming concepts (timeouts, error
  types, utility patterns) don't belong, even if used heavily. Ask: is this
  unique to this project's domain, or general? Only the former.
- **Show relationships** with bold term names and cardinality where obvious.
- **Flag conflicts explicitly** under "Flagged ambiguities" with a resolution.
- **Group under subheadings** when natural clusters emerge; a flat list is fine
  for a small cohesive set.

### Multi-context repos

If a repo spans several domains, a `CONTEXT-MAP.md` at the root lists them and
how they relate; each context gets its own `CONTEXT.md` in its subtree:

```md
# Context Map

## Contexts

- [Ordering](./src/ordering/CONTEXT.md) — receives and tracks customer orders
- [Billing](./src/billing/CONTEXT.md) — generates invoices and processes payments

## Relationships

- **Ordering → Billing**: Ordering emits `OrderPlaced`; Billing consumes it
- **Ordering ↔ Billing**: shared types for `CustomerId` and `Money`
```

If `CONTEXT-MAP.md` exists, read it to find the contexts. If only a root
`CONTEXT.md` exists, single context. If neither, create a root `CONTEXT.md`
when the first term resolves.

## ADR (docs/adr/NNNN-slug.md)

Record *that* a decision was made and *why*. Most ADRs are one paragraph.

```md
# {Short title of the decision}

{1-3 sentences: the context, what we decided, and why.}
```

Numbering: scan `docs/adr/` for the highest number, increment by one. First is
`0001-slug.md`. Create the directory lazily.

Optional sections, only when they add value (most ADRs need none):

- **Status** frontmatter (`proposed | accepted | deprecated | superseded by
  ADR-NNNN`) when decisions get revisited.
- **Considered Options** when rejected alternatives are worth remembering.
- **Consequences** when non-obvious downstream effects need flagging.

What qualifies (all three criteria met):

- Architectural shape ("write model is event-sourced, read model in Postgres").
- Integration patterns between contexts ("communicate via events, not HTTP").
- Technology choices with real lock-in (database, message bus, auth provider).
- Boundary/scope decisions and the explicit no-s.
- Deliberate deviations from the obvious path ("manual SQL not an ORM because
  X"), so nobody "fixes" a deliberate choice.
- Constraints not visible in code ("under 200ms because of the partner API
  contract").
