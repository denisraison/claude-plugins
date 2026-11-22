import { ARROWHEADS, COLORS, DIRECTIONS, FONT_NAMES, SHAPES, STROKE_STYLES, edgeKeys, resolveIcon } from "./layout.mjs";

const COLOR_NAMES = Object.keys(COLORS);

export function kebab(text) {
  return text.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "") || "node";
}

export function validateGraph(graph) {
  const errors = [];
  const warnings = [];
  const oneOf = (value, allowed, where) => {
    if (value !== undefined && !allowed.includes(value)) {
      errors.push(`${where}: ${JSON.stringify(value)} is not one of ${allowed.map((a) => JSON.stringify(a)).join(", ")}`);
    }
  };

  if (!Array.isArray(graph.nodes)) {
    return { errors: ["nodes must be an array"], warnings };
  }
  oneOf(graph.direction, DIRECTIONS, "direction");

  const ids = new Set();
  for (const [i, n] of graph.nodes.entries()) {
    const where = `nodes[${i}]${n?.id ? ` (${n.id})` : ""}`;
    if (typeof n?.id !== "string" || !n.id) {
      errors.push(`${where}: id is required`);
      continue;
    }
    if (ids.has(n.id)) {
      errors.push(`${where}: duplicate id`);
    }
    ids.add(n.id);
    if (typeof n.label !== "string" || !n.label.trim()) {
      errors.push(`${where}: label is required`);
    }
    oneOf(n.shape, SHAPES, `${where}.shape`);
    oneOf(n.color, COLOR_NAMES, `${where}.color`);
    oneOf(n.strokeStyle, STROKE_STYLES, `${where}.strokeStyle`);
    oneOf(n.font, FONT_NAMES, `${where}.font`);
    if (n.icon && !resolveIcon(n.icon)) {
      warnings.push(`${where}: unknown icon "${n.icon}", drawn without it (search with: icons <query>)`);
    }
    if (n.group !== undefined) {
      warnings.push(`${where}: "group" on a node is ignored, list the node in groups[].nodes instead`);
    }
  }

  for (const [i, e] of (graph.edges ?? []).entries()) {
    const where = `edges[${i}] (${e?.from} -> ${e?.to})`;
    if (!ids.has(e?.from)) {
      errors.push(`${where}: from "${e?.from}" is not a node id`);
    }
    if (!ids.has(e?.to)) {
      errors.push(`${where}: to "${e?.to}" is not a node id`);
    }
    if (e?.from === e?.to) {
      errors.push(`${where}: self-loops are not supported`);
    }
    oneOf(e?.strokeStyle, STROKE_STYLES, `${where}.strokeStyle`);
    oneOf(e?.endArrowhead, ARROWHEADS, `${where}.endArrowhead`);
  }

  const groupIds = new Set();
  for (const [i, gr] of (graph.groups ?? []).entries()) {
    const where = `groups[${i}]${gr?.id ? ` (${gr.id})` : ""}`;
    if (typeof gr?.id !== "string" || !gr.id) {
      errors.push(`${where}: id is required`);
      continue;
    }
    if (groupIds.has(gr.id)) {
      errors.push(`${where}: duplicate id`);
    }
    groupIds.add(gr.id);
    if (typeof gr.label !== "string" || !gr.label.trim()) {
      errors.push(`${where}: label is required`);
    }
    oneOf(gr.color, COLOR_NAMES, `${where}.color`);
    if (!Array.isArray(gr.nodes)) {
      errors.push(`${where}: nodes must be an array of node ids`);
      continue;
    }
    for (const id of gr.nodes) {
      if (!ids.has(id)) {
        errors.push(`${where}: "${id}" is not a node id`);
      }
    }
    if (gr.icon && !resolveIcon(gr.icon)) {
      warnings.push(`${where}: unknown icon "${gr.icon}", drawn without it`);
    }
  }

  return { errors, warnings };
}

