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
    atomic_write,
    build_plan_document,
    load_plan_document,
    paths_overlap,
    rollback_manifest,
    validate_plan_document,
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

    plan = subparsers.add_parser("plan")
    common_workspace(plan)
    plan.add_argument("--source", required=True)
    plan.add_argument("--target", required=True)
    plan.add_argument(
        "--objects", default="skills,instructions,mcp", help="comma-separated surfaces"
    )
    plan.add_argument(
        "--scope", choices=("user", "project", "local", "all"), default="project"
    )
    plan.add_argument("--output", type=Path)

    apply = subparsers.add_parser("apply")
    apply.add_argument("plan", type=Path)
    apply.add_argument("--registry", type=Path, default=REGISTRY_PATH)
    apply.add_argument("--manifest", type=Path)
    apply.add_argument("--yes", action="store_true")
    apply.add_argument("--json", action="store_true")

    verify = subparsers.add_parser("verify")
    verify.add_argument("--manifest", type=Path, required=True)
    verify.add_argument("--json", action="store_true")

    rollback = subparsers.add_parser("rollback")
    rollback.add_argument("--manifest", type=Path, required=True)
    rollback.add_argument("--yes", action="store_true")
    rollback.add_argument("--json", action="store_true")

    legacy = subparsers.add_parser(
        "legacy", help="run the explicit lookup and zero-write compatibility interface"
    )
    legacy.add_argument("legacy_args", nargs=argparse.REMAINDER)
    return parser


def selector(product: str | None, profile: str | None) -> str | None:
    if not product:
        if profile:
            raise ValueError("--profile requires --product")
        return None
    return f"{product}/{profile}" if profile else product


def reject_legacy_write(argv: list[str]) -> None:
    if "--yes" not in argv and "-y" not in argv:
        return
    raise ValueError(
        "legacy writes are disabled; create a saved plan with 'plan --output', "
        "then apply that exact plan file"
    )


def run_legacy_cli(argv: list[str]) -> int:
    reject_legacy_write(argv)
    environment = dict(os.environ)
    environment["AGENT_SKILLS_SETUP_INTERNAL_LEGACY"] = "1"
    completed = subprocess.run(
        ["bash", str(LEGACY_SCRIPT), *argv],
        check=False,
        env=environment,
    )
    return completed.returncode


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

    if args.command == "apply":
        if not args.yes:
            raise ValueError("apply requires --yes after reviewing the saved plan")
        document = load_plan_document(args.plan)
        workspace_value = document.get("workspace")
        if not isinstance(workspace_value, str) or not Path(workspace_value).is_absolute():
            raise ValueError("plan workspace must be an absolute path")
        registry = Registry(args.registry, Path(workspace_value))
        plan_items, _ = validate_plan_document(document, registry)
        manifest, manifest_path = apply_plan(
            plan_items,
            registry.workspace,
            args.manifest,
            provenance={
                "plan_path": str(args.plan.resolve()),
                "plan_sha256": document["plan_sha256"],
                "registry_sha256": document["registry_sha256"],
                "adapter_versions": document["adapter_versions"],
                "git_provenance": document.get("git_provenance"),
            },
        )
        emit(
            {
                "ok": True,
                "plan": str(args.plan),
                "plan_sha256": document["plan_sha256"],
                "manifest": str(manifest_path),
                "changes": manifest["changes"],
                "loss_report": manifest["loss_report"],
            },
            args.json,
        )
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
    document = build_plan_document(
        registry,
        args.source,
        args.target,
        object_types,
        args.scope,
    )
    if args.output:
        output_path = args.output.resolve(strict=False)
        protected_paths = [args.registry.resolve(strict=False)]
        for item in document["items"]:
            for side in ("source", "target"):
                surface = item.get(side)
                if isinstance(surface, dict) and isinstance(
                    surface.get("resolved_path"), str
                ):
                    protected_paths.append(Path(surface["resolved_path"]))
        if any(paths_overlap(output_path, path) for path in protected_paths):
            raise ValueError(
                "plan output overlaps the Registry or a planned source/target "
                f"surface: {output_path}"
            )
        atomic_write(
            output_path,
            json.dumps(document, indent=2, sort_keys=True) + "\n",
        )
    emit(document, args.json)
    return 0


def main() -> int:
    argv = sys.argv[1:]
    if not argv:
        create_parser().print_help()
        return 0
    if argv[0] == "legacy":
        try:
            return run_legacy_cli(argv[1:])
        except (OSError, ValueError, json.JSONDecodeError) as error:
            print(f"ERROR: {error}", file=sys.stderr)
            return 1
    if argv[0].startswith("-"):
        print(
            "ERROR: implicit legacy flags are disabled; use the explicit "
            "'legacy' subcommand for lookup or zero-write dry-run compatibility",
            file=sys.stderr,
        )
        return 2
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
