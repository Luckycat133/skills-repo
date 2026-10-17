"""Capture explicitly allowlisted scalar preferences as inert review material.

Shared configuration is never copied, merged, or written back to an IDE. Source
documents may contain unrelated credentials; only selected scalar fields enter
the existing ACB secret scanner and the resulting review payload.
"""

from __future__ import annotations

import hashlib
import importlib
import json
import math
import re
from pathlib import Path
from typing import Any

from acb.bundle import ACBSecretLeak, MAX_FILE_SIZE, scan_object_bytes


_UNSAFE_FIELD = re.compile(
    r"(?i)(credential|secret|token|password|api.?key|authorization|authentication|"
    r"trust|permission|approval|sandbox|(^|[_.-])env($|[_.-])|"
    r"(^|[_.-])hooks?($|[_.-])|(^|[_.-])projects?($|[_.-]))"
)
_FIELD_NAME = re.compile(r"^[A-Za-z][A-Za-z0-9_.-]*$")


class UnsupportedYAML(ValueError):
    """The bounded data-only YAML subset cannot represent this document."""


def _decode_yaml_subset(text: str) -> Any:
    """Read bounded indentation maps/sequences and scalar/flat flow arrays.

    No constructors, imports, tags, aliases, anchors, merge keys, block scalars,
    multiline quoted values, flow maps or multiple documents are evaluated.
    Unsupported syntax fails the whole document instead of guessing its shape.
    """
    from migration_core import _strip_frontmatter_comment

    def unsupported() -> None:
        raise UnsupportedYAML("yaml-unsupported-or-invalid")

    if len(text.splitlines()) > 20000:
        unsupported()
    tokens: list[tuple[int, str]] = []
    document_marker = False
    for line in text.splitlines():
        if "\t" in line:
            unsupported()
        content = _strip_frontmatter_comment(line.lstrip(" "))
        if not content:
            continue
        indentation = len(line) - len(line.lstrip(" "))
        if content == "---" and not tokens and not document_marker:
            document_marker = True
            continue
        if content in {"---", "..."} or content.startswith("%"):
            unsupported()
        tokens.append((indentation, content))
    if not tokens:
        return {}
    if tokens[0][0] != 0:
        unsupported()
    if len(tokens) == 1 and tokens[0][1] in {"{}", "[]"}:
        return {} if tokens[0][1] == "{}" else []
    nodes = 0

    def scalar(value: str) -> Any:
        value = value.strip()
        if not value:
            return None
        if value.startswith('"'):
            try:
                result = json.loads(value)
            except ValueError:
                unsupported()
            if not isinstance(result, str):
                unsupported()
            return result
        if value.startswith("'"):
            if not re.fullmatch(r"'(?:[^']|'')*'", value):
                unsupported()
            return value[1:-1].replace("''", "'")
        if value == "{}":
            return {}
        if value.startswith("["):
            if not value.endswith("]"):
                unsupported()
            body = value[1:-1].strip()
            if not body:
                return []
            parts: list[str] = []
            start = 0
            quote: str | None = None
            escaped = False
            for index, character in enumerate(body):
                if escaped:
                    escaped = False
                elif character == "\\" and quote == '"':
                    escaped = True
                elif quote:
                    if character == quote:
                        quote = None
                elif character in {'"', "'"}:
                    quote = character
                elif character in "[]{}":
                    unsupported()
                elif character == ",":
                    parts.append(body[start:index].strip())
                    start = index + 1
            parts.append(body[start:].strip())
            if quote or len(parts) > 5000 or any(not part for part in parts):
                unsupported()
            result = [scalar(part) for part in parts]
            if any(isinstance(item, (dict, list)) for item in result):
                unsupported()
            return result
        if value[0] in "&*!{}|>@`" or ": " in value or value.startswith(("- ", "? ")):
            unsupported()
        lowered = value.lower()
        if lowered in {"null", "~"}:
            return None
        if lowered in {"true", "false"}:
            return lowered == "true"
        if lowered in {".nan", ".inf", "+.inf", "-.inf"}:
            return float("nan" if lowered == ".nan" else "-inf" if lowered == "-.inf" else "inf")
        if re.fullmatch(r"[-+]?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?(?:[eE][-+]?[0-9]+)?", value):
            if len(value) > 256:
                unsupported()
            return float(value) if any(character in value for character in ".eE") else int(value)
        return value

    def pair(content: str) -> tuple[str, str] | None:
        quote: str | None = None
        escaped = False
        for index, character in enumerate(content):
            if escaped:
                escaped = False
            elif character == "\\" and quote == '"':
                escaped = True
            elif quote:
                if character == quote:
                    quote = None
            elif character in {'"', "'"}:
                quote = character
            elif character == ":" and (index + 1 == len(content) or content[index + 1] == " "):
                raw_key = content[:index]
                if re.fullmatch(r"[A-Za-z_][A-Za-z0-9_.-]*", raw_key):
                    key = raw_key
                elif raw_key.startswith(('"', "'")):
                    key = scalar(raw_key)
                    if not isinstance(key, str):
                        unsupported()
                else:
                    return None
                return key, content[index + 1:].strip()
        return None

    def block(offset: int, indentation: int, depth: int) -> tuple[Any, int]:
        nonlocal nodes
        if depth > 20:
            unsupported()
        sequence = tokens[offset][1] == "-" or tokens[offset][1].startswith("- ")
        result: Any = [] if sequence else {}

        def value(raw: str, offset: int, parent_indent: int) -> tuple[Any, int]:
            if raw:
                return scalar(raw), offset
            if offset < len(tokens) and (tokens[offset][0] > parent_indent or (
                    tokens[offset][0] == parent_indent and (tokens[offset][1] == "-" or tokens[offset][1].startswith("- ")))):
                return block(offset, tokens[offset][0], depth + 1)
            return None, offset

        def mapping_item(mapping: dict[str, Any], content: str, offset: int, key_indent: int) -> int:
            entry = pair(content)
            if entry is None or entry[0] in mapping:
                unsupported()
            mapping[entry[0]], offset = value(entry[1], offset, key_indent)
            return offset

        while offset < len(tokens) and tokens[offset][0] == indentation:
            content = tokens[offset][1]
            is_item = content == "-" or content.startswith("- ")
            if sequence != is_item:
                break
            nodes += 1
            if nodes > 20000:
                unsupported()
            offset += 1
            if not sequence:
                offset = mapping_item(result, content, offset, indentation)
                continue
            raw = content[1:].lstrip()
            if pair(raw) is not None:
                item: dict[str, Any] = {}
                offset = mapping_item(item, raw, offset, indentation + 2)
                while offset < len(tokens) and tokens[offset][0] == indentation + 2:
                    offset = mapping_item(item, tokens[offset][1], offset + 1, indentation + 2)
                result.append(item)
            else:
                item, offset = value(raw, offset, indentation)
                result.append(item)
        if offset < len(tokens) and tokens[offset][0] > indentation:
            unsupported()
        return result, offset

    result, offset = block(0, 0, 0)
    if offset != len(tokens):
        unsupported()
    return result


