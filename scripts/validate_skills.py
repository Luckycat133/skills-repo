#!/usr/bin/env python3
"""Validate publishable skills without requiring third-party dependencies."""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SKILLS = ROOT / "skills"
errors: list[str] = []

SECRET = re.compile(
    r"(?:sk-[A-Za-z0-9_-]{16,}"
    r"|gh[pousr]_[A-Za-z0-9]{20,}"
    r"|tvly-[A-Za-z0-9_-]{16,}"
    r"|AKIA[0-9A-Z]{16}"
    r"|ASIA[0-9A-Z]{16}"
    r"|xox[baprs]-[A-Za-z0-9-]{10,}"
    r"|ya29\.[A-Za-z0-9_-]+"
    r"|AIza[0-9A-Za-z_-]{35}"
    r"|sk_live_[A-Za-z0-9]{16,})"
)
PRIVATE_PATH = re.compile(r"(?:/Users/[^/\s]+|/home/[^/\s]+|[A-Za-z]:\\Users\\[^\\\s]+)")
LINK = re.compile(r"!?(?:\[[^\]]*\])\(([^)]+)\)")
NAME = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
ALLOWED_FRONTMATTER_FIELDS = {
    "name",
    "description",
    "license",
    "compatibility",
    "metadata",
    "allowed-tools",
}


def get_files_to_scan() -> list[Path]:
    try:
        res = subprocess.run(
            ["git", "ls-files", "--cached", "--others", "--exclude-standard"],
            cwd=ROOT,
            capture_output=True,
            text=True,
            check=True,
        )
        files = []
        for rel_path in res.stdout.splitlines():
            p = ROOT / rel_path
            if p.is_file():
                files.append(p)
        return files
    except Exception:
        return [
            p for p in ROOT.rglob("*")
            if p.is_file() and not any(part.startswith(".") for part in p.relative_to(ROOT).parts)
        ]


def frontmatter(text: str, path: Path) -> dict[str, str]:
    if not text.startswith("---\n"):
        errors.append(f"{path}: missing YAML frontmatter")
        return {}
    end = text.find("\n---\n", 4)
    if end < 0:
        errors.append(f"{path}: unterminated YAML frontmatter")
        return {}

    values: dict[str, str] = {}
    current_key: str | None = None
    for raw_line in text[4:end].splitlines():
        if raw_line.startswith((" ", "\t", "- ")):
            continue
        match = re.match(r"^([A-Za-z0-9_-]+):\s*(.*)$", raw_line)
        if match:
            current_key = match.group(1)
            value = match.group(2).strip()
            if value not in {"", ">", "|"}:
                values[current_key] = value.strip("'\"")
            elif current_key not in values:
                values[current_key] = ""
        elif current_key and raw_line.strip():
            values[current_key] = (values[current_key] + " " + raw_line.strip()).strip()
    return values


def frontmatter_body(text: str, path: Path) -> str:
    if not text.startswith("---\n"):
        return ""
    end = text.find("\n---\n", 4)
    if end < 0:
        return ""
    return text[4:end]


def validate_frontmatter_schema(body: str, path: Path) -> None:
    top_level = re.findall(r"(?m)^([A-Za-z0-9_-]+):", body)
    for duplicate in sorted({key for key in top_level if top_level.count(key) > 1}):
        errors.append(f"{path}: duplicate frontmatter field: {duplicate}")
    for field in sorted(set(top_level) - ALLOWED_FRONTMATTER_FIELDS):
        errors.append(f"{path}: unknown Agent Skills frontmatter field: {field}")

    metadata_field = re.search(r"(?m)^metadata:[ \t]*(.*)$", body)
    metadata_match = re.search(
        r"(?m)^metadata:[ \t]*\n(?P<body>(?:[ \t]+[^\n]*(?:\n|$))*)",
        body,
    )
    if metadata_field and metadata_field.group(1).strip():
        errors.append(f"{path}: metadata must be a string mapping")
    if metadata_match:
        metadata_lines = [
            line for line in metadata_match.group("body").splitlines() if line.strip()
        ]
        if not metadata_lines:
            errors.append(f"{path}: metadata must be a non-empty string mapping")
        for line in metadata_lines:
            match = re.fullmatch(r"  ([A-Za-z0-9_.-]+):\s*(.+)", line)
            if not match:
                errors.append(f"{path}: metadata must map string keys to string values")
                continue
            value = match.group(2).strip()
            if value.startswith(("{", "[", "|", ">")):
                errors.append(f"{path}: metadata values must be strings")
            if value[0] not in {"'", '"'} and re.fullmatch(
                r"(?i:true|false|null|~|[-+]?[0-9]+(?:\.[0-9]+)?)", value
            ):
                errors.append(f"{path}: metadata values must be quoted strings")

    allowed_tools = re.search(r"(?m)^allowed-tools:[ \t]*(.*)$", body)
    if allowed_tools:
        allowed_tools_value = allowed_tools.group(1).strip()
        if not allowed_tools_value or allowed_tools_value.startswith(("[", "{", "|", ">")):
            errors.append(f"{path}: allowed-tools must be a space-separated string")


