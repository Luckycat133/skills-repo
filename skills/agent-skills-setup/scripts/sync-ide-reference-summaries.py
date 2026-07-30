#!/usr/bin/env python3
"""Synchronize generated path summaries in per-IDE reference files."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path


OBJECT_LABELS = {
    "global_skills": "Global skills",
    "project_skills": "Project skills",
    "rules": "Rules",
    "mcp": "MCP",
    "project_mcp": "Project MCP",
    "project_config": "Project config",
    "config": "Config",
}
START = "<!-- GENERATED: ide-paths.json summary; do not edit this block -->"
END = "<!-- END GENERATED: ide-paths.json summary -->"
BLOCK_PATTERN = re.compile(
    rf"{re.escape(START)}\n.*?{re.escape(END)}\n?", re.DOTALL
)


def format_value(value: object) -> str:
    if isinstance(value, str):
        return f"`{value}`" if value else "Not mapped"
    if isinstance(value, dict):
        rows = [
            f"{platform}: `{path}`"
            for platform, path in sorted(value.items())
            if path
        ]
        return "<br>".join(rows) if rows else "Not mapped"
    return "Not mapped"


def summary(ide: str, values: dict[str, object]) -> str:
    rows = [
        START,
        "",
        "## Generated path summary",
        "",
        "This table is generated from `references/ide-paths.json`. The notes below explain product-specific behavior and portability trade-offs.",
        "Treat those notes as current compatibility evidence and practical guidance; when a user chooses a different approach, explain the trade-off and distinguish it from a hard limit in the bundled script.",
        "",
        "| Object | Documented path |",
        "| --- | --- |",
    ]
    for key, label in OBJECT_LABELS.items():
        rows.append(f"| {label} | {format_value(values.get(key, ''))} |")
    rows.extend(["", END, ""])
    return "\n".join(rows)


def update_reference(path: Path, generated: str, check: bool) -> bool:
    text = path.read_text(encoding="utf-8")
    if BLOCK_PATTERN.search(text):
        updated = BLOCK_PATTERN.sub(lambda _: generated, text)
    else:
        heading_end = text.find("\n")
        if heading_end < 0 or not text.startswith("# "):
            raise ValueError(f"{path}: expected a level-one Markdown heading")
        updated = text[: heading_end + 1] + "\n" + generated + text[heading_end + 1 :].lstrip("\n")

    if text == updated:
        return False
    if check:
        raise ValueError(f"{path}: generated path summary is out of date")
    path.write_text(updated, encoding="utf-8")
    return True


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--paths", type=Path, required=True)
    parser.add_argument("--references", type=Path, required=True)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    values = json.loads(args.paths.read_text(encoding="utf-8"))
    changed = 0
    try:
        for ide, mapping in sorted(values.items()):
            reference = args.references / f"{ide}.md"
            if not reference.is_file():
                raise ValueError(f"missing IDE reference: {reference}")
            if update_reference(reference, summary(ide, mapping), args.check):
                changed += 1
    except ValueError as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 1

    verb = "Verified" if args.check else "Updated"
    print(f"{verb} generated summaries for {len(values)} IDE references ({changed} changed).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
