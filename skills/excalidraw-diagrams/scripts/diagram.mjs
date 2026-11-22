import { execFile, spawn } from "node:child_process";
import { existsSync, mkdtempSync, readFileSync, rmSync, statSync, writeFileSync } from "node:fs";
import { createServer } from "node:http";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { baselineFromGraph, canvasGeometry, syncFromCanvas, validateGraph } from "./graph.mjs";
import { layoutGraph, searchIcons } from "./layout.mjs";

const USAGE = `usage: diagram.sh <command> <name>[.graph.json|.excalidraw]

  render <name> [--relayout]
                  fold canvas edits into <name>.graph.json, lay it out, write <name>.excalidraw.
                  Shapes already on the canvas stay where they are; --relayout lays everything out fresh
  sync <name>     fold canvas edits into <name>.graph.json without rendering
  open <name>     edit <name>.excalidraw in a local browser tab that reloads after each render
  preview <name>  write <name>.png, the diagram as Excalidraw exports it
  icons <query>   search icon slugs`;

function fail(msg) {
  console.error(msg);
  process.exit(1);
}

function paths(arg) {
  const stem = arg.replace(/\.graph\.json$|\.excalidraw$|\.json$/, "");
  return { graphPath: `${stem}.graph.json`, canvasPath: `${stem}.excalidraw` };
}

function readJson(path) {
  try {
    return JSON.parse(readFileSync(path, "utf8"));
  } catch (err) {
    fail(`could not read ${path}: ${err.message}`);
  }
}

function writeGraph(path, graph, baseline) {
  const { direction, nodes, edges, groups } = graph;
  const out = { direction, nodes, edges, groups, _canvas: baseline ?? undefined };
  writeFileSync(path, JSON.stringify(out, null, 2) + "\n");
}

function printReport(report) {
  for (const line of report) {
    console.log(`canvas: ${line}`);
  }
}

async function render(arg, relayout) {
  const { graphPath, canvasPath } = paths(arg);
  const doc = readJson(graphPath);
  const existing = existsSync(canvasPath) ? readJson(canvasPath) : null;

  let graph = doc;
  let absorbed = new Set();
  if (existing) {
    const synced = syncFromCanvas(doc, existing.elements ?? []);
    graph = synced.graph;
    absorbed = synced.absorbed;
    printReport(synced.report);
  }

  const { errors, warnings } = validateGraph(graph);
  for (const w of warnings) {
    console.log(`warning: ${w}`);
  }
  if (errors.length > 0) {
    fail(`not rendered, fix ${graphPath}:\n${errors.map((e) => `  - ${e}`).join("\n")}`);
  }

  // Keep what's on the canvas in place unless asked to tidy up or the flow direction changed.
  const sameDirection = (doc._canvas?.direction ?? "LR") === (graph.direction ?? "LR");
  const previous = existing && !relayout && sameDirection ? canvasGeometry(existing.elements ?? []) : null;
  const { elements, files } = await layoutGraph(graph, Date.now(), previous);
  const managedIds = new Set(elements.map((el) => el.id));

  // Keep anything drawn by hand that wasn't turned into a node or edge.
  const foreign = (existing?.elements ?? []).filter(
    (el) => !el.isDeleted && !el.customData?.diagram && !absorbed.has(el.id) && !managedIds.has(el.containerId),
  );
  const outIds = new Set([...managedIds, ...foreign.map((el) => el.id)]);
  const byId = new Map(elements.map((el) => [el.id, el]));
  for (const el of foreign) {
    for (const side of ["startBinding", "endBinding"]) {
      const target = el[side]?.elementId;
      if (!target) {
        continue;
      }
      if (!outIds.has(target)) {
        el[side] = null;
        continue;
      }
      const node = byId.get(target);
      if (node) {
        node.boundElements = [...(node.boundElements ?? []), { id: el.id, type: "arrow" }];
      }
    }
  }

  const fileMap = Object.fromEntries(files.map((f) => [f.id, f]));
  for (const el of foreign) {
    const file = el.type === "image" ? existing.files?.[el.fileId] : null;
    if (file) {
      fileMap[el.fileId] = file;
    }
  }

  const scene = {
    type: "excalidraw",
    version: 2,
    source: "excalidraw-diagrams",
    elements: [...elements, ...foreign],
    appState: { viewBackgroundColor: "#ffffff", ...existing?.appState },
    files: fileMap,
  };
  writeFileSync(canvasPath, JSON.stringify(scene, null, 2) + "\n");
  writeGraph(graphPath, graph, baselineFromGraph(graph));

  const kept = foreign.length > 0 ? `, kept ${foreign.length} hand-drawn element(s)` : "";
  console.log(`wrote ${canvasPath} (${graph.nodes.length} nodes, ${(graph.edges ?? []).length} edges${kept})`);
}

