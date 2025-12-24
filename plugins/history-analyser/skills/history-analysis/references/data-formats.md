# Data Formats Reference

## history.jsonl

Location: `~/.claude/history.jsonl`

Simple append-only log of user inputs.

```json
{
  "display": "User message or command",
  "timestamp": 1760299086653,
  "project": "/path/to/project",
  "pastedContents": {}
}
```

## Project Conversation Files

Location: `~/.claude/projects/{encoded-path}/*.jsonl`

Directory names encode the project path with hyphens replacing slashes.

### User Message Entry

```json
{
  "type": "user",
  "uuid": "c8eed096-62f9-44e6-8564-b1dc243437f3",
  "parentUuid": null,
  "timestamp": "2025-12-23T04:59:28.041Z",
  "sessionId": "023fc601-32ca-40c5-84a5-1fee27e0fdb1",
  "cwd": "/path/to/project",
  "gitBranch": "main",
  "message": {
    "role": "user",
    "content": "User's message text"
  }
}
```

### Assistant Message Entry

```json
{
  "type": "assistant",
  "uuid": "3ff55504-1b9d-4e87-8476-1bf9ddb0f258",
  "parentUuid": "c8eed096-62f9-44e6-8564-b1dc243437f3",
  "timestamp": "2025-12-23T04:59:28.917Z",
  "sessionId": "023fc601-32ca-40c5-84a5-1fee27e0fdb1",
  "message": {
    "role": "assistant",
    "model": "claude-haiku-4-5-20251001",
    "content": [
      {"type": "text", "text": "Response text"},
      {"type": "tool_use", "name": "Read", "input": {...}}
    ],
    "usage": {"input_tokens": 100, "output_tokens": 50}
  }
}
```

### File History Snapshot Entry

```json
{
  "type": "file-history-snapshot",
  "messageId": "uuid",
  "timestamp": "2025-12-23T05:00:00.000Z",
  "snapshot": {...}
}
```

## Key Fields

| Field | Description |
|-------|-------------|
| `type` | "user", "assistant", or "file-history-snapshot" |
| `timestamp` | ISO 8601 string |
| `sessionId` | Groups messages in a conversation |
| `cwd` | Working directory (project context) |
| `message.content` | String (user) or array of blocks (assistant) |
