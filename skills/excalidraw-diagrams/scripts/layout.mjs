// Graph -> Excalidraw elements. Palette and sizing adapted from
// YapDraw (https://github.com/rickytang666/yapdraw), MIT, Copyright (c) 2026 YapDraw.
import ELK from "elkjs/lib/elk.bundled.js";
import * as simpleIcons from "simple-icons";

export const SHAPES = ["rectangle", "diamond", "ellipse"];
export const STROKE_STYLES = ["solid", "dashed", "dotted"];
export const ARROWHEADS = ["arrow", "bar", "diamond", "dot", null];
export const DIRECTIONS = ["LR", "TB"];

// Excalidraw 0.18 font ids
const FONTS = {
  handwritten: { id: 5, lineHeight: 1.25, charWidth: 0.55 },
  normal: { id: 6, lineHeight: 1.35, charWidth: 0.52 },
  code: { id: 8, lineHeight: 1.25, charWidth: 0.6 },
};
export const FONT_NAMES = Object.keys(FONTS);

export const COLORS = {
  blue: { fill: "#a5d8ff", stroke: "#1971c2", zoneFill: "#dbe4ff", zoneStroke: "#4dabf7" },
  green: { fill: "#b2f2bb", stroke: "#2f9e44", zoneFill: "#d3f9d8", zoneStroke: "#69db7c" },
  purple: { fill: "#d0bfff", stroke: "#6741d9", zoneFill: "#e5dbff", zoneStroke: "#b197fc" },
  orange: { fill: "#ffd8a8", stroke: "#e67700", zoneFill: "#fff4e6", zoneStroke: "#ffa94d" },
  red: { fill: "#ffc9c9", stroke: "#c92a2a", zoneFill: "#fff5f5", zoneStroke: "#ff8787" },
  teal: { fill: "#c3fae8", stroke: "#0c8599", zoneFill: "#e6fcf5", zoneStroke: "#63e6be" },
  yellow: { fill: "#fff3bf", stroke: "#e67700", zoneFill: "#fff9db", zoneStroke: "#ffe066" },
  grey: { fill: "#f1f3f5", stroke: "#495057", zoneFill: "#f8f9fa", zoneStroke: "#ced4da" },
};

const SHAPE_SIZE = {
  rectangle: { w: 160, h: 70 },
  diamond: { w: 160, h: 100 },
  ellipse: { w: 140, h: 60 },
};
const NODE_FONT_SIZE = 15;
const EDGE_FONT_SIZE = 13;
const GROUP_FONT_SIZE = 14;
const GROUP_PADDING = 40;
const TEXT_PADDING = 5; // Excalidraw BOUND_TEXT_PADDING
const ICON_SIZE = 20;
const MAX_NODE_WIDTH = 260;
const EDGE_COLOR = "#495057";

const ICON_ALIASES = {
  k8s: "kubernetes",
  postgres: "postgresql",
  pg: "postgresql",
  mongo: "mongodb",
  kafka: "apachekafka",
  node: "nodedotjs",
  nodejs: "nodedotjs",
  vue: "vuedotjs",
  vuejs: "vuedotjs",
  next: "nextdotjs",
  nextjs: "nextdotjs",
  express: "express",
  rails: "rubyonrails",
  gcp: "googlecloud",
  gcs: "googlecloudstorage",
};

const iconsBySlug = new Map();
for (const icon of Object.values(simpleIcons)) {
  if (icon && typeof icon === "object" && "slug" in icon) {
    iconsBySlug.set(icon.slug, icon);
  }
}

export function resolveIcon(slug) {
  const s = String(slug).toLowerCase().trim();
  return iconsBySlug.get(ICON_ALIASES[s] ?? s) ?? null;
}

export function searchIcons(query) {
  const q = query.toLowerCase().replace(/[^a-z0-9]/g, "");
  const out = [];
  for (const icon of iconsBySlug.values()) {
    const title = icon.title.toLowerCase().replace(/[^a-z0-9]/g, "");
    if (icon.slug.includes(q) || title.includes(q)) {
      out.push(`${icon.slug}\t${icon.title}`);
    }
  }
  return out;
}

