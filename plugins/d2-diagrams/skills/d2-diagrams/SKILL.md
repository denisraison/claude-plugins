---
name: d2-diagrams
description: This skill should be used when the user asks to "create a diagram", "draw an architecture diagram", "visualize a flow", "make a system diagram", "generate a D2 diagram", or mentions D2, architecture diagrams, flow diagrams, sequence diagrams, or system visualization.
---

# D2 Diagram Generation

Generate professional diagrams using [D2](https://d2lang.com/), render them to PNG, visually evaluate the output, and iterate until the result is clean and readable.

## Prerequisites

Verify D2 is installed before starting:

```bash
which d2 || brew install d2
```

## C4 Model Framework

Use the [C4 model](https://c4model.com/) to decide the right level of abstraction before drawing anything. C4 defines four zoom levels — pick the one that matches what the diagram needs to communicate.

**Reference:** D2 has first-class C4 support since v0.7. See the [official D2 C4 guide](https://d2lang.com/blog/c4/) for examples including the C4 theme, `c4-person` shape, markdown labels, `d2-legend`, and the `suspend` keyword for multi-view models.

### Level 1 — System Context

**When**: Showing how the system fits into the wider world. For stakeholders, onboarding, high-level architecture.

- The system under discussion is one box in the center
- Surround it with the **people** (users, roles) and **external systems** it interacts with
- No internal detail — just relationships and protocols
- Typically 3-8 nodes

```
[Person] → [Your System] → [External System]
```

D2: Use `shape: person` for actors, single node for the system, ovals for external systems.

### Level 2 — Container

**When**: Showing the major technical building blocks inside a system. For developers, debugging, understanding how services connect.

- The system boundary is a container (dashed border)
- Inside: services, databases, message queues, frontends — each is a **container**
- Show inter-container communication (HTTP, gRPC, Pub/Sub, SQL)
- External systems and people sit outside the boundary
- Typically 5-15 nodes

D2: Use a container with `boundary` class for the system boundary. Use technology classes (`go`/`java`/`ts`) for services, `db` class for databases, `queue` class for message brokers.

### Level 3 — Component

**When**: Zooming into a single container to show its internal components. For deep debugging, code review, design discussions.

- The container boundary is the outer frame
- Inside: major modules, packages, classes, or handler groups
- Show dependencies between components
- Typically 5-12 nodes within one container

### Level 4 — Code

**Rarely needed**. Class diagrams, sequence diagrams. Usually auto-generated from code rather than hand-drawn.

### Choosing the Right Level

| Situation | Level | Example |
|-----------|-------|---------|
| "How does the platform work?" | L1 Context | User → Platform → Payment Provider |
| "How do our services connect?" | L2 Container | API Gateway → Order Service → DB |
| "How does the order service handle a request?" | L3 Component | Validator → Processor → Notifier |
| "What are the classes in the processor?" | L4 Code | Usually skip — read the code instead |

**Default to Level 2 (Container)** unless the user specifies otherwise. It's the most useful level for debugging and onboarding.

## Workflow

### 1. Plan the Diagram

Before writing D2, decide:

- **C4 Level**: Which zoom level? (default: L2 Container)
- **Direction**: `down` for hierarchies/pipelines, `right` for sequential flows
- **Scope**: One story per diagram. If the system is complex, split into focused diagrams rather than one mega-diagram
- **Node ordering**: Arrange nodes so arrows flow in one direction. Minimize arrows going backwards or sideways — these cause crossings

**Rule of thumb**: If a diagram has more than ~10 nodes or arrows that must cross, split it.

### 1b. Verify Names from Code

Before putting a service or component on a diagram, verify its actual name from the codebase or deployment configs. Don't guess or use colloquial names — check K8s manifests, Terraform modules, or service entrypoints. Wrong names on architecture diagrams erode trust in the documentation.

**No codebase?** For conceptual/design diagrams, skip this step. See [references/d2-advanced.md](references/d2-advanced.md) § "Conceptual Diagrams" for naming conventions.

### 2. Write the D2 Source

Place `.d2` files where they'll be maintained alongside the project:

```bash
# In a project — keep diagrams with docs
mkdir -p docs/diagrams
# Write to docs/diagrams/<name>.d2, renders to docs/diagrams/<name>.svg

# Standalone / exploratory — use a scratch directory
mkdir -p /tmp/d2-work
```

**Convention**: Name files after what they show, not the system: `payment-flow.d2`, `auth-sequence.d2`, `system-context.d2`. Keep the `.d2` source committed alongside the rendered output so anyone can re-render.

Follow the style guide in [references/d2-style.md](references/d2-style.md).

### 3. Render

```bash
# SVG — preferred for docs, wikis, web (scalable, searchable text, smaller files)
d2 --theme 0 --layout elk --pad 60 <input>.d2 <output>.svg

# PNG — for presentations, chat, or when SVG isn't supported
d2 --theme 0 --layout elk --pad 60 <input>.d2 <output>.png
# Add --scale 2 for higher-DPI output (retina/print)
```

- `--theme 0` — clean light theme (best for docs/presentations). For standard C4 look, use `--theme 200` (C4 theme)
- `--layout elk` — Eclipse Layout Kernel, handles complex graphs better than default dagre
- `--pad 60` — breathing room around edges
- **SVG vs PNG**: Default to SVG. Use PNG when the consumer doesn't support SVG (Slack, most chat tools) or when visual evaluation is needed (the judge loop requires PNG since the Read tool can read images)

### 4. Evaluate (Judge Loop)

Read the rendered PNG using the Read tool and evaluate against these criteria. **Score each 1-10, iterate until ALL are >= 8:**

| Criteria | What to check |
|----------|---------------|
| **C4 compliance** | Does the diagram follow C4 conventions for the chosen level? See the checklist below. |
| **Flow** | Do arrows follow one dominant direction (top→bottom or left→right)? Are there crossing arrows? Arrows going backwards? |
| **Readability** | Is all text legible? Are labels truncated? Is the diagram too wide/flat or too tall/narrow? |
| **Grouping** | Are related nodes visually close? Is there clear visual hierarchy? |
| **Simplicity** | Is every node and arrow necessary? Could anything be removed or split into a separate diagram? |

#### C4 Compliance Checklist (verify before rendering)

Run through this before every render. If any item is "no", fix the D2 source first.

- [ ] **Classes from the style guide only.** Every class used comes from [references/d2-style.md](references/d2-style.md). Do not invent custom classes.
- [ ] **Technology annotations on every node.** C4 format: `"name\n[Container: Tech]"` (e.g., `"order-service\n[Container: Go]"`) or shorthand `"name\n[Tech — role]"` (e.g., `"scheduler\n[Go — K8s CronJob]"`). No node should be just a name with no context.
- [ ] **Protocol labels on every edge.** Format: `"description\n[Protocol]"` (e.g., `"creates order\n[SQL]"`). Use `[SQL]`, `[gRPC]`, `[Pub/Sub]`, `[HTTPS]`, `[REST]`.
- [ ] **System boundary present** (L2+). A `boundary` class container wrapping internal components. External actors sit outside it.
- [ ] **External actors outside the boundary.** Users, triggers, external systems are not inside the system boundary.
- [ ] **No invented concepts.** The diagram shows architecture (what connects to what), not behavior or failure states. Failure modes, error paths, and "what happens when X breaks" belong in text, not in the diagram.

**Common fixes by symptom:**

| Symptom | Fix |
|---------|-----|
| Too wide/flat, text tiny | Switch `direction: right` → `direction: down` |
| Crossing arrows | Reorder node declarations. D2/ELK places nodes in declaration order |
| Spaghetti connections | Split into multiple diagrams. Remove secondary connections |
| Nodes scattered randomly | Use containers to group related nodes |
| Labels truncated | Shorten label text, use `\n` for line breaks |
| Too many edge labels | Remove obvious labels, keep only the non-obvious ones |

### 5. Iterate

If any criterion scores below 8:

1. Identify the specific problem from the rendered image
2. Edit the `.d2` source (reorder nodes, change direction, split diagram, adjust labels)
3. Re-render
4. Re-evaluate

**Do not stop until all criteria score >= 8.** Typically takes 2-3 iterations.

### 6. Deliver

Once the diagram passes evaluation:

1. Copy the `.d2` source file alongside the rendered output so it can be edited later
2. Render a final SVG for docs: `d2 --theme 0 --layout elk --pad 60 <file>.d2 <file>.svg`
3. Tell the user how to re-render if they edit the source

## Diagram Types

### C4 Level 1 — System Context
- Use `direction: down` or `direction: right`
- Center node uses `system` class, actors use `person` class, external systems use `external-system` class
- Label edges with relationship and protocol: `"sends orders\n[HTTPS/JSON]"`
- Keep it to 3-8 nodes max

### C4 Level 2 — Container
- Use `boundary` class container for the system boundary
- For diagram sets, add a sub-label to the boundary: `"System Name — Focus Area"` (e.g., `"Order Platform — Payment Flow"`)
- Inside: services (`go`/`java`/`ts`), databases (`db`), queues (`queue`)
- External actors and systems sit outside the boundary
- Label edges with protocol in square brackets: `"sends events\n[Pub/Sub]"`, `"reads\n[SQL]"`, `"config\n[gRPC]"`
- Split by flow if > 10 nodes (e.g., "data sync" vs "event processing")

**Message queues — explicit node vs edge label:**
- Use an **explicit queue node** when the queue is a clear fan-out/fan-in point (one producer, multiple consumers) — it visually shows the async boundary
- Use **edge labels** with `[Pub/Sub]` when most or all edges are async — adding queue nodes everywhere just adds noise

### C4 Level 3 — Component
- Use a container for the service boundary
- Inside: modules, handlers, pipelines as standard nodes
- Show internal dependencies

### Flow / Pipeline Diagram
- Use `direction: down` for vertical pipelines (data processing, ETL flows)
- Use `direction: right` for sequential processes
- Keep it linear — one dominant direction

### Sequence Diagram
- Wrap the entire diagram in a container with `shape: sequence_diagram`
- Actors are declared as direct children — order of declaration sets left-to-right position
- Use `->` for requests, `<-` or `-->` (dashed) for responses/async
- Group related steps with spans: `"Step Name": { ... }`
- Self-calls: `actor -> actor: "description"`
- Keep to 4-6 actors and ~10-15 messages max — beyond that, split into separate diagrams

```d2
flow: {
  shape: sequence_diagram

  client: "Client"
  gateway: "API Gateway"
  auth: "Auth Service"
  orders: "Order Service"
  db: "Database"

  client -> gateway: "POST /orders\n[HTTPS]"
  gateway -> auth: "validate token\n[gRPC]"
  auth -> gateway: "200 OK"
  gateway -> orders: "create order\n[gRPC]"
  orders -> db: "INSERT\n[SQL]"
  db -> orders: "order_id"
  orders -> gateway: "201 Created"
  gateway -> client: "{ order_id }"
}
```

### Fan-in / Fan-out
- Use `direction: right` with sources on the left, target on the right
- Order source nodes vertically so arrows don't cross

## Key Principles

1. **Follow the framework, don't invent** — use C4 conventions and the style guide classes. Do not create custom classes, colors, or shapes to "make it look better." The framework exists so every diagram is consistent without thinking about aesthetics
2. **One story per diagram** — don't try to show everything at once
3. **Arrows flow in one direction** — if arrows go backwards, the layout breaks
4. **Feedback loops are dashed** — visually distinguish the one arrow that goes backwards
5. **Direction matters** — `down` for pipelines, `right` for sequences
6. **Node declaration order matters** — D2/ELK places nodes roughly in the order they appear
7. **Containers help, but sparingly** — use them to group 2-4 related nodes, not as decoration
8. **Verify before you diagram** — check actual service names, deployment configs, and code before naming nodes
9. **Protocol in brackets** — always label edges with the transport protocol: `[Pub/Sub]`, `[SQL]`, `[gRPC]`, `[HTTPS]`
10. **Use `detail` class for internals** — when showing database tables, config values, or other internals without adding full nodes, use the `detail` rectangle class from the style guide
11. **Architecture, not behavior** — diagrams show what components exist and how they connect. Failure modes, error flows, and "what happens when" belong in the text around the diagram, not in the diagram itself

## Additional Resources

### Reference Files

- **[references/d2-style.md](references/d2-style.md)** — All D2 class definitions, edge colors, label guidelines, node naming conventions, layout tips, and complete C4 examples
- **[references/d2-advanced.md](references/d2-advanced.md)** — Icons, layers/scenarios/steps, variables, grid layouts, legends, tooltips/links, themes, multi-diagram sets, conceptual diagrams, and layout engine comparison
