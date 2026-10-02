#!/usr/bin/env python3
"""Validate publishable skills without requiring third-party dependencies."""

from __future__ import annotations

import argparse
import importlib.util
import json
import os
import re
import stat
import subprocess
import sys
from functools import lru_cache
from pathlib import Path
from types import ModuleType
from urllib.parse import unquote, urlsplit

ROOT = Path(__file__).resolve().parents[1]
SKILLS = ROOT / "skills"
errors: list[str] = []

SECRET = re.compile(
    r"(?:sk-[A-Za-z0-9_-]{16,}"
    r"|gh[pousr]_[A-Za-z0-9]{20,}"
    r"|github_pat_[A-Za-z0-9_]{20,}"
    r"|tvly-[A-Za-z0-9_-]{16,}"
    r"|AKIA[0-9A-Z]{16}"
    r"|ASIA[0-9A-Z]{16}"
    r"|xox[baprs]-[A-Za-z0-9-]{10,}"
    r"|ya29\.[A-Za-z0-9_-]+"
    r"|AIza[0-9A-Za-z_-]{35}"
    r"|sk_live_[A-Za-z0-9]{16,}"
    r"|-----BEGIN (?:OPENSSH |RSA |EC |DSA )?PRIVATE KEY-----)"
)
PRIVATE_PATH = re.compile(r"(?:/Users/[^/\s]+|/home/[^/\s]+|[A-Za-z]:\\Users\\[^\\\s]+)")
LINK = re.compile(r"!?\[[^\]]*\]\(\s*(<[^>]+>|[^\s)]+)(?:\s+[\"'][^\n]*?[\"'])?\s*\)")
NAME = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
ALLOWED_FRONTMATTER_FIELDS = {
    "name",
    "description",
    "license",
    "compatibility",
    "metadata",
    "allowed-tools",
}
TEXT_SUFFIXES = {".md", ".sh", ".py", ".yml", ".yaml", ".json", ".toml", ".tsv", ".txt"}
NON_STRING_SCALAR = re.compile(
    r"(?ix)^(?:true|false|yes|no|on|off|null|~|"
    r"[-+]?(?:[0-9][0-9_]*(?:\.[0-9_]*)?|\.[0-9_]+)(?:e[-+]?[0-9]+)?|"
    r"[-+]?0[xob][0-9a-f_]+|[-+]?\.(?:inf|nan)|[0-9]{4}-[0-9]{2}-[0-9]{2})$"
)
SCANNER_PATH = ROOT / "skills/agent-skills-setup/scripts/skill_secret_scanner.py"