def validate_skill(skill_dir: Path) -> None:
    path = skill_dir / "SKILL.md"
    if not path.is_file():
        errors.append(f"{skill_dir}: missing SKILL.md")
        return

    text = path.read_text(encoding="utf-8")
    metadata = frontmatter(text, path.relative_to(ROOT))
    fm_body = frontmatter_body(text, path.relative_to(ROOT))
    validate_frontmatter_schema(fm_body, path.relative_to(ROOT))
    name = metadata.get("name", "")
    description = metadata.get("description", "")

    if name != skill_dir.name:
        errors.append(f"{path.relative_to(ROOT)}: name must match directory ({skill_dir.name})")
    if not NAME.fullmatch(name) or len(name) > 64:
        errors.append(f"{path.relative_to(ROOT)}: name violates Agent Skills naming rules")
    if not description and "description:" not in fm_body:
        errors.append(f"{path.relative_to(ROOT)}: description is required")
    if description and len(description) > 1024:
        errors.append(f"{path.relative_to(ROOT)}: description must be 1-1024 characters")
    description_match = re.search(
        r"(?m)^description:\s*>?\s*\n(?P<body>(?:[ \t]+[^\n]*(?:\n|$))*)",
        fm_body,
    )
    if description_match:
        description_text = " ".join(
            line.strip() for line in description_match.group("body").splitlines()
        ).strip()
        if not 1 <= len(description_text) <= 1024:
            errors.append(f"{path.relative_to(ROOT)}: description must be 1-1024 characters")
    compatibility = metadata.get("compatibility", "")
    if compatibility and len(compatibility) > 500:
        errors.append(f"{path.relative_to(ROOT)}: compatibility exceeds 500 characters")
    if SECRET.search(text):
        errors.append(f"{path.relative_to(ROOT)}: possible secret detected")
    if PRIVATE_PATH.search(text):
        errors.append(f"{path.relative_to(ROOT)}: private absolute path detected")

    for target in LINK.findall(text):
        target = target.split("#", 1)[0].strip()
        if not target or "://" in target or target.startswith(("mailto:", "#")):
            continue
        resolved = (path.parent / target).resolve()
        try:
            resolved.relative_to(ROOT.resolve())
        except ValueError:
            errors.append(f"{path.relative_to(ROOT)}: link escapes repository: {target}")
            continue
        if not resolved.exists():
            errors.append(f"{path.relative_to(ROOT)}: broken relative link: {target}")


def _is_test_file(path: Path) -> bool:
    name = path.name
    if name.startswith(("test-", "test_")) or name == "conftest.py":
        return True
    return "tests" in path.parts


def main() -> int:
    if not SKILLS.is_dir():
        print("ERROR: skills/ directory is missing", file=sys.stderr)
        return 1

    skill_dirs = sorted(path for path in SKILLS.iterdir() if path.is_dir())
    if not skill_dirs:
        print("ERROR: no skill directories found", file=sys.stderr)
        return 1

    for skill_dir in skill_dirs:
        validate_skill(skill_dir)

    for path in get_files_to_scan():
        if path.resolve() == Path(__file__).resolve():
            continue
        if _is_test_file(path):
            continue
        if path.suffix.lower() not in {".md", ".sh", ".py", ".yml", ".yaml", ".json", ".toml"}:
            continue
        text = path.read_text(encoding="utf-8", errors="replace")
        if SECRET.search(text):
            errors.append(f"{path.relative_to(ROOT)}: possible secret detected")
        if PRIVATE_PATH.search(text):
            errors.append(f"{path.relative_to(ROOT)}: private absolute path detected")

    if errors:
        for error in sorted(set(errors)):
            print(f"ERROR: {error}", file=sys.stderr)
        return 1

    print(f"Validated {len(skill_dirs)} skill(s).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
