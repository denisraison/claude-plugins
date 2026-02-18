#!/usr/bin/env bash
set -euo pipefail

DIR=""
PORT=8420

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dir)  DIR="$2"; shift 2 ;;
        --port) PORT="$2"; shift 2 ;;
        *)      echo "Usage: $0 --dir <path> [--port <N>]"; exit 1 ;;
    esac
done

if [[ -z "$DIR" ]]; then
    echo "Error: --dir is required"
    echo "Usage: $0 --dir ./logo-output [--port $PORT]"
    exit 1
fi

DIR="$(cd "$DIR" && pwd)"

if [[ ! -d "$DIR" ]]; then
    echo "Error: directory does not exist: $DIR"
    exit 1
fi

# Kill existing process on the port
PID=$(ss -tlnp "sport = :$PORT" 2>/dev/null | grep -oP 'pid=\K[0-9]+' | head -1) || true
if [[ -n "$PID" ]]; then
    kill "$PID" 2>/dev/null && sleep 1
    echo "Killed existing process on port $PORT (pid $PID)"
fi

# Detect mode: brand dir (has stage* subdirs) vs project index
MODE=single
if ! ls -d "$DIR"/stage* &>/dev/null; then
    MODE=multi
fi

echo "Mode: $MODE"
echo "Serving gallery for: $DIR"
echo "Open http://0.0.0.0:$PORT"

python3 - "$DIR" "$PORT" "$MODE" << 'PYTHON_EOF'
import http.server
import json
import sys
from pathlib import Path
from urllib.parse import unquote

ROOT = Path(sys.argv[1])
PORT = int(sys.argv[2])
MODE = sys.argv[3]

STAGES = ["stage1-flash", "stage2-refined", "stage3-final", "stage4-brand-kit", "stage5-mockups"]
IMG_EXTS = {".png", ".jpg", ".jpeg", ".webp", ".svg"}
CONTENT_TYPES = {
    ".png": "image/png", ".jpg": "image/jpeg",
    ".jpeg": "image/jpeg", ".webp": "image/webp",
    ".svg": "image/svg+xml",
}


def get_images(brand_dir):
    data = {}
    for stage in STAGES:
        stage_dir = brand_dir / stage
        if not stage_dir.is_dir():
            data[stage] = []
            continue
        images = []
        for f in sorted(stage_dir.iterdir()):
            if f.suffix.lower() in IMG_EXTS:
                images.append({"name": f.name, "size": f.stat().st_size})
        data[stage] = images
    return data


def get_brands():
    brands = []
    for d in sorted(ROOT.iterdir()):
        if not d.is_dir() or d.name.startswith("."):
            continue
        thumb_url = None
        total = 0
        for stage in reversed(STAGES):
            stage_dir = d / stage
            if not stage_dir.is_dir():
                continue
            for f in sorted(stage_dir.iterdir()):
                if f.suffix.lower() in IMG_EXTS:
                    total += 1
                    if not thumb_url:
                        thumb_url = f"/{d.name}/images/{stage}/{f.name}"
        brands.append({
            "name": d.name,
            "thumbnail": thumb_url,
            "image_count": total,
        })
    return brands


