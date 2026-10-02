#!/usr/bin/env python3
"""Build and import validated Skill trees using isolated staging directories."""

from __future__ import annotations

import argparse
import importlib.util
import os
import shutil
import subprocess
import sys
import tempfile
import uuid
from pathlib import Path
from types import ModuleType

import validate_skills as validator

SCRIPT_DIR = Path(__file__).resolve().parent
RUNTIME_FILES = (
    "common.sh", "context-migrator.py", "ide-paths.tsv",
    "legacy-smart-ide-migration.sh", "migration_core.py",
    "scan-skill-secrets.py", "skill_secret_scanner.py", "smart-ide-migration.sh",
    "acb/__init__.py", "acb/bundle.py", "acb/key_security.py", "detect/__init__.py", "detect/probes.py",
    "registry/__init__.py", "registry/alias_resolver.py", "registry/exceptions.py",
)
CACHE_NAMES = {"__pycache__", ".pytest_cache", ".mypy_cache", ".ruff_cache", ".DS_Store"}


def ignored_artifacts(directory: str, names: list[str]) -> list[str]:
    return [
        name for name in names
        if name in CACHE_NAMES or name == ".env" or name.startswith(".env.") or name.endswith((".pyc", ".pyo"))
    ]


def validate_source(source: Path, name: str, *, include_test_files: bool = False) -> None:
    validator.errors.clear()
    findings = validator.validate_skill_directory(source, name, include_test_files=include_test_files)
    if findings:
        raise ValueError("Skill validation failed:\n" + "\n".join(sorted(set(findings))))


def checked_paths(source: Path, destination: Path, replace: bool) -> tuple[Path, Path]:
    for path in (source, destination):
        current = Path(path.anchor)
        for part in path.parts[1:]:
            current = current / part
            if not current.is_symlink():
                continue
            system_aliases = {
                Path("/tmp"): Path("/private/tmp"),
                Path("/var"): Path("/private/var"),
                Path("/etc"): Path("/private/etc"),
            }
            if sys.platform == "darwin" and current in system_aliases and current.resolve() == system_aliases[current]:
                continue
            raise ValueError(f"Skill path cannot traverse a symbolic link: {current}")
    if source.is_symlink() or not source.is_dir():
        raise ValueError(f"source Skill must be a regular directory: {source}")
    if destination.is_symlink() or destination.parent.is_symlink():
        raise ValueError(f"destination cannot be a symbolic link: {destination}")
    source = source.resolve()
    destination = destination.resolve()
    if source == destination or source in destination.parents or destination in source.parents:
        raise ValueError("source and destination Skill trees must not overlap")
    if os.path.lexists(destination) and (not replace or not destination.is_dir()):
        raise ValueError(f"package directory already exists or is not a directory: {destination}")
    return source, destination


def install_staging(staging: Path, destination: Path, replace: bool) -> None:
    """Commit a staged directory, restoring the old tree if the commit fails."""
    backup: Path | None = None
    if os.path.lexists(destination):
        if not replace or destination.is_symlink() or not destination.is_dir():
            raise ValueError(f"destination changed while staging: {destination}")
        backup = destination.with_name(f".{destination.name}.backup-{uuid.uuid4().hex}")
        os.replace(destination, backup)
    try:
        if os.path.lexists(destination):
            raise ValueError(f"destination changed while staging: {destination}")
        os.replace(staging, destination)
    except BaseException:
        if backup is not None:
            os.replace(backup, destination)
        raise
    if backup is not None:
        try:
            shutil.rmtree(backup)
        except OSError as error:
            print(f"WARN: installed Skill; old tree retained at {backup}: {error}", file=sys.stderr)


def import_skill(source: Path, destination: Path) -> None:
    source, destination = checked_paths(source, destination, replace=True)
    validate_source(source, destination.name)
    destination.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix=f".{destination.name}.stage-", dir=destination.parent) as temporary:
        staging = Path(temporary) / destination.name
        shutil.copytree(source, staging, symlinks=True, ignore=ignored_artifacts)
        validate_source(staging, destination.name)
        install_staging(staging, destination, replace=True)


def release_builder() -> ModuleType:
    spec = importlib.util.spec_from_file_location("clawhub_builder", SCRIPT_DIR / "build-clawhub-skill.py")
    if spec is None or spec.loader is None:
        raise ValueError("cannot load the ClawHub Skill builder")
    builder = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(builder)
    return builder


def stage_runtime(source: Path, destination: Path, version: str) -> None:
    builder = release_builder()
    if not builder.valid_version(version):
        raise ValueError(f"invalid release version: {version}")
    source, destination = checked_paths(source, destination, replace=False)
    validate_source(source, source.name)
    required = [source / "assets/LICENSE.clawhub", *(source / "scripts" / name for name in RUNTIME_FILES)]
    missing = [str(path.relative_to(source)) for path in required if not path.is_file() or path.is_symlink()]
    if missing:
        raise ValueError("missing runtime dependencies: " + ", ".join(missing))
    destination.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix=f".{destination.name}.stage-", dir=destination.parent) as temporary:
        staging = Path(temporary) / source.name
        staging.mkdir()
        shutil.copy2(source / "SKILL.md", staging / "SKILL.md")
        shutil.copy2(source / "assets/LICENSE.clawhub", staging / "LICENSE")
        for directory in ("assets", "references"):
            if (source / directory).is_dir():
                shutil.copytree(source / directory, staging / directory, symlinks=True, ignore=ignored_artifacts)
        for name in RUNTIME_FILES:
            target = staging / "scripts" / name
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source / "scripts" / name, target, follow_symlinks=False)
        # Validate the whitelist's link closure before the controlled ClawHub
        # frontmatter conversion, whose metadata intentionally differs from the SDK.
        validate_source(staging, source.name, include_test_files=True)
        text = (staging / "SKILL.md").read_text(encoding="utf-8")
        frontmatter, body = builder.split_skill(text)
        rendered = "---\n" + "\n".join(builder.build_frontmatter(frontmatter, version))
        (staging / "SKILL.md").write_text(rendered + "\n---\n" + body.lstrip("\n"), encoding="utf-8")
        smoke = subprocess.run(
            [sys.executable, "-I", "-B", str(staging / "scripts/context-migrator.py"), "--help"],
            cwd=staging, capture_output=True, text=True,
        )
        if smoke.returncode:
            raise ValueError("staged migration CLI failed its isolated smoke check:\n" + smoke.stderr.strip())
        install_staging(staging, destination, replace=False)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    for name in ("import", "stage"):
        command = commands.add_parser(name)
        command.add_argument("source", type=Path)
        command.add_argument("destination", type=Path)
        if name == "stage":
            command.add_argument("version")
    version = commands.add_parser("version")
    version.add_argument("version")
    args = parser.parse_args()
    try:
        if args.command == "import":
            import_skill(args.source.absolute(), args.destination.absolute())
        elif args.command == "stage":
            stage_runtime(args.source.absolute(), args.destination.absolute(), args.version)
        elif not release_builder().valid_version(args.version):
            raise ValueError(f"invalid release version: {args.version}")
    except (OSError, ValueError, shutil.Error) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
