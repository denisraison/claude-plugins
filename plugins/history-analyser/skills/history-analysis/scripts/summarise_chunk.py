#!/usr/bin/env python3
"""
Summarise JSONL files to extract insights.

Usage:
    summarise_chunk.py --files file1.jsonl,file2.jsonl
    summarise_chunk.py --files file1.jsonl --start-ts MS --end-ts MS

Output: JSON with summary statistics
"""

import json
import sys
from collections import Counter
from datetime import datetime
from pathlib import Path


def parse_timestamp(ts) -> int:
    if isinstance(ts, (int, float)):
        return int(ts)
    if isinstance(ts, str):
        try:
            dt = datetime.fromisoformat(ts.replace("Z", "+00:00"))
            return int(dt.timestamp() * 1000)
        except ValueError:
            return 0
    return 0


def extract_user_query(entry: dict) -> str:
    """Extract user's query text."""
    if "display" in entry:
        return entry["display"]

    message = entry.get("message", {})
    content = message.get("content", [])

    if isinstance(content, str):
        return content
    if isinstance(content, list):
        for item in content:
            if isinstance(item, dict) and item.get("type") == "text":
                return item.get("text", "")
    return ""


def summarise_file(filepath: str, start_ts: int = None, end_ts: int = None) -> dict:
    """Summarise a single JSONL file."""
    summary = {
        "projects": Counter(),
        "tools_used": Counter(),
        "user_queries": [],
        "message_count": 0,
        "user_count": 0,
        "assistant_count": 0,
        "earliest_ts": None,
        "latest_ts": None,
    }

    try:
        with open(filepath) as f:
            for line in f:
                try:
                    entry = json.loads(line)
                except json.JSONDecodeError:
                    continue

                entry_type = entry.get("type")
                if entry_type not in ("user", "assistant"):
                    continue

                ts = parse_timestamp(entry.get("timestamp", 0))
                if start_ts and ts < start_ts:
                    continue
                if end_ts and ts > end_ts:
                    continue

                summary["message_count"] += 1

                if summary["earliest_ts"] is None or ts < summary["earliest_ts"]:
                    summary["earliest_ts"] = ts
                if summary["latest_ts"] is None or ts > summary["latest_ts"]:
                    summary["latest_ts"] = ts

                cwd = entry.get("cwd", "")
                if cwd:
                    project = Path(cwd).name
                    summary["projects"][project] += 1

                if entry_type == "user":
                    summary["user_count"] += 1
                    query = extract_user_query(entry)
                    if query and len(query) > 10:
                        summary["user_queries"].append({
                            "query": query[:200],
                            "timestamp": entry.get("timestamp", ""),
                        })

                elif entry_type == "assistant":
                    summary["assistant_count"] += 1
                    message = entry.get("message", {})
                    content = message.get("content", [])
                    if isinstance(content, list):
                        for item in content:
                            if isinstance(item, dict) and item.get("type") == "tool_use":
                                summary["tools_used"][item.get("name", "unknown")] += 1

    except Exception as e:
        return {"error": f"Failed to read {filepath}: {e}"}

    summary["projects"] = dict(summary["projects"].most_common(10))
    summary["tools_used"] = dict(summary["tools_used"].most_common(10))
    summary["user_queries"] = summary["user_queries"][:20]

    return summary


def merge_summaries(summaries: list) -> dict:
    """Merge multiple file summaries."""
    merged = {
        "projects": Counter(),
        "tools_used": Counter(),
        "user_queries": [],
        "message_count": 0,
        "user_count": 0,
        "assistant_count": 0,
        "earliest_ts": None,
        "latest_ts": None,
        "files_processed": 0,
    }

    for s in summaries:
        if "error" in s:
            continue

        merged["files_processed"] += 1
        merged["message_count"] += s.get("message_count", 0)
        merged["user_count"] += s.get("user_count", 0)
        merged["assistant_count"] += s.get("assistant_count", 0)

        merged["projects"].update(s.get("projects", {}))
        merged["tools_used"].update(s.get("tools_used", {}))
        merged["user_queries"].extend(s.get("user_queries", []))

        earliest = s.get("earliest_ts")
        if earliest and (merged["earliest_ts"] is None or earliest < merged["earliest_ts"]):
            merged["earliest_ts"] = earliest

        latest = s.get("latest_ts")
        if latest and (merged["latest_ts"] is None or latest > merged["latest_ts"]):
            merged["latest_ts"] = latest

    merged["projects"] = dict(merged["projects"].most_common(15))
    merged["tools_used"] = dict(merged["tools_used"].most_common(15))
    merged["user_queries"] = sorted(
        merged["user_queries"],
        key=lambda x: x.get("timestamp", ""),
        reverse=True
    )[:30]

    return merged


def main():
    files = []
    start_ts = None
    end_ts = None

    args = sys.argv[1:]
    i = 0
    while i < len(args):
        if args[i] == "--files" and i + 1 < len(args):
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

    if not files:
        print(json.dumps({"error": "Missing --files"}))
        sys.exit(1)

    summaries = []
    for filepath in files:
        summary = summarise_file(filepath.strip(), start_ts, end_ts)
        summaries.append(summary)

    result = merge_summaries(summaries)
    print(json.dumps(result, indent=2, default=str))


if __name__ == "__main__":
    main()
