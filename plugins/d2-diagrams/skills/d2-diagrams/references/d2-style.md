# D2 Style Guide

Consistent styling for professional diagrams, following C4 model conventions.

## Color Palette

Use these class definitions. Copy the ones needed into the `.d2` file.

### C4 Element Classes

```d2
classes: {
  # C4 Person — users, roles, actors
  person: {
    shape: person
    style: {
      fill: "#dbeafe"
      stroke: "#2563eb"
      font-color: "#1e3a5f"
      bold: true
      font-size: 16
    }
  }

  # C4 System — the system under discussion (hero node, stands out)
  system: {
    style: {
      border-radius: 10
      fill: "#2563eb"
      stroke: "#1d4ed8"
      font-color: "#ffffff"
      bold: true
      font-size: 18
    }
  }

  # C4 External System — systems outside your control
  external-system: {
    style: {
      border-radius: 10
      fill: "#f3f4f6"
      stroke: "#9ca3af"
      font-color: "#374151"
      bold: true
      font-size: 16
    }
  }

  # C4 System Boundary — dashed border grouping containers
  boundary: {
    style: {
      fill: "#f8fafc"
      stroke: "#94a3b8"
      stroke-dash: 5
      border-radius: 12
      font-color: "#475569"
      font-size: 14
      bold: true
    }
  }

  # C4 Queue / Message Broker
  queue: {
    shape: queue
    style: {
      fill: "#fce7f3"
      stroke: "#db2777"
      font-color: "#831843"
      bold: true
      font-size: 15
    }
  }
}
```

### Technology-Specific Classes

```d2
classes: {
  # Go services
  go: {
    style: {
      border-radius: 10
      fill: "#dbeafe"
      stroke: "#2563eb"
      font-color: "#1e3a5f"
      bold: true
      font-size: 16
    }
  }

  # Java / backend services
  java: {
    style: {
      border-radius: 10
      fill: "#ede9fe"
      stroke: "#7c3aed"
      font-color: "#4c1d95"
      bold: true
      font-size: 16
    }
  }

  # TypeScript / Node services
  ts: {
    style: {
      border-radius: 10
      fill: "#cffafe"
      stroke: "#0891b2"
      font-color: "#164e63"
      bold: true
      font-size: 16
    }
  }

  # Python services
  python: {
    style: {
      border-radius: 10
      fill: "#fef3c7"
      stroke: "#d97706"
      font-color: "#78350f"
      bold: true
      font-size: 16
    }
  }

  # Rust services
  rust: {
    style: {
      border-radius: 10
      fill: "#fde2d1"
      stroke: "#c2410c"
      font-color: "#7c2d12"
      bold: true
      font-size: 16
    }
  }

  # Databases
  db: {
    shape: cylinder
    style: {
      fill: "#fef9c3"
      stroke: "#ca8a04"
      font-color: "#713f12"
      bold: true
      font-size: 16
    }
  }

  # External systems / entry/exit points
  ext: {
    shape: oval
    style: {
      fill: "#dcfce7"
      stroke: "#16a34a"
      font-color: "#14532d"
      font-size: 15
    }
  }

  # Jobs / cron / scheduled tasks
  job: {
    style: {
      border-radius: 10
      fill: "#f3f4f6"
      stroke: "#9ca3af"
      font-color: "#374151"
      font-size: 14
      stroke-dash: 4
    }
  }

  # Highlighted / key service
  key: {
    style: {
      border-radius: 10
      fill: "#d1fae5"
      stroke: "#059669"
      font-color: "#064e3b"
      bold: true
      font-size: 16
    }
  }

  # Trigger / special process
  trigger: {
    shape: hexagon
    style: {
      fill: "#fce7f3"
      stroke: "#db2777"
      font-color: "#831843"
      bold: true
      font-size: 15
    }
  }

  # Phase / grouping container
  phase: {
    style: {
      fill: "#f8fafc"
      stroke: "#e2e8f0"
      border-radius: 12
      font-color: "#64748b"
      font-size: 13
      bold: true
    }
  }

  # Detail / table listing
  detail: {
    shape: rectangle
    style: {
      fill: "#fff7ed"
      stroke: "#ea580c"
      font-color: "#7c2d12"
      border-radius: 6
      font-size: 13
    }
  }
}
```

## Edge Colors

Use consistent colors for different connection types:

```d2
# HTTP / REST / external traffic
style.stroke: "#16a34a"

# Pub/Sub / async messaging / event streaming (Kafka, NATS, etc.)
style.stroke: "#2563eb"

# gRPC / sync service calls
style.stroke: "#7c3aed"

# Database reads/writes
style.stroke: "#ca8a04"

# WebSocket / bidirectional
style.stroke: "#0891b2"

# Background / scheduled
style.stroke: "#9ca3af"
style.stroke-dash: 4

# Feedback loops / reverse flow
style.stroke: "#ea580c"
style.stroke-dash: 4

# Trigger / cascade
style.stroke: "#db2777"
```

**Quick reference table:**

| Protocol | Color | Hex |
|----------|-------|-----|
| HTTP / REST | Green | `#16a34a` |
| Pub/Sub / Streaming | Blue | `#2563eb` |
| gRPC | Purple | `#7c3aed` |
| SQL / Database | Amber | `#ca8a04` |
| WebSocket | Cyan | `#0891b2` |
| Background / Scheduled | Gray dashed | `#9ca3af` |
| Feedback / Reverse | Orange dashed | `#ea580c` |
| Trigger / Cascade | Pink | `#db2777` |

## Label Guidelines

- Use `\n` for multi-line labels: `"line one\nline two"`
- Keep labels short — 2-3 words per line, max 2 lines
- Only label edges that aren't obvious from context
- Use italic for protocol/transport: the label text itself conveys this

## Node Naming (C4 Convention)

Follow the standard C4 label format. Every node must have a `[bracketed]` annotation identifying what it is:

```
Name
[Container: Technology]
Optional description
```

Examples:
- `"api-gateway\n[Container: Go]"` — service with technology
- `"orders-db\n[Container: PostgreSQL]"` — database
- `"report-gen\n[CronJob: every 6h]"` — scheduled job
- `"Payment Provider\n[External System]"` — external actor
- `"notification-svc\n[Container: TypeScript]"` — Node.js/TS service
- `"ml-pipeline\n[Container: Python]"` — Python service

For shorter labels when the full format is too verbose, the two-line shorthand works: `"api-gateway\n[Go — routing]"`. The key: no node without a bracketed annotation.

## Layout Tips

- Declare nodes in the order they should be placed (top-to-bottom or left-to-right)
- For fan-in patterns: declare the sources first, then the target
- For fan-out patterns: declare the source first, then the targets
- Use invisible containers (`style.fill: transparent; style.stroke: transparent`) to force grouping without visual clutter

## C4 Examples

### Level 1 — System Context

```d2
direction: down

# Actors
customer: "Customer\n(end user)" {class: person}
admin: "Admin\n(operations)" {class: person}

# System under discussion
platform: "Order Management\n[e-commerce platform]" {class: system}

# External systems
analytics: "Analytics Platform\n[BigQuery]" {class: external-system}
payment: "Payment Gateway\n[Stripe]" {class: external-system}

customer -> platform: "places orders\n[HTTPS]" {style.stroke: "#16a34a"}
admin -> platform: "manages inventory\n[HTTPS]" {style.stroke: "#16a34a"}
platform -> analytics: "sends events\n[Pub/Sub]" {style.stroke: "#2563eb"}
platform -> payment: "processes payments\n[HTTPS]" {style.stroke: "#7c3aed"}
```

### Level 2 — Container

```d2
direction: right

customer: "Customer" {class: external-system}

platform: "Order Management Platform" {
  class: boundary

  gateway: "api-gateway\nGo — routing" {class: go}
  orders_db: "orders-db\nPostgreSQL" {class: db}
  order_svc: "order-service\nJava" {class: java}
  events: "Pub/Sub" {class: queue}

  gateway -> order_svc: "forwards\n[gRPC]" {style.stroke: "#7c3aed"}
  order_svc -> orders_db: "reads/writes\n[SQL]" {style.stroke: "#ca8a04"}
  order_svc -> events: "order events" {style.stroke: "#2563eb"}
}

customer -> platform.gateway: "API request\n[HTTPS]" {style.stroke: "#16a34a"}
```

### Level 3 — Component (inside a service)

```d2
direction: down

order_svc: "order-service" {
  class: boundary

  handler: "HTTP Handler\n[routes]" {class: go}
  validator: "Validator\n[input checks]" {class: go}
  processor: "Order Processor\n[business logic]" {class: key}
  repo: "Repository\n[data access]" {class: go}
  notifier: "Notifier\n[events]" {class: go}

  handler -> validator: "validates" {style.stroke: "#7c3aed"}
  validator -> processor: "processes" {style.stroke: "#7c3aed"}
  processor -> repo: "persists" {style.stroke: "#ca8a04"}
  processor -> notifier: "emits events" {style.stroke: "#2563eb"}
}
```