export function edgeKeys(edges) {
  const counts = new Map();
  return edges.map((e) => {
    const pair = `${e.from}>${e.to}`;
    const n = counts.get(pair) ?? 0;
    counts.set(pair, n + 1);
    return `${pair}#${n}`;
  });
}

function hash(str) {
  let h = 2166136261;
  for (let i = 0; i < str.length; i++) {
    h ^= str.charCodeAt(i);
    h = Math.imul(h, 16777619);
  }
  return h >>> 0;
}

function base(id, type, props, updated) {
  const seed = hash(id) || 1;
  return {
    id,
    type,
    x: 0,
    y: 0,
    width: 0,
    height: 0,
    angle: 0,
    strokeColor: "#1e1e1e",
    backgroundColor: "transparent",
    fillStyle: "solid",
    strokeWidth: 2,
    strokeStyle: "solid",
    roughness: 1,
    opacity: 100,
    groupIds: [],
    frameId: null,
    roundness: null,
    seed,
    version: 1,
    versionNonce: hash(`${id}:nonce`) || 1,
    isDeleted: false,
    boundElements: null,
    updated,
    link: null,
    locked: false,
    ...props,
  };
}

// Greedy word wrap with an average-glyph-width estimate. Excalidraw re-wraps
// bound text from originalText once fonts load, so this only needs to be close.
function wrapText(text, fontSize, font, maxWidth) {
  const charW = fontSize * font.charWidth;
  const maxChars = Math.max(1, Math.floor(maxWidth / charW));
  const lines = [];
  for (const para of String(text).split("\n")) {
    let line = "";
    for (const word of para.split(/\s+/).filter(Boolean)) {
      if (!line) {
        line = word;
        continue;
      }
      if ((line + " " + word).length <= maxChars) {
        line += " " + word;
        continue;
      }
      lines.push(line);
      line = word;
    }
    lines.push(line);
  }
  const width = Math.min(maxWidth, Math.max(...lines.map((l) => l.length)) * charW);
  const height = lines.length * fontSize * font.lineHeight;
  return { text: lines.join("\n"), width: Math.ceil(width), height: Math.ceil(height) };
}

// Usable text box inside a container, mirroring Excalidraw's getBoundTextMaxWidth/Height.
function textArea(shape, w, h) {
  if (shape === "ellipse") {
    return { w: Math.round((w / 2) * Math.SQRT2) - TEXT_PADDING * 2, h: Math.round((h / 2) * Math.SQRT2) - TEXT_PADDING * 2 };
  }
  if (shape === "diamond") {
    return { w: Math.round(w / 2) - TEXT_PADDING * 2, h: Math.round(h / 2) - TEXT_PADDING * 2 };
  }
  return { w: w - TEXT_PADDING * 2, h: h - TEXT_PADDING * 2 };
}

// Long labels widen the shape first, then grow it taller at the widest size.
function nodeSize(node) {
  const shape = node.shape ?? "rectangle";
  const font = FONTS[node.font ?? "handwritten"];
  const { w: minW, h } = SHAPE_SIZE[shape];
  let w = minW;
  let label;
  for (; w <= MAX_NODE_WIDTH; w += 20) {
    const area = textArea(shape, w, h);
    label = wrapText(node.label, NODE_FONT_SIZE, font, area.w);
    if (label.height <= area.h) {
      return { w, h, label };
    }
  }
  w -= 20;
  const scale = shape === "rectangle" ? 1 : shape === "ellipse" ? Math.SQRT2 : 2;
  return { w, h: Math.ceil(label.height * scale + TEXT_PADDING * 2 * scale), label };
}

