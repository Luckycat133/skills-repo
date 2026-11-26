#!/usr/bin/env python3
"""Maintainer-only packaging; never reads or modifies user IDE configuration."""
from __future__ import annotations

import argparse
import hashlib
from pathlib import Path
import zipfile

ROOT = Path(__file__).resolve().parents[1]
SKILL = ROOT / "skills" / "agent-skills-setup"
EXECUTABLE_REL_PATHS = frozenset({
    "scripts/migrate_context.py",
})
REQUIRED_ROOT_FILES = frozenset({
    "LICENSE",
    "SKILL.md",
    "scripts/migrate_context.py",
    "references/products.md",
    "references/instructions.md",
    "references/mcp.md",
    "references/other-context.md",
    "references/device-transfer.md",
})


def _is_admitted_relpath(rel: str) -> bool:
    if rel in REQUIRED_ROOT_FILES:
        return True
    parts = Path(rel).parts
    return len(parts) >= 2 and parts[0] in ("references", "assets") and rel.endswith(".md")


def package_files(skill: Path = SKILL) -> list[Path]:
    if skill.is_symlink() or not skill.is_dir():
        raise ValueError("Skill root must be an ordinary directory")
    files = []
    for path in sorted(skill.rglob("*")):
        if path.is_symlink():
            raise ValueError(f"symlink is not allowed: {path}")
        if "__pycache__" in path.parts or path.suffix == ".pyc":
            raise ValueError(f"bytecode cache is not allowed in Skill package: {path}")
        if path.is_dir():
            continue
        if not path.is_file():
            raise ValueError(f"non-regular package entry: {path}")
        rel = path.relative_to(skill).as_posix()
        if not _is_admitted_relpath(rel):
            raise ValueError(f"unexpected package file: {rel}")
        files.append(path)
    actual = {p.relative_to(skill).as_posix() for p in files}
    missing = REQUIRED_ROOT_FILES - actual
    if missing:
        raise ValueError(f"missing required package files: {sorted(missing)}")
    return files


def build(output: Path, skill: Path = SKILL) -> str:
    files = package_files(skill)
    output = output.absolute()
    if output == skill.resolve() or skill.resolve() in output.resolve().parents:
        raise ValueError("Output must be outside the Skill source")
    if output.exists() or output.is_symlink():
        raise ValueError("Refusing to replace an existing output; choose a new path")
    if not output.parent.is_dir():
        raise ValueError("Output parent must already exist")
    created = False
    try:
        stream = output.open("xb")
        created = True
        with stream, zipfile.ZipFile(stream, "w", compression=zipfile.ZIP_DEFLATED) as archive:
            for path in files:
                rel = path.relative_to(skill).as_posix()
                info = zipfile.ZipInfo("agent-skills-setup/" + rel)
                info.date_time = (2026, 11, 7, 0, 0, 0)
                info.compress_type = zipfile.ZIP_DEFLATED
                mode = 0o100755 if rel in EXECUTABLE_REL_PATHS else 0o100644
                info.external_attr = mode << 16
                archive.writestr(info, path.read_bytes())
    except Exception:
        if created and output.is_file():
            output.unlink()
        raise
    return hashlib.sha256(output.read_bytes()).hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    try:
        digest = build(args.output)
    except (OSError, ValueError, zipfile.BadZipFile) as exc:
        parser.exit(1, f"ERROR: {exc}\n")
    print(f"{digest}  {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
