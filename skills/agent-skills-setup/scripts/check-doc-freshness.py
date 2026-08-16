#!/usr/bin/env python3
"""Validate source provenance and optionally probe curated official docs."""

from __future__ import annotations

import argparse
import hashlib
import json
import sys
import time
import urllib.error
import urllib.request
from datetime import date
from pathlib import Path
from typing import Any


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
    value = dict(profiles[profile_id])
    parent_id = value.pop("inherits", None)
    if not parent_id:
        return value
    parent = resolve_profile(profiles, str(parent_id), stack + (profile_id,))
    parent.update(value)
    return parent


def validate_provenance(
    registry: dict[str, Any],
    today: date,
    max_age_days: int,
) -> list[str]:
    errors: list[str] = []
    for product_id, product in registry.get("products", {}).items():
        profiles = product.get("profiles", {}) if isinstance(product, dict) else {}
        for profile_id in profiles:
            profile = resolve_profile(profiles, profile_id)
            location = f"{product_id}/{profile_id}"
            try:
                verified = date.fromisoformat(str(profile.get("verified_at", "")))
                age = (today - verified).days
                if age < 0 or age > max_age_days:
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


def probe(check: dict[str, Any]) -> dict[str, Any]:
    url = str(check["url"])
    request = urllib.request.Request(
        url,
        headers={"User-Agent": "skills-repo-doc-freshness/1"},
    )
    with urllib.request.urlopen(request, timeout=30) as response:
        body = response.read(2_000_001)
        if len(body) > 2_000_000:
            raise ValueError("document exceeds 2 MB probe limit")
        final_url = response.geturl()
        status = getattr(response, "status", 200)
    text = body.decode("utf-8", errors="replace").lower()
    missing = [
        term
        for term in check.get("required_terms", [])
        if str(term).lower() not in text
    ]
    return {
        "id": check["id"],
        "url": url,
        "final_url": final_url,
        "status": status,
        "sha256": hashlib.sha256(body).hexdigest(),
        "missing_terms": missing,
    }


def check_stale_profiles(registry: dict[str, Any], today: date, max_age_days: int) -> list[str]:
    """Return list of profiles that have exceeded freshness window."""
    stale: list[str] = []
    for product_id, product in registry.get("products", {}).items():
        if product.get("lifecycle") != "active":
            continue
        profiles = product.get("profiles", {})
        for profile_id in profiles:
            profile = registry["products"][product_id]["profiles"][profile_id]
            try:
                verified = date.fromisoformat(str(profile.get("verified_at", "")))
                age = (today - verified).days
                if age > max_age_days:
                    stale.append(f"{product_id}/{profile_id}")
            except ValueError:
                stale.append(f"{product_id}/{profile_id} (invalid verified_at)")
    return stale


def demote_stale_support(registry: dict[str, Any], stale_profiles: list[str]) -> int:
    """Demote stale profiles from partial/manual to stale-* support levels.
    Returns number of profiles demoted.
    """
    demoted = 0
    for profile_spec in stale_profiles:
        product_id, profile_id = profile_spec.split("/", 1)
        if product_id not in registry.get("products", {}):
            continue
        product = registry["products"][product_id]
        profiles = product.get("profiles", {})
        if profile_id not in profiles:
            continue
        profile = profiles[profile_id]
        level = profile.get("support_level", "")
        if level == "partial":
            profile["support_level"] = "stale-partial"
            demoted += 1
        elif level == "manual":
            profile["support_level"] = "stale-manual"
            demoted += 1
        elif level == "source-only":
            profile["support_level"] = "stale-source-only"
            demoted += 1
    return demoted


def probe_with_retries(check: dict[str, Any], retries: int) -> dict[str, Any]:
    last_error: OSError | ValueError | urllib.error.URLError | None = None
    for attempt in range(1, retries + 2):
        try:
            result = probe(check)
            result["attempts"] = attempt
            return result
        except (OSError, ValueError, urllib.error.URLError) as error:
            last_error = error
            if attempt > retries:
                break
            time.sleep(min(2 ** (attempt - 1), 4))
    assert last_error is not None
    raise last_error


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--registry", type=Path, required=True)
    parser.add_argument("--checks", type=Path, required=True)
    parser.add_argument("--today", default=date.today().isoformat())
    parser.add_argument("--max-age-days", type=int, default=365)
    parser.add_argument("--online", action="store_true")
    parser.add_argument("--retries", type=int, default=2)
    parser.add_argument("--report", type=Path)
    parser.add_argument("--demote-stale", action="store_true", help="Demote stale profiles in registry")
    args = parser.parse_args()

    try:
        today = date.fromisoformat(args.today)
        if args.retries < 0:
            raise ValueError("--retries must be zero or greater")
        registry = load_object(args.registry)
        checks_document = load_object(args.checks)
        errors = validate_provenance(registry, today, args.max_age_days)

        # Check for stale profiles and optionally demote them
        stale_profiles = check_stale_profiles(registry, today, args.max_age_days)
        if stale_profiles:
            stale_error = f"stale profiles detected: {', '.join(stale_profiles)}"
            errors.append(stale_error)
            if args.demote_stale:
                demoted = demote_stale_support(registry, stale_profiles)
                if demoted:
                    # Write back the updated registry
                    args.registry.write_text(
                        json.dumps(registry, indent=2, sort_keys=True) + "\n",
                        encoding="utf-8",
                    )
                    print(f"Demoted {demoted} stale profiles", file=sys.stderr)
        checks = checks_document.get("checks")
        if checks_document.get("schema_version") != 1 or not isinstance(checks, list):
            errors.append("freshness checks: unsupported schema")
            checks = []
        identifiers: set[str] = set()
        for check in checks:
            if not isinstance(check, dict):
                errors.append("freshness checks: entry must be an object")
                continue
            identifier = check.get("id")
            if not isinstance(identifier, str) or not identifier or identifier in identifiers:
                errors.append("freshness checks: IDs must be unique strings")
            identifiers.add(str(identifier))
            if not isinstance(check.get("url"), str) or not check["url"].startswith(
                "https://"
            ):
                errors.append(f"freshness check {identifier}: URL must use HTTPS")
            terms = check.get("required_terms")
            if not isinstance(terms, list) or not terms or not all(
                isinstance(term, str) and term for term in terms
            ):
                errors.append(f"freshness check {identifier}: required_terms missing")

        results: list[dict[str, Any]] = []
        if args.online and not errors:
            for check in checks:
                try:
                    result = probe_with_retries(check, args.retries)
                    results.append(result)
                    if result["status"] < 200 or result["status"] >= 400:
                        errors.append(
                            f"freshness check {result['id']}: HTTP {result['status']}"
                        )
                    if result["missing_terms"]:
                        errors.append(
                            f"freshness check {result['id']}: missing terms "
                            + ", ".join(result["missing_terms"])
                        )
                except (OSError, ValueError, urllib.error.URLError) as error:
                    errors.append(f"freshness check {check.get('id')}: {error}")
        report = {
            "schema_version": 1,
            "checked_at": today.isoformat(),
            "online": args.online,
            "ok": not errors,
            "errors": errors,
            "results": results,
        }
        rendered = json.dumps(report, indent=2, sort_keys=True) + "\n"
        if args.report:
            args.report.parent.mkdir(parents=True, exist_ok=True)
            args.report.write_text(rendered, encoding="utf-8")
        print(rendered, end="")
        return 0 if not errors else 1
    except (OSError, ValueError, json.JSONDecodeError) as error:
        print(f"ERROR: {error}")
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
