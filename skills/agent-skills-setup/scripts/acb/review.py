"""Collect inert, scanned review material for another agent's manual rebuild.

These objects deliberately have no restore source or target. They preserve
standalone text only; shared configuration must use a format-specific adapter.
"""

from __future__ import annotations

import hashlib
import os
import re
import stat
from pathlib import Path
from typing import Any

from acb import bundle

REVIEW_TYPES = frozenset({
    "prompt", "prompts", "command", "commands", "agent", "agents",
    "hook", "hooks", "workflow", "workflows",
    "rules", "modes", "personas", "automation", "cron",
})
REVIEW_STORAGE = frozenset({"file", "directory", "hierarchy"})
FORBIDDEN_POLICIES = bundle.FORBIDDEN_SNAPSHOT_POLICIES - {"disabled-draft-only"}
_SENSITIVE_NAME = re.compile(
    r"(?i)(^\.env(?:\..*)?$|\.(?:pem|key|p12|pfx)$|^id_(?:rsa|ed25519|ecdsa)"
    r"|(?:^|[._-])(?:credentials?|oauth|auth|secrets?|tokens?|passwords?)(?:[._-]|$))"
)


def _segment(value: str) -> str:
    """Keep path components portable and collisions visible after sanitizing."""
    safe = re.sub(r"[^A-Za-z0-9_.+-]", "-", value).strip(".")[:100]
    if not safe or safe != value:
        safe = (safe or "item") + "-" + hashlib.sha256(value.encode()).hexdigest()[:12]
    return safe


def _canonical(row: dict[str, Any]) -> str:
    value = str(row.get("canonical_path") or row.get("path") or "<unavailable>")
    # Registry paths normally use ~, environment names or workspace-relative
    # paths. Never serialize a device's resolved absolute source path.
    if value.startswith(("/", "\\")) or re.match(r"^[A-Za-z]:", value):
        return "<external-source>"
    return value


