import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { describe, test } from "node:test";
import { baselineFromGraph, canvasGeometry, syncFromCanvas, validateGraph } from "./graph.mjs";
import { layoutGraph } from "./layout.mjs";

const GRAPH = {
  direction: "LR",
  nodes: [
    { id: "web", label: "Web App", color: "blue", icon: "react" },
    { id: "api", label: "API", color: "green" },
    { id: "db", label: "Postgres", color: "teal", icon: "postgresql" },
    { id: "ok", label: "Healthy?", shape: "diamond", color: "yellow" },
  ],
  edges: [
    { from: "web", to: "api", label: "HTTP" },
    { from: "api", to: "db", label: "SQL" },
    { from: "api", to: "ok" },
  ],
  groups: [{ id: "backend", label: "Backend", color: "green", nodes: ["api", "db"] }],
};

// A graph as it sits on disk right after a render, plus the canvas that render wrote.
async function rendered(graph = GRAPH) {
  return {
    graph: { ...structuredClone(graph), _canvas: baselineFromGraph(graph) },
    elements: (await layoutGraph(graph, 0)).elements,
  };
}

const relabel = (elements, id, text) =>
  elements.map((el) => (el.id === id ? { ...el, text, originalText: text } : el));
const remove = (elements, ...ids) => elements.filter((el) => !ids.includes(el.id));

describe("layoutGraph", () => {
  test("every binding points at an element that points back", async () => {
    const { elements } = await layoutGraph(GRAPH, 0);
    const byId = new Map(elements.map((el) => [el.id, el]));
    for (const el of elements) {
      for (const ref of el.boundElements ?? []) {
        const other = byId.get(ref.id);
        assert.ok(other, `${el.id} -> missing ${ref.id}`);
        assert.equal(other.type, ref.type);
        const backRef = other.containerId ?? [other.startBinding?.elementId, other.endBinding?.elementId];
        assert.ok([].concat(backRef).includes(el.id), `${ref.id} does not point back to ${el.id}`);
      }
      if (el.containerId) {
        assert.ok(byId.get(el.containerId)?.boundElements.some((r) => r.id === el.id), `${el.id} container lacks ref`);
      }
    }
  });

  test("arrow points are relative to the arrow origin", async () => {
    const arrows = (await layoutGraph(GRAPH, 0)).elements.filter((el) => el.type === "arrow");
    assert.equal(arrows.length, 3);
    for (const a of arrows) {
      assert.deepEqual(a.points[0], [0, 0]);
    }
  });

  test("same input gives byte-identical output", async () => {
    assert.equal(JSON.stringify(await layoutGraph(GRAPH, 0)), JSON.stringify(await layoutGraph(GRAPH, 0)));
  });

  const sizeCases = [
    { name: "short label keeps the default size", shape: "ellipse", label: "Start", w: (w) => w === 140, h: (h) => h === 60 },
    { name: "medium label widens before growing taller", shape: "ellipse", label: "Admin invites email", w: (w) => w > 140, h: (h) => h === 60 },
    { name: "medium label widens a diamond", shape: "diamond", label: "Has first & last name?", w: (w) => w > 160, h: (h) => h === 100 },
    { name: "very long label grows taller at max width", shape: "ellipse", label: "Customer arrives at the checkout counter with a very full cart and a coupon", w: (w) => w === 260, h: (h) => h > 60 },
  ];
  for (const c of sizeCases) {
    test(c.name, async () => {
      const graph = { nodes: [{ id: "a", label: c.label, shape: c.shape }], edges: [] };
      const shape = (await layoutGraph(graph, 0)).elements.find((el) => el.id === "node-a");
      assert.ok(c.w(shape.width), `width ${shape.width}`);
      assert.ok(c.h(shape.height), `height ${shape.height}`);
    });
  }

  test("a loop back to an earlier step is the edge that points backwards", async () => {
    const graph = {
      direction: "TB",
      nodes: ["start", "page", "check", "login", "redirect"].map((id) => ({ id, label: id })),
      edges: [
        { from: "start", to: "page" },
        { from: "page", to: "check" },
        { from: "check", to: "login" },
        { from: "login", to: "redirect" },
        { from: "redirect", to: "page" },
      ],
    };
    const { elements } = await layoutGraph(graph, 0);
    const y = (id) => elements.find((el) => el.id === `node-${id}`).y;
    assert.ok(y("page") < y("check") && y("check") < y("login") && y("login") < y("redirect"));
  });

  test("zones of different groups do not overlap", async () => {
    const graph = {
      direction: "LR",
      nodes: ["a", "b", "c", "d", "e"].map((id) => ({ id, label: id })),
      edges: [{ from: "a", to: "b" }, { from: "b", to: "c" }, { from: "c", to: "d" }, { from: "a", to: "e" }],
      groups: [
        { id: "one", label: "One", nodes: ["a", "b", "d"] },
        { id: "two", label: "Two", nodes: ["c"] },
      ],
    };
    const { elements } = await layoutGraph(graph, 0);
    const [one, two] = ["group-one", "group-two"].map((id) => elements.find((el) => el.id === id));
    const overlap = one.x < two.x + two.width && two.x < one.x + one.width && one.y < two.y + two.height && two.y < one.y + one.height;
    assert.equal(overlap, false);
  });
});