// Point where the ray from the shape's center toward `toward` leaves its outline.
function clipToShape(box, toward) {
  const cx = box.x + box.w / 2;
  const cy = box.y + box.h / 2;
  const ux = toward.x - cx;
  const uy = toward.y - cy;
  if (ux === 0 && uy === 0) {
    return { x: cx, y: cy };
  }
  const rx = Math.abs(ux) / (box.w / 2);
  const ry = Math.abs(uy) / (box.h / 2);
  const d = box.shape === "ellipse" ? Math.hypot(rx, ry) : box.shape === "diamond" ? rx + ry : Math.max(rx, ry);
  return { x: cx + ux / d, y: cy + uy / d };
}

function insideShape(box, p) {
  const rx = Math.abs(p.x - (box.x + box.w / 2)) / (box.w / 2);
  const ry = Math.abs(p.y - (box.y + box.h / 2)) / (box.h / 2);
  return box.shape === "ellipse" ? rx * rx + ry * ry <= 1 : box.shape === "diamond" ? rx + ry <= 1 : rx <= 1 && ry <= 1;
}

// ELK attaches edges to the bounding box. For diamonds and ellipses, slide the
// endpoint inward along its own segment onto the outline so the route keeps its angle.
function attachToOutline(box, end, next) {
  if (box.shape === "rectangle") {
    return end;
  }
  const len = Math.hypot(end.x - next.x, end.y - next.y) || 1;
  const dx = (end.x - next.x) / len;
  const dy = (end.y - next.y) / len;
  const at = (t) => ({ x: end.x + dx * t, y: end.y + dy * t });
  const reach = box.w + box.h;
  let hi = 0;
  while (hi <= reach && !insideShape(box, at(hi))) {
    hi += 4;
  }
  if (hi > reach) {
    return clipToShape(box, next);
  }
  let lo = Math.max(0, hi - 4);
  for (let i = 0; i < 16; i++) {
    const mid = (lo + hi) / 2;
    if (insideShape(box, at(mid))) {
      hi = mid;
    } else {
      lo = mid;
    }
  }
  return at(hi);
}

function midpoint(points) {
  const n = points.length;
  if (n % 2 === 1) {
    return points[(n - 1) / 2];
  }
  const a = points[n / 2 - 1];
  const b = points[n / 2];
  return { x: (a.x + b.x) / 2, y: (a.y + b.y) / 2 };
}

function boundText(id, containerId, text, opts, updated) {
  return base(id, "text", {
    x: opts.x,
    y: opts.y,
    width: text.width,
    height: text.height,
    strokeColor: opts.color ?? "#1e1e1e",
    text: text.text,
    originalText: opts.original,
    fontSize: opts.fontSize,
    fontFamily: opts.font.id,
    textAlign: opts.textAlign ?? "center",
    verticalAlign: opts.verticalAlign ?? "middle",
    containerId,
    autoResize: true,
    lineHeight: opts.font.lineHeight,
    customData: { diagram: { kind: "label" } },
  }, updated);
}

function iconElement(id, fileId, x, y, groupIds, updated) {
  return base(id, "image", {
    x,
    y,
    width: ICON_SIZE,
    height: ICON_SIZE,
    strokeColor: "transparent",
    groupIds,
    fileId,
    status: "saved",
    scale: [1, 1],
    crop: null,
    customData: { diagram: { kind: "icon" } },
  }, updated);
}

function iconFile(icon, colorHex, updated) {
  const id = `simpleicon-${icon.slug}-${colorHex.slice(1)}`;
  const svg = icon.svg.replace("<svg ", `<svg width="24" height="24" fill="${colorHex}" `);
  return {
    id,
    mimeType: "image/svg+xml",
    dataURL: `data:image/svg+xml;base64,${Buffer.from(svg).toString("base64")}`,
    created: updated,
  };
}

const elk = new ELK();
const GROUP_PADDING_TOP = 44; // room for the zone label

