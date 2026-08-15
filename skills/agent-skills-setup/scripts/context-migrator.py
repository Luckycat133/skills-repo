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

    migrate = subparsers.add_parser(
        "migrate",
        help="One-sentence migration: detect → inventory → plan → apply → verify.",
    )
    common_workspace(migrate)
    migrate.add_argument("--source", required=True, help="<product>/<profile>")
    migrate.add_argument("--target", required=True, help="<product>/<profile>")
    migrate.add_argument(
        "--objects",
        default="all-portable",
        help=(
            "Comma-separated object list, 'all-portable' (default), or "
            "'all-inventory' (also records forbidden/generated items)."
        ),
    )
    migrate.add_argument(
        "--scope",
        default="user,project",
        help="user, project, user+project, all (all requires --yes)",
    )
    migrate.add_argument(
        "--plan-only", action="store_true", help="Stop after planning."
    )
    migrate.add_argument("--plan-out", type=Path)
    migrate.add_argument("--manifest-out", type=Path)
    migrate.add_argument("--verify-out", type=Path)
    migrate.add_argument("--yes", action="store_true")
    migrate.add_argument(
        "--include",
        dest="include_lossy",
        choices=("lossy",),
        help="Also apply ready-lossy items.",
    )
    migrate.add_argument(
        "--accept-loss",
        dest="accept_loss",
        default="",
        help="Comma-separated plan indices to apply as lossy.",
    )
    migrate.add_argument(
        "--strict",
        action="store_true",
        help="Reject plans containing any non-ready item.",
    )

    apply = subparsers.add_parser("apply")
    apply.add_argument("plan", type=Path)
    apply.add_argument("--registry", type=Path, default=REGISTRY_PATH)
    apply.add_argument("--manifest", type=Path)
    apply.add_argument("--yes", action="store_true")
    apply.add_argument("--json", action="store_true")
    apply.add_argument(
        "--apply-safe",
        dest="apply_safe",
        action="store_true",
        default=True,
        help="Apply ready and draft-disabled items; manifest the rest (default).",
    )
    apply.add_argument(
        "--no-apply-safe",
        dest="apply_safe",
        action="store_false",
        help="Disable safe apply; require every item to be ready.",
    )
    apply.add_argument(
        "--include",
        dest="include_lossy",
        choices=("lossy",),
        help="Include lossy items alongside ready items.",
    )
    apply.add_argument(
        "--accept-loss",
        dest="accept_loss",
        default="",
        help="Comma-separated plan indices to apply as lossy even without --include lossy.",
    )
    apply.add_argument(
        "--strict",
        action="store_true",
        help="Reject any plan containing a non-ready item (legacy semantics).",
    )

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


AUTOMATIC_OBJECT_TYPES = {"skills", "instructions", "mcp"}
INVENTORY_ONLY_OBJECT_TYPES = {
    "prompts",
    "commands",
    "workflows",
    "plugins",
    "agents",
    "modes",
    "personas",
    "hooks",
    "cron",
    "automation",
    "user_memory",
    "generated_memory",
    "cloud_knowledge",
    "config",
    "policy",
    "trust",
}


def resolve_objects(value: str) -> list[str]:
    """Translate --objects shorthand into an explicit object list."""
    tokens = [token.strip() for token in value.split(",") if token.strip()]
    if not tokens:
        return ["skills", "instructions", "mcp"]
    if tokens == ["all-portable"]:
        return ["skills", "instructions", "mcp"]
    if tokens == ["all-inventory"]:
        return [
            "skills",
            "instructions",
            "mcp",
            *sorted(INVENTORY_ONLY_OBJECT_TYPES),
        ]
    return tokens


def default_workspace_migration_dir(workspace: Path) -> Path:
    return workspace / ".migration"