describe("keeping positions on re-render", () => {
  const byId = (elements, id) => elements.find((el) => el.id === id);
  const center = (el) => ({ x: el.x + el.width / 2, y: el.y + el.height / 2 });
  const move = (elements, id, dx, dy) => elements.map((el) => (el.id === id ? { ...el, x: el.x + dx, y: el.y + dy } : el));
  const box = (el) => ({ x: el.x, y: el.y, w: el.width, h: el.height });
  const overlaps = (a, b) => a.x < b.x + b.w && b.x < a.x + a.w && a.y < b.y + b.h && b.y < a.y + a.h;

  test("a node the user dragged stays where they put it", async () => {
    const { elements } = await layoutGraph(GRAPH, 0);
    const dragged = move(elements, "node-db", 300, 200);
    const again = (await layoutGraph(GRAPH, 0, canvasGeometry(dragged))).elements;
    assert.deepEqual(box(byId(again, "node-db")), box(byId(dragged, "node-db")));
    assert.deepEqual(box(byId(again, "node-web")), box(byId(elements, "node-web")));
  });

  test("renaming a node keeps its center and leaves the others alone", async () => {
    const { elements } = await layoutGraph(GRAPH, 0);
    const renamed = structuredClone(GRAPH);
    renamed.nodes[1].label = "Orders API with a much longer name";
    const again = (await layoutGraph(renamed, 0, canvasGeometry(elements))).elements;
    assert.deepEqual(center(byId(again, "node-api")), center(byId(elements, "node-api")));
    assert.deepEqual(box(byId(again, "node-web")), box(byId(elements, "node-web")));
  });

  test("arrows left dangling by a moved box are routed again", async () => {
    const { elements } = await layoutGraph(GRAPH, 0);
    const moved = move(elements, "node-db", 0, 400);
    const again = (await layoutGraph(GRAPH, 0, canvasGeometry(moved))).elements;
    const arrow = byId(again, "edge-api>db#0");
    const end = { x: arrow.x + arrow.points.at(-1)[0], y: arrow.y + arrow.points.at(-1)[1] };
    const db = byId(again, "node-db");
    assert.ok(end.y >= db.y - 12 && end.y <= db.y + db.height + 12, `arrow ends at y ${end.y}, db spans ${db.y}-${db.y + db.height}`);
  });

  test("arrows between untouched nodes keep their exact route", async () => {
    const { elements } = await layoutGraph(GRAPH, 0);
    const again = (await layoutGraph(GRAPH, 0, canvasGeometry(elements))).elements;
    const route = (el) => ({ x: el.x, y: el.y, points: el.points });
    assert.deepEqual(route(byId(again, "edge-web>api#0")), route(byId(elements, "edge-web>api#0")));
  });

  test("a new node lands in the column a fresh layout would give it, without overlapping anything", async () => {
    const { elements } = await layoutGraph(GRAPH, 0);
    const grown = structuredClone(GRAPH);
    grown.nodes.push({ id: "cache", label: "Redis" });
    grown.edges.push({ from: "api", to: "cache" });
    const again = (await layoutGraph(grown, 0, canvasGeometry(elements))).elements;
    const cache = byId(again, "node-cache");
    for (const el of again.filter((e) => e.customData?.diagram?.kind === "node" && e.id !== "node-cache")) {
      assert.equal(overlaps(box(cache), box(el)), false, `overlaps ${el.id}`);
    }
    const freshCache = byId((await layoutGraph(grown, 0)).elements, "node-cache");
    assert.ok(Math.abs(cache.x - freshCache.x) < 20, `cache x ${cache.x}, fresh layout x ${freshCache.x}`);
    assert.ok(cache.x > byId(again, "node-api").x, "cache sits downstream of api");
    assert.ok(byId(again, "edge-api>cache#0"), "new edge is drawn");
  });
});