async function computeLayout(graph, sizes, keys, edgeLabels) {
  const { nodes, edges = [], groups = [], direction = "LR" } = graph;
  // A node can only sit in one ELK container, so a node listed in two groups goes with the first.
  const parent = new Map();
  for (const group of groups) {
    for (const id of group.nodes) {
      if (!parent.has(id) && sizes.has(id)) {
        parent.set(id, group.id);
      }
    }
  }
  const leaf = (n) => ({ id: n.id, width: sizes.get(n.id).w, height: sizes.get(n.id).h });
  // Each zone goes where its first member sits in the node list, so model order
  // (used to break loops) matches the order the user described things in.
  const children = [];
  const placed = new Set();
  for (const n of nodes) {
    const groupId = parent.get(n.id);
    if (!groupId) {
      children.push(leaf(n));
      continue;
    }
    if (placed.has(groupId)) {
      continue;
    }
    placed.add(groupId);
    children.push({
      id: `cluster:${groupId}`,
      layoutOptions: { "elk.padding": `[top=${GROUP_PADDING_TOP},left=${GROUP_PADDING},bottom=${GROUP_PADDING},right=${GROUP_PADDING}]` },
      children: nodes.filter((m) => parent.get(m.id) === groupId).map(leaf),
    });
  }

  const result = await elk.layout({
    id: "root",
    layoutOptions: {
      "elk.algorithm": "layered",
      "elk.direction": direction === "TB" ? "DOWN" : "RIGHT",
      "elk.edgeRouting": "ORTHOGONAL",
      "elk.hierarchyHandling": "INCLUDE_CHILDREN",
      "elk.json.shapeCoords": "ROOT",
      "elk.json.edgeCoords": "ROOT",
      "elk.padding": "[top=60,left=60,bottom=60,right=60]",
      "elk.spacing.nodeNode": "50",
      "elk.layered.spacing.nodeNodeBetweenLayers": "90",
      "elk.spacing.edgeNode": "25",
      "elk.spacing.edgeEdge": "18",
      "elk.layered.spacing.edgeNodeBetweenLayers": "25",
      "elk.layered.nodePlacement.strategy": "NETWORK_SIMPLEX",
      // Follow the order nodes and edges are listed in, so a loop back to an earlier step is the edge that points backwards.
      "elk.layered.considerModelOrder.strategy": "NODES_AND_EDGES",
      "elk.layered.cycleBreaking.strategy": "MODEL_ORDER",
      "elk.edgeLabels.inline": "true",
    },
    children,
    edges: edges.map((e, i) => ({
      id: keys[i],
      sources: [e.from],
      targets: [e.to],
      labels: edgeLabels[i] ? [{ text: e.label, width: edgeLabels[i].width + 10, height: edgeLabels[i].height }] : [],
    })),
  });

  const boxes = new Map();
  const zones = new Map();
  const visit = (n) => {
    if (n.id.startsWith("cluster:")) {
      zones.set(n.id.slice("cluster:".length), { x: n.x, y: n.y, w: n.width, h: n.height });
    } else if (n.id !== "root") {
      const node = nodes.find((x) => x.id === n.id);
      boxes.set(n.id, { x: Math.round(n.x), y: Math.round(n.y), w: n.width, h: n.height, shape: node.shape ?? "rectangle" });
    }
    for (const c of n.children ?? []) {
      visit(c);
    }
  };
  visit(result);

  const routes = new Map();
  const labelCenters = new Map();
  for (const e of result.edges ?? []) {
    const l = e.labels?.[0];
    if (l?.x !== undefined) {
      labelCenters.set(e.id, { x: l.x + l.width / 2, y: l.y + l.height / 2 });
    }
    const pts = [];
    for (const sec of e.sections ?? []) {
      for (const p of [sec.startPoint, ...(sec.bendPoints ?? []), sec.endPoint]) {
        const last = pts.at(-1);
        if (!last || last.x !== p.x || last.y !== p.y) {
          pts.push({ x: p.x, y: p.y });
        }
      }
    }
    routes.set(e.id, pts);
  }
  return { boxes, zones, routes, labelCenters };
}

const overlaps = (a, b, margin) =>
  a.x < b.x + b.w + margin && b.x < a.x + a.w + margin && a.y < b.y + b.h + margin && b.y < a.y + a.h + margin;

