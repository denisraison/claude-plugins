#!/usr/bin/env bash
# Deterministically gather the layered QA.md corpus for qa-scenarios.
# Walks UP from a start dir collecting every QA.md, so a repo-level file and a
# workspace-level file are both included. Stops at $HOME or the filesystem root.
# Does NOT stop at .git — repos nest inside workspaces, so .git is not the boundary.
#
# Optional: set QA_WORKSPACE_MARKER to a filename (e.g. a multi-repo manifest) to
# stop the walk once a directory containing that marker has been collected. Leave
# unset for the default $HOME/root bound, which suits most layouts.
#
# Usage: gather-qa.sh [start-dir]   (default: current directory)
# Prints each QA.md labelled by path, nearest (most specific) first.
set -euo pipefail

marker="${QA_WORKSPACE_MARKER:-}"
dir="$(cd "${1:-.}" && pwd)"
files=()
while :; do
  [ -f "$dir/QA.md" ] && files+=("$dir/QA.md")
  # optional workspace boundary: collect this level, then stop
  [ -n "$marker" ] && [ -e "$dir/$marker" ] && break
  parent="$(dirname "$dir")"
  [ "$parent" = "$dir" ] && break          # filesystem root
  [ "$dir" = "$HOME" ] && break            # don't climb above home
  dir="$parent"
done

if [ "${#files[@]}" -eq 0 ]; then
  echo "NO_QA_FILES_FOUND"
  echo "(bootstrap mode: no QA.md found from start dir up to the workspace root)"
  exit 0
fi

echo "Found ${#files[@]} QA.md file(s), nearest first. The LAST one (highest in the tree) is the workspace/product corpus; nearer ones are repo-local."
echo
for f in "${files[@]}"; do
  echo "===== QA corpus: $f ====="
  cat "$f"
  echo
done
