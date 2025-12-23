# Skill Structure Patterns

Reference for organising SKILL.md content.

## Directory Structure

```
plugins/<plugin-name>/
├── .claude-plugin/
│   └── plugin.json        # Plugin metadata
└── skills/<skill-name>/
    ├── SKILL.md           # Required: main instructions
    ├── references/        # Optional: docs loaded on demand
    ├── scripts/           # Optional: executable scripts
    └── assets/            # Optional: templates, images
```

## Content Patterns

### 1. Workflow-Based

Best for sequential processes with clear steps.

```markdown
## Workflow

### Step 1: Analyse
Examine the input and determine the approach.

### Step 2: Process
Apply transformations or operations.

### Step 3: Validate
Verify the output meets requirements.
```

### 2. Task-Based

Best for skills offering different operations.

```markdown
## Tasks

### Creating Files
How to create new files of this type.

### Editing Files
How to modify existing files.

### Converting Files
How to convert between formats.
```

### 3. Reference/Guidelines

Best for standards or specifications.

```markdown
## Guidelines

### Naming Conventions
Follow these patterns for names.

### Code Style
Apply these formatting rules.
```

### 4. Conditional

Best for branching logic.

```markdown
## Decision Tree

Is this a new file or existing?
- New: Follow the creation workflow
- Existing: Follow the editing workflow
```

## Progressive Disclosure

Load content in stages:

1. **Always loaded**: Frontmatter (name + description)
2. **Loaded when triggered**: SKILL.md body
3. **Loaded on demand**: references/ files

Put detailed content in references/ to keep SKILL.md focused.

## Resource Types

| Directory | Purpose | Loaded |
|-----------|---------|--------|
| scripts/ | Executable code | When run |
| references/ | Documentation | On demand |
| assets/ | Templates, files | When copied |

## Writing Tips

- Use imperative language ("Process the file" not "This processes files")
- Include concrete examples with realistic scenarios
- Keep SKILL.md under 500 lines
- Third-person in descriptions ("Processes files" not "I process files")
- Include "when to use" triggers in the description
