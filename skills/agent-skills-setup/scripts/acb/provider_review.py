"""Preserve reviewed Codex provider/profile fields without shared-config bytes.

Output is inert source material for the destination agent's field-level TOML
merge. It never transports login state, activates a provider, or writes an IDE.
"""

from __future__ import annotations

import hashlib
import importlib
import json
import os
import re
import stat
import urllib.parse
from typing import Any

from acb.bundle import (
    ACBSecretLeak, MAX_BUNDLE_FILES, MAX_FILE_SIZE, MAX_TOTAL_SIZE, scan_object_bytes,
)
from acb.preferences import _portable_canonical
from acb.mcp_review import _safe_review_url, _safe_review_value


PROVIDER_FIELDS = frozenset({
    "name", "base_url", "wire_api", "env_key", "requires_openai_auth",
    "request_max_retries", "stream_max_retries", "stream_idle_timeout_ms",
    "http_headers", "env_http_headers", "supports_websockets",
})
PROFILE_FIELDS = frozenset({
    "model", "model_provider", "model_reasoning_effort", "personality",
})
_NAME = re.compile(r"^[A-Za-z0-9][A-Za-z0-9_.-]{0,127}$")
_ENV_NAME = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")


def _json_bytes(value: Any) -> bytes:
    return (json.dumps(value, ensure_ascii=False, sort_keys=True, indent=2, allow_nan=False) + "\n").encode("utf-8")


def _safe_name(value: Any) -> bool:
    if not isinstance(value, str) or not _NAME.fullmatch(value):
        return False
    try:
        scan_object_bytes(_json_bytes({"name": value}), "provider-review.json")
    except ACBSecretLeak:
        return False
    return True


