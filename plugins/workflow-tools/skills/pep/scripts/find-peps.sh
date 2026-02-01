#!/bin/bash
# Find PEP documents in the current project

case "$1" in
  "list")
    find . -path "*/docs/*" -name "PEP-*.md" 2>/dev/null | sort
    ;;
  "next")
    # Find highest PEP number and suggest next
    highest=$(find . -path "*/docs/*" -name "PEP-*.md" 2>/dev/null | \
      grep -oE 'PEP-[0-9]+' | grep -oE '[0-9]+' | sort -n | tail -1)
    if [ -z "$highest" ]; then
      echo "001"
    else
      printf "%03d" $((highest + 1))
    fi
    ;;
  *)
    echo "Usage: find-peps.sh [list|next]"
    ;;
esac
