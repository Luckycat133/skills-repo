#!/usr/bin/env python3
"""Build and import validated Skill trees using isolated staging directories."""

from __future__ import annotations

import argparse
import errno
import hashlib
import json
import stat
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


def check_path_components(path: Path) -> None:
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


def checked_paths(source: Path, destination: Path, replace: bool) -> tuple[Path, Path]:
    for path in (source, destination):
        check_path_components(path)
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


def tree_state(path: Path) -> str | None:
    if not os.path.lexists(path):
        return None
    digest = hashlib.sha256()
    if path.is_symlink() or not path.is_dir():
        raise ValueError(f"expected a regular Skill directory: {path}")
    for entry in [path, *sorted(path.rglob("*"))]:
        if entry.is_symlink() or not (entry.is_file() or entry.is_dir()):
            raise ValueError(f"unsupported Skill entry: {entry}")
        digest.update(json.dumps([
            entry.relative_to(path).as_posix(), entry.is_dir(),
            stat.S_IMODE(entry.stat().st_mode),
            entry.stat().st_size if entry.is_file() else None,
        ]).encode("utf-8"))
        if entry.is_file():
            with entry.open("rb") as handle:
                for chunk in iter(lambda: handle.read(1024 * 1024), b""):
                    digest.update(chunk)
    return digest.hexdigest()


def install_recovery_container(destination: Path) -> Path:
    device = destination.parent.stat().st_dev
    for base in (destination.parent.parent, Path(tempfile.gettempdir())):
        check_path_components(base)
        if base != destination.parent and base.is_dir() and base.stat().st_dev == device:
            try:
                return Path(tempfile.mkdtemp(prefix=".skill-install-recovery-", dir=base))
            except OSError as error:
                if error.errno not in {errno.EACCES, errno.EROFS, errno.ENOENT}:
                    raise
                continue
    raise ValueError("no same-filesystem recovery directory outside live Skill root")


def recovery_path(destination: Path) -> Path:
    return destination.with_name(f".{destination.name}.install-recovery.json")


def recover_install(destination: Path) -> None:
    """Roll back an interrupted install, preserving unrecognized changes."""
    destination = destination.absolute()
    check_path_components(destination)
    journal_path = recovery_path(destination)
    if journal_path.is_symlink():
        raise ValueError("recovery journal cannot be a symbolic link")
    journal = json.loads(journal_path.read_text(encoding="utf-8"))
    if journal.get("destination") != str(destination):
        raise ValueError("recovery journal destination mismatch")
    backup = Path(journal["backup"]) if journal["backup"] else None
    if backup:
        check_path_components(backup)
        if backup.name != "previous" or not backup.parent.name.startswith(".skill-install-recovery-"):
            raise ValueError("invalid recovery backup path")
    current = tree_state(destination)
    if current not in (None, journal["before"], journal["after"]):
        raise ValueError("recovery refused: destination changed after interruption")
    if backup and tree_state(backup) != journal["before"]:
        # An interruption before the old tree was moved needs no backup.
        if current == journal["before"] and not os.path.lexists(backup):
            journal_path.unlink()
            return
        raise ValueError("recovery refused: backup missing or changed")
    if current != journal["before"]:
        container = install_recovery_container(destination)
        temporary = container / "restored"
        if backup:
            shutil.copytree(backup, temporary)
            if tree_state(temporary) != journal["before"]:
                raise ValueError("recovery copy does not match backup")
        if current is not None:
            os.replace(destination, container / "interrupted")
        if backup:
            os.replace(temporary, destination)
        shutil.rmtree(container)
    journal_path.unlink()


def install_staging(staging: Path, destination: Path, replace: bool) -> None:
    """Commit a staged tree with a persistent, explicit hard-exit recovery path."""
    staging, destination = staging.absolute(), destination.absolute()
    backup: Path | None = None
    journal_path = recovery_path(destination)
    if os.path.lexists(journal_path):
        raise ValueError(f"interrupted install: run skill_package.py recover {destination}")
    if os.path.lexists(destination):
        if not replace or destination.is_symlink() or not destination.is_dir():
            raise ValueError(f"destination changed while staging: {destination}")
        backup = install_recovery_container(destination) / "previous"
    journal = {"destination": str(destination), "backup": str(backup) if backup else None,
               "before": tree_state(destination), "after": tree_state(staging)}
    # O_EXCL serializes installs of this destination and preserves pending recovery.
    with journal_path.open("x", encoding="utf-8") as handle:
        json.dump(journal, handle)
        handle.flush()
        os.fsync(handle.fileno())
    try:
        if backup:
            os.replace(destination, backup)
        if os.path.lexists(destination):
            raise ValueError(f"destination changed while staging: {destination}")
        os.replace(staging, destination)
    except BaseException:
        recover_install(destination)
        if backup is not None and backup.exists():
            shutil.rmtree(backup.parent)
        raise
    # The new tree is committed. The backup can be cleaned independently.
    journal_path.unlink()
    if backup is not None:
        try:
            shutil.rmtree(backup.parent)
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
    recover = commands.add_parser("recover")
    recover.add_argument("destination", type=Path)
    version = commands.add_parser("version")
    version.add_argument("version")
    args = parser.parse_args()
    try:
        if args.command == "recover":
            recover_install(args.destination)
        elif args.command == "import":
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
