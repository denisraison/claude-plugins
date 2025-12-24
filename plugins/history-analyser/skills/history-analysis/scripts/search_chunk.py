#!/usr/bin/env python3
"""
Search within JSONL files for a pattern.

Usage:
    search_chunk.py --query "pattern" --files file1.jsonl,file2.jsonl
    search_chunk.py --query "pattern" --files file1.jsonl --start-ts MS --end-ts MS

Output: JSON with matching messages and context
"""

import json
import re
import sys
from pathlib import Path
from datetime import datetime


def extract_content(entry: dict) -> str:
    """Extract all searchable text from an entry."""
    texts = []

    if "display" in entry:
        texts.append(entry["display"])

    message = entry.get("message", {})
    content = message.get("content", [])

    if isinstance(content, str):
        texts.append(content)
    elif isinstance(content, list):
        for item in content:
            if isinstance(item, dict):
                if item.get("type") == "text":
                    texts.append(item.get("text", ""))
                elif item.get("type") == "tool_use":
                    texts.append(f"[tool: {item.get('name', '')}]")
                    if "input" in item:
                        texts.append(str(item["input"]))
                elif item.get("type") == "tool_result":
                    result = item.get("content", "")
                    if isinstance(result, str):
                        texts.append(result[:500])

    return "\n".join(texts)


def parse_timestamp(ts) -> int:
    """Convert various timestamp formats to Unix ms."""
    if isinstance(ts, (int, float)):
        return int(ts)
    if isinstance(ts, str):
        try:
            dt = datetime.fromisoformat(ts.replace("Z", "+00:00"))
            return int(dt.timestamp() * 1000)
        except ValueError:
            return 0
    return 0


def search_file(filepath: str, pattern: re.Pattern, start_ts: int = None, end_ts: int = None) -> list:
    """Search a single JSONL file for the pattern."""
    matches = []

    try:
        with open(filepath) as f:
            for line_num, line in enumerate(f, 1):
                try:
                    entry = json.loads(line)
                except json.JSONDecodeError:
                    continue

                if entry.get("type") not in ("user", "assistant", None):
                    if entry.get("type") == "file-history-snapshot":
                        continue

                ts = parse_timestamp(entry.get("timestamp", 0))
                if start_ts and ts < start_ts:
                    continue
                if end_ts and ts > end_ts:
                    continue

                content = extract_content(entry)
                if not pattern.search(content):
                    continue

                matches.append({
                    "file": filepath,
                    "line": line_num,
                    "type": entry.get("type", "unknown"),
                    "timestamp": entry.get("timestamp", ""),
                    "project": entry.get("cwd", ""),
                    "session_id": entry.get("sessionId", ""),
                    "preview": content[:300],
                })
    except Exception as e:
        return [{"error": f"Failed to read {filepath}: {e}"}]

    return matches


def main():
    query = None
    files = []
    start_ts = None
    end_ts = None

    args = sys.argv[1:]
    i = 0
    while i < len(args):
        if args[i] == "--query" and i + 1 < len(args):
            query = args[i + 1]
            i += 2
        elif args[i] == "--files" and i + 1 < len(args):
            files = args[i + 1].split(",")
            i += 2
        elif args[i] == "--start-ts" and i + 1 < len(args):
            start_ts = int(args[i + 1])
            i += 2
        elif args[i] == "--end-ts" and i + 1 < len(args):
            end_ts = int(args[i + 1])
            i += 2
        else:
            i += 1

    if not query:
        print(json.dumps({"error": "Missing --query"}))
        sys.exit(1)

    if not files:
        print(json.dumps({"error": "Missing --files"}))
        sys.exit(1)

    try:
        pattern = re.compile(query, re.IGNORECASE)
    except re.error as e:
        print(json.dumps({"error": f"Invalid regex: {e}"}))
        sys.exit(1)

    all_matches = []
    for filepath in files:
        matches = search_file(filepath.strip(), pattern, start_ts, end_ts)
        all_matches.extend(matches)

    result = {
        "query": query,
        "files_searched": len(files),
        "total_matches": len(all_matches),
        "matches": all_matches[:100],
    }

    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
