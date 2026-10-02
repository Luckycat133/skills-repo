#!/usr/bin/env python3
"""Validate source provenance offline for curated official docs."""

from __future__ import annotations

import argparse
import copy
import json
import os
import stat
import sys
import tempfile
from datetime import date
from pathlib import Path
from typing import Any

DEMOTION_LEVELS = {
    "partial": "stale-partial",
    "manual": "stale-manual",
    "source-only": "stale-source-only",
}


def load_object(path: Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"{path}: expected an object")
    return value


def resolve_profile(
    profiles: dict[str, Any],
    profile_id: str,
    stack: tuple[str, ...] = (),
) -> dict[str, Any]:
    if profile_id in stack:
        raise ValueError(f"profile inheritance cycle: {profile_id}")
    if profile_id not in profiles or not isinstance(profiles[profile_id], dict):
        raise ValueError(f"profile must name a defined object: {profile_id}")
    value = dict(profiles[profile_id])
    parent_id = value.pop("inherits", None)
    if not parent_id:
        return value
    parent = resolve_profile(profiles, str(parent_id), stack + (profile_id,))
    parent.update(value)
    return parent


def products(registry: dict[str, Any]) -> dict[str, Any]:
    value = registry.get("products")
    if not isinstance(value, dict):
        raise ValueError("registry products must be an object")
    for product_id, product in value.items():
        if not isinstance(product, dict) or not isinstance(product.get("profiles", {}), dict):
            raise ValueError(f"{product_id}: product and profiles must be objects")
    return value


def effective_support_level(
    registry: dict[str, Any], profiles: dict[str, Any], profile_id: str
) -> str | None:
    """Match Registry._with_support after resolving profile inheritance."""
    profile = resolve_profile(profiles, profile_id)
    if "support_level" in profile:
        level = profile["support_level"]
    else:
        contracts = registry.get("support_contract", {})
        if not isinstance(contracts, dict):
            raise ValueError("registry support_contract must be an object")
        policy = str(profile.get("migration_policy", ""))
        contract = contracts.get(policy, {})
        if not isinstance(contract, dict):
            raise ValueError(f"support contract for {policy} must be an object")
        level = contract.get("support_level")
    if level is not None and not isinstance(level, str):
        raise ValueError(f"{profile_id}: support_level must be a string")
    return level


def validate_provenance(
    registry: dict[str, Any],
    today: date,
    max_age_days: int,
    acknowledged_stale: set[str] | None = None,
) -> list[str]:
    errors: list[str] = []
    for product_id, product in products(registry).items():
        profiles = product.get("profiles", {}) if isinstance(product, dict) else {}
        for profile_id in profiles:
            profile = resolve_profile(profiles, profile_id)
            location = f"{product_id}/{profile_id}"
            try:
                verified = date.fromisoformat(str(profile.get("verified_at", "")))
                age = (today - verified).days
                if age < 0 or (age > max_age_days and location not in (acknowledged_stale or set())):
                    errors.append(f"{location}: verified_at outside freshness window")
            except ValueError:
                errors.append(f"{location}: invalid verified_at")
            sources = profile.get("sources")
            if not isinstance(sources, list) or not sources:
                errors.append(f"{location}: missing official sources")
                continue
            for source in sources:
                if not isinstance(source, str) or not source.startswith("https://"):
                    errors.append(f"{location}: source must use HTTPS")
        if product.get("template") and product.get("verified_at"):
            location = f"{product_id}/template"
            try:
                verified = date.fromisoformat(str(product["verified_at"]))
                age = (today - verified).days
                if age < 0 or age > max_age_days:
                    errors.append(f"{location}: verified_at outside freshness window")
            except ValueError:
                errors.append(f"{location}: invalid verified_at")
            sources = product.get("sources", [])
            if not isinstance(sources, list) or not all(
                isinstance(source, str) and source.startswith("https://")
                for source in sources
            ):
                errors.append(f"{location}: invalid sources")
    return errors


def check_stale_profiles(registry: dict[str, Any], today: date, max_age_days: int) -> list[str]:
    """Return list of profiles that have exceeded freshness window."""
    stale: list[str] = []
    for product_id, product in products(registry).items():
        if product.get("lifecycle") != "active":
            continue
        profiles = product.get("profiles", {})
        for profile_id in profiles:
            profile = resolve_profile(profiles, profile_id)
            try:
                verified = date.fromisoformat(str(profile.get("verified_at", "")))
                age = (today - verified).days
                if age > max_age_days:
                    stale.append(f"{product_id}/{profile_id}")
            except ValueError:
                # Invalid dates are errors, not evidence that a profile is old.
                continue
    return stale


def demote_stale_support(registry: dict[str, Any], stale_profiles: list[str]) -> int:
    """Demote stale profiles from effective support levels to stale-*.
    Returns number of profiles demoted.
    """
    demoted = 0
    stale_set = set(stale_profiles)
    # Resolve every original level before mutation: a parent's new explicit
    # support must not change how a child's own policy is interpreted.
    levels: dict[str, str | None] = {}
    for profile_spec in stale_profiles:
        product_id, profile_id = profile_spec.split("/", 1)
        if product_id not in registry.get("products", {}):
            continue
        product = registry["products"][product_id]
        profiles = product.get("profiles", {})
        if profile_id not in profiles:
            continue
        levels[profile_spec] = effective_support_level(registry, profiles, profile_id)
    for profile_spec, level in levels.items():
        product_id, profile_id = profile_spec.split("/", 1)
        profiles = registry["products"][product_id]["profiles"]
        profile = profiles[profile_id]
        parent_id = profile.get("inherits")
        parent_spec = f"{product_id}/{parent_id}"
        if (parent_id and "support_level" not in profile and parent_spec in stale_set
                and levels.get(parent_spec) == level):
            # The parent's downgrade is inherited; avoid freezing a redundant
            # child override after that parent is reverified in the future.
            continue
        if level in DEMOTION_LEVELS:
            profile["support_level"] = DEMOTION_LEVELS[level]
            demoted += 1
    return demoted


