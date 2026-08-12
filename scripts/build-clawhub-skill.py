#!/usr/bin/env python3
"""Build the ClawHub-specific SKILL.md frontmatter from the canonical Skill."""

from __future__ import annotations

import argparse
import re
from pathlib import Path


def split_skill(text: str) -> tuple[list[str], str]:
    if not text.startswith("---\n"):
        raise ValueError("canonical SKILL.md must start with YAML frontmatter")
    end = text.find("\n---\n", 4)
    if end < 0:
        raise ValueError("canonical SKILL.md has unterminated frontmatter")
    return text[4:end].splitlines(), text[end + len("\n---\n") :]


def build_frontmatter(lines: list[str], version: str) -> list[str]:
    output: list[str] = []
    skipping_metadata = False
    inserted_version = False

    for line in lines:
        if line.startswith("metadata:"):
            skipping_metadata = True
            continue
        if skipping_metadata and line.startswith((" ", "\t")):
            continue
        skipping_metadata = False
        if line.startswith("license:"):
            continue
        output.append(line)
        if line.startswith("name:"):
            output.append(f'version: "{version}"')
            inserted_version = True

    if not inserted_version:
        raise ValueError("canonical SKILL.md is missing name")
    output.extend(
        [
            "metadata:",
            "  openclaw:",
            "    requires:",
            "      bins:",
            "        - bash",
            "        - python3",
        ]
    )
    return output


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("destination", type=Path)
    parser.add_argument("--version", required=True)
    args = parser.parse_args()

    if not re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+(?:[.-][A-Za-z0-9]+)?", args.version):
        raise SystemExit(f"invalid release version: {args.version}")

    frontmatter, body = split_skill(args.source.read_text(encoding="utf-8"))
    rendered = "---\n" + "\n".join(build_frontmatter(frontmatter, args.version))
    rendered += "\n---\n" + body.lstrip("\n")
    args.destination.write_text(rendered, encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
