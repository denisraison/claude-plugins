#!/usr/bin/env python3
"""
Skill Initializer - Creates a new skill within a plugin

Usage:
    init_skill.py <skill-name> --plugin <plugin-name>
    init_skill.py <skill-name> --path <path>

Examples:
    init_skill.py code-reviewer --plugin dev-tools
    init_skill.py my-helper --path plugins/my-plugin/skills
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


def find_plugins_dir() -> Path:
    cwd = Path.cwd()
    if (cwd / "plugins").is_dir():
        return cwd / "plugins"
    for parent in cwd.parents:
        if (parent / "plugins").is_dir():
            return parent / "plugins"
    return cwd / "plugins"


def init_skill(skill_name: str, plugin_name: str = None, path: str = None) -> bool:
    if path:
        skill_dir = Path(path).resolve() / skill_name
    elif plugin_name:
        plugins_dir = find_plugins_dir()
        skill_dir = plugins_dir / plugin_name / "skills" / skill_name
    else:
        print("Error: Must provide --plugin or --path")
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
    if len(args) < 3:
        print(__doc__)
        sys.exit(1)

    skill_name = args[0]
    plugin_name = None
    path = None

    i = 1
    while i < len(args):
        if args[i] == "--plugin" and i + 1 < len(args):
            plugin_name = args[i + 1]
            i += 2
        elif args[i] == "--path" and i + 1 < len(args):
            path = args[i + 1]
            i += 2
        else:
            i += 1

    if init_skill(skill_name, plugin_name, path):
        sys.exit(0)
    else:
        sys.exit(1)


if __name__ == "__main__":
    main()
