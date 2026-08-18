"""Agent Context Bundle (.acb) creation, verification, and restore.

Layout::

    <bundle>.acb/
        manifest.json          schema_version, source_platform, objects
        inventory.json         portable per-product surface inventory
        compatibility.json     per-product target-eligibility matrix
        requirements.json      executables, packages, extensions, manual_installs
        secrets.required.json  non-secret names of required credentials
        reauth.json            per-MCP re-auth action list
        rebuild.json           per-object manual-rebuild manifest
        checksums.json         sha256 of every other file
        objects/<surface>/     reviewed object content (no secrets)

The bundle is created from a snapshot of the local filesystem plus the
Registry v2 inventory.  :func:`verify_bundle` performs closed-world integrity
checks ensuring no unexpected or missing files, no symlinks/devices, and
accurate SHA256 hashes.
"""

from __future__ import annotations

import dataclasses
import hashlib
import json
import os
import re
import shutil
import stat
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import skill_secret_scanner

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

# Resource safety limits
MAX_BUNDLE_FILES = 5000
MAX_FILE_SIZE = 10 * 1024 * 1024       # 10 MB per file
MAX_TOTAL_SIZE = 100 * 1024 * 1024     # 100 MB total
MAX_DIR_DEPTH = 16

# Safe binary extensions allowlist
SAFE_BINARY_EXTENSIONS = frozenset({
    ".png", ".jpg", ".jpeg", ".gif", ".webp", ".ico",
    ".svg", ".woff", ".woff2", ".ttf", ".eot", ".otf"
})

# Forbidden snapshot policies and non-migratable object types (audit P0-2)
FORBIDDEN_SNAPSHOT_POLICIES = frozenset({
    "forbidden-regenerate",
    "never-migrate",
    "source-only",
    "cloud-rebuild",
    "disabled-draft-only",
})

FORBIDDEN_SNAPSHOT_OBJECT_TYPES = frozenset({
    "generated_memory",
    "session",
    "chat",
    "runtime",
    "database",
    "trust",
    "approval",
    "oauth_state",
    "credentials",
})

_SENSITIVE_FILENAME_HINT = re.compile(
    r"(?i)(^\.env(\..+)?$|\.pem$|\.key$|^id_rsa|^id_ed25519|^id_ecdsa|\.p12$|\.pfx$)"
)


class ACBError(Exception):
    """Base class for ACB failures."""


class ACBSecretLeak(ACBError):
    """Raised when literal secret values are detected in bundle content."""


class ACBIntegrityError(ACBError):
    """Raised when bundle integrity or containment check fails."""


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
    def from_dict(cls, payload: dict[str, Any]) -> "ACBManifest":
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


def is_binary_bytes(data: bytes) -> bool:
    """Determine whether data is non-text binary."""
    if b"\x00" in data:
        return True
    try:
        data.decode("utf-8")
        return False
    except UnicodeDecodeError:
        return True


def looks_like_secret_value(value: Any) -> bool:
    """Heuristic check: does this string look like a literal credential?

    Uses the SAME unified scanner as Skills/objects (audit #6) so that only
    genuine credential SHAPES are flagged — provider tokens, private-key
    blocks, or ``key=value`` / ``key: value`` assignments — not prose that
    merely mentions words like "secret" or "token".
    """
    if not isinstance(value, str):
        return False
    if not value or value.startswith("${") or value.startswith("$") or value.startswith("<"):
        return False
    return skill_secret_scanner.finding_reason(value.encode("utf-8")) is not None


