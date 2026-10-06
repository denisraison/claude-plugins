---
name: excalidraw-diagrams
description: This skill should be used when the user asks to "create a diagram", "draw an architecture diagram", "make a flowchart", "visualize this flow", "draw our system", asks for an Excalidraw or ".excalidraw" file, or dictates a diagram out loud (often via Hex speech-to-text) like "so React talks to the API which reads Postgres". Also use for follow-up edits to an existing diagram ("add Redis", "remove the queue", "I moved some stuff, update it", "tidy it up") and for exporting one as a PNG.
---

# Excalidraw Diagrams

Turn a spoken or typed description into an editable `.excalidraw` file. Claude only decides **what** is in the diagram (nodes, edges, groups) as a small graph JSON. `scripts/diagram.sh` does all layout (ELK), styling, icons and the Excalidraw file format. Never hand-write Excalidraw elements.

Each diagram is two files side by side:

- `<name>.graph.json` is the source of truth that Claude edits.
- `<name>.excalidraw` is the rendered output the user opens and edits.

Put them in the current directory unless the user names a place. Use a short kebab-case name.

## Input is speech

Requests usually arrive as raw dictation, so read them for intent, not literally:

- Ignore filler ("um", "so basically", "you know").
- "actually", "no wait", "scratch that", "I mean" replace the thing just said. "It writes to S3, actually GCS" means GCS only.
- Only draw what was said. "Connects to Postgres" adds Postgres, not a cache or a queue. When in doubt, do less.
- Fix obvious transcription slips of tech names (e.g. "post gress", "cooper netties", "traffic" for Traefik).

## Workflow

**New diagram**

1. Write `<name>.graph.json` (schema below).
2. Run `scripts/diagram.sh render <name>.graph.json`.
3. Check it (below), then report the `.excalidraw` path and any warnings the script printed.

**Changing an existing diagram**

1. Run `scripts/diagram.sh sync <name>.graph.json`. This folds anything the user changed on the canvas (deleted, renamed, relabeled, re-shaped, hand-drawn labeled boxes and arrows between boxes) into the graph and prints what it found. Mention those changes back briefly.
2. Read `<name>.graph.json`, then make the change with targeted Edit calls. Do not rewrite the whole file, so untouched nodes keep their ids.
3. Run `scripts/diagram.sh render <name>.graph.json`. Everything already on the canvas stays where it is, including boxes the user dragged; only new things get placed.
4. Check it (below).

Add `--relayout` to render only when the user asks to tidy up, clean up or re-arrange, or when the check below shows a placement problem. It lays everything out fresh and throws away the user's manual positions. Changing `direction` does this automatically.

**Check every render**

Run `scripts/diagram.sh preview <name>.graph.json` and Read the `<name>.png` it writes. It is exactly what Excalidraw would export. Look for:

- an arrow pointing against the flow that isn't a real loop back
- labels sitting on top of each other or on a box
- a route that wraps around a zone (usually a group that splits a chain: A in the group, B outside, C back in)
- text too long for its box, or one diagram so wide it's unreadable

Fix it in the graph, not with more renders: reorder `nodes` so they follow the flow (the layout follows that order), include the in-between node in the group or drop the group, shorten labels, or use `--relayout` if new nodes were squeezed in badly. Then preview again. Two rounds is usually enough. If it still looks off, say what's wrong instead of looping.

Never edit or delete the `_canvas` key. It records what the canvas last looked like, which is how sync tells the user's canvas edits apart from graph edits.

If render prints `not rendered, fix ...`, fix the listed problems in the graph and run it again. Nothing is written until the graph is valid.

## Graph schema

```json
{
  "direction": "LR",
  "nodes": [
    { "id": "api", "label": "Orders API", "shape": "rectangle", "color": "green", "icon": "nodedotjs", "strokeStyle": "solid", "font": "handwritten" }
  ],
  "edges": [
    { "from": "web", "to": "api", "label": "HTTP", "strokeStyle": "solid", "endArrowhead": "arrow" }
  ],
  "groups": [
    { "id": "backend", "label": "Backend", "color": "green", "nodes": ["api", "db"], "icon": "googlecloud" }
  ]
}
```