// Elbow route between two boxes that were placed independently of each other.
function elbowRoute(from, to, direction) {
  const fc = { x: from.x + from.w / 2, y: from.y + from.h / 2 };
  const tc = { x: to.x + to.w / 2, y: to.y + to.h / 2 };
  if (direction === "TB" && to.y >= from.y + from.h + 20) {
    const midY = (from.y + from.h + to.y) / 2;
    return [{ x: fc.x, y: from.y + from.h }, { x: fc.x, y: midY }, { x: tc.x, y: midY }, { x: tc.x, y: to.y }];
  }
  if (direction !== "TB" && to.x >= from.x + from.w + 20) {
    const midX = (from.x + from.w + to.x) / 2;
    return [{ x: from.x + from.w, y: fc.y }, { x: midX, y: fc.y }, { x: midX, y: tc.y }, { x: to.x, y: tc.y }];
  }
  return [clipToShape(from, tc), clipToShape(to, fc)];
}

// Keeps everything already on the canvas where it is (including what the user
// dragged) and fits new nodes in next to the neighbours they connect to.
function keepPositions(graph, sizes, keys, fresh, previous) {
  const { nodes, edges = [], direction = "LR" } = graph;
  const boxes = new Map();
  const resized = new Set();
  const offsets = [];
  for (const node of nodes) {
    const prev = previous.nodes.get(node.id);
    if (!prev) {
      continue;
    }
    const shape = node.shape ?? "rectangle";
    const f = fresh.boxes.get(node.id);
    offsets.push({ id: node.id, dx: prev.x + prev.w / 2 - (f.x + f.w / 2), dy: prev.y + prev.h / 2 - (f.y + f.h / 2) });
    if (prev.label === node.label && prev.type === shape) {
      boxes.set(node.id, { x: prev.x, y: prev.y, w: prev.w, h: prev.h, shape });
      continue;
    }
    const { w, h } = sizes.get(node.id);
    boxes.set(node.id, { x: Math.round(prev.x + prev.w / 2 - w / 2), y: Math.round(prev.y + prev.h / 2 - h / 2), w, h, shape });
    resized.add(node.id);
  }

  const fallback = offsets.length > 0
    ? { dx: offsets.reduce((a, o) => a + o.dx, 0) / offsets.length, dy: offsets.reduce((a, o) => a + o.dy, 0) / offsets.length }
    : { dx: 0, dy: 0 };
  const neighbour = (id) => {
    for (const e of edges) {
      const other = e.from === id ? e.to : e.to === id ? e.from : null;
      const o = other && offsets.find((x) => x.id === other);
      if (o) {
        return o;
      }
    }
    return fallback;
  };
  // step sideways (across the flow) until the new node is clear of everything
  const step = direction === "TB" ? { x: 1, y: 0 } : { x: 0, y: 1 };
  for (const node of nodes) {
    if (boxes.has(node.id)) {
      continue;
    }
    const f = fresh.boxes.get(node.id);
    const { dx, dy } = neighbour(node.id);
    const origin = { ...f, x: Math.round(f.x + dx), y: Math.round(f.y + dy) };
    let box = origin;
    for (let i = 1; i <= 40 && [...boxes.values()].some((b) => overlaps(box, b, 30)); i++) {
      const dist = Math.ceil(i / 2) * (step.x ? f.w + 40 : f.h + 30) * (i % 2 ? 1 : -1);
      box = { ...origin, x: origin.x + step.x * dist, y: origin.y + step.y * dist };
    }
    boxes.set(node.id, box);
    resized.add(node.id);
  }

  // An arrow is only reused if both ends still sit on their boxes (a box moved
  // without its arrows following leaves them dangling).
  const touches = (b, p) => p.x >= b.x - 12 && p.x <= b.x + b.w + 12 && p.y >= b.y - 12 && p.y <= b.y + b.h + 12;
  const routes = new Map();
  const reused = new Set();
  edges.forEach((e, i) => {
    const prev = previous.edges.get(keys[i]);
    const pts = prev?.points.map(([px, py]) => ({ x: prev.x + px, y: prev.y + py }));
    if (pts && !resized.has(e.from) && !resized.has(e.to) && touches(boxes.get(e.from), pts[0]) && touches(boxes.get(e.to), pts.at(-1))) {
      routes.set(keys[i], pts);
      reused.add(keys[i]);
      return;
    }
    routes.set(keys[i], elbowRoute(boxes.get(e.from), boxes.get(e.to), direction));
  });
  return { boxes, zones: new Map(), routes, labelCenters: new Map(), reused };
}

