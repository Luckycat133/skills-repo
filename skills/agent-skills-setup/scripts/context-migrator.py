#!/usr/bin/env python3
"""Safe profile-aware CLI for agent context migration."""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from pathlib import Path
from typing import Any

from migration_core import (
    KNOWN_COMMANDS,
    Registry,
    apply_plan,
    build_plan,
    rollback_manifest,
    verify_manifest,
)


SCRIPT_DIR = Path(__file__).resolve().parent
REGISTRY_PATH = SCRIPT_DIR.parent / "references" / "registry-v2.json"
LEGACY_SCRIPT = SCRIPT_DIR / "legacy-smart-ide-migration.sh"


def emit(value: Any, as_json: bool) -> None:
    if as_json:
        print(json.dumps(value, indent=2, sort_keys=True))
        return
    if isinstance(value, list):
        for row in value:
            print(json.dumps(row, sort_keys=True))
    elif isinstance(value, dict):
        print(json.dumps(value, indent=2, sort_keys=True))
    else:
        print(value)


def common_workspace(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--workspace", type=Path, default=Path.cwd())
    parser.add_argument("--registry", type=Path, default=REGISTRY_PATH)
    parser.add_argument("--json", action="store_true")


def create_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Inventory, plan, apply, verify, and roll back agent context migrations."
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    detect = subparsers.add_parser("detect")
    common_workspace(detect)
    detect.add_argument("--product")
    detect.add_argument("--profile")

    inventory = subparsers.add_parser("inventory")
    common_workspace(inventory)
    inventory.add_argument("--product")
    inventory.add_argument("--profile")

    for command in ("plan", "apply"):
        subparser = subparsers.add_parser(command)
        common_workspace(subparser)
        subparser.add_argument("--source", required=True)
        subparser.add_argument("--target", required=True)
        subparser.add_argument(
            "--objects", default="skills,instructions,mcp", help="comma-separated surfaces"
        )
        subparser.add_argument(
            "--scope", choices=("user", "project", "all"), default="project"
        )
        if command == "apply":
            subparser.add_argument("--yes", action="store_true")
            subparser.add_argument("--manifest", type=Path)

    verify = subparsers.add_parser("verify")
    verify.add_argument("--manifest", type=Path, required=True)
    verify.add_argument("--json", action="store_true")

    rollback = subparsers.add_parser("rollback")
    rollback.add_argument("--manifest", type=Path, required=True)
    rollback.add_argument("--yes", action="store_true")
    rollback.add_argument("--json", action="store_true")
    return parser


def selector(product: str | None, profile: str | None) -> str | None:
    if not product:
        if profile:
            raise ValueError("--profile requires --product")
        return None
    return f"{product}/{profile}" if profile else product


def run_new_cli(argv: list[str]) -> int:
    args = create_parser().parse_args(argv)
    if args.command == "verify":
        errors = verify_manifest(args.manifest)
        result = {"ok": not errors, "errors": errors, "manifest": str(args.manifest)}
        emit(result, args.json)
        return 0 if not errors else 1
    if args.command == "rollback":
        if not args.yes:
            raise ValueError("rollback requires --yes")
        restored = rollback_manifest(args.manifest)
        emit({"ok": True, "restored": restored}, args.json)
        return 0

    registry = Registry(args.registry, args.workspace)
    if args.command in {"detect", "inventory"}:
        selected = selector(args.product, args.profile)
        rows = registry.inventory(selected)
        if args.command == "detect":
            rows = [row for row in rows if row.get("exists")]
        emit(rows, args.json)
        return 0

    object_types = [item.strip() for item in args.objects.split(",") if item.strip()]
    unsupported = sorted(set(object_types) - {"skills", "instructions", "mcp"})
    if unsupported:
        raise ValueError(f"unsupported automatic objects: {', '.join(unsupported)}")
    plan, projected_loss = build_plan(
        registry,
        args.source,
        args.target,
        object_types,
        args.scope,
    )
    result = {
        "source": args.source,
        "target": args.target,
        "scope": args.scope,
        "items": [item.to_dict() for item in plan],
        "loss_report": projected_loss.to_dict(),
    }
    if args.command == "plan":
        emit(result, args.json)
        return 0
    if not args.yes:
        raise ValueError("apply requires --yes after reviewing plan output")
    manifest, manifest_path = apply_plan(plan, registry.workspace, args.manifest)
    result["manifest"] = str(manifest_path)
    result["changes"] = manifest["changes"]
    result["loss_report"] = manifest["loss_report"]
    emit(result, args.json)
    return 0


def main() -> int:
    argv = sys.argv[1:]
    if not argv:
        create_parser().print_help()
        return 0
    if argv[0] not in KNOWN_COMMANDS and argv[0].startswith("-"):
        completed = subprocess.run(["bash", str(LEGACY_SCRIPT), *argv], check=False)
        return completed.returncode
    if argv[0] not in KNOWN_COMMANDS:
        print(f"ERROR: unknown command: {argv[0]}", file=sys.stderr)
        return 2
    try:
        return run_new_cli(argv)
    except (OSError, ValueError, json.JSONDecodeError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
