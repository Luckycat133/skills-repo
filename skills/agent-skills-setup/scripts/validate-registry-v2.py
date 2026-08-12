#!/usr/bin/env python3
"""Validate the versioned product/profile/surface migration registry."""

from __future__ import annotations

import argparse
import json
import re
import sys
from datetime import date
from pathlib import Path
from typing import Any


INDEX_LINK = re.compile(r"^- \[`([^`]+)`\]\(([^)]+)\)", re.MULTILINE)
PRODUCT_ID = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
REQUIRED_NEW_PRODUCTS = {
    "qoder",
    "qwen-code",
    "mistral-vibe",
    "factory-droid",
    "warp-oz",
    "pi",
    "crush",
}
EXPECTED_TEMPLATES: dict[str, str | None] = {
    "roo-code": "legacy-source-only",
    "void-editor": "legacy-source-only",
    "supermaven": "legacy-source-only",
    "firebase-studio": None,
    "codeium": "legacy-alias",
    "tongyi-lingma": "legacy-alias",
    "pieces": "provider",
    "emacs": "host-editor",
    "neovim": "host-editor",
    "helix": "host-editor",
    "devin": "cloud-ui",
    "v0": "cloud-ui",
    "lovable": "cloud-ui",
    "bolt-new": "cloud-ui",
    "trae-work": "cloud-ui",
    "cody": "cloud-ui",
}


def load_json(path: Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"{path}: root must be an object")
    return value


def resolve_profile(
    product_id: str,
    profile_id: str,
    profiles: dict[str, Any],
    stack: tuple[str, ...] = (),
) -> dict[str, Any]:
    if profile_id in stack:
        raise ValueError(
            f"products.{product_id}.profiles.{profile_id}: inheritance cycle"
        )
    profile = profiles.get(profile_id)
    if not isinstance(profile, dict):
        raise ValueError(
            f"products.{product_id}.profiles.{profile_id}: profile must be an object"
        )
    parent_id = profile.get("inherits")
    if parent_id is None:
        return dict(profile)
    if not isinstance(parent_id, str) or parent_id not in profiles:
        raise ValueError(
            f"products.{product_id}.profiles.{profile_id}: unknown parent {parent_id!r}"
        )
    resolved = resolve_profile(product_id, parent_id, profiles, stack + (profile_id,))
    resolved.update(profile)
    resolved.pop("inherits", None)
    return resolved


def validate_surface(
    location: str,
    surface_name: str,
    entries: Any,
    known_policies: set[str],
    errors: list[str],
) -> None:
    if not isinstance(entries, list) or not entries:
        errors.append(f"{location}.{surface_name}: expected a non-empty array")
        return
    for index, entry in enumerate(entries):
        item = f"{location}.{surface_name}[{index}]"
        if not isinstance(entry, dict):
            errors.append(f"{item}: expected an object")
            continue
        for field in ("scope", "storage", "path", "policy"):
            if not isinstance(entry.get(field), str) or not entry[field]:
                errors.append(f"{item}.{field}: expected a non-empty string")
        policy = entry.get("policy")
        if isinstance(policy, str) and policy not in known_policies:
            errors.append(f"{item}.policy: unknown policy {policy!r}")
        source_format = entry.get("format")
        if source_format is not None and not isinstance(source_format, str):
            errors.append(f"{item}.format: expected a string")


