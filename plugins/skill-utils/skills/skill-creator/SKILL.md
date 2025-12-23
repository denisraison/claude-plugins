---
name: skill-creator
description: Creates new Claude Code skills with proper structure. Use when the user wants to create a new skill, scaffold a skill, or add a skill to a plugin.
---

# Skill Creator

Creates properly structured skills for Claude Code plugins.

## When to Use

- User asks to "create a skill" or "add a skill"
- User wants to scaffold a new capability
- User mentions SKILL.md or skill structure

## Creating a Skill

### 1. Determine Location

Skills live inside plugins:

```
plugins/<plugin-name>/
├── .claude-plugin/plugin.json
└── skills/<skill-name>/
    ├── SKILL.md           # Required
    ├── references/        # Optional: docs loaded on demand
    └── scripts/           # Optional: executable scripts
```

Ask the user:
- Which plugin should contain this skill?
- Or should we create a new plugin?

### 2. Run the Init Script

```bash
python3 scripts/init_skill.py <skill-name> --plugin <plugin-name>
```

This creates the skill directory with a template SKILL.md.

### 3. Validate the Skill

```bash
python3 scripts/validate_skill.py plugins/<plugin>/skills/<skill>
```

Checks:
- SKILL.md exists with valid frontmatter
- Name follows hyphen-case convention
- Description is present and under 1024 chars
- No invalid frontmatter keys

## SKILL.md Structure

```markdown
---
name: my-skill
description: What this skill does. Use when [specific triggers].
---

# Skill Title

## Overview
Brief explanation of the skill's purpose.

## Workflow / Tasks / Guidelines
Main content organised by pattern (see references/structure.md).

## Resources
Description of any scripts or references included.
```

### Frontmatter Rules

| Field | Required | Notes |
|-------|----------|-------|
| name | Yes | Hyphen-case, max 64 chars |
| description | Yes | Max 1024 chars, include "when to use" |
| license | No | Optional license identifier |
| allowed-tools | No | Restrict which tools skill can use |

### Content Guidelines

- Keep SKILL.md under 500 lines
- Use progressive disclosure: put details in references/
- Include concrete examples with realistic user requests
- Third-person descriptions ("Processes files" not "I process files")

## After Creation

1. Edit SKILL.md to fill in the TODOs
2. Add any scripts or references needed
3. Run validate to check structure
4. Bump plugin version in plugin.json
5. Reinstall the plugin to pick up changes

For detailed structure patterns, read references/structure.md.