def scan_object_bytes(data: bytes, path_name: str) -> None:
    """Perform strict secret, private-key, and binary safety scans on raw object bytes."""
    path = Path(path_name)
    base_name = path.name

    # 1. Block sensitive file names (.env, private keys, certificates)
    if _SENSITIVE_FILENAME_HINT.search(base_name):
        raise ACBSecretLeak(f"forbidden sensitive file in bundle: {path_name}")

    # 2. Check binary safety
    if is_binary_bytes(data):
        # Check executable magic headers
        if data.startswith(b"\x7fELF"):
            raise ACBSecretLeak(f"executable ELF binary rejected: {path_name}")
        if data.startswith((b"\xfe\xed\xfa\xce", b"\xfe\xed\xfa\xcf", b"\xcf\xfa\xed\xfe", b"\xca\xfe\xba\xbe")):
            raise ACBSecretLeak(f"executable Mach-O binary rejected: {path_name}")
        if data.startswith(b"MZ"):
            raise ACBSecretLeak(f"executable PE binary rejected: {path_name}")

        # Check extension against binary allowlist
        ext = path.suffix.lower()
        if ext not in SAFE_BINARY_EXTENSIONS:
            raise ACBSecretLeak(f"unallowlisted binary file rejected: {path_name}")
        return

    # 3. Unified generic secret scan. Reuses skill_secret_scanner.finding_reason
    # so that credentials are detected identically across the Skill scanner and
    # ACB objects (audit #6): private keys, provider patterns, Bearer tokens,
    # connection-string userinfo, and literal credential assignments
    # (password=, client_secret:, DATABASE_URL with embedded creds, etc.).
    secret_reason = skill_secret_scanner.finding_reason(data)
    if secret_reason is not None:
        raise ACBSecretLeak(f"{secret_reason} in {path_name}")

    # 4. Require clean UTF-8 text for non-binary allowlisted content.
    try:
        data.decode("utf-8")
    except UnicodeDecodeError:
        raise ACBSecretLeak(f"undecodable non-allowlisted text: {path_name}")


def assert_no_lateral_secrets(payload: dict[str, Any]) -> None:
    """Reject literal secret-looking strings in a structured payload."""
    for key, value in _walk(payload):
        if isinstance(value, str) and looks_like_secret_value(value):
            if key.endswith(".name") or key == "name":
                if isinstance(value, str) and re.match(r"^[A-Z][A-Z0-9_]+$", value):
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


def validate_path_containment(relative_path: str | Path, base_dir: Path) -> Path:
    """Ensure path has no absolute segments, traversal, drive specifiers, and stays within base_dir."""
    p_str = str(relative_path).replace("\\", "/")
    if p_str.startswith("/") or re.match(r"^[a-zA-Z]:", p_str) or p_str.startswith("//"):
        raise ACBIntegrityError(f"forbidden absolute/UNC path: {relative_path}")
    parts = Path(p_str).parts
    if ".." in parts or any(part.startswith("/") for part in parts):
        raise ACBIntegrityError(f"path traversal detected: {relative_path}")
    resolved_target = (base_dir / p_str).resolve()
    try:
        resolved_target.relative_to(base_dir.resolve())
    except ValueError:
        raise ACBIntegrityError(f"path escapes base directory: {relative_path}")
    return resolved_target


