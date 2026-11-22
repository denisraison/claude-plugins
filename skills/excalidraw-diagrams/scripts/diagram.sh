#!/usr/bin/env bash
set -euo pipefail
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ ! -d "$dir/node_modules/elkjs" ] || [ ! -d "$dir/node_modules/simple-icons" ]; then
  npm install --prefix "$dir" --silent --no-audit --no-fund >&2
fi
exec node "$dir/diagram.mjs" "$@"
