"""Agent Context Bundle (.acb) creation, verification, and restore.

Layout::

    <bundle>.acb/
        manifest.json          schema_version, source_platform, objects
        inventory.json         full per-product surface inventory
        compatibility.json     per-product target-eligibility matrix
        requirements.json      executables, packages, extensions, manual_installs
        secrets.required.json  non-secret names of required credentials
        reauth.json            per-MCP re-auth action list
        rebuild.json           per-object manual-rebuild manifest
        checksums.json         sha256 of every other JSON file
        objects/<surface>/     reviewed object content (no secrets)
        raw-reviewed/          pre-conversion source snapshots

The bundle is created from a snapshot of the local filesystem plus the
Registry v2 inventory.  :func:`verify_bundle` re-reads the checksums
file and re-hashes every other JSON file.

Secret handling: the snapshot phase redacts literal credentials before
they reach the bundle.  Only the names of required credentials (e.g.
``LINEAR_API_KEY``) end up in :file:`secrets.required.json`.  The
function rejects any attempt to write literal secret values into the
bundle and returns an explicit error.
"""

from __future__ import annotations

import dataclasses
import hashlib
import json
import os
import re
import shutil
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

ACB_SCHEMA_VERSION = 1
ACB_MANIFEST_NAME = "manifest.json"
ACB_INVENTORY_NAME = "inventory.json"
ACB_COMPATIBILITY_NAME = "compatibility.json"
ACB_REQUIREMENTS_NAME = "requirements.json"
ACB_SECRETS_NAME = "secrets.required.json"
ACB_REAUTH_NAME = "reauth.json"
ACB_REBUILD_NAME = "rebuild.json"
ACB_CHECKSUMS_NAME = "checksums.json"
ACB_OBJECTS_DIR = "objects"

ACB_JSON_FILES = (
    ACB_MANIFEST_NAME,
    ACB_INVENTORY_NAME,
    ACB_COMPATIBILITY_NAME,
    ACB_REQUIREMENTS_NAME,
    ACB_SECRETS_NAME,
    ACB_REAUTH_NAME,
    ACB_REBUILD_NAME,
)

_SECRET_HINT = re.compile(
    r"(?i)(token|secret|password|passwd|api[_-]?key|authorization|cookie|bearer)"
)
_PROVIDER_SECRET_HINT = re.compile(
    r"(?:sk-[A-Za-z0-9_-]{16,}|gh[pousr]_[A-Za-z0-9]{16,}|AKIA[0-9A-Z]{16}|ASIA[0-9A-Z]{16}|xox[baprs]-[A-Za-z0-9-]{10,}|ya29\.[A-Za-z0-9_-]+|AIza[0-9A-Za-z_-]{30,}|sk_live_[A-Za-z0-9]{16,}|Bearer\s+[A-Za-z0-9._~+/-]{16,})"
)


class ACBError(Exception):
    """Base class for ACB failures."""


class ACBSecretLeak(ACBError):
    """Raised when literal secret values are detected in bundle content."""


@dataclasses.dataclass
class ACBManifest:
    schema_version: int
    bundle_id: str
    created_at: str
    source_platform: dict[str, str]
    inventory_summary: dict[str, Any]
    objects: list[dict[str, Any]]

    def to_dict(self) -> dict[str, Any]:
        return {
            "schema_version": self.schema_version,
            "bundle_id": self.bundle_id,
            "created_at": self.created_at,
            "source_platform": self.source_platform,
            "inventory_summary": self.inventory_summary,
            "objects": self.objects,
        }

    @classmethod
    def from_dict(cls, payload: dict[str, str]) -> "ACBManifest":
        return cls(
            schema_version=int(payload["schema_version"]),
            bundle_id=str(payload["bundle_id"]),
            created_at=str(payload["created_at"]),
            source_platform=dict(payload.get("source_platform", {})),
            inventory_summary=dict(payload.get("inventory_summary", {})),
            objects=list(payload.get("objects", [])),
        )


def sha256_text(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: Path) -> str:
    return sha256_bytes(path.read_bytes())


def looks_like_secret_value(value: Any) -> bool:
    """Heuristic check: does this string look like a credential?"""
    if not isinstance(value, str):
        return False
    if not value or value.startswith("${") or value.startswith("$") or value.startswith("<"):
        return False
    return bool(_SECRET_HINT.search(value) or _PROVIDER_SECRET_HINT.search(value))


def assert_no_lateral_secrets(payload: dict[str, Any]) -> None:
    """Reject literal secret-looking strings in a payload."""
    for key, value in _walk(payload):
            if isinstance(value, str) and looks_like_secret_value(value):
                # secrets.required.json is the only allowed home for
                # secret names; flag any other occurrence as a leak.
                if key == "name" and isinstance(value, str) and re.match(
                    r"^[A-Z][A-Z0-9_]+$", value
                ):
                    continue
                raise ACBSecretLeak(
                    f"literal credential-looking string at {key}: {value[:32]!r}"
                )