@lru_cache(maxsize=1)
def credential_scanner() -> ModuleType:
    # Load only this repository's reviewed scanner, never code from an import.
    spec = importlib.util.spec_from_file_location("repository_skill_secret_scanner", SCANNER_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError("cannot load the repository credential scanner")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def display_path(path: Path) -> Path:
    try:
        return path.relative_to(ROOT)
    except ValueError:
        return path


def string_scalar(value: str, path: Path, field: str) -> str:
    """Parse string-valued YAML scalars, rejecting malformed quotes and types."""
    value = value.strip()
    if value.startswith("'"):
        match = re.fullmatch(r"'((?:[^']|'')*)'\s*(?:#.*)?", value)
        if match:
            return match.group(1).replace("''", "'")
    elif value.startswith('"'):
        match = re.fullmatch(r'("(?:[^"\\]|\\.)*")\s*(?:#.*)?', value)
        if match:
            try:
                parsed = json.loads(match.group(1))
                if isinstance(parsed, str):
                    return parsed
            except ValueError:
                pass
    else:
        value = re.split(r"\s+#", value, maxsplit=1)[0].rstrip()
        if value and not NON_STRING_SCALAR.fullmatch(value) and not re.match(r"[-?:](?:\s|$)", value) and not value.startswith(
            ("[", "{", "!", "&", "*", "|", ">", "`", "@")
        ) and not re.search(r":\s", value):
            return value
    errors.append(f"{path}: {field} must be a valid YAML string (quote non-string scalars)")
    return ""


def block_scalar(value: str, children: list[str], path: Path, field: str, base_indent: int = 0) -> str | None:
    header = re.fullmatch(r"([>|])([+-]?[1-9]?|[1-9][+-]?)(?:[ \t]+#.*)?", value)
    if not header:
        return None
    nonempty = [line for line in children if line.strip()]
    indicator = re.search(r"[1-9]", header.group(2))
    indentation = base_indent + int(indicator.group()) if indicator else min(
        (len(line) - len(line.lstrip(" ")) for line in nonempty), default=base_indent + 1
    )
    if any(len(line) - len(line.lstrip(" ")) < indentation for line in nonempty):
        errors.append(f"{path}: invalid indentation in {field} block string")
    lines = [line[indentation:] if line.strip() else "" for line in children]
    if header.group(1) == "|":
        parsed = "\n".join(lines)
    else:
        parsed = ""
        for index, line in enumerate(lines):
            if index:
                previous = lines[index - 1]
                parsed += " " if previous and line and not previous.startswith(" ") and not line.startswith(" ") else "\n"
            parsed += line
    if "-" in header.group(2):
        return parsed.rstrip("\n")
    return parsed + "\n" if "+" in header.group(2) else parsed.rstrip("\n") + "\n"


def get_files_to_scan() -> list[Path]:
    try:
        res = subprocess.run(
            ["git", "ls-files", "-z", "--cached", "--others", "--exclude-standard"],
            cwd=ROOT,
            capture_output=True,
            text=True,
            check=True,
        )
        files = []
        for rel_path in res.stdout.split("\0"):
            if not rel_path:
                continue
            p = ROOT / rel_path
            if p.is_file():
                files.append(p)
        return files
    except (OSError, subprocess.CalledProcessError):
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
    lines = text[4:end].splitlines()
    index = 0
    while index < len(lines):
        raw_line = lines[index]
        index += 1
        if not raw_line.strip() or raw_line.lstrip().startswith("#"):
            continue
        match = re.fullmatch(r"([A-Za-z0-9_-]+):[ \t]*(.*)", raw_line)
        if match:
            current_key = match.group(1)
            value = match.group(2).strip()
            children: list[str] = []
            while index < len(lines) and (not lines[index].strip() or lines[index].startswith((" ", "\t"))):
                children.append(lines[index])
                index += 1
            if any("\t" in line[:len(line) - len(line.lstrip())] for line in children):
                errors.append(f"{path}: frontmatter indentation must use spaces")
            if current_key == "metadata":
                continue
            parsed_block = block_scalar(value, children, path, current_key)
            if parsed_block is not None:
                values[current_key] = parsed_block
            elif any(line.strip() and not line.lstrip().startswith("#") for line in children):
                joined = " ".join([value, *(line.strip() for line in children if line.strip() and not line.lstrip().startswith("#"))])
                values[current_key] = string_scalar(joined, path, current_key)
            else:
                values[current_key] = string_scalar(value, path, current_key)
        else:
            errors.append(f"{path}: invalid frontmatter line {index}")
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
        r"(?m)^metadata:[^\n]*(?:\n(?P<body>(?:[ \t]+[^\n]*(?:\n|$)|\n)*))?",
        body,
    )
    if metadata_field:
        header = re.split(r"\s+#", metadata_field.group(1), maxsplit=1)[0].strip()
        metadata_lines = [
            line for line in ((metadata_match.group("body") or "") if metadata_match else "").splitlines()
            if line.strip() and not line.lstrip().startswith("#")
        ]
        if header == "{}":
            if metadata_lines:
                errors.append(f"{path}: empty metadata mapping cannot have nested entries")
        elif header and not header.startswith("#"):
            errors.append(f"{path}: metadata must be a string mapping")
        elif not metadata_lines:
            errors.append(f"{path}: metadata must be a non-empty string mapping")
        seen: set[str] = set()
        indentation = min((len(line) - len(line.lstrip(" ")) for line in metadata_lines), default=2)
        index = 0
        while index < len(metadata_lines):
            line = metadata_lines[index]
            index += 1
            match = re.fullmatch(
                r" {" + str(indentation) + r"}(\"(?:[^\"\\]|\\.)*\"|'(?:[^']|'')*'|[A-Za-z0-9_.-]+):[ \t]*(.*)", line
            )
            if not match:
                errors.append(f"{path}: metadata must map string keys to string values")
                continue
            key = string_scalar(match.group(1), path, "metadata key")
            value = match.group(2).strip()
            if key in seen:
                errors.append(f"{path}: duplicate metadata key: {key}")
            seen.add(key)
            children: list[str] = []
            while index < len(metadata_lines) and len(metadata_lines[index]) - len(metadata_lines[index].lstrip(" ")) > indentation:
                children.append(metadata_lines[index])
                index += 1
            parsed_block = block_scalar(value, children, path, f"metadata.{key}", indentation)
            if parsed_block is None:
                if children:
                    value = " ".join([value, *(child.strip() for child in children)])
                before = len(errors)
                string_scalar(value, path, f"metadata.{key}")
                if len(errors) > before:
                    errors.append(f"{path}: metadata must map string keys to string values")
            if not value or (value[0] not in {"'", '"'} and NON_STRING_SCALAR.fullmatch(value)):
                errors.append(f"{path}: metadata values must be quoted strings")

    allowed_tools = re.search(r"(?m)^allowed-tools:[ \t]*(.*)$", body)
    if allowed_tools:
        allowed_tools_value = allowed_tools.group(1).strip()
        if not allowed_tools_value or allowed_tools_value.startswith(("[", "{", "|", ">")):
            errors.append(f"{path}: allowed-tools must be a space-separated string")