def valid_review_fields(value: Any) -> bool:
    """Reject wildcard selectors, empty paths, duplicate paths and unsafe keys."""
    if not isinstance(value, list) or not value:
        return False
    seen: set[tuple[str, ...]] = set()
    for field in value:
        if not isinstance(field, list) or not field:
            return False
        if not all(
            isinstance(part, str) and _FIELD_NAME.fullmatch(part)
            and not _UNSAFE_FIELD.search(part) for part in field
        ):
            return False
        key = tuple(field)
        if key in seen:
            return False
        seen.add(key)
    return True


def valid_review_value(value: Any, field: list[str]) -> bool:
    """Finite scalars plus explicitly selected, bounded string-array roles."""
    if field and field[-1] == "roles" and isinstance(value, list):
        return len(value) <= 128 and all(isinstance(item, str) and len(item) <= 1024 for item in value)
    return (value is None or isinstance(value, (str, bool, int, float))) and not (
        isinstance(value, float) and not math.isfinite(value)
    )


def _decode_preferences(data: bytes, format_name: str) -> dict[str, Any]:
    if len(data) > MAX_FILE_SIZE:
        raise ValueError("preference-source-too-large")
    text = data.decode("utf-8")
    if format_name == "toml":
        # No fallback installation or third-party parser on older Python.
        parser = importlib.import_module("tomllib")
        decoded = parser.loads(text)
    elif format_name in {"json", "jsonc"}:
        if format_name == "jsonc":
            from migration_core import _strip_jsonc

            text = _strip_jsonc(text)
        decoded = json.loads(text)
    elif format_name in {"yaml", "yml"}:
        decoded = _decode_yaml_subset(text)
    else:
        raise ValueError("unsupported-format")
    if not isinstance(decoded, dict):
        raise ValueError("root-not-object")
    return decoded


def _portable_canonical(value: str, registry: Any) -> str:
    """Do not serialize custom registry entries' machine-specific locations."""
    path = Path(value)
    if not path.is_absolute() and not re.match(r"^[A-Za-z]:[\\/]", value):
        return value
    for root, prefix in ((registry.home, "~/"), (registry.workspace, "")):
        try:
            return prefix + path.relative_to(root).as_posix()
        except ValueError:
            continue
    return "<external-preferences>"


