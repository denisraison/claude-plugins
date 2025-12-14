# Claude Plugins Repository

Personal collection of Claude Code plugins using cursor-agent CLI.

## Repository Structure

- `plugins/` - Individual plugins
- `scratch/` - Temporary working directory (gitignored)

## Development

No build step required. Plugins use bash scripts and cursor-agent CLI.

## Skill Structure

Scripts must live **inside the skill directory**, not at the plugin root:

```
plugins/<name>/
├── .claude-plugin/plugin.json
└── skills/<skill-name>/
    ├── SKILL.md
    ├── references/
    └── scripts/           <-- scripts here
        └── my-script.sh
```

Reference scripts in SKILL.md as `scripts/my-script.sh` (relative to skill directory).

See: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview

## Adding Models

Edit `plugins/consultant/skills/consulting-models/scripts/models.conf` to add new models.
Format: `ALIAS|MODEL_ID|DESCRIPTION`

## Updating Plugins

When changing a plugin, bump the version in both files:
- `.claude-plugin/marketplace.json` (plugin entry)
- `plugins/<name>/.claude-plugin/plugin.json`

Then run:
```
/plugin marketplace update santos
/plugin install <plugin>@santos
```

The cache is keyed by version, so changes won't take effect without a version bump.

## Skill Authoring Tips

**From official docs:**
- Keep SKILL.md under 500 lines, use reference files for details
- Use third-person in descriptions ("Processes files" not "I process files")
- Scripts should handle errors, not punt to Claude
- Use validation loops: create plan, validate with script, then execute

**From practical experience:**
- Start simple: a SKILL.md file is all you need to begin
- Skills are auto-discovered by Claude (unlike slash commands which need explicit invocation)
- Wrap existing CLI tools and APIs, skills can access anything on your system
- Good descriptions matter: Claude uses them to decide when to trigger the skill
- Test with real prompts to verify discovery works as expected

## References

- [Skills Overview](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview)
- [Skills Best Practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)
- [nicknisi/claude-plugins](https://github.com/nicknisi/claude-plugins) - Reference implementation
- [Claude Skills Guide](https://nicknisi.com/posts/claude-skills/) - Practical walkthrough
