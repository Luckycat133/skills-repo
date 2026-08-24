#!/usr/bin/env python3
"""Safe profile-aware CLI for agent context migration."""

from __future__ import annotations

import argparse
import contextlib
import hashlib
import io
import json
import os
import shutil
import subprocess
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

_SCRIPT_DIR = str(Path(__file__).resolve().parent)
if _SCRIPT_DIR not in sys.path:
    sys.path.insert(0, _SCRIPT_DIR)

from migration_core import (
    ADAPTER_VERSIONS,
    KNOWN_COMMANDS,
    Registry,
    apply_plan,
    atomic_write,
    build_plan,
    build_plan_document,
    choose_surface,
    git_provenance,
    hash_path,
    json_sha256,
    load_plan_document,
    paths_overlap,
    rollback_manifest,
    validate_plan_document,
    verify_manifest,
    _plan_hash_payload,
)

from acb.bundle import (
    ACB_CHECKSUMS_NAME,
    ACB_OBJECTS_DIR,
    ACB_SCHEMA_VERSION,
    ACBManifest,
    ACBSecretLeak,
    collect_reauth,
    collect_rebuild,
    collect_requirements,
    collect_source_objects,
    load_manifest,
    make_bundle_id,
    restore_bundle_objects,
    verify_bundle,
    write_bundle,
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
        help="One-sentence migration: detect -> inventory -> plan -> apply -> verify.",
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

    migrate.add_argument(
        "--include-session",
        dest="include_session",
        action="store_true",
        help=(
            "Explicitly opt in to handoff/session transfer "
            "(whitelisted fields only: reviewed summary, git branch, "
            "selected file list, reviewed patch)."
        ),
    )
    apply = subparsers.add_parser("apply")
    apply.add_argument("plan", type=Path)
    apply.add_argument("--registry", type=Path, default=REGISTRY_PATH)
    apply.add_argument("--manifest", type=Path)
    apply.add_argument(
        "--bundle",
        type=Path,
        help="Path to .acb bundle archive for bundle-backed restore plans.",
    )
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

    apply.add_argument(
        "--include-session",
        dest="include_session",
        action="store_true",
        help=(
            "Explicitly opt in to handoff/session transfer for replayed "
            "plans (whitelisted fields only)."
        ),
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

    snapshot = subparsers.add_parser(
        "snapshot",
        help="Capture a portable Agent Context Bundle (ACB) of the current device.",
    )
    common_workspace(snapshot)
    snapshot.add_argument("--output", type=Path, help="Bundle output directory (default: <workspace>/device.acb).")
    snapshot.add_argument("--source", default="cline/ide")
    snapshot.add_argument("--target", default="forge/cli")
    snapshot.add_argument("--scope", default="user,project")
    snapshot.add_argument(
        "--all-installed",
        action="store_true",
        help="Snapshot all detected and installed products on this device.",
    )

    verify_bundle = subparsers.add_parser(
        "bundle-verify",
        help="Verify checksums inside an ACB directory.",
    )
    verify_bundle.add_argument("bundle", type=Path)
    verify_bundle.add_argument("--json", action="store_true", default=True)

    restore = subparsers.add_parser(
        "restore",
        help="Verify an ACB and rebuild a local restore plan against the current device.",
    )
    common_workspace(restore)
    restore.add_argument("bundle", type=Path)
    restore.add_argument("--source", default="cline/ide")
    restore.add_argument("--target", default="forge/cli")
    restore.add_argument("--scope", default="user,project")
    restore.add_argument(
        "--all-installed",
        action="store_true",
        help="Restore context across all detected and installed target products.",
    )
    restore.add_argument("--plan-out", type=Path)
    restore.add_argument(
        "--plan-in",
        "--plan",
        dest="plan_in",
        type=Path,
        help="Replay a previously reviewed plan document.",
    )
    restore.add_argument("--manifest-out", type=Path)
    restore.add_argument("--apply-safe", action="store_true", default=True)
    restore.add_argument(
        "--no-apply-safe", dest="apply_safe", action="store_false"
    )
    restore.add_argument(
        "--include", dest="include_lossy", choices=("lossy",),
    )
    restore.add_argument("--strict", action="store_true")
    restore.add_argument("--yes", action="store_true")
    restore.add_argument(
        "--plan-only",
        action="store_true",
        help="Build and review restore plan without applying to target surfaces.",
    )
    restore.add_argument(
        "--restore-root",
        type=Path,
        help="Destination tree for bundle/objects/ restore (default: <workspace>/.acb-restored).",
    )
    restore.add_argument(
        "--allow-noop",
        action="store_true",
        help="Allow restore to succeed with zero applied items (otherwise a bundle that resolves no eligible items is a hard failure).",
    )
    restore.add_argument(
        "--dry-run",
        action="store_true",
        help="Plan and stage objects/ without writing.",
    )

    doctor = subparsers.add_parser(
        "doctor",
        help="Inspect an ACB and surface missing executables / re-auth actions.",
    )
    doctor.add_argument("bundle", type=Path)
    doctor.add_argument("--json", action="store_true", default=True)
    return parser


def selector(product: str | None, profile: str | None) -> str | None:
    if not product:
        if profile:
            raise ValueError("--profile requires --product")
        return None
    return f"{product}/{profile}" if profile else product


def reject_legacy_write(argv: list[str]) -> None:
    """Enforce the legacy subcommand as strictly read-only.

    The guarantee is structural, not flag filtering (audit SDI-4 /
    AST4): only the documented read-only modes --print-path and
    --dry-run are allowed through to the legacy engine at all.  Any
    other invocation — with or without --yes — is refused here.
    """
    if "--yes" in argv or "-y" in argv:
        raise ValueError(
            "legacy writes are disabled; create a saved plan with 'plan --output', "
            "then apply that exact plan file"
        )
    if not argv or "--help" in argv or "-h" in argv:
        return
    readonly = "--print-path" in argv or "--dry-run" in argv
    if not readonly:
        raise ValueError(
            "legacy subcommand is read-only lookup compatibility only: "
            "pass --print-path <ide> <object> or --dry-run. "
            "Use 'plan' / 'apply' for migrations."
        )


AUTOMATIC_OBJECT_TYPES = {"skills", "instructions", "mcp"}
INVENTORY_ONLY_OBJECT_TYPES = {
    "prompts",
    "commands",
    "workflows",
    "plugins",
    "handoff",
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


def run_detection(args: argparse.Namespace) -> int:
    """Run per-product detection probes against the local device.

    Uses the Registry v2 ``detection`` block on each profile (binary,
    file-signature, app-bundle). Detection is PROBE-ONLY: inventory.exists
    is NOT used as a fallback to claim "installed" (audit P0-3).
    Returns one ``InstallState`` per profile.
    """
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    from detect.probes import (
        detect_profile,
        detect_product,
        probe_binary,
        probe_file_signature,
        InstallState,
    )
    workspace = args.workspace.resolve()
    registry = Registry(args.registry, workspace)
    home = registry.home
    profiles_to_check: set[tuple[str, str]] = set()
    for product_id, product in registry.products.items():
        for profile_id in product.get("profiles", {}):
            profiles_to_check.add((product_id, profile_id))

    filter_prod = getattr(args, "product", None)
    filter_prof = getattr(args, "profile", None)
    if filter_prod:
        profiles_to_check = {p for p in profiles_to_check if p[0] == filter_prod}
    if filter_prof:
        profiles_to_check = {p for p in profiles_to_check if p[1] == filter_prof}

    detections: list[dict[str, str]] = []
    for product_id, profile_id in sorted(profiles_to_check):
        product = registry.products[product_id]
        profile = product["profiles"][profile_id]
        detection = profile.get("detection", []) or []
        profile_state = InstallState.NOT_DETECTED
        profile_evidence: list[str] = []
        for probe in detection:
            if not isinstance(probe, dict):
                continue
            kind = probe.get("type")
            if kind == "binary":
                names = probe.get("command") or probe.get("binaries") or []
                version_command = probe.get("version_command")
                if isinstance(names, str):
                    names = [names]
                result = probe_binary(
                    product_id, profile_id, names,
                    version_command=version_command,
                )
                # Use the most definitive state across all probes for this profile
                # Priority: INSTALLED > CONFIGURED_ONLY > COMPATIBILITY_ONLY > CLOUD_CONNECTED > LEGACY > AMBIGUOUS > NOT_DETECTED
                if result.state.value == "installed":
                    profile_state = InstallState.INSTALLED
                    profile_evidence.extend(result.evidence)
                    break  # INSTALLED is definitive
                elif result.state.value == "configured-only" and profile_state not in (InstallState.INSTALLED,):
                    profile_state = InstallState.CONFIGURED_ONLY
                    profile_evidence.extend(result.evidence)
                elif result.state.value == "compatibility-only" and profile_state not in (InstallState.INSTALLED, InstallState.CONFIGURED_ONLY):
                    profile_state = InstallState.COMPATIBILITY_ONLY
                    profile_evidence.extend(result.evidence)
                elif result.state.value == "cloud-connected" and profile_state not in (InstallState.INSTALLED, InstallState.CONFIGURED_ONLY, InstallState.COMPATIBILITY_ONLY):
                    profile_state = InstallState.CLOUD_CONNECTED
                    profile_evidence.extend(result.evidence)
                elif result.state.value == "legacy" and profile_state not in (InstallState.INSTALLED, InstallState.CONFIGURED_ONLY, InstallState.COMPATIBILITY_ONLY, InstallState.CLOUD_CONNECTED):
                    profile_state = InstallState.LEGACY
                    profile_evidence.extend(result.evidence)
                elif result.state.value == "ambiguous" and profile_state == InstallState.NOT_DETECTED:
                    profile_state = InstallState.AMBIGUOUS
                    profile_evidence.extend(result.evidence)
                # NOT_DETECTED doesn't change anything
            elif kind == "file-signature":
                paths = probe.get("paths") or []
                result = probe_file_signature(
                    product_id, profile_id, paths,
                    workspace=workspace, home=home,
                )
                if result.state.value == "installed":
                    profile_state = InstallState.INSTALLED
                    profile_evidence.extend(result.evidence)
                    break
                elif result.state.value == "configured-only" and profile_state not in (InstallState.INSTALLED,):
                    profile_state = InstallState.CONFIGURED_ONLY
                    profile_evidence.extend(result.evidence)
                elif result.state.value == "compatibility-only" and profile_state not in (InstallState.INSTALLED, InstallState.CONFIGURED_ONLY):
                    profile_state = InstallState.COMPATIBILITY_ONLY
                    profile_evidence.extend(result.evidence)
                elif result.state.value == "cloud-connected" and profile_state not in (InstallState.INSTALLED, InstallState.CONFIGURED_ONLY, InstallState.COMPATIBILITY_ONLY):
                    profile_state = InstallState.CLOUD_CONNECTED
                    profile_evidence.extend(result.evidence)
                elif result.state.value == "legacy" and profile_state not in (InstallState.INSTALLED, InstallState.CONFIGURED_ONLY, InstallState.COMPATIBILITY_ONLY, InstallState.CLOUD_CONNECTED):
                    profile_state = InstallState.LEGACY
                    profile_evidence.extend(result.evidence)
                elif result.state.value == "ambiguous" and profile_state == InstallState.NOT_DETECTED:
                    profile_state = InstallState.AMBIGUOUS
                    profile_evidence.extend(result.evidence)
            elif kind == "app-bundle":
                result = detect_product(
                    product_id, profile_id,
                    app_bundle_id=probe.get("darwin_bundle_id"),
                )
                if result.state.value == "installed":
                    profile_state = InstallState.INSTALLED
                    profile_evidence.extend(result.evidence)
                    break
                elif result.state.value == "configured-only" and profile_state not in (InstallState.INSTALLED,):
                    profile_state = InstallState.CONFIGURED_ONLY
                    profile_evidence.extend(result.evidence)
                elif result.state.value == "compatibility-only" and profile_state not in (InstallState.INSTALLED, InstallState.CONFIGURED_ONLY):
                    profile_state = InstallState.COMPATIBILITY_ONLY
                    profile_evidence.extend(result.evidence)
                elif result.state.value == "cloud-connected" and profile_state not in (InstallState.INSTALLED, InstallState.CONFIGURED_ONLY, InstallState.COMPATIBILITY_ONLY):
                    profile_state = InstallState.CLOUD_CONNECTED
                    profile_evidence.extend(result.evidence)
                elif result.state.value == "legacy" and profile_state not in (InstallState.INSTALLED, InstallState.CONFIGURED_ONLY, InstallState.COMPATIBILITY_ONLY, InstallState.CLOUD_CONNECTED):
                    profile_state = InstallState.LEGACY
                    profile_evidence.extend(result.evidence)
                elif result.state.value == "ambiguous" and profile_state == InstallState.NOT_DETECTED:
                    profile_state = InstallState.AMBIGUOUS
                    profile_evidence.extend(result.evidence)
            # Other probe types (vscode-extension, schema-probe, cloud-account, environment)
            # are declared in Registry but not yet implemented in probes.py

        # Targeted fallback: check inventory for workspace-relative paths only.
        # Home-relative paths (user-scoped) are covered by probes; workspace-relative
        # paths (project-scoped) may not have probes but are valid installations.
        # This avoids the old bug where inventory.exists claimed "installed" for
        # shared/compatibility-only paths like AGENTS.md or .agents/skills.
        if profile_state is InstallState.NOT_DETECTED:
            rows = registry.inventory(f"{product_id}/{profile_id}")
            for row in rows:
                if not row.get("exists"):
                    continue
                resolved = row.get("resolved_path")
                if not resolved:
                    continue
                resolved_path = Path(resolved)
                # Only claim INSTALLED if the path is under workspace (project-scoped)
                # and NOT under home (user-scoped). Home paths should be caught by probes.
                try:
                    is_under_workspace = resolved_path.is_relative_to(workspace)
                    is_under_home = resolved_path.is_relative_to(home)
                except ValueError:
                    is_under_workspace = False
                    is_under_home = False
                if is_under_workspace and not is_under_home:
                    # Check if this is a shared/compatibility path
                    c_path = row.get("canonical_path", "")
                    role = row.get("location_role", "canonical")
                    if c_path in ("AGENTS.md", ".agents/skills", ".agents") or role != "canonical":
                        profile_state = InstallState.COMPATIBILITY_ONLY
                    else:
                        profile_state = InstallState.INSTALLED
                    profile_evidence.append(f"inventory:{row.get('object_type')}:{c_path}")
                    break

        detections.append(
            {
                "product": product_id,
                "profile": profile_id,
                "state": profile_state.value,
                "evidence": profile_evidence,
            }
        )
    emit(
        {
            "ok": True,
            "stage": "detect",
            "platform": sys.platform,
            "home": str(home),
            "detections": detections,
        },
        args.json,
    )
    return 0


def run_snapshot(args: argparse.Namespace) -> int:
    """Capture a portable ACB snapshot of the current device.

    Strict Snapshot Allowlist (audit P0-2):
    - Collects only the requested source product/profile and requested scope(s).
    - Collects only portable object types (skills, instructions, mcp) in the migration plan.
    - Strictly rejects forbidden-regenerate, never-migrate, session, chat, runtime,
      database, generated memory, and trust/credential stores.
    """
    workspace = args.workspace.resolve()
    registry = Registry(args.registry, workspace)
    bundle_root = (args.output or workspace / "device.acb").resolve(strict=False)
    inventory_rows = registry.inventory(None)
    detect_rows = [row for row in inventory_rows if row.get("exists")]

    requested_scopes = {
        s.strip().lower()
        for s in (args.scope or "user,project").split(",")
        if s.strip()
    }
    if "all" in requested_scopes:
        requested_scopes = {"user", "project", "local"}
    allowed_object_types = set(
        resolve_objects(getattr(args, "objects", "skills,instructions,mcp"))
    )

    all_installed = getattr(args, "all_installed", False) or args.source in ("auto", "all-installed")
    source_product, source_profile = (
        (None, None)
        if all_installed
        else (args.source.split("/", 1) if "/" in args.source else (args.source, None))
    )

    if all_installed:
        # Auto-orchestrate snapshot across all detected and installed products.
        #
        # Audit P0-3 (0.8.27): detection result is the SINGLE source of truth.
        # inventory_rows.exists must NEVER be used as a fallback to claim
        # "installed" — that previously masked failing detection probes and
        # produced bundles that claimed to contain a product with no files.
        from detect.probes import detect_profile, InstallState
        detected_selectors: set[str] = set()  # "product/profile" pairs
        detection_status: dict[str, str] = {}  # "product/profile" -> state
        for prod_id, prod in registry.products.items():
            for prof_id, prof in prod.get("profiles", {}).items():
                detection = prof.get("detection", []) or []
                profile_state = InstallState.NOT_DETECTED
                profile_evidence: list[str] = []
                for probe in detection:
                    if not isinstance(probe, dict):
                        continue
                    paths = probe.get("paths", [])
                    binaries = probe.get("command") or probe.get("binaries") or []
                    if isinstance(binaries, str):
                        binaries = [binaries]
                    res = detect_profile(
                        prod_id,
                        prof_id,
                        binaries=binaries,
                        file_signatures=paths,
                        home=registry.home,
                        workspace=workspace,
                        app_bundle_id=probe.get("darwin_bundle_id"),
                    )
                    # Use the most definitive state across all probes for this profile
                    # Priority: INSTALLED > CONFIGURED_ONLY > COMPATIBILITY_ONLY > CLOUD_CONNECTED > LEGACY > AMBIGUOUS > NOT_DETECTED
                    if res.state.value == "installed":
                        profile_state = InstallState.INSTALLED
                        profile_evidence.extend(res.evidence)
                        break  # INSTALLED is definitive
                    elif res.state.value == "configured-only" and profile_state not in (InstallState.INSTALLED,):
                        profile_state = InstallState.CONFIGURED_ONLY
                        profile_evidence.extend(res.evidence)
                    elif res.state.value == "compatibility-only" and profile_state not in (InstallState.INSTALLED, InstallState.CONFIGURED_ONLY):
                        profile_state = InstallState.COMPATIBILITY_ONLY
                        profile_evidence.extend(res.evidence)
                    elif res.state.value == "cloud-connected" and profile_state not in (InstallState.INSTALLED, InstallState.CONFIGURED_ONLY, InstallState.COMPATIBILITY_ONLY):
                        profile_state = InstallState.CLOUD_CONNECTED
                        profile_evidence.extend(res.evidence)
                    elif res.state.value == "legacy" and profile_state not in (InstallState.INSTALLED, InstallState.CONFIGURED_ONLY, InstallState.COMPATIBILITY_ONLY, InstallState.CLOUD_CONNECTED):
                        profile_state = InstallState.LEGACY
                        profile_evidence.extend(res.evidence)
                    elif res.state.value == "ambiguous" and profile_state == InstallState.NOT_DETECTED:
                        profile_state = InstallState.AMBIGUOUS
                        profile_evidence.extend(res.evidence)
                    # NOT_DETECTED doesn't change anything
                selector = f"{prod_id}/{prof_id}"
                detection_status[selector] = profile_state.value
                if profile_state in (
                    InstallState.INSTALLED,
                    InstallState.CONFIGURED_ONLY,
                    InstallState.COMPATIBILITY_ONLY,
                ):
                    detected_selectors.add(selector)

        plan_rows: list[dict[str, Any]] = []
        failed_products: list[dict[str, str]] = []
        for selector in sorted(detected_selectors):
            try:
                doc = build_plan_document(
                    registry,
                    selector,
                    args.target or "forge/cli",
                    sorted(allowed_object_types),
                    args.scope,
                )
                plan_rows.extend(doc.get("items", []))
            except Exception as error:
                # Audit P1-2: never silently swallow per-product plan build
                # failures. Capture and surface them so the snapshot summary
                # can report parse_failed / plan_failed per product.
                failed_products.append({"selector": selector, "error": str(error)})
                print(
                    f"WARNING: failed to build plan for {selector}: {error}",
                    file=sys.stderr,
                )
    else:
        document = build_plan_document(
            registry,
            args.source or "cline/ide",
            args.target or "forge/cli",
            sorted(allowed_object_types),
            args.scope,
        )
        plan_rows = document.get("items", [])
    installed_products_list = (
            sorted(detected_selectors)
            if all_installed
            else sorted({row["product"] for row in detect_rows})
        )
    inventory_summary = {
        "installed_products": installed_products_list,
        "surface_count": sum(
            1 for row in inventory_rows if row.get("object_type")
        ),
        "detection_status": detection_status if all_installed else {},
        "failed_products": failed_products if all_installed else [],
    }

    # Only include authorized, planned objects in manifest
    manifest_objects = []
    for item in plan_rows:
        surface_type = item.get("object_type", "")
        item_scope = (item.get("source") or {}).get("scope", "")
        if surface_type not in allowed_object_types:
            continue
        if requested_scopes and item_scope not in requested_scopes:
            continue
        manifest_objects.append(
            {
                "object_id": item.get("object_id", ""),
                "product": (item.get("source") or {}).get("product", ""),
                "profile": (item.get("source") or {}).get("profile", ""),
                "surface": surface_type,
                "scope": item_scope,
                "status": item.get("status", ""),
                "reason": item.get("reason", ""),
                "secret_status": "clean",
            }
        )

    manifest = ACBManifest(
        schema_version=ACB_SCHEMA_VERSION,
        bundle_id=make_bundle_id(),
        created_at=datetime.now(timezone.utc).isoformat(),
        source_platform={
            "system": sys.platform,
            "python": sys.version.split()[0],
        },
        inventory_summary=inventory_summary,
        objects=manifest_objects,
    )
    # Copy source files under objects/ using strict allowlist (audit P0-2 & 0.8.25).
    if not all_installed:
        source_product, source_profile = (
            args.source.split("/", 1) if "/" in args.source else (args.source, None)
        )
    else:
        source_product, source_profile = None, None

    collect_summary = {"captured": 0, "manual_rebuild": 0, "excluded_by_policy": 0, "parse_failed": 0, "secret_rejected": 0, "conflict": 0}
    try:
        objects_dir_files, collect_summary = collect_source_objects(
            registry,
            inventory_rows,
            home=registry.home,
            workspace=workspace,
            source_product=source_product,
            source_profile=source_profile,
            allowed_scopes=requested_scopes,
            allowed_object_types=allowed_object_types,
            plan_items=plan_rows,
        )
    except ACBError as error:
        # Parse failure during object collection - emit failure with summary
        inventory_summary["collection_summary"] = collect_summary
        emit(
            {
                "ok": False,
                "stage": "snapshot",
                "error": str(error),
                "summary": inventory_summary,
            },
            args.json,
        )
        return 1

    # compatibility: source_product x target_product matrix sourced from
    # Registry v2 support_level, not just the product list. Audit P1-7:
    # the previous "products: [...]" shape was a placeholder, not a
    # matrix. This is conservative: only include pairs that the Registry
    # explicitly advertises as bidirectional-reviewed (the surface
    # support level that ACB restore will actually attempt).
    compatibility_products = sorted(registry.products.keys())
    compatibility_pairs: list[dict[str, str]] = []
    for src in compatibility_products:
        src_product = registry.products.get(src, {})
        src_default_profile = src_product.get("default_profile", "cli")
        for tgt in compatibility_products:
            if src == tgt:
                continue
            tgt_product = registry.products.get(tgt, {})
            tgt_default_profile = tgt_product.get("default_profile", "cli")
            try:
                # Silently resolve: the matrix walks every product pair, and
                # Registry._log_resolution would otherwise spam one alias line
                # per call (O(N^2) stderr noise during snapshot).
                buffer = io.StringIO()
                with contextlib.redirect_stderr(buffer):
                    src_profile_data = registry.profile(f"{src}/{src_default_profile}")
                    tgt_profile_data = registry.profile(f"{tgt}/{tgt_default_profile}")
            except Exception as error:
                print(f"WARNING: failed to get profile for compatibility pair {src}->{tgt}: {error}", file=sys.stderr)
                continue
            # profile() returns (resolved_product, resolved_profile, profile_data)
            src_profile = src_profile_data[2] if len(src_profile_data) > 2 else {}
            tgt_profile = tgt_profile_data[2] if len(tgt_profile_data) > 2 else {}
            src_support = src_profile.get("support_level")
            tgt_support = tgt_profile.get("support_level")
            if src_support == "bidirectional-reviewed" and tgt_support == "bidirectional-reviewed":
                compatibility_pairs.append({
                    "source": src,
                    "target": tgt,
                    "supported": True,
                    "evidence": src_profile.get("evidence"),
                })
    compatibility = {
        "schema_version": 2,
        "matrix_kind": "source_x_target_bidirectional_reviewed",
        "products": compatibility_products,
        "pairs": compatibility_pairs,
    }

    requirements, requirements_summary = collect_requirements(
        inventory_rows, plan_rows, objects_dir_files=objects_dir_files
    )
    reauth = collect_reauth(plan_rows)
    rebuild = collect_rebuild(plan_rows)
    # secrets_required: each entry is a non-secret description of a
    # credential the user must re-supply on the target device. The name
    # is derived from the MCP server's command / package, not the
    # object_id. The shape is designed so doctor / human readers can
    # understand "what credential" without inspecting the bundle.
    secrets_required = []
    for action in reauth:
        obj_id = action.get("object_id", "")
        # Audit P1-7: surface credential names instead of object IDs.
        # Derive a stable, human-readable name from the package/command
        # when possible, falling back to the object_id only when no
        # better signal is available.
        package = (
            action.get("source", {}).get("package")
            or action.get("source", {}).get("command")
            or ""
        )
        if package:
            cred_name = f"{package}::credential"
        else:
            cred_name = obj_id or "unknown-credential"
        secrets_required.append({
            "name": cred_name,
            "used_by": [obj_id] if obj_id else [],
            "recommended_storage": "environment-or-keychain",
        })
    try:
        write_bundle(
            bundle_root=bundle_root,
            manifest=manifest,
            inventory_rows=inventory_rows,
            compatibility=compatibility,
            requirements=requirements,
            secrets_required=secrets_required,
            reauth=reauth,
            rebuild=rebuild,
            objects_dir_files=objects_dir_files,
            adapter_versions=ADAPTER_VERSIONS,
        )
    except ACBSecretLeak as error:
        print(f"ERROR: ACB secret leak: {error}", file=sys.stderr)
        return 1
    emit(
        {
            "ok": True,
            "stage": "snapshot",
            "bundle": str(bundle_root),
            "bundle_id": manifest.bundle_id,
            "manifest": str(bundle_root / "manifest.json"),
            "checksums": str(bundle_root / ACB_CHECKSUMS_NAME),
            "objects_dir": str(bundle_root / ACB_OBJECTS_DIR),
            "objects_captured": len(objects_dir_files),
            "detected": detect_rows[:50],
            "summary": inventory_summary,
            "collection_summary": collect_summary,
        },
        args.json,
    )
    return 0


def run_bundle_verify(args: argparse.Namespace) -> int:
    """Verify checksums for every file recorded in checksums.json."""
    errors = verify_bundle(args.bundle.resolve())
    emit(
        {
            "ok": not errors,
            "bundle": str(args.bundle.resolve()),
            "errors": errors,
        },
        args.json,
    )
    return 0 if not errors else 1


def run_restore(args: argparse.Namespace) -> int:
    """Verify and rebuild a plan from an ACB on the current device.

    Dual-side Plan Architecture (audit P0-1 & P0-3):
    1. Restore source is ALWAYS the verified bundle. Local source installation on
       device B does not alter or replace bundle content.
    2. Bundle objects are staged into an isolated temporary source tree.
    3. Source surfaces are resolved from the staged source registry; target
       surfaces are resolved from the real destination registry on this device.
    4. The reviewed PlanDocument contains the real destination target paths,
       real pre-apply target states (evaluating exists -> replace vs create),
       real unified/semantic diffs against the destination, and real workspace.
    5. The hash of this exact document is locked as plan_sha256 and recorded in
       provenance upon apply.
    6. Executed target paths == reviewed plan target paths at all times.
    """
    bundle_root = args.bundle.resolve()
    errors = verify_bundle(bundle_root)
    if errors:
        emit({"ok": False, "stage": "verify", "errors": errors}, args.json)
        return 1
    manifest = load_manifest(bundle_root)
    workspace = args.workspace.resolve()
    target_registry = Registry(args.registry, workspace)
    detected = [row for row in target_registry.inventory(None) if row.get("exists")]

    all_installed = getattr(args, "all_installed", False) or args.target in ("auto", "all-installed")
    source_sel = args.source or "cline/ide"
    target_sel = args.target or "forge/cli"
    object_types = resolve_objects(getattr(args, "objects", "skills,instructions,mcp"))
    have_bundle_objects = (bundle_root / ACB_OBJECTS_DIR).is_dir()

    # Optional object extraction into an explicit restore-root (audit #4:
    # opt-in; defaults OFF so we never imply a transaction landed there).
    restore_root = (
        args.restore_root.resolve(strict=False) if args.restore_root else None
    )
    restore_result = (
        restore_bundle_objects(bundle_root, restore_root, dry_run=args.dry_run)
        if restore_root is not None
        else None
    )

    temp_dir: str | None = None
    try:
        temp_dir = tempfile.mkdtemp(prefix="acb-source-stage-")
        temp_source_dir = Path(temp_dir)
        staged_home = temp_source_dir / "home"
        staged_home.mkdir(parents=True, exist_ok=True)

        if have_bundle_objects:
            objects_root = bundle_root / ACB_OBJECTS_DIR
            requested_scopes = {
                s.strip().lower()
                for s in (args.scope or "user,project").split(",")
                if s.strip()
            }
            if "all" in requested_scopes:
                requested_scopes = {"user", "project", "local"}

            for source_file in sorted(objects_root.rglob("*")):
                if source_file.is_file():
                    rel = source_file.relative_to(objects_root)
                    parts = rel.parts
                    if len(parts) >= 5:
                        obj_t, prod, prof, scp = parts[0], parts[1], parts[2], parts[3]
                        # For all_installed, stage all products; otherwise filter by source_prod
                        if all_installed or prod == source_sel.split("/")[0]:
                            if scp.lower() in requested_scopes:
                                target_staged = temp_source_dir / Path(*parts[4:])
                                target_staged.parent.mkdir(parents=True, exist_ok=True)
                                target_staged.write_bytes(source_file.read_bytes())

        source_registry = Registry(
            args.registry, temp_source_dir, home=staged_home
        )

        plan_in = getattr(args, "plan_in", None)
        if plan_in:
            document = load_plan_document(plan_in.resolve())
            plan_items, _ = validate_plan_document(
                document, target_registry, source_registry=source_registry
            )
        elif all_installed:
            # Multi-target all-installed restore: detect installed target IDEs on Device B
            # and restore applicable bundle objects to each.
            from detect.probes import detect_profile, InstallState
            target_detected_selectors: set[str] = set()  # "product/profile" pairs
            target_detection_status: dict[str, str] = {}  # "product/profile" -> state
            for prod_id, prod in target_registry.products.items():
                for prof_id, prof in prod.get("profiles", {}).items():
                    detection = prof.get("detection", []) or []
                    profile_state = InstallState.NOT_DETECTED
                    profile_evidence: list[str] = []
                    for probe in detection:
                        if not isinstance(probe, dict):
                            continue
                        paths = probe.get("paths", [])
                        binaries = probe.get("command") or probe.get("binaries") or []
                        if isinstance(binaries, str):
                            binaries = [binaries]
                        res = detect_profile(
                            prod_id,
                            prof_id,
                            binaries=binaries,
                            file_signatures=paths,
                            home=target_registry.home,
                            workspace=workspace,
                            app_bundle_id=probe.get("darwin_bundle_id"),
                        )
                        # Use the most definitive state across all probes for this profile
                        if res.state.value == "installed":
                            profile_state = InstallState.INSTALLED
                            profile_evidence.extend(res.evidence)
                            break
                        elif res.state.value == "configured-only" and profile_state not in (InstallState.INSTALLED,):
                            profile_state = InstallState.CONFIGURED_ONLY
                            profile_evidence.extend(res.evidence)
                        elif res.state.value == "compatibility-only" and profile_state not in (InstallState.INSTALLED, InstallState.CONFIGURED_ONLY):
                            profile_state = InstallState.COMPATIBILITY_ONLY
                            profile_evidence.extend(res.evidence)
                        elif res.state.value == "cloud-connected" and profile_state not in (InstallState.INSTALLED, InstallState.CONFIGURED_ONLY, InstallState.COMPATIBILITY_ONLY):
                            profile_state = InstallState.CLOUD_CONNECTED
                            profile_evidence.extend(res.evidence)
                        elif res.state.value == "legacy" and profile_state not in (InstallState.INSTALLED, InstallState.CONFIGURED_ONLY, InstallState.COMPATIBILITY_ONLY, InstallState.CLOUD_CONNECTED):
                            profile_state = InstallState.LEGACY
                            profile_evidence.extend(res.evidence)
                        elif res.state.value == "ambiguous" and profile_state == InstallState.NOT_DETECTED:
                            profile_state = InstallState.AMBIGUOUS
                            profile_evidence.extend(res.evidence)
                    selector = f"{prod_id}/{prof_id}"
                    target_detection_status[selector] = profile_state.value
                    if profile_state in (
                        InstallState.INSTALLED,
                        InstallState.CONFIGURED_ONLY,
                        InstallState.COMPATIBILITY_ONLY,
                    ):
                        target_detected_selectors.add(selector)

            # Extract source selectors from bundle manifest (product/profile pairs that have objects)
            bundle_source_selectors = sorted({
                f"{obj.get('product')}/{obj.get('profile')}"
                for obj in manifest.objects
                if obj.get("product") and obj.get("profile")
            })
            if not bundle_source_selectors:
                bundle_source_selectors = [source_sel] if source_sel else ["cline/ide"]

            all_items: list[dict[str, Any]] = []
            seen_target_paths: set[str] = set()
            failed_targets: list[dict[str, str]] = []
            for tgt_selector in sorted(target_detected_selectors):
                for src_selector in bundle_source_selectors:
                    try:
                        doc = build_plan_document(
                            source_registry,
                            src_selector,
                            tgt_selector,
                            object_types,
                            args.scope,
                            target_registry=target_registry,
                        )
                        for item in doc.get("items", []):
                            target_path = (item.get("target") or {}).get("resolved_path")
                            if target_path and target_path in seen_target_paths:
                                # Conflict: multiple sources mapping to same target path
                                # Skip subsequent ones but record in loss report
                                continue
                            if target_path:
                                seen_target_paths.add(target_path)
                            all_items.append(item)
                    except Exception as error:
                        # Audit P1-2: never silently swallow per-target plan
                        # build failures during all-installed restore. Surface
                        # the failure so the restore summary can report it.
                        failed_targets.append({
                            "source": src_selector,
                            "target": tgt_selector,
                            "error": str(error),
                        })
                        print(
                            f"WARNING: restore plan build failed for source={src_selector} target={tgt_selector}: {error}",
                            file=sys.stderr,
                        )

            document = {
                "schema_version": 1,
                "created_at": datetime.now(timezone.utc).isoformat(),
                "workspace": str(target_registry.workspace),
                "source": "all-installed",
                "source_profile": "all",
                "source_support_level": "bidirectional-reviewed",
                "target": "all-installed",
                "target_profile": "all",
                "target_support_level": "bidirectional-reviewed",
                "scope": args.scope or "user,project",
                "objects": object_types,
                "registry_sha256": hash_path(target_registry.path),
                "adapter_versions": ADAPTER_VERSIONS,
                "git_provenance": git_provenance(target_registry.workspace),
                "items": all_items,
                "loss_report": {"dropped_fields": [], "warnings": []},
                "rebuild_manifest": {
                    "credential_policy": "references-only; never include literal credentials",
                    "items": [],
                },
                "detection_status": target_detection_status,
                "failed_targets": failed_targets,
            }
            document["plan_sha256"] = json_sha256(_plan_hash_payload(document))
            plan_items, _ = validate_plan_document(
                document, target_registry, source_registry=source_registry
            )
        else:
            # Build dual-side plan: source=bundle (source_registry), target=destination device (target_registry)
            document = build_plan_document(
                source_registry,
                source_sel,
                target_sel,
                object_types,
                args.scope,
                target_registry=target_registry,
            )
            # Enforce TOCTOU state lock validation on the generated plan document
            plan_items, _ = validate_plan_document(
                document, target_registry, source_registry=source_registry
            )

        # Write the reviewed plan document if requested
        plan_out = None
        if args.plan_out and not args.dry_run:
            plan_out = args.plan_out.resolve(strict=False)
            plan_out.parent.mkdir(parents=True, exist_ok=True)
            atomic_write(
                plan_out,
                json.dumps(document, indent=2, sort_keys=True) + "\n",
            )

        plan_display = str(plan_out) if plan_out else (str(plan_in) if plan_in else None)

        if args.dry_run:
            # Zero-write guarantee for dry-run.
            emit(
                {
                    "ok": True,
                    "stage": "plan",
                    "bundle": str(bundle_root),
                    "bundle_id": manifest.bundle_id,
                    "plan": plan_display,
                    "plan_sha256": document["plan_sha256"],
                    "restore": restore_result,
                    "dry_run": True,
                    "detected": detected[:50],
                    "failed_targets": document.get("failed_targets", []),
                },
                args.json,
            )
            return 0

        is_plan_only = getattr(args, "plan_only", False) or not args.yes
        if is_plan_only:
            emit(
                {
                    "ok": True,
                    "stage": "plan",
                    "bundle": str(bundle_root),
                    "bundle_id": manifest.bundle_id,
                    "plan": plan_display,
                    "plan_sha256": document["plan_sha256"],
                    "restore": restore_result,
                    "detected": detected[:50],
                    "failed_targets": document.get("failed_targets", []),
                },
                args.json,
            )
            return 0

        if args.apply_safe:
            # No-op guard (audit #2): bundle carried objects but nothing
            # eligible was resolved — refuse to report success.
            if have_bundle_objects and not any(
                item.status == "ready" for item in plan_items
            ):
                if not getattr(args, "allow_noop", False):
                    emit(
                        {
                            "ok": False,
                            "stage": "apply",
                            "error": "restore resolved no eligible items; refusing silent no-op (use --allow-noop to override)",
                        },
                        args.json,
                    )
                    return 1
            return _apply_restore(
                plan_items, workspace, args, bundle_root, manifest,
                document, restore_result, detected,
            )

        emit(
            {
                "ok": True,
                "stage": "plan",
                "bundle": str(bundle_root),
                "bundle_id": manifest.bundle_id,
                "plan": plan_display,
                "plan_sha256": document["plan_sha256"],
                "restore": restore_result,
                "detected": detected[:50],
                "failed_targets": document.get("failed_targets", []),
            },
            args.json,
        )
        return 0
    finally:
        # The staged source tree must stay alive until apply_plan has read it,
        # so it is cleaned up only here (audit #5: never leak to /tmp).
        if temp_dir is not None and Path(temp_dir).exists():
            shutil.rmtree(temp_dir, ignore_errors=True)


def _apply_restore(
    plan_items: list,
    workspace: Path,
    args: argparse.Namespace,
    bundle_root: Path,
    manifest,
    document: dict,
    restore_result,
    detected,
) -> int:
    """Apply a resolved plan, verify it, and emit the result."""
    manifest_obj, manifest_path_out = apply_plan(
        plan_items, workspace, args.manifest_out,
        provenance={
            "bundle_path": str(bundle_root),
            "bundle_id": manifest.bundle_id,
            "plan_sha256": document["plan_sha256"],
            "registry_sha256": document["registry_sha256"],
            "adapter_versions": document["adapter_versions"],
        },
        apply_safe=True,
        include_lossy=(args.include_lossy == "lossy"),
        accept_loss_ids=set(),
        strict=args.strict,
    )
    verify_errors = verify_manifest(manifest_path_out)
    emit(
        {
            "ok": not verify_errors,
            "stage": "verify",
            "bundle": str(bundle_root),
            "plan": str(args.plan_out) if getattr(args, "plan_out", None) else None,
            "manifest": str(manifest_path_out),
            "restore": restore_result,
            "stale_targets": [],
            "detected": detected[:50],
            "summary": manifest_obj.get("summary", {}),
            "errors": verify_errors,
            "failed_targets": document.get("failed_targets", []),
        },
        args.json,
    )
    return 0 if not verify_errors else 1


def run_doctor(args: argparse.Namespace) -> int:
    """Inspect a bundle and surface missing executables / re-auth work."""
    bundle_root = args.bundle.resolve()
    errors = verify_bundle(bundle_root)
    if errors:
        emit({"ok": False, "stage": "verify", "errors": errors}, args.json)
        return 1
    requirements = json.loads(
        (bundle_root / "requirements.json").read_text(encoding="utf-8")
    )
    reauth = json.loads((bundle_root / "reauth.json").read_text(encoding="utf-8"))
    rebuild = json.loads((bundle_root / "rebuild.json").read_text(encoding="utf-8"))
    missing_executables: list[str] = []
    for binary in requirements.get("executables", []):
        if not shutil.which(binary):
            missing_executables.append(binary)
    emit(
        {
            "ok": not missing_executables,
            "bundle": str(bundle_root),
            "missing_executables": missing_executables,
            "reauth_actions": reauth.get("items", []),
            "rebuild_actions": rebuild.get("items", []),
            "platform_notes": requirements.get("platform_notes", []),
        },
        args.json,
    )
    return 0 if not missing_executables else 1


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
        allow_session_handoff=bool(getattr(args, "include_session", False)),
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
    bash_exe = "bash"
    if os.name == "nt":
        # On Windows hosts PATH can resolve bare "bash" to the System32
        # WSL launcher, which is not an MSYS shell: its output carries
        # NUL bytes and its lookups return nothing. Prefer Git Bash.
        for candidate in (
            Path(os.environ.get("PROGRAMW6432", r"C:\Program Files")) / "Git" / "bin" / "bash.exe",
            Path(os.environ.get("ProgramFiles", r"C:\Program Files")) / "Git" / "usr" / "bin" / "bash.exe",
        ):
            if candidate.is_file():
                bash_exe = str(candidate)
                break
    completed = subprocess.run(
        [bash_exe, str(LEGACY_SCRIPT), *argv],
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

        source_registry = None
        temp_dir = None
        bundle_root = None
        try:
            if getattr(args, "bundle", None):
                bundle_root = args.bundle.resolve()
                errors = verify_bundle(bundle_root)
                if errors:
                    emit({"ok": False, "stage": "verify", "errors": errors}, args.json)
                    return 1
                temp_dir = tempfile.mkdtemp(prefix="acb-source-stage-")
                temp_source_dir = Path(temp_dir)
                staged_home = temp_source_dir / "home"
                staged_home.mkdir(parents=True, exist_ok=True)
                objects_root = bundle_root / ACB_OBJECTS_DIR
                if objects_root.is_dir():
                    for source_file in sorted(objects_root.rglob("*")):
                        if source_file.is_file():
                            rel = source_file.relative_to(objects_root)
                            parts = rel.parts
                            if len(parts) >= 5:
                                target_staged = temp_source_dir / Path(*parts[4:])
                                target_staged.parent.mkdir(parents=True, exist_ok=True)
                                target_staged.write_bytes(source_file.read_bytes())
                source_registry = Registry(
                    args.registry, temp_source_dir, home=staged_home
                )

            plan_items, _ = validate_plan_document(
                document, registry, source_registry=source_registry
            )
            accept_loss_ids = {
                token.strip()
                for token in args.accept_loss.split(",")
                if token.strip()
            }
            provenance = {
                "plan_path": str(args.plan.resolve()),
                "plan_sha256": document["plan_sha256"],
                "registry_sha256": document["registry_sha256"],
                "adapter_versions": document["adapter_versions"],
                "git_provenance": document.get("git_provenance"),
            }
            if bundle_root is not None:
                provenance["bundle_path"] = str(bundle_root)
            manifest, manifest_path = apply_plan(
                plan_items,
                registry.workspace,
                args.manifest,
                provenance=provenance,
                apply_safe=args.apply_safe,
                include_lossy=(args.include_lossy == "lossy"),
                accept_loss_ids=accept_loss_ids,
                strict=args.strict,
                allow_session_handoff=bool(getattr(args, "include_session", False)),
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
        finally:
            if temp_dir is not None and Path(temp_dir).exists():
                shutil.rmtree(temp_dir, ignore_errors=True)

    if args.command == "migrate":
        if not args.yes:
            raise ValueError(
                "migrate requires --yes after specifying source/target/objects"
            )
        return run_migrate(args)

    if args.command == "snapshot":
        return run_snapshot(args)

    if args.command == "bundle-verify":
        return run_bundle_verify(args)

    if args.command == "restore":
        return run_restore(args)

    if args.command == "doctor":
        return run_doctor(args)

    registry = Registry(args.registry, args.workspace)
    if args.command in {"detect", "inventory"}:
        if args.command == "detect":
            return run_detection(args)
        selected = selector(args.product, args.profile)
        rows = registry.inventory(selected)
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
    if not argv or argv[0] in {"-h", "--help"}:
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