def collect_preferences(
    registry: Any, selected_profiles: set[str], scopes: set[str]
) -> tuple[dict[str, bytes], list[dict[str, Any]], dict[str, list[str]], list[dict[str, Any]]]:
    """Return payload files, manifest entries, object bindings and manual tasks.

    Field paths are arrays: ``[\"editor.fontSize\"]`` is a literal dotted key;
    ``[\"model\", \"name\"]`` selects a nested scalar. Missing/non-scalar fields
    are explicitly reported and never claimed as captured preferences.
    """
    from migration_core import ensure_no_symlink_components, scope_matches

    files: dict[str, bytes] = {}
    objects: list[dict[str, Any]] = []
    bindings: dict[str, list[str]] = {}
    tasks: list[dict[str, Any]] = []
    seen: set[tuple[str, str, str, str]] = set()
    scope_expression = ",".join(sorted(scopes))
    for selector in sorted(selected_profiles):
        product, profile, profile_data = registry.profile(selector)
        for entry in profile_data.get("surfaces", {}).get("preferences", []):
            scope = entry.get("scope", "")
            if not scope_matches(scope, scope_expression):
                continue
            original_path = str(entry.get("path", ""))
            canonical = _portable_canonical(original_path, registry)
            identity = (product, profile, scope, original_path)
            if identity in seen:
                continue
            seen.add(identity)
            task: dict[str, Any] = {
                "product": product, "profile": profile, "scope": scope,
                "object_type": "preferences", "canonical_path": canonical,
                "status": "excluded", "reason": "invalid-review-fields",
                "next_action": "Review the selected fields and configure the target product manually; verify the values in its native UI.",
                "payload": [],
            }
            tasks.append(task)
            fields = entry.get("review_fields")
            if (not valid_review_fields(fields)
                    or entry.get("policy") != "manual-template"
                    or entry.get("storage") != "config-subobject"):
                continue
            try:
                source, boundary = registry.resolve_path(entry)
                ensure_no_symlink_components(source, boundary)
                if source.is_symlink():
                    raise ValueError("symlink")
                if not source.exists():
                    task.update(status="not-present", reason="source-not-present")
                    continue
                if not source.is_file() or source.stat().st_size > MAX_FILE_SIZE:
                    task.update(status="excluded", reason="source-not-regular-or-too-large")
                    continue
                source_bytes = source.read_bytes()
                task["source_content_sha256"] = hashlib.sha256(source_bytes).hexdigest()
                document = _decode_preferences(source_bytes, entry.get("format", ""))
            except ModuleNotFoundError:
                task.update(status="missing-parser", reason="tomllib-unavailable")
                continue
            except UnsupportedYAML:
                task.update(status="manual-review", reason="yaml-unsupported-or-invalid")
                continue
            except (OSError, ValueError, UnicodeError):
                # Parser exceptions can include source lines or absolute paths.
                task.update(status="malformed", reason="source-unreadable-unsafe-or-invalid")
                continue
            captured: list[dict[str, Any]] = []
            omitted: list[dict[str, Any]] = []
            for field in fields:
                value: Any = document
                for part in field:
                    if not isinstance(value, dict) or part not in value:
                        omitted.append({"path": field, "reason": "field-not-present"})
                        break
                    value = value[part]
                else:
                    if not valid_review_value(value, field):
                        omitted.append({"path": field, "reason": "field-not-scalar"})
                        continue
                    candidate = {"path": field, "value": value}
                    try:
                        scan_object_bytes(json.dumps(candidate, ensure_ascii=False, allow_nan=False).encode("utf-8"), "preferences.json")
                    except ACBSecretLeak:
                        omitted.append({"path": field, "reason": "secret-rejected"})
                        continue
                    captured.append(candidate)
            task["omitted_fields"] = omitted
            task["fields_captured"] = len(captured)
            if not captured:
                task.update(status="excluded", reason="no-safe-present-scalar-fields")
                continue
            fingerprint = hashlib.sha256(original_path.encode("utf-8")).hexdigest()[:16]
            relative = f"review/{product}/{profile}/{scope}/preferences-{fingerprint}.json"
            payload = {
                "schema_version": 1, "review_only": True,
                "product": product, "profile": profile, "scope": scope,
                "canonical_path": canonical, "fields": captured,
                "source_content_sha256": task["source_content_sha256"],
            }
            data = (json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True, allow_nan=False) + "\n").encode("utf-8")
            scan_object_bytes(data, relative)
            files[relative] = data
            bindings.setdefault(f"review/{product}/{profile}/{scope}", []).append(relative)
            objects.append({
                "object_id": f"review-preferences-{product}-{profile}-{scope}-{fingerprint}",
                "product": product, "profile": profile, "scope": scope,
                "surface": "review", "status": "manual-rebuild",
                "reason": "Allowlisted scalar preferences require manual target review.",
                "secret_status": "clean", "source_format": "json",
            })
            task.update(
                status="partial-review" if omitted else "review-captured",
                reason="some-fields-omitted" if omitted else "allowlisted-scalars-captured",
                payload=[f"objects/{relative}"],
            )
    return files, objects, bindings, tasks