Only `id` and `label` (nodes), `from` and `to` (edges), and `id`, `label` and `nodes` (groups) are required. Leave everything else out unless it means something.

- `direction`: `"LR"` for architectures, pipelines, data flows. `"TB"` for flowcharts, decision trees, hierarchies.
- `id`: kebab-case of the label ("Web App" -> `web-app`). Never change an existing id. Rename by changing `label`.
- `shape`: `rectangle` (default), `diamond` (decisions), `ellipse` (start/end).
- `color`: `blue` clients/frontends, `green` services/success, `purple` gateways/middleware, `orange` external/third-party, `red` errors/failure, `teal` databases/storage/queues, `yellow` decisions, `grey` generic (default).
- `icon`: a simple-icons slug, only for a well-known technology the user actually named (no Gmail logo on a generic "send email"). If one of a set of siblings has no icon (Google has one, Microsoft doesn't), leave all of them without. Look slugs up with `scripts/diagram.sh icons <query>` when unsure. An unknown slug draws without an icon and prints a warning.
- `strokeStyle`: `solid` (default), `dashed` (async/optional), `dotted` (planned/inactive). Works on nodes and edges.
- `font`: `handwritten` (default), `normal`, `code`.
- Edges point the way the call goes, caller to callee ("Looker reads ClickHouse" is `looker -> clickhouse`), except in pipelines described as data moving ("events flow into Kafka").
- Edge `label`: only when it adds something, like a protocol ("gRPC", "SQL"), data ("events") or a branch ("Yes"/"No").
- `endArrowhead`: `arrow` (default), `bar`, `diamond`, `dot`, or `null` for no arrowhead.
- `groups`: background zones for layers, teams, phases or hosting boundaries ("runs on GCP" means a group with that provider's icon). Membership lives only in `groups[].nodes`. A node in two groups clusters with the first one.

## Shape the graph like the real thing

- Real systems fan out and fan in. A gateway calls several services, several clients hit one API, services share a database. Only draw a chain A -> B -> C when each step really connects to just one other.
- No self-loops.
- The one arrow that loops back to an earlier step (retry, redirect back, "now logged in") gets `"strokeStyle": "dashed"`.
- One story per diagram. If it starts needing a second zone layout or a legend, split it.
- When the diagram is of a real codebase you can see, use the real service, table and queue names from the code or deploy config, not what was said in passing.
- Architectures: zones like "Client / Service / Data" once 3+ nodes clearly belong to a tier, protocol labels on edges.
- Flowcharts: green ellipse Start and End, every decision is a yellow diamond, decision edges labeled ("Yes"/"No", "Approved"/"Rejected"), red for failure paths. Use groups as swim lanes when several roles are involved.

## Opening the file

After the first render, start the local editor as a background command (it runs until stopped) unless one is already running for this diagram:

```bash
scripts/diagram.sh open <name>.graph.json
```

It opens a browser tab with a full Excalidraw editor on that file. The user's edits save to the file automatically, and every later render shows up in the tab within a second, so there is nothing to reopen. The page loads Excalidraw from esm.sh, so it needs internet.

`.excalidraw` is the standard scene format, so the file also opens on excalidraw.com (menu, then Open), in the Obsidian Excalidraw plugin, or in the VS Code/Cursor Excalidraw extension. Those don't reload after a render, and the user has to save before asking for the next change.

## Limits

- New nodes added to a kept layout are fitted in next to what they connect to, not re-optimised with everything else. After many additions the picture drifts from what a fresh layout would give; `--relayout` resets it.
- Arrows between two existing boxes keep their exact route. New arrows, and arrows whose ends no longer touch their boxes, get a simple elbow route.
- Preview and the live editor load Excalidraw from esm.sh, so they need internet. Preview needs Chrome (set `CHROME` to another Chromium binary if it isn't in /Applications).
- Hand-drawn things that aren't labeled boxes or box-to-box arrows (freehand, sticky text, unlabeled shapes) are kept as-is, at the same position.
- Dense graphs with many groups can have long or crossing edges. Fewer groups, or splitting into two diagrams, usually reads better.