def validate_registry(
    registry_path: Path,
    index_path: Path,
    references_dir: Path,
    today: date,
    max_age_days: int,
) -> list[str]:
    registry = load_json(registry_path)
    errors: list[str] = []
    if registry.get("schema_version") != 2:
        errors.append("schema_version: expected 2")
    schema_reference = registry.get("$schema")
    if not isinstance(schema_reference, str) or not schema_reference:
        errors.append("$schema: expected a relative schema path")
    else:
        schema_path = registry_path.parent / schema_reference
        try:
            load_json(schema_path)
        except (OSError, ValueError, json.JSONDecodeError) as error:
            errors.append(f"$schema: cannot load {schema_reference}: {error}")

    try:
        registry_verified = date.fromisoformat(str(registry.get("verified_at", "")))
        age = (today - registry_verified).days
        if age < 0:
            errors.append("verified_at: cannot be in the future")
        elif age > max_age_days:
            errors.append(
                f"verified_at: registry is stale ({age} days; maximum {max_age_days})"
            )
    except ValueError:
        errors.append("verified_at: expected an ISO date")

    policies = registry.get("object_policies")
    if not isinstance(policies, dict) or not policies:
        errors.append("object_policies: expected a non-empty object")
        known_policies: set[str] = set()
    else:
        known_policies = {
            value for value in policies.values() if isinstance(value, str)
        }
        known_policies.add("source-only")

    templates = registry.get("profile_templates")
    if not isinstance(templates, dict) or not templates:
        errors.append("profile_templates: expected a non-empty object")
        templates = {}
    else:
        for template_id, template in templates.items():
            location = f"profile_templates.{template_id}"
            if not isinstance(template, dict):
                errors.append(f"{location}: expected an object")
                continue
            for field in ("kind", "migration_policy", "surfaces"):
                if field not in template:
                    errors.append(f"{location}.{field}: missing")

    products = registry.get("products")
    if not isinstance(products, dict) or not products:
        return errors + ["products: expected a non-empty object"]

    index_links = dict(INDEX_LINK.findall(index_path.read_text(encoding="utf-8")))
    missing_from_v2 = sorted(set(index_links) - set(products))
    if missing_from_v2:
        errors.append(f"products: missing index IDs: {', '.join(missing_from_v2)}")
    missing_references = sorted(set(products) - set(index_links))
    if missing_references:
        errors.append(f"index: missing registry IDs: {', '.join(missing_references)}")
    for product_id, relative_path in index_links.items():
        reference = (index_path.parent / relative_path).resolve()
        if not reference.is_file() or references_dir.resolve() not in reference.parents:
            errors.append(f"index.{product_id}: missing reference {relative_path}")

    missing_new = sorted(REQUIRED_NEW_PRODUCTS - set(products))
    if missing_new:
        errors.append(f"products: missing audited additions: {', '.join(missing_new)}")

    for product_id, product in products.items():
        location = f"products.{product_id}"
        if not PRODUCT_ID.fullmatch(product_id):
            errors.append(f"{location}: invalid product ID")
        if not isinstance(product, dict):
            errors.append(f"{location}: expected an object")
            continue
        template_id = product.get("template")
        if template_id is not None:
            if template_id not in templates:
                errors.append(f"{location}.template: unknown template {template_id!r}")
            if product.get("profiles"):
                errors.append(f"{location}: template products cannot define profiles")
            continue

        for field in ("display_name", "category", "lifecycle"):
            if not isinstance(product.get(field), str) or not product[field]:
                errors.append(f"{location}.{field}: expected a non-empty string")

        profiles = product.get("profiles")
        default_profile = product.get("default_profile")
        if not isinstance(profiles, dict) or not profiles:
            errors.append(f"{location}.profiles: expected a non-empty object")
            continue
        if default_profile not in profiles:
            errors.append(f"{location}.default_profile: must name an existing profile")

        for profile_id in profiles:
            profile_location = f"{location}.profiles.{profile_id}"
            try:
                resolved = resolve_profile(product_id, profile_id, profiles)
            except ValueError as error:
                errors.append(str(error))
                continue
            for field in ("kind", "migration_policy"):
                if not isinstance(resolved.get(field), str) or not resolved[field]:
                    errors.append(f"{profile_location}.{field}: expected a string")
            surfaces = resolved.get("surfaces", {})
            if not isinstance(surfaces, dict):
                errors.append(f"{profile_location}.surfaces: expected an object")
                continue
            for field in ("version_range", "verified_at", "sources"):
                if field not in resolved:
                    errors.append(f"{profile_location}.{field}: missing provenance")
            sources = resolved.get("sources")
            if not isinstance(sources, list) or not sources or not all(
                isinstance(source, str) and source.startswith("https://")
                for source in sources
            ):
                errors.append(f"{profile_location}.sources: expected HTTPS sources")
            try:
                verified = date.fromisoformat(str(resolved.get("verified_at", "")))
                age = (today - verified).days
                if age < 0 or age > max_age_days:
                    errors.append(
                        f"{profile_location}.verified_at: outside freshness window"
                    )
            except ValueError:
                errors.append(f"{profile_location}.verified_at: expected an ISO date")
            for surface_name, entries in surfaces.items():
                validate_surface(
                    profile_location,
                    surface_name,
                    entries,
                    known_policies,
                    errors,
                )

    for product_id, expected_template in EXPECTED_TEMPLATES.items():
        product = products.get(product_id, {})
        if expected_template is None:
            profiles = product.get("profiles", {}) if isinstance(product, dict) else {}
            policies_found = {
                profile.get("migration_policy")
                for profile in profiles.values()
                if isinstance(profile, dict)
            }
            if "source-only" not in policies_found:
                errors.append(f"products.{product_id}: expected a source-only profile")
        elif not isinstance(product, dict) or product.get("template") != expected_template:
            errors.append(
                f"products.{product_id}.template: expected {expected_template!r}"
            )

    return errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--registry", type=Path, required=True)
    parser.add_argument("--index", type=Path, required=True)
    parser.add_argument("--references", type=Path, required=True)
    parser.add_argument("--today", default=date.today().isoformat())
    parser.add_argument("--max-age-days", type=int, default=365)
    args = parser.parse_args()
    try:
        today = date.fromisoformat(args.today)
        errors = validate_registry(
            args.registry,
            args.index,
            args.references,
            today,
            args.max_age_days,
        )
    except (OSError, ValueError, json.JSONDecodeError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 1
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1
    print("Registry v2 validation passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
