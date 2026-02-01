---
name: skill-creator
description: This skill should be used when the user asks to "create a skill", "add a skill to a plugin", "add a skill to a repository", "scaffold a skill", "write a new skill", "improve skill description", or needs guidance on skill structure, progressive disclosure, or skill development best practices.
---

# Skill Creator

Creates properly structured skills for Claude Code plugins or repositories.

## About Skills

Skills are modular, self-contained packages that extend Claude's capabilities by providing specialised knowledge, workflows, and tools. Think of them as "onboarding guides" for specific domains or tasks, transforming Claude from a general-purpose agent into a specialised agent equipped with procedural knowledge.

### What Skills Provide

1. **Specialised workflows** - Multi-step procedures for specific domains
2. **Tool integrations** - Instructions for working with specific file formats or APIs
3. **Domain expertise** - Company-specific knowledge, schemas, business logic
4. **Bundled resources** - Scripts, references, and assets for complex and repetitive tasks

### Anatomy of a Skill

Every skill consists of a required SKILL.md file and optional bundled resources:

```
skill-name/
├── SKILL.md (required)
│   ├── YAML frontmatter metadata (required)
│   │   ├── name: (required)
│   │   └── description: (required)
│   └── Markdown instructions (required)
└── Bundled Resources (optional)
    ├── scripts/          - Executable code (Python/Bash/etc.)
    ├── references/       - Documentation loaded into context as needed
    └── assets/           - Files used in output (templates, icons, fonts)
```

### Bundled Resources

#### Scripts (`scripts/`)

Executable code for tasks requiring deterministic reliability or repeatedly rewritten.

- **When to include**: Same code being rewritten repeatedly, or deterministic reliability needed
- **Example**: `scripts/rotate_pdf.py` for PDF rotation tasks
- **Benefits**: Token efficient, deterministic, may execute without loading into context

#### References (`references/`)

Documentation loaded as needed to inform Claude's process and thinking.

- **When to include**: Documentation Claude should reference while working
- **Examples**: Database schemas, API documentation, domain knowledge, company policies
- **Benefits**: Keeps SKILL.md lean, loaded only when Claude determines it's needed
- **Best practice**: If files are large (>10k words), include grep search patterns in SKILL.md

#### Assets (`assets/`)

Files used within output Claude produces, not loaded into context.

- **When to include**: Files that will be used in the final output
- **Examples**: Logo images, PowerPoint templates, HTML/React boilerplate, fonts
- **Benefits**: Separates output resources from documentation

### Progressive Disclosure

Skills use a three-level loading system to manage context efficiently:

1. **Metadata (name + description)** - Always in context (~100 words)
2. **SKILL.md body** - When skill triggers (<5k words)
3. **Bundled resources** - As needed by Claude (unlimited)

Keep SKILL.md lean (1,500-2,000 words ideal). Move detailed content to references/.

## Skill Creation Process

### Step 1: Understand the Skill with Concrete Examples

To create an effective skill, clearly understand concrete examples of how it will be used. Ask questions like:

- "What functionality should this skill support?"
- "Can you give examples of how this skill would be used?"
- "What would a user say that should trigger this skill?"

Conclude this step when there is a clear sense of the functionality the skill should support.

### Step 2: Plan the Reusable Skill Contents

Analyse each example by:

1. Considering how to execute on the example from scratch
2. Identifying what scripts, references, and assets would be helpful when executing repeatedly

**Example**: Building a `pdf-editor` skill for "Help me rotate this PDF":
- Rotating a PDF requires re-writing the same code each time
- A `scripts/rotate_pdf.py` script would be helpful

**Example**: Building a `big-query` skill for "How many users logged in today?":
- Querying BigQuery requires re-discovering table schemas each time
- A `references/schema.md` file documenting the schemas would be helpful

### Step 3: Determine Location and Initialise

Ask the user which type of skill they want:

**Repository Skills** (local to a specific repo):
```
<repo>/.claude/skills/<skill-name>/
├── SKILL.md
├── references/
└── scripts/
```

Use for: project-specific workflows, repo-local automation, team conventions.

**Plugin Skills** (shareable across repos):
```
plugins/<plugin-name>/skills/<skill-name>/
├── SKILL.md
├── references/
└── scripts/
```

Use for: reusable skills, multi-repo tools, publishable capabilities.

Run the init script:

```bash
# Repository skills
python3 scripts/init_skill.py <skill-name> --repo
python3 scripts/init_skill.py <skill-name> --repo --path /path/to/repo

# Plugin skills
python3 scripts/init_skill.py <skill-name> --plugin <plugin-name>
```

### Step 4: Edit the Skill

Remember that the skill is being created for another instance of Claude to use. Focus on information that would be beneficial and non-obvious to Claude.

#### Start with Bundled Resources

Begin with the reusable resources identified in Step 2. This may require user input (brand assets, documentation, etc.). Delete any example directories not needed.

#### Write SKILL.md

**Writing Style**: Use **imperative/infinitive form** (verb-first instructions), not second person:

| Correct (imperative) | Incorrect (second person) |
|---------------------|---------------------------|
| Parse the configuration file. | You should parse the configuration file. |
| Validate input before processing. | You need to validate input. |
| Use grep to search for patterns. | You can use grep to search. |

**Frontmatter Description**: Use third-person format with specific trigger phrases:

```yaml
---
name: my-skill
description: This skill should be used when the user asks to "specific phrase 1", "specific phrase 2", or mentions specific-topic. Provides guidance for X.
---
```

Good description:
```yaml
description: This skill should be used when the user asks to "create a hook", "add a PreToolUse hook", "validate tool use", or mentions hook events (PreToolUse, PostToolUse, Stop).
```

Bad descriptions:
```yaml
description: Use this skill when working with hooks.  # Wrong person, vague
description: Provides hook guidance.  # No trigger phrases
```

**Body Content**: Answer these questions:

1. What is the purpose of the skill, in a few sentences?
2. When should the skill be used?
3. How should Claude use the skill? Reference all bundled resources.

### Step 5: Validate the Skill

```bash
python3 scripts/validate_skill.py .claude/skills/<skill>
python3 scripts/validate_skill.py plugins/<plugin>/skills/<skill>
```

Checks:
- SKILL.md exists with valid frontmatter
- Name follows hyphen-case convention
- Description is present and under 1024 chars
- No invalid frontmatter keys

**Manual validation checklist:**

- [ ] Description uses third person ("This skill should be used when...")
- [ ] Description includes specific trigger phrases
- [ ] Body uses imperative/infinitive form
- [ ] Body is lean (1,500-2,000 words ideal, <5k max)
- [ ] Detailed content moved to references/
- [ ] All referenced files exist
- [ ] Scripts are executable

### Step 6: Iterate

After testing the skill, users may request improvements.

**Iteration workflow:**
1. Use the skill on real tasks
2. Notice struggles or inefficiencies
3. Identify how SKILL.md or bundled resources should be updated
4. Implement changes and test again

## Frontmatter Reference

| Field | Required | Notes |
|-------|----------|-------|
| name | Yes | Hyphen-case, max 64 chars |
| description | Yes | Max 1024 chars, third-person, include trigger phrases |
| license | No | Optional license identifier |
| allowed-tools | No | Restrict which tools skill can use |

## Common Mistakes

### Weak Trigger Description

Bad:
```yaml
description: Provides guidance for working with hooks.
```

Good:
```yaml
description: This skill should be used when the user asks to "create a hook", "add a PreToolUse hook", or mentions hook events.
```

### Too Much in SKILL.md

Bad:
```
skill-name/
└── SKILL.md  (8,000 words - everything in one file)
```

Good:
```
skill-name/
├── SKILL.md  (1,800 words - core essentials)
└── references/
    ├── patterns.md (2,500 words)
    └── advanced.md (3,700 words)
```

### Second Person Writing

Bad:
```markdown
You should start by reading the configuration file.
You need to validate the input.
```

Good:
```markdown
Start by reading the configuration file.
Validate the input before processing.
```

### Missing Resource References

Bad: SKILL.md with no mention of references/ or scripts/

Good:
```markdown
## Resources

### Reference Files
- **`references/patterns.md`** - Detailed patterns
- **`references/advanced.md`** - Advanced techniques

### Scripts
- **`scripts/validate.sh`** - Validation utility
```

## After Creation

For repository skills:
1. Edit SKILL.md to fill in the TODOs
2. Add scripts or references as needed
3. Run validate to check structure

For plugin skills:
1. Edit SKILL.md to fill in the TODOs
2. Add scripts or references as needed
3. Run validate to check structure
4. Bump plugin version in plugin.json
5. Reinstall the plugin to pick up changes