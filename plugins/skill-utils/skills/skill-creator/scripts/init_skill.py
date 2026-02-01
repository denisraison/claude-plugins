#!/usr/bin/env python3
"""
Skill Initializer - Creates a new skill for a plugin or repository

Usage:
    init_skill.py <skill-name> --repo [--path <repo-path>]
    init_skill.py <skill-name> --plugin <plugin-name>

Examples:
    init_skill.py deploy-helper --repo                    # In current repo
    init_skill.py deploy-helper --repo --path /my/repo    # In specific repo
    init_skill.py code-reviewer --plugin dev-tools        # In a plugin
"""

import sys
from pathlib import Path

SKILL_TEMPLATE = """---
name: {skill_name}
description: [TODO: What this skill does. Use when <specific triggers>.]
---

# {skill_title}

## Overview

[TODO: 1-2 sentences explaining what this skill enables]

## Workflow

[TODO: Choose a structure pattern:

1. **Workflow-Based** - Sequential steps for processes
2. **Task-Based** - Different operations/capabilities
3. **Reference/Guidelines** - Standards or specifications

Delete this section when done.]

## Resources

[TODO: Describe any scripts or references, or delete this section]
"""


def title_case(name: str) -> str:
    return " ".join(word.capitalize() for word in name.split("-"))


def find_repo_root(start: Path = None) -> Path:
    """Find the repository root by looking for .git directory."""
    cwd = start or Path.cwd()
    if (cwd / ".git").exists():
        return cwd
    for parent in cwd.parents:
        if (parent / ".git").exists():
            return parent
    return cwd


def find_plugins_dir() -> Path:
    cwd = Path.cwd()
    if (cwd / "plugins").is_dir():
        return cwd / "plugins"
    for parent in cwd.parents:
        if (parent / "plugins").is_dir():
            return parent / "plugins"
    return cwd / "plugins"


def init_skill(
    skill_name: str,
    plugin_name: str = None,
    repo_mode: bool = False,
    path: str = None,
) -> bool:
    if repo_mode:
        repo_root = Path(path).resolve() if path else find_repo_root()
        skill_dir = repo_root / ".claude" / "skills" / skill_name
    elif plugin_name:
        plugins_dir = find_plugins_dir()
        skill_dir = plugins_dir / plugin_name / "skills" / skill_name
    else:
        print("Error: Must provide --repo or --plugin")
        return False

    if skill_dir.exists():
        print(f"Error: Directory already exists: {skill_dir}")
        return False

    skill_dir.mkdir(parents=True)
    print(f"Created: {skill_dir}")

    skill_md = skill_dir / "SKILL.md"
    content = SKILL_TEMPLATE.format(
        skill_name=skill_name,
        skill_title=title_case(skill_name),
    )
    skill_md.write_text(content)
    print(f"Created: {skill_md}")

    (skill_dir / "scripts").mkdir()
    (skill_dir / "references").mkdir()
    print("Created: scripts/ and references/ directories")

    print(f"\nSkill '{skill_name}' initialised at {skill_dir}")
    print("\nNext steps:")
    print("1. Edit SKILL.md to complete the TODOs")
    print("2. Add scripts or references as needed")
    print("3. Run validate_skill.py to check structure")
    return True


def main():
    args = sys.argv[1:]
    if len(args) < 2:
        print(__doc__)
        sys.exit(1)

    skill_name = args[0]
    plugin_name = None
    repo_mode = False
    path = None

    i = 1
    while i < len(args):
        if args[i] == "--plugin" and i + 1 < len(args):
            plugin_name = args[i + 1]
            i += 2
        elif args[i] == "--repo":
            repo_mode = True
            i += 1
        elif args[i] == "--path" and i + 1 < len(args):
            path = args[i + 1]
            i += 2
        else:
            i += 1

    if init_skill(skill_name, plugin_name, repo_mode, path):
        sys.exit(0)
    else:
        sys.exit(1)


if __name__ == "__main__":
    main()