// What the canvas looked like the last time it was folded into the graph.
// Canvas edits are detected against this, so graph edits made since then survive.
export function baselineFromGraph(graph) {
  const keys = edgeKeys(graph.edges ?? []);
  return {
    nodes: Object.fromEntries(graph.nodes.map((n) => [n.id, { label: n.label, shape: n.shape ?? "rectangle" }])),
    edges: Object.fromEntries((graph.edges ?? []).map((e, i) => [keys[i], { label: e.label ?? "" }])),
    groups: Object.fromEntries((graph.groups ?? []).map((g) => [g.id, { label: g.label }])),
    direction: graph.direction ?? "LR",
    absorbed: [],
  };
}

// Where the diagram's own nodes and arrows currently sit on the canvas.
export function canvasGeometry(elements) {
  const canvas = readCanvas(elements);
  const nodes = new Map();
  for (const [id, el] of canvas.nodes) {
    nodes.set(id, { x: el.x, y: el.y, w: el.width, h: el.height, type: el.type, label: canvas.textOf.get(el.id) ?? "" });
  }
  const edges = new Map();
  for (const [key, el] of canvas.edges) {
    edges.set(key, { x: el.x, y: el.y, points: el.points });
  }
  return { nodes, edges };
}

function readCanvas(elements) {
  const live = elements.filter((el) => !el.isDeleted);
  const textOf = new Map();
  for (const el of live) {
    if (el.type === "text" && el.containerId) {
      textOf.set(el.containerId, (el.originalText ?? el.text ?? "").trim());
    }
  }
  const nodes = new Map();
  const edges = new Map();
  const groups = new Map();
  for (const el of live) {
    const d = el.customData?.diagram;
    if (d?.kind === "node") {
      nodes.set(d.id, el);
    } else if (d?.kind === "edge") {
      edges.set(d.key, el);
    } else if (d?.kind === "group") {
      groups.set(d.id, el);
    }
  }
  return { live, textOf, nodes, edges, groups };
}