function sync(arg) {
  const { graphPath, canvasPath } = paths(arg);
  const doc = readJson(graphPath);
  if (!existsSync(canvasPath)) {
    console.log(`no ${canvasPath} yet, nothing to sync`);
    return;
  }
  const { graph, baseline, report } = syncFromCanvas(doc, readJson(canvasPath).elements ?? []);
  if (report.length === 0) {
    console.log("canvas: no changes since last render");
    return;
  }
  printReport(report);
  writeGraph(graphPath, graph, baseline ?? doc._canvas);
}

function serve(canvasPath, port, onListen, onPng) {
  const pages = {
    "/": readFileSync(new URL("./viewer.html", import.meta.url)),
    "/preview": readFileSync(new URL("./preview.html", import.meta.url)),
  };
  const mtime = () => String(statSync(canvasPath).mtimeMs);
  const server = createServer((req, res) => {
    if (req.method === "GET" && pages[req.url]) {
      res.writeHead(200, { "content-type": "text/html" }).end(pages[req.url]);
      return;
    }
    if (req.method === "GET" && req.url === "/mtime") {
      res.writeHead(200, { "content-type": "text/plain" }).end(mtime());
      return;
    }
    if (req.method === "GET" && req.url === "/scene") {
      res.writeHead(200, { "content-type": "application/json", "x-mtime": mtime() }).end(readFileSync(canvasPath));
      return;
    }
    if (req.method === "PUT" && req.url === "/png" && onPng) {
      const chunks = [];
      req.on("data", (c) => chunks.push(c));
      req.on("end", () => {
        res.writeHead(204).end();
        onPng(Buffer.concat(chunks), req.headers["x-error"]);
      });
      return;
    }
    if (req.method === "PUT" && req.url === "/scene") {
      const chunks = [];
      req.on("data", (c) => chunks.push(c));
      req.on("end", () => {
        writeFileSync(canvasPath, Buffer.concat(chunks));
        res.writeHead(204, { "x-mtime": mtime() }).end();
      });
      return;
    }
    res.writeHead(404).end();
  });
  server.listen(port, "127.0.0.1", () => onListen(`http://127.0.0.1:${server.address().port}`, server));
}

function requireCanvas(arg) {
  const { canvasPath } = paths(arg);
  if (!existsSync(canvasPath)) {
    fail(`no ${canvasPath} yet, render it first`);
  }
  return canvasPath;
}

function open(arg) {
  const canvasPath = requireCanvas(arg);
  serve(canvasPath, Number(process.env.PORT ?? 0), (base) => {
    console.log(`editing ${canvasPath} at ${base}/ (ctrl-c to stop)`);
    if (process.env.BROWSER !== "none") {
      execFile("open", [`${base}/`]);
    }
  });
}

const CHROME = process.env.CHROME ?? "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";

// The page renders with Excalidraw's own exportToBlob in headless Chrome, so the
// PNG is exactly what Excalidraw's export gives, then posts it back here.
function preview(arg) {
  const canvasPath = requireCanvas(arg);
  if (!existsSync(CHROME)) {
    fail(`Chrome not found at ${CHROME}, set CHROME to a Chrome or Chromium binary`);
  }
  const pngPath = canvasPath.replace(/\.excalidraw$/, ".png");
  const profile = mkdtempSync(join(tmpdir(), "excalidraw-preview-"));
  let chrome = null;
  let timer = null;
  const finish = (server, msg, ok) => {
    clearTimeout(timer);
    server.close();
    server.closeAllConnections();
    (ok ? console.log : console.error)(msg);
    // Chrome keeps writing to its profile until it has fully exited
    chrome.once("exit", () => {
      try {
        rmSync(profile, { recursive: true, force: true, maxRetries: 10, retryDelay: 100 });
      } catch {
        // a helper process still holds it; it's in the OS temp dir, so leave it
      }
      process.exit(ok ? 0 : 1);
    });
    chrome.kill();
  };
  let srv = null;
  serve(canvasPath, 0, (base, server) => {
    srv = server;
    chrome = spawn(CHROME, ["--headless=new", "--disable-gpu", "--no-first-run", `--user-data-dir=${profile}`, `${base}/preview`], { stdio: "ignore" });
    timer = setTimeout(() => finish(server, "preview failed: timed out after 60s (the page needs internet for esm.sh)", false), 60000);
  }, (png, error) => {
    if (error || png.length === 0) {
      finish(srv, `preview failed: ${error ?? "empty image"}`, false);
      return;
    }
    writeFileSync(pngPath, png);
    finish(srv, `wrote ${pngPath}`, true);
  });
}

const [command, arg, ...flags] = process.argv.slice(2);
if (!command || !arg) {
  fail(USAGE);
}
if (command === "render") {
  await render(arg, flags.includes("--relayout"));
} else if (command === "sync") {
  sync(arg);
} else if (command === "open") {
  open(arg);
} else if (command === "preview") {
  preview(arg);
} else if (command === "icons") {
  const matches = searchIcons(arg);
  console.log(matches.length > 0 ? matches.slice(0, 20).join("\n") : `no icons match "${arg}"`);
} else {
  fail(USAGE);
}