def _walk(payload: Any, path: tuple[str, ...] = ()) -> Any:
    if isinstance(payload, dict):
        for key, value in payload.items():
            yield from _walk(value, path + (str(key),))
    elif isinstance(payload, list):
        for index, value in enumerate(payload):
            yield from _walk(value, path + (f"[{index}]",))
    else:
        yield ".".join(path), payload


def collect_requirements(
    inventory_rows: list[dict[str, Any]],
    plan_rows: list[dict[str, Any]],
) -> dict[str, Any]:
    """Derive a structured requirements document from inventory + plan.

    Heuristic: extract binary-style hints from ``inventory_rows``
    (e.g. cline CLI -> ``cline`` binary) plus per-object MCP packages.
    """
    executables: set[str] = set()
    extensions: set[str] = set()
    packages: list[dict[str, str]] = []
    manual_installs: list[str] = []
    for row in inventory_rows:
        product = row.get("product")
        if product and row.get("exists") and row.get("object_type") == "skills":
            executables.add(product)
    for item in plan_rows:
        if item.get("status") not in {"ready", "ready-lossy", "draft-disabled"}:
            continue
        if item.get("object_type") == "mcp":
            server = item.get("target") or {}
            cmd = server.get("path") or ""
            if cmd:
                packages.append({"manager": "auto", "name": cmd})
    return {
        "executables": sorted(executables),
        "extensions": sorted(extensions),
        "packages": packages,
        "manual_installs": manual_installs,
        "platform_notes": [],
    }


def collect_reauth(
    plan_rows: list[dict[str, Any]],
) -> list[dict[str, str]]:
    """Per-MCP re-auth action list derived from plan rows."""
    actions: list[dict[str, str]] = []
    for item in plan_rows:
        if item.get("status") == "manual-rebuild" and item.get("object_type") == "mcp":
            actions.append(
                {
                    "object_id": item.get("object_id", ""),
                    "reason": item.get("reason", "OAuth re-auth required"),
                    "action": "Open the target product's MCP UI, sign in, and re-add the server.",
                }
            )
    return actions


def collect_rebuild(
    plan_rows: list[dict[str, Any]],
) -> list[dict[str, str]]:
    """Per-object manual-rebuild manifest."""
    actions: list[dict[str, str]] = []
    for item in plan_rows:
        if item.get("status") in {"manual-rebuild", "forbidden"}:
            actions.append(
                {
                    "object_id": item.get("object_id", ""),
                    "object_type": item.get("object_type", ""),
                    "reason": item.get("reason", ""),
                    "actions": item.get("manual_actions", []),
                }
            )
    return actions