export function syncFromCanvas(graph, elements) {
  const baseline = graph._canvas ?? null;
  const canvas = readCanvas(elements);
  const report = [];
  const next = {
    direction: graph.direction,
    nodes: graph.nodes.map((n) => ({ ...n })),
    edges: (graph.edges ?? []).map((e) => ({ ...e })),
    groups: (graph.groups ?? []).map((g) => ({ ...g, nodes: [...g.nodes] })),
  };

  if (baseline) {
    const goneNodes = new Set(Object.keys(baseline.nodes).filter((id) => !canvas.nodes.has(id)));
    for (const n of next.nodes.filter((n) => goneNodes.has(n.id))) {
      report.push(`deleted node "${n.label}"`);
    }
    next.nodes = next.nodes.filter((n) => !goneNodes.has(n.id));

    const goneEdges = new Set(Object.keys(baseline.edges).filter((k) => !canvas.edges.has(k)));
    const keys = edgeKeys(next.edges);
    next.edges = next.edges.filter((e, i) => {
      if (!goneEdges.has(keys[i]) || goneNodes.has(e.from) || goneNodes.has(e.to)) {
        return true;
      }
      report.push(`deleted edge ${e.from} -> ${e.to}`);
      return false;
    });

    const goneGroups = new Set(Object.keys(baseline.groups).filter((id) => !canvas.groups.has(id)));
    for (const g of next.groups.filter((g) => goneGroups.has(g.id))) {
      report.push(`deleted group "${g.label}"`);
    }
    next.groups = next.groups.filter((g) => !goneGroups.has(g.id));

    for (const [id, el] of canvas.nodes) {
      const was = baseline.nodes[id];
      const node = next.nodes.find((n) => n.id === id);
      if (!was || !node) {
        continue;
      }
      const text = canvas.textOf.get(el.id);
      if (text && text !== was.label && text !== node.label) {
        report.push(`renamed node "${node.label}" -> "${text}"`);
        node.label = text;
      }
      if (SHAPES.includes(el.type) && el.type !== was.shape && el.type !== (node.shape ?? "rectangle")) {
        report.push(`changed "${node.label}" to ${el.type}`);
        node.shape = el.type === "rectangle" ? undefined : el.type;
      }
    }

    const keysNow = edgeKeys(next.edges);
    next.edges.forEach((edge, i) => {
      const was = baseline.edges[keysNow[i]];
      const el = canvas.edges.get(keysNow[i]);
      if (!was || !el) {
        return;
      }
      const text = canvas.textOf.get(el.id) ?? "";
      if (text !== was.label && text !== (edge.label ?? "")) {
        report.push(`relabeled edge ${edge.from} -> ${edge.to}: "${text}"`);
        edge.label = text || undefined;
      }
    });

    for (const [id, el] of canvas.groups) {
      const was = baseline.groups[id];
      const group = next.groups.find((g) => g.id === id);
      const text = canvas.textOf.get(el.id);
      if (was && group && text && text !== was.label && text !== group.label) {
        report.push(`renamed group "${group.label}" -> "${text}"`);
        group.label = text;
      }
    }
  }

  // Shapes and arrows drawn by hand become graph nodes and edges.
  const absorbed = new Set(baseline?.absorbed ?? []);
  const elementToNode = new Map([...canvas.nodes].map(([id, el]) => [el.id, id]));
  let unlabeled = 0;
  for (const el of canvas.live) {
    if (el.customData?.diagram || !SHAPES.includes(el.type)) {
      continue;
    }
    const text = canvas.textOf.get(el.id);
    if (!text) {
      unlabeled++;
      continue;
    }
    const id = kebab(text);
    elementToNode.set(el.id, id);
    if (absorbed.has(el.id)) {
      continue;
    }
    absorbed.add(el.id);
    if (!next.nodes.some((n) => n.id === id)) {
      next.nodes.push({ id, label: text, ...(el.type === "rectangle" ? {} : { shape: el.type }) });
      report.push(`added node "${text}" (drawn by hand)`);
    }
  }
  for (const el of canvas.live) {
    if (el.customData?.diagram || el.type !== "arrow" || absorbed.has(el.id)) {
      continue;
    }
    const from = elementToNode.get(el.startBinding?.elementId);
    const to = elementToNode.get(el.endBinding?.elementId);
    if (!from || !to || from === to) {
      continue;
    }
    absorbed.add(el.id);
    if (!next.edges.some((e) => e.from === from && e.to === to)) {
      const label = canvas.textOf.get(el.id);
      next.edges.push({ from, to, ...(label ? { label } : {}) });
      report.push(`added edge ${from} -> ${to} (drawn by hand)`);
    }
  }
  for (const el of canvas.live) {
    if (el.type === "text" && absorbed.has(el.containerId)) {
      absorbed.add(el.id);
    }
  }
  if (unlabeled > 0) {
    report.push(`left ${unlabeled} unlabeled shape(s) as-is, label them to turn them into nodes`);
  }

  const ids = new Set(next.nodes.map((n) => n.id));
  next.edges = next.edges.filter((e) => ids.has(e.from) && ids.has(e.to));
  for (const g of next.groups) {
    g.nodes = g.nodes.filter((id) => ids.has(id));
  }

  const nextBaseline = baseline ? { ...canvasBaseline(canvas, [...absorbed]), direction: baseline.direction } : null;
  return { graph: next, baseline: nextBaseline, report, absorbed };
}

function canvasBaseline(canvas, absorbed) {
  const nodes = {};
  for (const [id, el] of canvas.nodes) {
    nodes[id] = { label: canvas.textOf.get(el.id) ?? "", shape: el.type };
  }
  const edges = {};
  for (const [key, el] of canvas.edges) {
    edges[key] = { label: canvas.textOf.get(el.id) ?? "" };
  }
  const groups = {};
  for (const [id, el] of canvas.groups) {
    groups[id] = { label: canvas.textOf.get(el.id) ?? "" };
  }
  return { nodes, edges, groups, absorbed };
}