describe("diagram.sh", () => {
  const run = (dir, ...args) => execFileSync("node", [new URL("./diagram.mjs", import.meta.url).pathname, ...args], { cwd: dir, encoding: "utf8" });
  const nodeBox = (dir, id) => {
    const el = JSON.parse(readFileSync(join(dir, "d.excalidraw"), "utf8")).elements.find((e) => e.id === `node-${id}`);
    return { x: el.x, y: el.y };
  };

  test("render keeps a dragged node, --relayout puts it back", () => {
    const dir = mkdtempSync(join(tmpdir(), "diagram-test-"));
    try {
      writeFileSync(join(dir, "d.graph.json"), JSON.stringify(GRAPH));
      run(dir, "render", "d");
      const original = nodeBox(dir, "db");

      const canvasPath = join(dir, "d.excalidraw");
      const scene = JSON.parse(readFileSync(canvasPath, "utf8"));
      scene.elements = scene.elements.map((el) => (el.id === "node-db" ? { ...el, x: el.x + 400 } : el));
      writeFileSync(canvasPath, JSON.stringify(scene));

      run(dir, "render", "d");
      assert.deepEqual(nodeBox(dir, "db"), { x: original.x + 400, y: original.y });

      run(dir, "render", "d", "--relayout");
      assert.deepEqual(nodeBox(dir, "db"), original);
    } finally {
      rmSync(dir, { recursive: true, force: true });
    }
  });

  test("changing direction lays the diagram out fresh", () => {
    const dir = mkdtempSync(join(tmpdir(), "diagram-test-"));
    try {
      writeFileSync(join(dir, "d.graph.json"), JSON.stringify(GRAPH));
      run(dir, "render", "d");
      const lr = [nodeBox(dir, "web"), nodeBox(dir, "api")];
      const doc = JSON.parse(readFileSync(join(dir, "d.graph.json"), "utf8"));
      writeFileSync(join(dir, "d.graph.json"), JSON.stringify({ ...doc, direction: "TB" }));
      run(dir, "render", "d");
      const tb = [nodeBox(dir, "web"), nodeBox(dir, "api")];
      assert.ok(lr[1].x > lr[0].x && tb[1].y > tb[0].y, JSON.stringify({ lr, tb }));
    } finally {
      rmSync(dir, { recursive: true, force: true });
    }
  });
});