INDEX_HTML = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Logo Projects</title>
<style>
* { margin: 0; padding: 0; box-sizing: border-box; }
body { background: #111; color: #ccc; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, monospace; }
header { padding: 16px 24px; border-bottom: 1px solid #333; }
header h1 { font-size: 18px; color: #fff; font-weight: 500; }
main { padding: 24px; }
.grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(260px, 1fr)); gap: 20px; }
.card { background: #1a1a1a; border: 1px solid #282828; border-radius: 8px; overflow: hidden; transition: border-color 0.15s; text-decoration: none; color: inherit; display: block; }
.card:hover { border-color: #4a9; }
.card .thumb { width: 100%; height: 200px; object-fit: contain; background: #222; display: block; }
.card .no-thumb { width: 100%; height: 200px; background: #222; display: flex; align-items: center; justify-content: center; color: #444; font-size: 14px; }
.card .info { padding: 14px 16px; }
.card .name { font-size: 16px; color: #fff; font-weight: 500; }
.card .meta { font-size: 12px; color: #666; margin-top: 4px; }
</style>
</head>
<body>
<header><h1>Logo Projects</h1></header>
<main><div class="grid" id="grid"></div></main>
<script>
async function load() {
    const brands = await (await fetch("/api/brands")).json();
    document.getElementById("grid").innerHTML = brands.map(b =>
        `<a class="card" href="/${b.name}/">
            ${b.thumbnail
                ? `<img class="thumb" src="${b.thumbnail}" loading="lazy" alt="${b.name}">`
                : `<div class="no-thumb">No images yet</div>`}
            <div class="info">
                <div class="name">${b.name}</div>
                <div class="meta">${b.image_count} image${b.image_count !== 1 ? "s" : ""}</div>
            </div>
        </a>`
    ).join("");
}
load();
</script>
</body>
</html>"""

GALLERY_HTML = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>__BRAND_NAME__ Gallery</title>
<style>
* { margin: 0; padding: 0; box-sizing: border-box; }
body { background: #111; color: #ccc; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, monospace; }
header { padding: 16px 24px; border-bottom: 1px solid #333; display: flex; align-items: center; justify-content: space-between; }
header h1 { font-size: 18px; color: #fff; font-weight: 500; }
.back { color: #4a9; text-decoration: none; font-size: 13px; margin-right: 16px; }
.back:hover { color: #5cb; }
#status { font-size: 12px; color: #666; }
#status.active { color: #4a9; }
.tabs { display: flex; gap: 4px; padding: 12px 24px; border-bottom: 1px solid #222; }
.tab { padding: 8px 16px; background: #1a1a1a; border: 1px solid #333; border-radius: 6px; cursor: pointer; color: #888; font-size: 13px; transition: all 0.15s; }
.tab:hover { color: #ccc; border-color: #555; }
.tab.active { color: #fff; background: #252525; border-color: #4a9; }
.tab .count { margin-left: 6px; color: #666; font-size: 11px; }
.tab.active .count { color: #4a9; }
main { padding: 24px; }
.grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(220px, 1fr)); gap: 16px; }
.card { background: #1a1a1a; border: 1px solid #282828; border-radius: 8px; overflow: hidden; cursor: pointer; transition: border-color 0.15s; }
.card:hover { border-color: #4a9; }
.card img { width: 100%; min-height: 140px; max-height: 280px; object-fit: contain; background: #222; display: block; }
.card .info { padding: 10px 12px; }
.card .name { font-size: 12px; color: #aaa; word-break: break-all; }
.card .size { font-size: 11px; color: #555; margin-top: 2px; }
.empty { color: #444; font-size: 14px; padding: 48px 0; text-align: center; }
#lightbox { display: none; position: fixed; inset: 0; background: rgba(0,0,0,0.92); z-index: 100; cursor: pointer; align-items: center; justify-content: center; }
#lightbox.open { display: flex; }
#lightbox img { max-width: 90vw; max-height: 90vh; object-fit: contain; border-radius: 4px; }
#lightbox .caption { position: fixed; bottom: 24px; left: 50%; transform: translateX(-50%); color: #888; font-size: 13px; }
</style>
</head>
<body>
<header>
    <div style="display:flex;align-items:center">__BACK_LINK__<h1>__BRAND_NAME__</h1></div>
    <span id="status">connecting...</span>
</header>
<div class="tabs" id="tabs"></div>
<main id="main"></main>
<div id="lightbox" onclick="this.classList.remove('open')">
    <img id="lb-img" src="">
    <div class="caption" id="lb-caption"></div>
</div>
<script>
const BASE = "__BASE_URL__";
const STAGES = ["stage1-flash", "stage2-refined", "stage3-final", "stage4-brand-kit", "stage5-mockups"];
const LABELS = { "stage1-flash": "Flash", "stage2-refined": "Refined", "stage3-final": "Final", "stage4-brand-kit": "Brand Kit", "stage5-mockups": "Mockups" };
let currentStage = STAGES[0];
let cache = {};

function formatSize(bytes) {
    if (bytes < 1024) return bytes + " B";
    if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + " KB";
    return (bytes / (1024 * 1024)).toFixed(1) + " MB";
}

function renderTabs(data) {
    const tabs = document.getElementById("tabs");
    tabs.innerHTML = STAGES.map(s => {
        const n = (data[s] || []).length;
        return `<div class="tab ${s === currentStage ? "active" : ""}" data-stage="${s}">${LABELS[s]}<span class="count">${n}</span></div>`;
    }).join("");
    tabs.querySelectorAll(".tab").forEach(t => {
        t.onclick = () => { currentStage = t.dataset.stage; render(cache); };
    });
}

function renderStage(stage, images) {
    if (!images || images.length === 0) return `<div class="empty">No images yet</div>`;
    return `<div class="grid">${images.map(img =>
        `<div class="card" onclick="openLightbox('${BASE}/images/${stage}/${img.name}', '${img.name}')">
            <img src="${BASE}/images/${stage}/${img.name}" loading="lazy" alt="${img.name}">
            <div class="info"><div class="name">${img.name}</div><div class="size">${formatSize(img.size)}</div></div>
        </div>`
    ).join("")}</div>`;
}

function render(data) {
    cache = data;
    renderTabs(data);
    document.getElementById("main").innerHTML = renderStage(currentStage, data[currentStage] || []);
}

function openLightbox(src, name) {
    document.getElementById("lb-img").src = src;
    document.getElementById("lb-caption").textContent = name;
    document.getElementById("lightbox").classList.add("open");
}

async function poll() {
    const status = document.getElementById("status");
    try {
        const data = await (await fetch(BASE + "/api/images")).json();
        render(data);
        status.textContent = "live";
        status.className = "active";
    } catch {
        status.textContent = "disconnected";
        status.className = "";
    }
}

document.addEventListener("keydown", e => {
    if (e.key === "Escape") document.getElementById("lightbox").classList.remove("open");
});

poll();
setInterval(poll, 3000);
</script>
</body>
</html>"""


def gallery_html(brand_name, base_url="", back_link=""):
    return GALLERY_HTML.replace("__BASE_URL__", base_url) \
                       .replace("__BACK_LINK__", back_link) \
                       .replace("__BRAND_NAME__", brand_name)


class Handler(http.server.BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        pass

    def do_GET(self):
        path = unquote(self.path)

        if MODE == "multi":
            self.handle_multi(path)
        else:
            self.handle_single(path)

    def handle_multi(self, path):
        if path == "/" or path == "/index.html":
            self.respond(200, "text/html", INDEX_HTML.encode())
            return

        if path == "/api/brands":
            self.respond(200, "application/json", json.dumps(get_brands()).encode())
            return

        parts = path.strip("/").split("/", 1)
        brand = parts[0]
        rest = "/" + parts[1] if len(parts) > 1 else "/"
        brand_dir = ROOT / brand

        if not brand_dir.is_dir() or brand_dir.name.startswith("."):
            self.respond(404, "text/plain", b"not found")
            return

        if rest == "/" or rest == "/index.html":
            back = '<a class="back" href="/">&larr; Projects</a>'
            self.respond(200, "text/html", gallery_html(brand, f"/{brand}", back).encode())
            return

        if rest == "/api/images":
            self.respond(200, "application/json", json.dumps(get_images(brand_dir)).encode())
            return

        if rest.startswith("/images/"):
            self.serve_image(brand_dir, rest[len("/images/"):])
            return

        self.respond(404, "text/plain", b"not found")

    def handle_single(self, path):
        if path == "/" or path == "/index.html":
            self.respond(200, "text/html", gallery_html(ROOT.name).encode())
            return

        if path == "/api/images":
            self.respond(200, "application/json", json.dumps(get_images(ROOT)).encode())
            return

        if path.startswith("/images/"):
            self.serve_image(ROOT, path[len("/images/"):])
            return

        self.respond(404, "text/plain", b"not found")

    def serve_image(self, base, subpath):
        parts = subpath.split("/", 1)
        if len(parts) != 2:
            self.respond(404, "text/plain", b"not found")
            return
        stage, filename = parts
        filepath = base / stage / filename
        if filepath.is_file() and base in filepath.resolve().parents:
            ct = CONTENT_TYPES.get(filepath.suffix.lower(), "application/octet-stream")
            self.respond(200, ct, filepath.read_bytes())
            return
        self.respond(404, "text/plain", b"not found")

    def respond(self, code, content_type, body):
        self.send_response(code)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        if content_type == "application/json":
            self.send_header("Cache-Control", "no-cache")
        self.end_headers()
        self.wfile.write(body)


print(f"Gallery server running on http://0.0.0.0:{PORT}")
print(f"Serving images from: {ROOT}")
print(f"Mode: {MODE}")
print("Press Ctrl+C to stop")
http.server.HTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
PYTHON_EOF