def validate_skill(skill_dir: Path, expected_name: str | None = None) -> None:
    path = skill_dir / "SKILL.md"
    if not path.is_file() or path.is_symlink():
        errors.append(f"{skill_dir}: missing SKILL.md")
        return

    try:
        text = path.read_text(encoding="utf-8")
    except (OSError, UnicodeError) as error:
        errors.append(f"{display_path(path)}: cannot read UTF-8 Skill: {error}")
        return
    metadata = frontmatter(text, display_path(path))
    fm_body = frontmatter_body(text, display_path(path))
    validate_frontmatter_schema(fm_body, display_path(path))
    name = metadata.get("name", "")
    description = metadata.get("description", "")

    expected = expected_name or skill_dir.name
    if name != expected:
        errors.append(f"{display_path(path)}: name must match directory ({expected})")
    if not NAME.fullmatch(name) or len(name) > 64:
        errors.append(f"{display_path(path)}: name violates Agent Skills naming rules")
    if not description.strip() or len(description) > 1024:
        errors.append(f"{display_path(path)}: description must be 1-1024 characters")
    compatibility = metadata.get("compatibility", "")
    if compatibility and len(compatibility) > 500:
        errors.append(f"{display_path(path)}: compatibility exceeds 500 characters")
    if SECRET.search(text):
        errors.append(f"{display_path(path)}: possible secret detected")
    if PRIVATE_PATH.search(text):
        errors.append(f"{display_path(path)}: private absolute path detected")

    validate_links(path, text, skill_dir)


def validate_links(path: Path, text: str, boundary: Path) -> None:
    prose = re.sub(r"(?ms)^(`{3,}|~{3,})[^\n]*\n.*?^\1[^\n]*(?:\n|$)", "", text)
    prose = re.sub(r"(`+)(.*?)\1", "", prose, flags=re.DOTALL)

    for raw_target in LINK.findall(prose):
        target = raw_target.strip("<>")
        try:
            parsed = urlsplit(target)
        except ValueError:
            errors.append(f"{display_path(path)}: invalid link target: {target}")
            continue
        if parsed.scheme or parsed.netloc or not parsed.path:
            continue
        target = unquote(parsed.path)
        try:
            resolved = (path.parent / target).resolve()
        except (OSError, RuntimeError) as error:
            errors.append(f"{display_path(path)}: cannot resolve relative link: {error}")
            continue
        try:
            resolved.relative_to(boundary.resolve())
        except ValueError:
            errors.append(f"{display_path(path)}: link escapes Skill directory: {target}")
            continue
        if not resolved.exists():
            errors.append(f"{display_path(path)}: broken relative link: {target}")


