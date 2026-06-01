
# When to Use

You need to locate a specific prior conversation or session, either because the user explicitly asks ("find our chat about X") or because you're catching up on prior work. The `/recall` command (which greps the session logs and topical memory) is the tool; this skill documents how to use it effectively.

# Key Lessons

**Filter by date first, read content second**
- Time-bound your search before querying ("2026-05-25", "last week")
- Recent matches are usually what the user means
- Session snippet previews can be misleading — they show what the session *ended* with, not what it started on. Don't skip results based on preview text alone.

**Use specific proper nouns over broad keywords**
- Search for person names, project codes, or distinctive domain terms first
- A distinctive proper noun finds faster and cleaner than a broad topic phrase when both appear in the text
- Narrow your search vocabulary before querying, rather than hoping broad keywords self-filter

**Date + one specific term usually beats broad keywords alone**
- "2026-05-25" + a distinctive name beats a broad topic phrase for finding a specific conversation
- Broad searches return many results; the problem becomes reading all of them, not retrieval

**Reconcile past findings with current state**
- Prior session output may be stale. After finding context, verify key facts against current code/databases before acting on old results
- Use read-only tools to validate assumptions against current state, not just replay old session output

# Common Mistakes

- Searching on a generic term and skipping results because the snippet preview doesn't mention the topic (snippets are tail-heavy)
- Not constraining by date, leading to many false positives
- Assuming a snippet summarizes the whole session instead of its conclusion

# Example

Wrong: Search a broad topic phrase → see 10 results, skip the 2026-05-25 one because its snippet shows what the session *ended* on (an unrelated tail task) → miss the main thread at the session start.

Right: Search "2026-05-25" + a distinctive proper noun → find the session instantly → confirm it opens on the topic you wanted.