// `previous` is the geometry already on the canvas ({ nodes, edges } maps keyed by
// node id and edge key). Without it, or with nothing in common, lay out from scratch.
export async function layoutGraph(graph, updated = Date.now(), previous = null) {
  const { nodes, edges = [], groups = [] } = graph;
  const sizes = new Map(nodes.map((n) => [n.id, nodeSize(n)]));
  const keys = edgeKeys(edges);
  const edgeFont = FONTS.handwritten;
  const edgeLabels = edges.map((e) => (e.label ? wrapText(e.label, EDGE_FONT_SIZE, edgeFont, 200) : null));
  const fresh = await computeLayout(graph, sizes, keys, edgeLabels);
  const incremental = previous && nodes.some((n) => previous.nodes.has(n.id));
  const { boxes, zones: clusterBoxes, routes, labelCenters, reused = new Set() } = incremental
    ? keepPositions(graph, sizes, keys, fresh, previous)
    : fresh;

  const elements = [];
  const files = new Map();
  const bound = new Map(); // container element id -> boundElements[]
  const addBound = (containerId, ref) => {
    const list = bound.get(containerId) ?? [];
    list.push(ref);
    bound.set(containerId, list);
  };

  // Zones first so they render behind nodes; larger zones behind smaller ones.
  const zones = groups
    .map((group) => {
      const cluster = clusterBoxes.get(group.id);
      if (cluster) {
        return { group, ...cluster };
      }
      const members = group.nodes.map((id) => boxes.get(id)).filter(Boolean);
      if (members.length === 0) {
        return null;
      }
      const x = Math.min(...members.map((b) => b.x)) - GROUP_PADDING;
      const y = Math.min(...members.map((b) => b.y)) - GROUP_PADDING_TOP;
      const w = Math.max(...members.map((b) => b.x + b.w)) + GROUP_PADDING - x;
      const h = Math.max(...members.map((b) => b.y + b.h)) + GROUP_PADDING - y;
      return { group, x, y, w, h };
    })
    .filter(Boolean)
    .sort((a, b) => b.w * b.h - a.w * a.h);

  for (const { group, x, y, w, h } of zones) {
    const c = COLORS[group.color ?? "grey"];
    const id = `group-${group.id}`;
    const textId = `${id}-text`;
    elements.push(base(id, "rectangle", {
      x,
      y,
      width: w,
      height: h,
      strokeColor: c.zoneStroke,
      backgroundColor: c.zoneFill,
      strokeWidth: 1,
      customData: { diagram: { kind: "group", id: group.id } },
    }, updated));
    addBound(id, { id: textId, type: "text" });
    const label = wrapText(group.label, GROUP_FONT_SIZE, FONTS.handwritten, w - TEXT_PADDING * 2);
    elements.push(boundText(textId, id, label, {
      x: x + TEXT_PADDING,
      y: y + TEXT_PADDING,
      original: group.label,
      fontSize: GROUP_FONT_SIZE,
      font: FONTS.handwritten,
      textAlign: "left",
      verticalAlign: "top",
    }, updated));

    const icon = group.icon ? resolveIcon(group.icon) : null;
    if (icon) {
      const file = iconFile(icon, c.zoneStroke, updated);
      files.set(file.id, file);
      elements.push(iconElement(`icon-${id}`, file.id, x + 8, y + h - ICON_SIZE - 8, [], updated));
    }
  }

  for (const node of nodes) {
    const box = boxes.get(node.id);
    const { label } = sizes.get(node.id);
    const c = COLORS[node.color ?? "grey"];
    const font = FONTS[node.font ?? "handwritten"];
    const id = `node-${node.id}`;
    const textId = `${id}-text`;
    const icon = node.icon ? resolveIcon(node.icon) : null;
    // icon + shape + label move together when dragged
    const groupIds = icon ? [`${id}-grp`] : [];

    elements.push(base(id, box.shape, {
      x: box.x,
      y: box.y,
      width: box.w,
      height: box.h,
      strokeColor: c.stroke,
      backgroundColor: c.fill,
      strokeStyle: node.strokeStyle ?? "solid",
      roundness: box.shape === "rectangle" ? { type: 3 } : { type: 2 },
      groupIds,
      customData: { diagram: { kind: "node", id: node.id } },
    }, updated));
    addBound(id, { id: textId, type: "text" });
    elements.push({
      ...boundText(textId, id, label, {
        x: Math.round(box.x + (box.w - label.width) / 2),
        y: Math.round(box.y + (box.h - label.height) / 2),
        original: node.label,
        fontSize: NODE_FONT_SIZE,
        font,
      }, updated),
      groupIds,
    });

    if (icon) {
      const file = iconFile(icon, c.stroke, updated);
      files.set(file.id, file);
      const ix = box.shape === "rectangle" ? box.x + 8 : Math.round(box.x + box.w / 2 - ICON_SIZE / 2);
      const iy = box.shape === "rectangle" ? box.y + 8 : box.y + 6;
      elements.push(iconElement(`icon-${id}`, file.id, ix, iy, groupIds, updated));
    }
  }

  edges.forEach((edge, i) => {
    const key = keys[i];
    const pts = (routes.get(key) ?? []).map((p) => ({ ...p }));
    if (pts.length < 2) {
      return;
    }
    if (!reused.has(key)) {
      pts[0] = attachToOutline(boxes.get(edge.from), pts[0], pts[1]);
      pts[pts.length - 1] = attachToOutline(boxes.get(edge.to), pts.at(-1), pts.at(-2));
    }

    const start = pts[0];
    const points = pts.map((p) => [Math.round(p.x - start.x) + 0, Math.round(p.y - start.y) + 0]); // + 0 turns -0 into 0
    const xs = points.map((p) => p[0]);
    const ys = points.map((p) => p[1]);
    const id = `edge-${key}`;
    const fromId = `node-${edge.from}`;
    const toId = `node-${edge.to}`;

    const arrow = base(id, "arrow", {
      x: Math.round(start.x),
      y: Math.round(start.y),
      width: Math.max(...xs) - Math.min(...xs),
      height: Math.max(...ys) - Math.min(...ys),
      strokeColor: EDGE_COLOR,
      strokeStyle: edge.strokeStyle ?? "solid",
      roundness: null,
      points,
      lastCommittedPoint: null,
      startBinding: { elementId: fromId, focus: 0, gap: 1, fixedPoint: null },
      endBinding: { elementId: toId, focus: 0, gap: 1, fixedPoint: null },
      startArrowhead: null,
      endArrowhead: edge.endArrowhead === undefined ? "arrow" : edge.endArrowhead,
      elbowed: false,
      customData: { diagram: { kind: "edge", key, from: edge.from, to: edge.to } },
    }, updated);
    elements.push(arrow);
    addBound(fromId, { id, type: "arrow" });
    addBound(toId, { id, type: "arrow" });

    if (edge.label) {
      const textId = `${id}-text`;
      const label = edgeLabels[i];
      // ELK reserved this spot; Excalidraw re-centers the label if the arrow is edited
      const mid = labelCenters.get(key) ?? midpoint(pts);
      addBound(id, { id: textId, type: "text" });
      elements.push(boundText(textId, id, label, {
        x: Math.round(mid.x - label.width / 2),
        y: Math.round(mid.y - label.height / 2),
        original: edge.label,
        fontSize: EDGE_FONT_SIZE,
        font: edgeFont,
        color: EDGE_COLOR,
      }, updated));
    }
  });

  for (const el of elements) {
    const refs = bound.get(el.id);
    if (refs) {
      el.boundElements = refs;
    }
  }

  return { elements, files: [...files.values()] };
}