def collect_provider_review(
    registry: Any, *, selected_profiles: set[str], scopes: set[str]
) -> tuple[dict[str, bytes], list[dict[str, Any]], dict[str, list[str]], list[dict[str, Any]]]:
    """Return files, grouped review objects, exact bindings and omission tasks."""
    from migration_core import (
        LossReport,
        ensure_no_symlink_components, scope_matches,
    )

    files: dict[str, bytes] = {}
    manifests: dict[str, dict[str, Any]] = {}
    bindings: dict[str, list[str]] = {}
    tasks: list[dict[str, Any]] = []
    seen: set[tuple[str, str, str, str]] = set()
    for selector in sorted(selected_profiles):
        product, profile, profile_data = registry.profile(selector)
        if product != "codex":
            continue
        for entry in profile_data.get("surfaces", {}).get("preferences", []):
            scope = str(entry.get("scope", ""))
            if (entry.get("format") != "toml"
                    or not scope_matches(scope, ",".join(sorted(scopes)))):
                continue
            original = str(entry.get("path", ""))
            identity = (product, profile, scope, original)
            if identity in seen:
                continue
            seen.add(identity)
            canonical = _portable_canonical(original, registry)
            task: dict[str, Any] = {
                "product": product, "profile": profile, "scope": scope,
                "object_type": "provider-settings", "canonical_path": canonical,
                "status": "excluded", "reason": "unsupported-preferences-surface",
                "automatic_restore": False, "payload": [], "omissions": [],
                "next_action": "The agent reviews these allowlisted provider/profile fields and merges supported fields into native Codex TOML on the destination. Remap endpoints and bind credentials locally; never overwrite the shared config or activate unreviewed content.",
            }
            tasks.append(task)
            if entry.get("storage") != "config-subobject" or entry.get("policy") != "manual-template":
                continue
            try:
                source, boundary = registry.resolve_path(entry)
                ensure_no_symlink_components(source, boundary)
                if source.is_symlink():
                    raise ValueError("unsafe-source")
                if not source.exists():
                    task.update(status="not-present", reason="source-not-present")
                    continue
                flags = os.O_RDONLY | getattr(os, "O_NOFOLLOW", 0) | getattr(os, "O_NONBLOCK", 0)
                descriptor = os.open(source, flags)
                with os.fdopen(descriptor, "rb") as reader:
                    info = os.fstat(reader.fileno())
                    if not stat.S_ISREG(info.st_mode) or info.st_size > MAX_FILE_SIZE:
                        task.update(reason="source-not-regular-or-too-large")
                        continue
                    raw = reader.read(MAX_FILE_SIZE + 1)
                if len(raw) > MAX_FILE_SIZE:
                    task.update(reason="source-too-large")
                    continue
                parser = importlib.import_module("tomllib")
                document = parser.loads(raw.decode("utf-8"))
                if not isinstance(document, dict):
                    raise ValueError("invalid-document")
            except ModuleNotFoundError:
                task.update(status="missing-parser", reason="tomllib-unavailable")
                continue
            except (OSError, ValueError, UnicodeError):
                task.update(status="malformed", reason="source-unreadable-unsafe-or-invalid")
                continue

            omissions: list[dict[str, Any]] = task["omissions"]
            redactions: list[dict[str, Any]] = []
            required_credentials: set[str] = set()

            def omit(section: str, name: str, reason: str, field: str = "") -> None:
                item = {"section": section, "entry": name, "reason": reason}
                if field:
                    item["field"] = field
                omissions.append(item)

            def selected_fields(section: str, name: str, raw_entry: Any) -> dict[str, Any] | None:
                if not isinstance(raw_entry, dict):
                    omit(section, name, "entry-not-object")
                    return None
                allowed = PROVIDER_FIELDS if section == "model_providers" else PROFILE_FIELDS
                result: dict[str, Any] = {}
                entry_credentials: set[str] = set()
                unknown = [key for key in raw_entry if key not in allowed]
                safe_unknown = sorted(key for key in unknown if _safe_name(key))
                if unknown:
                    omissions.append({
                        "section": section, "entry": name, "reason": "unknown-fields-not-captured",
                        "fields": safe_unknown, "unsafe_field_names_omitted": len(unknown) - len(safe_unknown),
                    })
                for field in sorted(allowed & raw_entry.keys()):
                    value = raw_entry[field]
                    if field in {"http_headers", "env_http_headers"}:
                        if not isinstance(value, dict):
                            omit(section, name, "header-map-required", field)
                            continue
                        headers: dict[str, str] = {}
                        for header, header_value in value.items():
                            if not _safe_name(header) or not isinstance(header_value, str):
                                omit(section, name, "unsafe-header-not-captured", field)
                                continue
                            if field == "env_http_headers":
                                if not _ENV_NAME.fullmatch(header_value):
                                    omit(section, name, "environment-variable-name-required", field)
                                    continue
                                headers[header] = header_value
                                entry_credentials.add(header_value)
                            else:
                                headers[header], changed = _safe_review_value(header, header_value)
                                entry_credentials.update(re.findall(r"\$\{([A-Za-z_][A-Za-z0-9_]*)\}", headers[header]))
                                if changed:
                                    redactions.append({"section": section, "entry": name, "field": field, "header": header})
                        result[field] = headers
                    elif field == "base_url":
                        if not isinstance(value, str):
                            omit(section, name, "string-required", field)
                            continue
                        try:
                            losses = LossReport()
                            result[field], removed_query, query_credentials = _safe_review_url(value, name, losses)
                            entry_credentials.update(query_credentials)
                            if result[field] != value:
                                redactions.append({
                                    "section": section, "entry": name, "field": field,
                                    "query_fields_removed": [key for key in removed_query if _safe_name(key)],
                                })
                        except ValueError:
                            omit(section, name, "invalid-url-not-captured", field)
                    elif field == "env_key":
                        if isinstance(value, str) and _ENV_NAME.fullmatch(value):
                            result[field] = value
                            entry_credentials.add(value)
                        else:
                            omit(section, name, "environment-variable-name-required", field)
                    elif field == "requires_openai_auth":
                        if isinstance(value, bool):
                            result[field] = value
                        else:
                            omit(section, name, "boolean-required", field)
                    elif field in {"request_max_retries", "stream_max_retries", "stream_idle_timeout_ms"}:
                        if type(value) is int and value >= 0:
                            result[field] = value
                        else:
                            omit(section, name, "nonnegative-integer-required", field)
                    elif isinstance(value, str):
                        result[field] = value
                    else:
                        omit(section, name, "string-required", field)
                try:
                    scan_object_bytes(_json_bytes({name: result}), "provider-review.json")
                except ACBSecretLeak:
                    omit(section, name, "secret-rejected-entry")
                    return None
                required_credentials.update(entry_credentials)
                return result or None

            payload: dict[str, Any] = {
                "schema_version": 1, "review_only": True, "automatic_restore": False,
                "product": product, "profile": profile, "scope": scope,
                "canonical_path": canonical, "model_providers": {}, "profiles": {},
            }
            chosen_provider = document.get("model_provider")
            if chosen_provider is not None:
                if _safe_name(chosen_provider):
                    payload["model_provider"] = chosen_provider
                else:
                    omit("root", "model_provider", "unsafe-provider-selector")
            for section in ("model_providers", "profiles"):
                source_entries = document.get(section, {})
                if not isinstance(source_entries, dict):
                    omit(section, "<unavailable>", "section-not-object")
                    continue
                for name, raw_entry in source_entries.items():
                    if not _safe_name(name):
                        omit(section, "<unsafe-entry-name>", "unsafe-entry-name")
                        continue
                    captured = selected_fields(section, name, raw_entry)
                    if captured is not None:
                        payload[section][name] = captured
            task["redactions"] = redactions
            task["required_credentials"] = sorted(required_credentials)
            task["providers_captured"] = len(payload["model_providers"])
            task["profiles_captured"] = len(payload["profiles"])
            if not (payload["model_providers"] or payload["profiles"] or "model_provider" in payload):
                task.update(reason="no-safe-provider-profile-fields")
                continue
            payload["unknown_fields"] = [item for item in omissions if item["reason"] == "unknown-fields-not-captured"]
            payload["required_credentials"] = sorted(required_credentials)
            payload["redactions"] = redactions
            payload["value_note"] = "Literal headers and URL query values were omitted; the destination agent reconstructs non-secret values, while the user supplies authentication locally."
            fingerprint = hashlib.sha256(original.encode("utf-8")).hexdigest()[:16]
            group = f"review/{product}/{profile}/{scope}"
            relative = f"{group}/provider-settings-{fingerprint}.json"
            data = _json_bytes(payload)
            try:
                scan_object_bytes(data, relative)
            except ACBSecretLeak:
                task.update(reason="secret-rejected-payload")
                continue
            if len(data) > MAX_FILE_SIZE:
                task.update(reason="review-payload-too-large")
                continue
            if len(files) >= MAX_BUNDLE_FILES or sum(map(len, files.values())) + len(data) > MAX_TOTAL_SIZE:
                task.update(reason="review-resource-limit")
                continue
            files[relative] = data
            bindings.setdefault(group, []).append(relative)
            manifests.setdefault(group, {
                "surface": "review", "object_type": "review", "product": product,
                "profile": profile, "scope": scope, "status": "manual-rebuild",
                "source_format": "inert-provider-settings", "automatic_restore": False,
            })
            task.update(
                status="partial-review" if omissions or redactions else "review-captured",
                reason="provider-profile-fields-captured", payload=[f"objects/{relative}"],
            )
    return files, list(manifests.values()), bindings, tasks
