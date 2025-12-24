# Workflow Reference

## Search Workflow

1. **Parse date range**
   ```bash
   python3 scripts/date_utils.py "last week"
   ```
   Returns `start_ts` and `end_ts` in milliseconds.

2. **Get chunk manifest**
   ```bash
   python3 scripts/chunk_data.py --start-ts $START --end-ts $END
   ```
   Returns list of chunks with file paths.

3. **Decision point**
   - If `needs_parallel` is false: search directly
   - If `needs_parallel` is true: spawn Task agents

4. **Search chunks**
   For each chunk, run:
   ```bash
   python3 scripts/search_chunk.py --query "pattern" \
     --files file1.jsonl,file2.jsonl \
     --start-ts $START --end-ts $END
   ```

5. **Synthesise results**
   Combine matches from all chunks, deduplicate, rank by relevance.

## Summary Workflow

1. **Parse date range** (same as search)

2. **Get chunk manifest** (same as search)

3. **Summarise chunks**
   For each chunk:
   ```bash
   python3 scripts/summarise_chunk.py --files file1.jsonl,file2.jsonl \
     --start-ts $START --end-ts $END
   ```

4. **Synthesise summary**
   Merge project counts, tool usage, extract themes from user queries.

## Parallel Processing with Task Tool

When `chunk_count > 1`, spawn parallel agents:

```
For chunk_index, chunk in enumerate(manifest.chunks):
    Task(
        description: f"Process chunk {chunk_index + 1}",
        subagent_type: "Explore",
        prompt: f"""
            Run the search/summary script on these files:
            {chunk.files}

            Query: {user_query}
            Start: {start_ts}
            End: {end_ts}

            Return the JSON output.
        """
    )
```

Collect all Task results and merge.

## Output Formats

### Search Result
```json
{
  "query": "auth",
  "total_matches": 15,
  "matches": [
    {
      "file": "/path/to/file.jsonl",
      "type": "user",
      "timestamp": "2025-12-20T10:00:00Z",
      "project": "/path/to/project",
      "preview": "First 300 chars..."
    }
  ]
}
```

### Summary Result
```json
{
  "message_count": 500,
  "projects": {"project-a": 200, "project-b": 150},
  "tools_used": {"Read": 100, "Edit": 50, "Bash": 30},
  "user_queries": [
    {"query": "Sample query...", "timestamp": "..."}
  ]
}
```
