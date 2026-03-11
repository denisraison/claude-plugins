# D2 Advanced Features

Features beyond the core C4 workflow. Consult this reference when a diagram needs multi-view composition, icons, grid layouts, or other advanced D2 capabilities.

## Icons

Add icons to nodes for instant visual recognition. D2 hosts free icons at [icons.terrastruct.com](https://icons.terrastruct.com/).

```d2
gateway: "API Gateway" {
  icon: https://icons.terrastruct.com/aws%2FNetworking%20&%20Content%20Delivery%2FAmazon-API-Gateway.svg
  class: go
}

postgres: "PostgreSQL" {
  icon: https://icons.terrastruct.com/dev%2Fpostgresql.svg
  class: db
}
```

- Icons placed automatically — center for nodes, top-left for containers
- Use `near` keyword to reposition: `icon.near: top-center`
- Local files work too: `icon: ./assets/logo.png`
- Use sparingly — icons on every node creates visual noise. Best on 2-3 key nodes

## Layers, Scenarios, and Steps

D2 supports multi-board composition for diagrams that need multiple views.

### Layers — Independent Views

Each layer is a blank board. Use for different levels of abstraction (C4 L1 vs L2).

```d2
# Base board (L1 - System Context)
user: "User" {class: person}
platform: "Platform" {class: system}
user -> platform

layers: {
  containers: {
    # L2 - Container view (completely separate board)
    platform: "Platform" {
      class: boundary
      api: "api-service" {class: go}
      db: "database" {class: db}
      api -> db
    }
  }
}
```

### Scenarios — Variations of the Same Diagram

Inherit from the base board. Use for showing normal vs failure states, dev vs prod environments.

```d2
# Base
api: "API" {class: go}
db: "Database" {class: db}
api -> db: "reads\n[SQL]"

scenarios: {
  with-cache: {
    cache: "Redis Cache" {class: db}
    api -> cache: "checks first\n[Redis]"
    cache -> db: "miss\n[SQL]"
  }
}
```

### Steps — Sequential Animation

Each step inherits from the previous one. Use for request flows, deployment sequences.

```d2
client: "Client" {class: ext}
api: "API" {class: go}
db: "Database" {class: db}

steps: {
  1: {
    client -> api: "1. request"
  }
  2: {
    api -> db: "2. query"
  }
  3: {
    db -> api: "3. result"
  }
  4: {
    api -> client: "4. response"
  }
}
```

Export animated: `d2 --animate-interval 1200 flow.d2 flow.svg`

## Variables

Define reusable values to avoid repetition.

```d2
vars: {
  team-color: "#2563eb"
  db-color: "#ca8a04"
}

api: "api-service" {
  style.stroke: ${team-color}
}
orders: "orders-db" {
  style.stroke: ${db-color}
}
```

## Grid Layouts

Arrange nodes in a structured grid — useful for comparisons, matrices, and structured overviews.

```d2
tech-radar: {
  grid-columns: 4

  adopt: "Adopt" {style.fill: "#d1fae5"}
  trial: "Trial" {style.fill: "#fef9c3"}
  assess: "Assess" {style.fill: "#fce7f3"}
  hold: "Hold" {style.fill: "#f3f4f6"}
}
```

- Set `grid-columns` OR `grid-rows` (or both) on a container
- First keyword defined is the dominant fill direction
- `grid-gap: 0` for tight table-like layouts
- Connections between grid cells are straight center-to-center lines (no path-finding)

## Legend

Add a legend to make diagrams self-documenting, especially when multiple edge colors or node types are used.

```d2
d2-legend: {
  shape: rectangle
  "Go Service" {class: go}
  "Java Service" {class: java}
  "Database" {class: db}
  "Async Queue" {class: queue}
}
```

The legend renders as a separate box. Keep it to 3-5 entries — if the diagram needs more, it's probably too complex.

## Tooltips and Links

Add interactivity to SVG output (not available in PNG).

```d2
api: "api-service" {
  tooltip: "Handles authentication, rate limiting, and request routing"
  link: https://github.com/org/api-service
}
```

## Themes

D2 ships with multiple themes. Common choices:

| Theme | Flag | Best for |
|-------|------|----------|
| Default (light) | `--theme 0` | Docs, wikis, light backgrounds |
| C4 | `--theme 200` | Standard C4 model look |
| Dark Mauve | `--theme 200` | Dark-mode presentations |
| Terminal | `--theme 300` | Terminal/CLI docs |

Full theme gallery: `d2 --help` or [d2lang.com themes](https://d2lang.com/tour/themes).

For dark backgrounds, also consider `--dark-theme` flag which auto-generates a dark variant.

## Higher Resolution Output

```bash
# 2x scale for retina displays and print
d2 --theme 0 --layout elk --pad 60 --scale 2 input.d2 output.png

# 3x for large poster prints
d2 --theme 0 --layout elk --pad 60 --scale 3 input.d2 output.png
```

SVG output is resolution-independent — `--scale` only matters for PNG.

## Multi-Diagram Sets

When a system needs multiple diagrams, keep them consistent:

1. **Shared naming** — the same service has the same node ID across diagrams (`api_gateway`, not `gateway` in one and `api-gw` in another)
2. **Consistent classes** — copy the same class definitions into every `.d2` file (or use D2 imports)
3. **Cross-reference in titles** — use the boundary label to indicate scope: `"Platform — Auth Flow"`, `"Platform — Payment Flow"`
4. **Naming convention** — prefix files by level and scope: `l1-system-context.d2`, `l2-payment-flow.d2`, `l2-auth-flow.d2`, `l3-order-service.d2`
5. **Index file** — for large sets, maintain a markdown index linking diagrams with one-line descriptions of what each shows

## Conceptual Diagrams (No Codebase)

When designing a system that doesn't exist yet or diagramming for exploration:

- Skip the "verify names from code" step
- Use descriptive, intention-revealing names (`auth-service`, `order-processor`) rather than placeholder names (`service-a`, `component-1`)
- Mark speculative elements: add `(proposed)` or `(TBD)` to labels
- Prefer Level 2 (Container) — it's concrete enough to be useful without implying implementation details
- Use the `job` class (dashed border) for components that are uncertain or optional

## Layout Engine Comparison

| Engine | Flag | Best for |
|--------|------|----------|
| ELK | `--layout elk` | Complex graphs, many connections (default recommendation) |
| Dagre | `--layout dagre` | Simple hierarchies, faster rendering |
| TALA | `--layout tala` | Premium layout, best results (requires license) |

Stick with ELK unless there's a reason to switch. Dagre can produce cleaner results for simple trees.