def collect_review_materials(
    rows: list[dict], *, selected_profiles: set[str], scopes: set[str]
) -> tuple[dict[str, bytes], list[dict], dict[str, list[str]], list[dict]]:
    """Capture selected standalone review surfaces without enabling them.

    Returns object-relative bytes, grouped manifest objects, their exact file
    map, and actionable per-surface/per-file tasks. Failure messages are stable
    reason codes, never raw exceptions or local absolute paths. File/depth/size
    limits match the bundle limits; failed files do not discard safe siblings.
    """
    from migration_core import scope_matches

    objects: dict[str, bytes] = {}
    manifests: dict[str, dict] = {}
    file_map: dict[str, list[str]] = {}
    tasks: list[dict] = []
    total_size = 0
    examined = 0
    seen: set[tuple[str, str, str, str]] = set()

    for row in rows:
        product = str(row.get("product") or "")
        profile = str(row.get("profile") or "")
        scope = str(row.get("scope") or "")
        object_type = str(row.get("object_type") or "")
        if (f"{product}/{profile}" not in selected_profiles or not scope_matches(scope, ",".join(sorted(scopes)))
                or object_type not in REVIEW_TYPES):
            continue
        canonical = _canonical(row)
        group = "/".join(("review", _segment(product), _segment(profile), _segment(scope)))
        task_base = {
            "product": product, "profile": profile, "scope": scope,
            "object_type": object_type, "canonical_path": canonical,
            "status": "manual-rebuild", "automatic_restore": False,
        }

        def record(reason: str, *, relative: str = "", payload: str = "") -> None:
            task = dict(task_base)
            task.update({
                "reason": reason, "payload_path": payload,
                "next_action": (
                    "Review the inert text, adapt paths and dependencies, then explicitly "
                    "approve and verify activation in the target IDE."
                    if payload else
                    "Recover or recreate this surface from the original IDE; resolve the "
                    "reported exclusion before attempting a reviewed manual rebuild."
                ),
            })
            if relative:
                task["source_relative_path"] = relative
            tasks.append(task)

        if row.get("policy") in FORBIDDEN_POLICIES:
            record("excluded-by-policy")
            continue
        if row.get("storage") not in REVIEW_STORAGE:
            record("shared-or-unsupported-storage")
            continue
        resolved = row.get("resolved_path")
        if not resolved:
            record("source-unavailable")
            continue
        source = Path(resolved)
        identity = (group, object_type, canonical, str(source))
        if identity in seen:
            continue
        seen.add(identity)
        # Include the canonical surface and actual alias in the digest so two
        # same-named surfaces cannot overwrite one another in the same group.
        digest = hashlib.sha256(
            (canonical + "\0" + str(row.get("path") or canonical)
             + "\0" + str(source)).encode()
        ).hexdigest()[:16]
        root = f"{group}/{_segment(object_type)}/{_segment(source.name)}-{digest}"
        # A root symlink (including a missing symlink target) is an explicit
        # failure, not a nonexistent surface. Never traverse symlink parents
        # below the resolved registry boundary either.
        boundary = Path(row["boundary"]) if row.get("boundary") else source.parent
        try:
            relative_source = source.relative_to(boundary)
            component = boundary
            components = [boundary]
            for part in relative_source.parts:
                component /= part
                components.append(component)
            if any(component.is_symlink() for component in components):
                record("symlink-not-captured")
                continue
            mode = source.lstat().st_mode
        except ValueError:
            record("source-outside-boundary")
            continue
        except FileNotFoundError:
            record("source-missing")
            continue
        except OSError:
            record("source-unreadable")
            continue
        if _SENSITIVE_NAME.search(source.name):
            record("sensitive-name-not-captured")
            continue

        captured: list[str] = []
        captured_modes: dict[str, int] = {}
        failures = 0

        def fail(reason: str, relative: str) -> None:
            nonlocal failures
            failures += 1
            record(reason, relative=relative)

        def collect(path: Path, parts: tuple[str, ...], depth: int) -> None:
            nonlocal total_size, examined
            relative = "/".join(_segment(part) for part in parts)
            if examined >= bundle.MAX_BUNDLE_FILES:
                fail("file-count-limit", relative)
                return
            examined += 1
            # The verifier counts all components below objects/, including
            # review/product/profile/scope/type/source. Reserve those layers.
            if len(Path(root).parts) + max(1, len(parts)) > bundle.MAX_DIR_DEPTH:
                fail("directory-depth-limit", relative)
                return
            if _SENSITIVE_NAME.search(path.name):
                fail("sensitive-name-not-captured", relative)
                return
            try:
                item_mode = path.lstat().st_mode
                if stat.S_ISLNK(item_mode):
                    fail("symlink-not-captured", relative)
                    return
                if stat.S_ISDIR(item_mode):
                    # Bound directory enumeration as well as captured bytes.
                    with os.scandir(path) as entries:
                        children = []
                        for entry in entries:
                            if len(children) >= bundle.MAX_BUNDLE_FILES:
                                fail("file-count-limit", relative)
                                break
                            children.append(entry.name)
                    for child in sorted(children):
                        collect(path / child, (*parts, child), depth + 1)
                    return
                if not stat.S_ISREG(item_mode):
                    fail("nonregular-file-not-captured", relative)
                    return
                # O_NOFOLLOW where available closes the final-component race;
                # fstat verifies the opened file is ordinary before reading.
                flags = os.O_RDONLY | getattr(os, "O_NOFOLLOW", 0) | getattr(os, "O_NONBLOCK", 0)
                descriptor = os.open(path, flags)
                with os.fdopen(descriptor, "rb") as reader:
                    info = os.fstat(reader.fileno())
                    if not stat.S_ISREG(info.st_mode):
                        fail("nonregular-file-not-captured", relative)
                        return
                    if info.st_size > bundle.MAX_FILE_SIZE:
                        fail("file-size-limit", relative)
                        return
                    data = reader.read(bundle.MAX_FILE_SIZE + 1)
                if len(data) > bundle.MAX_FILE_SIZE:
                    fail("file-size-limit", relative)
                    return
                if total_size + len(data) > bundle.MAX_TOTAL_SIZE:
                    fail("total-size-limit", relative)
                    return
                if bundle.is_binary_bytes(data):
                    fail("binary-not-captured", relative)
                    return
                destination = f"{root}/{relative}" if relative else f"{root}/{_segment(path.name)}"
                bundle.scan_object_bytes(data, destination)
                if destination in objects:
                    fail("payload-path-conflict", relative)
                    return
                objects[destination] = data
                total_size += len(data)
                captured.append(destination)
                captured_modes[destination] = stat.S_IMODE(info.st_mode) & 0o777
            except bundle.ACBSecretLeak:
                fail("secret-not-captured", relative)
            except FileNotFoundError:
                fail("source-missing", relative)
            except OSError:
                fail("source-unreadable", relative)

        if stat.S_ISREG(mode):
            collect(source, (), 0)
        elif stat.S_ISDIR(mode):
            collect(source, (), 0)
        else:
            fail("nonregular-file-not-captured", "")
        if captured:
            file_map.setdefault(group, []).extend(captured)
            manifests.setdefault(group, {
                "surface": "review", "object_type": "review", "product": product,
                "profile": profile, "scope": scope, "status": "manual-rebuild",
                "source_format": "inert-reviewed-text", "automatic_restore": False,
            })
            record("review-material-partially-captured" if failures else "review-material-captured",
                   payload=f"objects/{root}")
            tasks[-1]["file_modes"] = captured_modes
        elif not failures:
            record("source-empty")
    return objects, list(manifests.values()), file_map, tasks