def validate_checks(document: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    checks = document.get("checks")
    if document.get("schema_version") != 1 or not isinstance(checks, list):
        return ["freshness checks: unsupported schema"]
    identifiers: set[str] = set()
    for check in checks:
        if not isinstance(check, dict):
            errors.append("freshness checks: entry must be an object")
            continue
        identifier = check.get("id")
        if not isinstance(identifier, str) or not identifier or identifier in identifiers:
            errors.append("freshness checks: IDs must be unique strings")
        identifiers.add(str(identifier))
        if not isinstance(check.get("url"), str) or not check["url"].startswith("https://"):
            errors.append(f"freshness check {identifier}: URL must use HTTPS")
        terms = check.get("required_terms")
        if not isinstance(terms, list) or not terms or not all(isinstance(term, str) and term for term in terms):
            errors.append(f"freshness check {identifier}: required_terms missing")
    return errors


def write_json_atomic(path: Path, value: dict[str, Any]) -> None:
    if path.is_symlink():
        raise ValueError(f"refusing to replace a symbolic output file: {path}")
    path.parent.mkdir(parents=True, exist_ok=True)
    staged: Path | None = None
    try:
        with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8", dir=path.parent, prefix=f".{path.name}.", delete=False) as output:
            staged = Path(output.name)
            output.write(json.dumps(value, indent=2, sort_keys=True) + "\n")
        if path.exists():
            staged.chmod(stat.S_IMODE(path.stat().st_mode))
        os.replace(staged, path)
    finally:
        if staged is not None:
            staged.unlink(missing_ok=True)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Validate documentation freshness and source provenance offline."
    )
    parser.add_argument("--registry", type=Path, required=True)
    parser.add_argument("--checks", type=Path, required=True)
    parser.add_argument("--today", default=date.today().isoformat())
    parser.add_argument("--max-age-days", type=int, default=365)
    parser.add_argument("--online", action="store_true", help="Disallowed: this skill operates strictly offline")
    parser.add_argument("--retries", type=int, default=2)
    parser.add_argument("--report", type=Path)
    parser.add_argument("--demote-stale", action="store_true", help="Demote stale profiles in registry")
    args = parser.parse_args(argv)
    errors: list[str] = []
    stale_profiles: list[str] = []
    demoted_profiles: list[str] = []
    report_path = args.report

    try:
        if args.report and args.report.resolve() in {args.registry.resolve(), args.checks.resolve()}:
            report_path = None
            raise ValueError("--report must not overwrite registry or checks inputs")
        if args.online:
            raise ValueError("--online network mode is disallowed. This skill operates strictly offline.")
        today = date.fromisoformat(args.today)
        if args.retries < 0:
            raise ValueError("--retries must be zero or greater")
        if args.max_age_days < 0:
            raise ValueError("--max-age-days must be zero or greater")
        registry = load_object(args.registry)
        checks_document = load_object(args.checks)
        check_errors = validate_checks(checks_document)
        errors = validate_provenance(registry, today, args.max_age_days) + check_errors

        # Check for stale profiles and optionally demote them
        stale_profiles = check_stale_profiles(registry, today, args.max_age_days)
        unhandled = list(stale_profiles)
        if stale_profiles and args.demote_stale:
            candidate = copy.deepcopy(registry)
            demote_stale_support(candidate, stale_profiles)
            acknowledged: set[str] = set()
            proposed: list[str] = []
            for location in stale_profiles:
                product_id, profile_id = location.split("/", 1)
                profiles = candidate["products"][product_id]["profiles"]
                if effective_support_level(candidate, profiles, profile_id) in DEMOTION_LEVELS.values():
                    acknowledged.add(location)
                if registry["products"][product_id]["profiles"][profile_id] != profiles[profile_id]:
                    proposed.append(location)
            unhandled = [location for location in stale_profiles if location not in acknowledged]
            errors = validate_provenance(candidate, today, args.max_age_days, acknowledged) + check_errors
            if not errors and not unhandled and proposed:
                write_json_atomic(args.registry, candidate)
                demoted_profiles = proposed
                print(f"Demoted {len(proposed)} stale profiles", file=sys.stderr)
        if unhandled:
            errors.append(f"stale profiles detected: {', '.join(unhandled)}")
    except (OSError, ValueError, json.JSONDecodeError) as error:
        errors.append(str(error))
        print(f"ERROR: {error}", file=sys.stderr)

    report = {
        "schema_version": 1,
        "checked_at": args.today,
        "online": False,
        "ok": not errors,
        "errors": errors,
        "results": [],
        "stale_profiles": stale_profiles,
        "demoted_profiles": demoted_profiles,
    }
    if report_path:
        try:
            write_json_atomic(report_path, report)
        except (OSError, ValueError) as error:
            print(f"ERROR: cannot write freshness report: {error}", file=sys.stderr)
            return 1
    print(json.dumps(report, indent=2, sort_keys=True))
    return 0 if not errors else 1


if __name__ == "__main__":
    raise SystemExit(main())
