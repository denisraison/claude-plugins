#!/usr/bin/env python3
"""
Skill Validator - Checks skill structure and frontmatter

Usage:
    validate_skill.py <skill-directory>

Examples:
    validate_skill.py plugins/consultant/skills/consulting-models
    validate_skill.py ./my-skill
"""

import sys
import re
from pathlib import Path

try:
    import yaml
    HAS_YAML = True
except ImportError:
    HAS_YAML = False

ALLOWED_FRONTMATTER = {"name", "description", "license", "allowed-tools", "metadata"}


def parse_frontmatter(content: str) -> tuple[dict | None, str]:
    if not content.startswith("---"):
        return None, "No YAML frontmatter found (must start with ---)"

    match = re.match(r"^---\n(.*?)\n---", content, re.DOTALL)
    if not match:
        return None, "Invalid frontmatter format (missing closing ---)"

    frontmatter_text = match.group(1)

    if HAS_YAML:
        try:
            data = yaml.safe_load(frontmatter_text)
            if not isinstance(data, dict):
                return None, "Frontmatter must be a YAML dictionary"
            return data, ""
        except yaml.YAMLError as e:
            return None, f"Invalid YAML: {e}"

    # Fallback: basic parsing without yaml module
    data = {}
    for line in frontmatter_text.strip().split("\n"):
        if ":" in line:
            key, _, value = line.partition(":")
            data[key.strip()] = value.strip()
    return data, ""


def validate_skill(skill_path: str) -> tuple[bool, list[str]]:
    path = Path(skill_path)
    errors = []
    warnings = []

    skill_md = path / "SKILL.md"
    if not skill_md.exists():
        return False, ["SKILL.md not found"]

    content = skill_md.read_text()
    frontmatter, error = parse_frontmatter(content)

    if error:
        return False, [error]

    # Check required fields
    if "name" not in frontmatter:
        errors.append("Missing required field: name")
    if "description" not in frontmatter:
        errors.append("Missing required field: description")

    # Validate name
    name = frontmatter.get("name", "")
    if name:
        if not re.match(r"^[a-z0-9-]+$", name):
            errors.append(f"Name '{name}' must be hyphen-case (lowercase, digits, hyphens)")
        if name.startswith("-") or name.endswith("-") or "--" in name:
            errors.append(f"Name '{name}' has invalid hyphen placement")
        if len(name) > 64:
            errors.append(f"Name too long ({len(name)} chars, max 64)")

    # Validate description
    desc = frontmatter.get("description", "")
    if desc:
        if "<" in desc or ">" in desc:
            errors.append("Description cannot contain angle brackets")
        if len(desc) > 1024:
            errors.append(f"Description too long ({len(desc)} chars, max 1024)")
        if "[TODO" in desc:
            warnings.append("Description contains TODO placeholder")

    # Check for unexpected keys
    unexpected = set(frontmatter.keys()) - ALLOWED_FRONTMATTER
    if unexpected:
        errors.append(f"Unexpected frontmatter keys: {', '.join(sorted(unexpected))}")

    # Check content length
    lines = content.split("\n")
    if len(lines) > 500:
        warnings.append(f"SKILL.md has {len(lines)} lines (recommended max: 500)")

    if errors:
        return False, errors + warnings

    messages = ["Skill is valid"]
    if warnings:
        messages.extend(warnings)
    return True, messages


def main():
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(1)

    valid, messages = validate_skill(sys.argv[1])

    for msg in messages:
        prefix = "OK:" if valid and msg == "Skill is valid" else "Warning:" if "TODO" in msg or "lines" in msg else "Error:"
        print(f"{prefix} {msg}")

    sys.exit(0 if valid else 1)


if __name__ == "__main__":
    main()