def run_migrate(args: argparse.Namespace) -> int:
    """Orchestrate detect -> inventory -> plan -> apply -> verify."""
    workspace = args.workspace.resolve()
    registry = Registry(args.registry, workspace)

    # 1. detect --installed (informational; does not gate the run).
    detect_rows = [row for row in registry.inventory(None) if row.get("exists")]

    # 2. Resolve --objects.
    object_types = resolve_objects(args.objects)

    # Reject unsupported automatic object types unless all-inventory.
    unsupported = sorted(
        set(object_types) - AUTOMATIC_OBJECT_TYPES - INVENTORY_ONLY_OBJECT_TYPES
    )
    if unsupported:
        raise ValueError(
            "unsupported automatic objects: "
            + ", ".join(unsupported)
            + "; use --objects 'skills,instructions,mcp' or 'all-portable'"
        )
    # Inventory-only types only run as inventory metadata; the planner
    # already records them as manual-rebuild / forbidden items.
    auto_object_types = [
        obj for obj in object_types if obj in AUTOMATIC_OBJECT_TYPES
    ]

    # 3. scope handling: default user,project; full-disk 'all' requires --yes.
    scope = args.scope
    if scope == "all" and not args.yes:
        raise ValueError("--scope all requires --yes")
    if scope not in {"user", "project", "user,project", "all"}:
        raise ValueError(f"unsupported scope: {scope}")

    # 4. plan
    document = build_plan_document(
        registry, args.source, args.target, auto_object_types, scope,
    )

    # 5. save plan
    plan_out = (
        args.plan_out.resolve(strict=False)
        if args.plan_out
        else default_workspace_migration_dir(workspace) / "migrate-plan.json"
    )
    plan_out.parent.mkdir(parents=True, exist_ok=True)
    atomic_write(
        plan_out,
        json.dumps(document, indent=2, sort_keys=True) + "\n",
    )

    if args.plan_only:
        emit(
            {
                "ok": True,
                "stage": "plan",
                "plan": str(plan_out),
                "plan_sha256": document["plan_sha256"],
                "detected": detect_rows,
            },
            args.json,
        )
        return 0

    # 6. apply (re-load the saved plan so the apply path matches the
    # production flow exactly).
    plan_items, _ = validate_plan_document(document, registry)
    accept_loss_ids = {
        token.strip() for token in args.accept_loss.split(",") if token.strip()
    }
    default_manifest_out = (
        args.manifest_out.resolve(strict=False)
        if args.manifest_out
        else default_workspace_migration_dir(workspace) / "migrate-manifest.json"
    )
    manifest, manifest_path_out = apply_plan(
        plan_items,
        workspace,
        default_manifest_out,
        provenance={
            "plan_path": str(plan_out.resolve()),
            "plan_sha256": document["plan_sha256"],
            "registry_sha256": document["registry_sha256"],
            "adapter_versions": document["adapter_versions"],
            "git_provenance": document.get("git_provenance"),
        },
        apply_safe=True,
        include_lossy=(args.include_lossy == "lossy"),
        accept_loss_ids=accept_loss_ids,
        strict=args.strict,
    )

    # 7. verify
    errors = verify_manifest(manifest_path_out)
    verify_out = (
        args.verify_out.resolve(strict=False)
        if args.verify_out
        else default_workspace_migration_dir(workspace) / "migrate-verify.json"
    )
    verify_out.parent.mkdir(parents=True, exist_ok=True)
    atomic_write(
        verify_out,
        json.dumps(
            {
                "ok": not errors,
                "errors": errors,
                "manifest": str(manifest_path_out),
                "plan": str(plan_out),
            },
            indent=2,
            sort_keys=True,
        )
        + "\n",
    )

    emit(
        {
            "ok": not errors,
            "stage": "verify",
            "plan": str(plan_out),
            "manifest": str(manifest_path_out),
            "verify": str(verify_out),
            "summary": manifest.get("summary", {}),
            "errors": errors,
            "detected": detect_rows,
        },
        args.json,
    )
    return 0 if not errors else 1


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
        accept_loss_ids = {
            token.strip()
            for token in args.accept_loss.split(",")
            if token.strip()
        }
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
            apply_safe=args.apply_safe,
            include_lossy=(args.include_lossy == "lossy"),
            accept_loss_ids=accept_loss_ids,
            strict=args.strict,
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

    if args.command == "migrate":
        if not args.yes:
            raise ValueError(
                "migrate requires --yes after specifying source/target/objects"
            )
        return run_migrate(args)

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