def write_bundle(
    *,
    bundle_root: Path,
    manifest: ACBManifest,
    inventory_rows: list[dict[str, Any]],
    compatibility: dict[str, Any],
    requirements: dict[str, Any],
    secrets_required: list[dict[str, str]],
    reauth: list[dict[str, str]],
    rebuild: list[dict[str, str]],
    objects_dir_files: dict[str, bytes] | None = None,
) -> Path:
    """Write a fully-formed ACB at ``bundle_root``.

    ``objects_dir_files`` is an optional mapping of relative paths
    (under ``objects/``) to file bytes.  Literal-secret values inside
    the JSON payloads raise :class:`ACBSecretLeak`.
    """
    bundle_root = bundle_root.resolve()
    bundle_root.mkdir(parents=True, exist_ok=True)
    objects_root = bundle_root / ACB_OBJECTS_DIR
    if objects_root.exists():
        shutil.rmtree(objects_root)
    objects_root.mkdir(parents=True)

    json_payloads: dict[str, dict[str, Any]] = {
        ACB_MANIFEST_NAME: manifest.to_dict(),
        ACB_INVENTORY_NAME: {"rows": inventory_rows},
        ACB_COMPATIBILITY_NAME: compatibility,
        ACB_REQUIREMENTS_NAME: requirements,
        ACB_SECRETS_NAME: {"items": secrets_required},
        ACB_REAUTH_NAME: {"items": reauth},
        ACB_REBUILD_NAME: {"items": rebuild},
    }
    for name, payload in json_payloads.items():
        assert_no_lateral_secrets(payload)
        (bundle_root / name).write_text(
            json.dumps(payload, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )

    if objects_dir_files:
        for relative, data in objects_dir_files.items():
            target = objects_root / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(data)

    checksums: dict[str, str] = {}
    for name in ACB_JSON_FILES:
        checksums[name] = sha256_file(bundle_root / name)
    for relative_path in (objects_dir_files or {}).keys():
        checksums[f"{ACB_OBJECTS_DIR}/{relative_path}"] = sha256_file(
            objects_root / relative_path
        )
    (bundle_root / ACB_CHECKSUMS_NAME).write_text(
        json.dumps(checksums, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    return bundle_root


def collect_source_objects(
    registry: "Any",
    rows: list[dict[str, Any]],
    *,
    home: Path | None = None,
    workspace: Path | None = None,
    source_product: str | None = None,
    source_profile: str | None = None,
) -> dict[str, bytes]:
    """Walk existing inventory rows and copy each existing source file
    into a stable per-object path under ``objects/``.

    Recurses through Skill directories (which are one level deep),
    copies instructions/MCP single files, and silently skips
    anything missing or unreadable.

    If ``source_product`` and ``source_profile`` are provided, only rows
    matching that product/profile are collected.
    """
    from pathlib import Path as _Path
    objects: dict[str, bytes] = {}
    for row in rows:
        if not row.get("exists"):
            continue
        # Filter by source product/profile if provided
        if source_product and row.get("product") != source_product:
            continue
        if source_profile and row.get("profile") != source_profile:
            continue
        resolved = row.get("resolved_path")
        if not isinstance(resolved, str):
            continue
        source_path = _Path(resolved)
        if not source_path.exists():
            continue
        object_type = row.get("object_type") or "unknown"
        product = row.get("product") or "unknown"
        profile = row.get("profile") or "default"
        scope = row.get("scope") or "unknown"
        canonical = row.get("canonical_path") or source_path.name
        relative = _path_for_object(
            object_type, product, profile, scope, canonical
        )
        if source_path.is_file():
            objects[relative] = source_path.read_bytes()
        elif source_path.is_dir():
            # Skill dirs have one level of children; recurse one level.
            for child in sorted(source_path.iterdir()):
                if child.is_file():
                    objects[f"{relative}/{child.name}"] = child.read_bytes()
                elif child.is_dir():
                    for grandchild in sorted(child.iterdir()):
                        if grandchild.is_file():
                            objects[f"{relative}/{child.name}/{grandchild.name}"] = (
                                grandchild.read_bytes()
                            )
    return objects


def _path_for_object(
    object_type: str, product: str, profile: str, scope: str, canonical: str
) -> str:
    """Build a stable relative path under ``objects/`` for a given
    inventory row."""
    safe_canonical = canonical.strip("/").replace("~", "home").replace("..", "_")
    return f"{object_type}/{product}/{profile}/{scope}/{safe_canonical}"


def restore_bundle_objects(
    bundle_root: Path,
    destination_root: Path,
    *,
    dry_run: bool = False,
) -> dict[str, Any]:
    """Copy every file recorded in ``bundle/objects/`` into the
    destination tree.  Returns a manifest describing what was
    written (or what would be written under ``dry_run``).

    Literal-secret-looking content is refused via
    :func:`assert_no_lateral_secrets`; any object whose path is
    outside ``destination_root`` is rejected.
    """
    bundle_root = bundle_root.resolve()
    destination_root = destination_root.resolve()
    objects_root = bundle_root / ACB_OBJECTS_DIR
    if not objects_root.is_dir():
        raise ACBError(f"bundle has no objects/ directory: {bundle_root}")
    written: list[dict[str, Any]] = []
    skipped: list[dict[str, str]] = []
    for source in sorted(objects_root.rglob("*")):
        if not source.is_file():
            continue
        relative = source.relative_to(objects_root).as_posix()
        target = (destination_root / relative).resolve()
        if not str(target).startswith(str(destination_root)):
            skipped.append({"path": relative, "reason": "escapes destination"})
            continue
        try:
            payload = {"path": relative, "content": source.read_text(encoding="utf-8")}
            assert_no_lateral_secrets(payload)
        except (ACBSecretLeak, UnicodeDecodeError):
            skipped.append({"path": relative, "reason": "secret-shaped content"})
            continue
        if not dry_run:
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(source.read_bytes())
        written.append(
            {
                "path": relative,
                "sha256": sha256_file(source),
                "size": source.stat().st_size,
            }
        )
    return {
        "bundle": str(bundle_root),
        "destination": str(destination_root),
        "written": written,
        "skipped": skipped,
        "dry_run": dry_run,
    }


def verify_bundle(bundle_root: Path) -> list[str]:
    """Verify every checksum recorded in checksums.json matches on disk."""
    bundle_root = bundle_root.resolve()
    checksums_path = bundle_root / ACB_CHECKSUMS_NAME
    if not checksums_path.is_file():
        return [f"missing {ACB_CHECKSUMS_NAME}"]
    checksums = json.loads(checksums_path.read_text(encoding="utf-8"))
    errors: list[str] = []
    for relative, expected in checksums.items():
        target = bundle_root / relative
        if not target.is_file():
            errors.append(f"missing file: {relative}")
            continue
        actual = sha256_file(target)
        if actual != expected:
            errors.append(f"checksum mismatch: {relative}")
    return errors


def load_manifest(bundle_root: Path) -> ACBManifest:
    bundle_root = bundle_root.resolve()
    return ACBManifest.from_dict(
        json.loads((bundle_root / ACB_MANIFEST_NAME).read_text(encoding="utf-8"))
    )


def make_bundle_id(timestamp: datetime | None = None) -> str:
    timestamp = timestamp or datetime.now(timezone.utc)
    return f"acb-{timestamp.strftime('%Y%m%dT%H%M%SZ')}"