def validate_skill_directory(skill_dir: Path, expected_name: str | None = None, *, include_test_files: bool = False) -> list[str]:
    """Validate a complete, self-contained Skill without following symbolic links."""
    before = len(errors)
    if not skill_dir.is_dir() or skill_dir.is_symlink():
        errors.append(f"{display_path(skill_dir)}: Skill must be a regular directory")
        return errors[before:]
    def walk_error(error: OSError) -> None:
        errors.append(f"{display_path(skill_dir)}: cannot inspect Skill directory: {error}")
    for directory, directories, names in os.walk(skill_dir, followlinks=False, onerror=walk_error):
        for name in (*directories, *names):
            path = Path(directory, name)
            try:
                mode = path.lstat().st_mode
                if stat.S_ISLNK(mode):
                    errors.append(f"{display_path(path)}: symbolic links are not allowed in a publishable Skill")
                elif not stat.S_ISREG(mode) and not stat.S_ISDIR(mode):
                    errors.append(f"{display_path(path)}: special files are not allowed in a publishable Skill")
                elif stat.S_ISREG(mode) and (include_test_files or not _is_test_file(path.relative_to(skill_dir))):
                    data = path.read_bytes()
                    reason = credential_scanner().finding_reason(data)
                    text = data.decode("utf-8", errors="replace")
                    if SECRET.search(text) or reason:
                        errors.append(f"{display_path(path)}: possible secret detected" + (f" ({reason})" if reason else ""))
                    if PRIVATE_PATH.search(text):
                        errors.append(f"{display_path(path)}: private absolute path detected")
                    if path.suffix.lower() == ".md" and path != skill_dir / "SKILL.md":
                        validate_links(path, text, skill_dir)
            except (OSError, RuntimeError) as error:
                errors.append(f"{display_path(path)}: cannot inspect file: {error}")
        directories[:] = [name for name in directories if name != "__pycache__" and not Path(directory, name).is_symlink()]
    validate_skill(skill_dir, expected_name)
    return errors[before:]


def _is_test_file(path: Path) -> bool:
    name = path.name
    if name.startswith(("test-", "test_")) or name == "conftest.py":
        return True
    return "tests" in path.parts


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--skill-dir", type=Path, help="validate one complete Skill directory")
    parser.add_argument("--name", help="expected name when importing a Skill")
    args = parser.parse_args(argv)
    if args.name and not args.skill_dir:
        parser.error("--name requires --skill-dir")
    errors.clear()
    if args.skill_dir:
        validate_skill_directory(args.skill_dir.absolute(), args.name)
        skill_dirs = [args.skill_dir]
    else:
        skill_dirs = sorted(path for path in SKILLS.iterdir() if path.is_dir()) if SKILLS.is_dir() else []
        for skill_dir in skill_dirs:
            validate_skill_directory(skill_dir)
    if not SKILLS.is_dir():
        if not args.skill_dir:
            print("ERROR: skills/ directory is missing", file=sys.stderr)
            return 1

    if not skill_dirs:
        print("ERROR: no skill directories found", file=sys.stderr)
        return 1

    for path in [] if args.skill_dir else get_files_to_scan():
        if path.resolve() == Path(__file__).resolve():
            continue
        if _is_test_file(path.relative_to(ROOT)):
            continue
        if path.suffix.lower() not in TEXT_SUFFIXES:
            continue
        text = path.read_text(encoding="utf-8", errors="replace")
        if SECRET.search(text):
            errors.append(f"{display_path(path)}: possible secret detected")
        if PRIVATE_PATH.search(text):
            errors.append(f"{display_path(path)}: private absolute path detected")

    if errors:
        for error in sorted(set(errors)):
            print(f"ERROR: {error}", file=sys.stderr)
        return 1

    print(f"Validated {len(skill_dirs)} skill(s).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