def sanitize_inventory_for_bundle(rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """Sanitize inventory rows for portable bundles by stripping machine-specific paths and local user info."""
    clean_rows: list[dict[str, Any]] = []
    for row in rows:
        clean_row = {
            "product": row.get("product", ""),
            "profile": row.get("profile", "default"),
            "object_type": row.get("object_type", ""),
            "scope": row.get("scope", ""),
            "canonical_path": row.get("canonical_path", ""),
            "format": row.get("format", ""),
            "policy": row.get("policy", ""),
            "content_hash": row.get("content_hash", ""),
            "exists": bool(row.get("exists", False)),
        }
        clean_rows.append(clean_row)
    return clean_rows


def collect_requirements(
    inventory_rows: list[dict[str, Any]],
    plan_rows: list[dict[str, Any]],
) -> dict[str, Any]:
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
    """Write a fully-formed, closed-world ACB at ``bundle_root``."""
    bundle_root = bundle_root.resolve()
    bundle_root.mkdir(parents=True, exist_ok=True)
    objects_root = bundle_root / ACB_OBJECTS_DIR
    if objects_root.exists():
        shutil.rmtree(objects_root)
    objects_root.mkdir(parents=True)

    # Sanitize inventory for portable bundle
    portable_inventory = sanitize_inventory_for_bundle(inventory_rows)

    json_payloads: dict[str, dict[str, Any]] = {
        ACB_MANIFEST_NAME: manifest.to_dict(),
        ACB_INVENTORY_NAME: {"rows": portable_inventory},
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

    # Verify and write raw object files with byte-level scanning
    total_bytes = 0
    file_count = 0
    if objects_dir_files:
        for relative, data in sorted(objects_dir_files.items()):
            file_count += 1
            total_bytes += len(data)
            if file_count > MAX_BUNDLE_FILES:
                raise ACBError(f"bundle file count exceeded limit ({MAX_BUNDLE_FILES})")
            if len(data) > MAX_FILE_SIZE:
                raise ACBError(f"file size exceeded limit ({MAX_FILE_SIZE} bytes): {relative}")
            if total_bytes > MAX_TOTAL_SIZE:
                raise ACBError(f"bundle total size exceeded limit ({MAX_TOTAL_SIZE} bytes)")

            # Strict byte-level secret and binary scan
            scan_object_bytes(data, relative)

            # Strict path containment check
            target = validate_path_containment(relative, objects_root)
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(data)

    # Post-write directory-wide secret scan
    for p in bundle_root.rglob("*"):
        if p.is_file() and p.name != ACB_CHECKSUMS_NAME:
            scan_object_bytes(p.read_bytes(), str(p.relative_to(bundle_root)))

    # Compute checksums for all written files
    checksums: dict[str, str] = {}
    for name in ACB_JSON_FILES:
        checksums[name] = sha256_file(bundle_root / name)
    for relative_path in sorted((objects_dir_files or {}).keys()):
        norm_path = Path(relative_path).as_posix()
        checksums[f"{ACB_OBJECTS_DIR}/{norm_path}"] = sha256_file(
            objects_root / norm_path
        )
    (bundle_root / ACB_CHECKSUMS_NAME).write_text(
        json.dumps(checksums, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    return bundle_root


def collect_source_objects(
    registry: Any,
    rows: list[dict[str, Any]],
    *,
    home: Path | None = None,
    workspace: Path | None = None,
    source_product: str | None = None,
    source_profile: str | None = None,
    allowed_scopes: set[str] | None = None,
    allowed_object_types: set[str] | None = None,
    plan_items: list[dict[str, Any]] | None = None,
) -> dict[str, bytes]:
    """Walk existing inventory rows and copy source files into stable paths under ``objects/``.

    Strict Allowlist (audit P0-2):
    - Refuses forbidden policies (forbidden-regenerate, never-migrate, source-only, etc.)
    - Refuses non-migratable types (generated_memory, session, chat, runtime, database, trust, etc.)
    - Only collects requested scopes and requested object types
    - Only collects objects that match the planned migration items when plan_items is provided
    """
    objects: dict[str, bytes] = {}
    plan_object_types = {item.get("object_type") for item in plan_items} if plan_items else None
    for row in rows:
        if not row.get("exists"):
            continue
        if source_product and row.get("product") != source_product:
            continue
        if source_profile and row.get("profile") != source_profile:
            continue

        object_type = row.get("object_type") or "unknown"
        policy = row.get("policy") or ""
        scope = row.get("scope") or "unknown"

        # P0-2: Strict snapshot allowlist
        if policy in FORBIDDEN_SNAPSHOT_POLICIES:
            continue
        if object_type in FORBIDDEN_SNAPSHOT_OBJECT_TYPES:
            continue
        if allowed_scopes is not None and scope not in allowed_scopes:
            continue
        if allowed_object_types is not None and object_type not in allowed_object_types:
            continue
        if plan_object_types is not None and object_type not in plan_object_types:
            continue

        resolved = row.get("resolved_path")
        if not isinstance(resolved, str):
            continue
        source_path = Path(resolved)
        if not source_path.exists() or source_path.is_symlink():
            continue

        product = row.get("product") or "unknown"
        profile = row.get("profile") or "default"
        canonical = row.get("canonical_path") or source_path.name
        relative = _path_for_object(object_type, product, profile, scope, canonical)

        storage = row.get("storage") or ""
        format_name = row.get("source_format") or row.get("format") or ""

        if source_path.is_file():
            if not _SENSITIVE_FILENAME_HINT.search(source_path.name):
                if storage == "config-subobject":
                    # Strict field-level whitelist for config subobjects (audit P0):
                    # Never copy the entire host config file (e.g. settings.json with sibling tokens/telemetry/keys).
                    if object_type == "mcp":
                        try:
                            from migration_core import parse_mcp_document, emit_mcp_document
                            raw_text = source_path.read_text(encoding="utf-8")
                            servers = parse_mcp_document(raw_text, format_name)
                            emitted_text, _ = emit_mcp_document(servers, format_name)
                            objects[relative] = emitted_text.encode("utf-8")
                        except Exception:
                            pass
                    elif object_type == "instructions":
                        try:
                            from migration_core import parse_instruction, emit_instruction
                            raw_text = source_path.read_text(encoding="utf-8")
                            instruction = parse_instruction(raw_text, format_name, scope, storage)
                            emitted_text, _ = emit_instruction(instruction, format_name)
                            objects[relative] = emitted_text.encode("utf-8")
                        except Exception:
                            pass
                    else:
                        # Refuse to copy raw host config files for unsupported subobject types
                        pass
                else:
                    objects[relative] = source_path.read_bytes()
        elif source_path.is_dir():
            # Deep recursive collection up to MAX_DIR_DEPTH
            _collect_tree(source_path, relative, objects, depth=0)
    return objects


def _collect_tree(dir_path: Path, prefix: str, out: dict[str, bytes], depth: int = 0) -> None:
    if depth > MAX_DIR_DEPTH:
        return
    for item in sorted(dir_path.iterdir()):
        if item.is_symlink():
            continue
        if _SENSITIVE_FILENAME_HINT.search(item.name):
            continue
        rel = f"{prefix}/{item.name}"
        if item.is_file():
            out[rel] = item.read_bytes()
        elif item.is_dir():
            _collect_tree(item, rel, out, depth + 1)


def _path_for_object(
    object_type: str, product: str, profile: str, scope: str, canonical: str
) -> str:
    """Build a sanitized stable relative path under ``objects/``."""
    safe_canonical = canonical.strip("/\\").replace("~", "home").replace("..", "_")
    safe_canonical = re.sub(r"[/\\:]+", "/", safe_canonical)
    return f"{object_type}/{product}/{profile}/{scope}/{safe_canonical}"


def restore_bundle_objects(
    bundle_root: Path,
    destination_root: Path,
    *,
    dry_run: bool = False,
) -> dict[str, Any]:
    """Extract files from ``bundle/objects/`` safely into destination tree."""
    bundle_root = bundle_root.resolve()
    destination_root = destination_root.resolve()
    objects_root = bundle_root / ACB_OBJECTS_DIR
    if not objects_root.is_dir():
        raise ACBError(f"bundle has no objects/ directory: {bundle_root}")
    written: list[dict[str, Any]] = []
    skipped: list[dict[str, str]] = []
    for source in sorted(objects_root.rglob("*")):
        if not source.is_file() or source.is_symlink():
            continue
        relative = source.relative_to(objects_root).as_posix()
        try:
            target = validate_path_containment(relative, destination_root)
        except ACBIntegrityError as error:
            skipped.append({"path": relative, "reason": str(error)})
            continue

        try:
            data = source.read_bytes()
            scan_object_bytes(data, relative)
        except ACBSecretLeak as error:
            skipped.append({"path": relative, "reason": str(error)})
            continue

        if not dry_run:
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(data)
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
    """Perform closed-world verification of ACB bundle integrity."""
    bundle_root = bundle_root.resolve()
    if not bundle_root.is_dir():
        return [f"bundle directory not found: {bundle_root}"]

    checksums_path = bundle_root / ACB_CHECKSUMS_NAME
    if not checksums_path.is_file() or checksums_path.is_symlink():
        return [f"missing or invalid {ACB_CHECKSUMS_NAME}"]

    try:
        checksums = json.loads(checksums_path.read_text(encoding="utf-8"))
    except Exception as error:
        return [f"corrupted {ACB_CHECKSUMS_NAME}: {error}"]

    errors: list[str] = []

    # 1. Closed-world file enumeration: actual files == expected files
    expected_files = set(checksums.keys())
    actual_files: set[str] = set()

    for path in sorted(bundle_root.rglob("*")):
        # Reject non-regular files: symlinks, sockets, FIFOs, devices
        st = path.lstat()
        if stat.S_ISLNK(st.st_mode) or stat.S_ISFIFO(st.st_mode) or stat.S_ISSOCK(st.st_mode) or stat.S_ISCHR(st.st_mode) or stat.S_ISBLK(st.st_mode):
            errors.append(f"illegal non-regular file in bundle: {path.relative_to(bundle_root).as_posix()}")
            continue
        if path.is_file():
            rel_posix = path.relative_to(bundle_root).as_posix()
            if rel_posix != ACB_CHECKSUMS_NAME:
                actual_files.add(rel_posix)

    extra_files = actual_files - expected_files
    if extra_files:
        for extra in sorted(extra_files):
            errors.append(f"unexpected extra file in bundle: {extra}")

    missing_files = expected_files - actual_files
    if missing_files:
        for missing in sorted(missing_files):
            errors.append(f"missing file: {missing}")

    # 2. Checksum validation for all listed files
    for relative, expected in sorted(checksums.items()):
        target = bundle_root / relative
        if target.is_file() and not target.is_symlink():
            actual = sha256_file(target)
            if actual != expected:
                errors.append(f"checksum mismatch: {relative}")

    # 3. Validate JSON schemas & secret scans
    for json_name in ACB_JSON_FILES:
        target = bundle_root / json_name
        if target.is_file():
            try:
                payload = json.loads(target.read_text(encoding="utf-8"))
                assert_no_lateral_secrets(payload)
            except Exception as error:
                errors.append(f"invalid JSON payload in {json_name}: {error}")

    # 3b. Re-scan every stored object with the same strict secret/binary
    # scanner used at write time (audit #7). A bundle that passed write-time
    # scanning but was later tampered (or supplied by an untrusted source)
    # must still be rejected at verify time. We also re-apply the
    # resource safety limits (file count, per-file size, total size, depth).
    objects_root = bundle_root / ACB_OBJECTS_DIR
    if not objects_root.is_dir():
        errors.append(f"bundle has no {ACB_OBJECTS_DIR}/ directory")
    else:
        total_object_bytes = 0
        max_depth_seen = 0
        object_count = 0
        for source in sorted(objects_root.rglob("*")):
            if not source.is_file() or source.is_symlink():
                continue
            object_count += 1
            rel = source.relative_to(objects_root).as_posix()
            depth = len(Path(rel).parts)
            max_depth_seen = max(max_depth_seen, depth)
            if object_count > MAX_BUNDLE_FILES:
                errors.append(
                    f"object file count exceeded limit ({MAX_BUNDLE_FILES}): {rel}"
                )
                break
            try:
                data = source.read_bytes()
            except Exception as error:
                errors.append(f"cannot read object {rel}: {error}")
                continue
            if len(data) > MAX_FILE_SIZE:
                errors.append(
                    f"object size exceeded limit ({MAX_FILE_SIZE} bytes): {rel}"
                )
            total_object_bytes += len(data)
            try:
                scan_object_bytes(data, rel)
            except ACBSecretLeak as error:
                errors.append(f"secret/binary violation in object {rel}: {error}")
        if max_depth_seen > MAX_DIR_DEPTH:
            errors.append(
                f"object directory depth exceeded limit ({MAX_DIR_DEPTH}): {max_depth_seen}"
            )
        if total_object_bytes > MAX_TOTAL_SIZE:
            errors.append(
                f"object total size exceeded limit ({MAX_TOTAL_SIZE} bytes)"
            )

    return errors


class BundleSurfaceProvider:
    """Provides virtual surface items and content from verified bundle objects."""

    def __init__(self, bundle_root: Path):
        self.bundle_root = bundle_root.resolve()
        self.objects_root = self.bundle_root / ACB_OBJECTS_DIR
        self.manifest = load_manifest(self.bundle_root)

    def get_object_tree(self, object_type: str, product: str, profile: str, scope: str) -> list[Path]:
        """Find all files belonging to a specific surface object in the bundle."""
        target_dir = self.objects_root / object_type / product / profile / scope
        if not target_dir.is_dir():
            return []
        return sorted(p for p in target_dir.rglob("*") if p.is_file())


def load_manifest(bundle_root: Path) -> ACBManifest:
    bundle_root = bundle_root.resolve()
    return ACBManifest.from_dict(
        json.loads((bundle_root / ACB_MANIFEST_NAME).read_text(encoding="utf-8"))
    )


def make_bundle_id(timestamp: datetime | None = None) -> str:
    timestamp = timestamp or datetime.now(timezone.utc)
    return f"acb-{timestamp.strftime('%Y%m%dT%H%M%SZ')}"