describe("syncFromCanvas", () => {
  const cases = [
    {
      name: "untouched canvas changes nothing",
      edit: (els) => els,
      report: [],
      check: (g) => assert.deepEqual(g.nodes, GRAPH.nodes),
    },
    {
      name: "deleting a node drops it, its edges and its group membership",
      edit: (els) => remove(els, "node-db", "node-db-text", "icon-node-db"),
      report: ['deleted node "Postgres"'],
      check: (g) => {
        assert.ok(!g.nodes.some((n) => n.id === "db"));
        assert.ok(!g.edges.some((e) => e.to === "db"));
        assert.deepEqual(g.groups[0].nodes, ["api"]);
      },
    },
    {
      name: "deleting an arrow drops only that edge",
      edit: (els) => remove(els, "edge-api>db#0", "edge-api>db#0-text"),
      report: ["deleted edge api -> db"],
      check: (g) => assert.deepEqual(g.edges.map((e) => e.to), ["api", "ok"]),
    },
    {
      name: "renaming a node's text renames the node",
      edit: (els) => relabel(els, "node-db-text", "Aurora"),
      report: ['renamed node "Postgres" -> "Aurora"'],
      check: (g) => assert.equal(g.nodes.find((n) => n.id === "db").label, "Aurora"),
    },
    {
      name: "editing an arrow label relabels the edge",
      edit: (els) => relabel(els, "edge-api>db#0-text", "pgx"),
      report: ['relabeled edge api -> db: "pgx"'],
      check: (g) => assert.equal(g.edges[1].label, "pgx"),
    },
    {
      name: "changing a shape type updates the node shape",
      edit: (els) => els.map((el) => (el.id === "node-api" ? { ...el, type: "ellipse" } : el)),
      report: ['changed "API" to ellipse'],
      check: (g) => assert.equal(g.nodes.find((n) => n.id === "api").shape, "ellipse"),
    },
    {
      name: "a hand-drawn labeled box and a bound arrow become a node and an edge",
      edit: (els) => [
        ...els,
        { id: "r1", type: "rectangle", boundElements: [{ id: "t1", type: "text" }] },
        { id: "t1", type: "text", containerId: "r1", text: "Redis Cache", originalText: "Redis Cache" },
        { id: "a1", type: "arrow", startBinding: { elementId: "node-api" }, endBinding: { elementId: "r1" } },
      ],
      report: ['added node "Redis Cache" (drawn by hand)', "added edge api -> redis-cache (drawn by hand)"],
      check: (g, absorbed) => {
        assert.deepEqual(g.nodes.at(-1), { id: "redis-cache", label: "Redis Cache" });
        assert.deepEqual(g.edges.at(-1), { from: "api", to: "redis-cache" });
        assert.deepEqual([...absorbed].sort(), ["a1", "r1", "t1"]);
      },
    },
    {
      name: "unlabeled hand-drawn shapes are reported, not added",
      edit: (els) => [...els, { id: "e1", type: "ellipse" }],
      report: ["left 1 unlabeled shape(s) as-is, label them to turn them into nodes"],
      check: (g) => assert.equal(g.nodes.length, 4),
    },
  ];

  for (const c of cases) {
    test(c.name, async () => {
      const { graph, elements } = await rendered();
      const out = syncFromCanvas(graph, c.edit(elements));
      assert.deepEqual(out.report, c.report);
      c.check(out.graph, out.absorbed);
    });
  }

  test("nodes added to the graph since the last render are not treated as deleted", async () => {
    const { graph, elements } = await rendered();
    graph.nodes.push({ id: "cache", label: "Cache" });
    const out = syncFromCanvas(graph, elements);
    assert.ok(out.graph.nodes.some((n) => n.id === "cache"));
    assert.deepEqual(out.report, []);
  });

  test("a graph edit made after a sync is not overwritten by the canvas on the next sync", async () => {
    const { graph, elements } = await rendered();
    const canvas = relabel(elements, "node-db-text", "Aurora");
    const first = syncFromCanvas(graph, canvas);
    const edited = { ...first.graph, _canvas: first.baseline };
    edited.nodes.find((n) => n.id === "db").label = "Aurora Serverless";
    const second = syncFromCanvas(edited, canvas);
    assert.equal(second.graph.nodes.find((n) => n.id === "db").label, "Aurora Serverless");
  });

  test("a hand-drawn node deleted from the graph after a sync stays deleted", async () => {
    const { graph, elements } = await rendered();
    const canvas = [
      ...elements,
      { id: "r1", type: "rectangle" },
      { id: "t1", type: "text", containerId: "r1", text: "Redis", originalText: "Redis" },
    ];
    const first = syncFromCanvas(graph, canvas);
    const edited = { ...first.graph, _canvas: first.baseline };
    edited.nodes = edited.nodes.filter((n) => n.id !== "redis");
    const second = syncFromCanvas(edited, canvas);
    assert.ok(!second.graph.nodes.some((n) => n.id === "redis"));
  });
});

describe("validateGraph", () => {
  const cases = [
    { name: "valid graph", graph: GRAPH, errors: 0, warnings: 0 },
    { name: "unknown color", graph: { nodes: [{ id: "a", label: "A", color: "pink" }] }, errors: 1, warnings: 0 },
    { name: "duplicate node id", graph: { nodes: [{ id: "a", label: "A" }, { id: "a", label: "B" }] }, errors: 1, warnings: 0 },
    { name: "edge to missing node", graph: { nodes: [{ id: "a", label: "A" }], edges: [{ from: "a", to: "b" }] }, errors: 1, warnings: 0 },
    { name: "self-loop", graph: { nodes: [{ id: "a", label: "A" }], edges: [{ from: "a", to: "a" }] }, errors: 1, warnings: 0 },
    { name: "group lists missing node", graph: { nodes: [{ id: "a", label: "A" }], groups: [{ id: "g", label: "G", nodes: ["x"] }] }, errors: 1, warnings: 0 },
    { name: "unknown icon is a warning", graph: { nodes: [{ id: "a", label: "A", icon: "nope-not-real" }] }, errors: 0, warnings: 1 },
    { name: "group field on node is a warning", graph: { nodes: [{ id: "a", label: "A", group: "g" }] }, errors: 0, warnings: 1 },
  ];
  for (const c of cases) {
    test(c.name, async () => {
      const { errors, warnings } = validateGraph(c.graph);
      assert.equal(errors.length, c.errors, errors.join("; "));
      assert.equal(warnings.length, c.warnings, warnings.join("; "));
    });
  }
});
