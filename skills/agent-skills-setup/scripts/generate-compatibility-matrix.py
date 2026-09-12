#!/usr/bin/env python3
"""Generate ``docs/agent-skills-setup/compatibility-matrix.md`` from registry
data, IDE path tables, E2E test coverage, and human tier overrides.

Inputs (all paths relative to repo root unless absolute):
  --registry    references/registry-v2.json
  --paths       references/ide-paths.tsv
  --overrides   references/ide-tier-overrides.json
  --scripts-dir scripts   (scans test-*.sh)
  --output      docs/agent-skills-setup/compatibility-matrix.md

Tier rules (in priority order, highest first):
  1. User override in ide-tier-overrides.json for the (profile, scope, object_type).
  2. If the source or target profile's migration_policy is in {manual-template,
     official-api-or-rebuild-checklist, manual-rebuild, source-only,
     never-migrate, forbidden-regenerate}: tier = "Manual / Rebuild".
  3. If a test-*.sh in scripts/ exercises (source, target, scope, object_type):
     tier = "E2E Verified".
  4. Else (both profiles are bidirectional-reviewed): tier = "Adapter-Compatible".
  5. If a profile does not surface the object_type at all: object is omitted
     from the row (cell shows "-").

Run --check to verify the output matches committed content (CI gate).
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parents[3]

# Tier classification constants
TIER_E2E = "E2E Verified"
TIER_ADAPTER = "Adapter-Compatible"
TIER_MANUAL = "Manual / Rebuild"
TIER_NA = "Not Applicable"
TIER_NOT_SURFACED = "-"

MANUAL_POLICIES = frozenset({
    "manual-template",
    "official-api-or-rebuild-checklist",
    "manual-rebuild",
    "source-only",
    "never-migrate",
    "forbidden-regenerate",
    "disabled-draft-only",
    "forbidden",
})

OBJECT_TYPES = ("skills", "instructions", "mcp")
SCOPES = ("user", "project")

# Regex helpers for parsing test scripts
RE_SOURCE = re.compile(r"--source\s+([a-zA-Z0-9._/-]+)")
RE_TARGET = re.compile(r"--target\s+([a-zA-Z0-9._/-]+)")
RE_OBJECTS = re.compile(r"--objects\s+([a-zA-Z0-9,_-]+)")
RE_SCOPE = re.compile(r"--scope\s+([a-zA-Z0-9,_-]+)")

# Mapping from ide-paths.tsv surface keys to object types
TSV_SURFACE_TO_OBJECT = {
    "skills": "skills",
    "instructions": "instructions",
    "mcp": "mcp",
}


def load_registry(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text())


def load_overrides(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {"tiers": {}}
    data = json.loads(path.read_text())
    return data.get("tiers", {}) or {}


def load_paths_tsv(path: Path) -> dict[str, list[tuple[str, str]]]:
    """Return ``{product: [(surface_type, path), ...]}`` from the TSV."""
    if not path.exists():
        return {}
    paths: dict[str, list[tuple[str, str]]] = {}
    for line in path.read_text().splitlines()[1:]:
        if not line.strip():
            continue
        parts = line.split("\t")
        if len(parts) < 4:
            continue
        product, surface_type, _scope, file_path = parts[0], parts[1], parts[2], parts[3]
        paths.setdefault(product, []).append((surface_type, file_path))
    return paths


def resolve_selector(selector: str, aliases: dict[str, str], registry: dict[str, Any]) -> str | None:
    """Resolve a possibly-aliased selector like ``cursor`` -> ``cursor/ide``."""
    if "/" in selector:
        return selector if selector in _all_profile_selectors(registry) else None
    # Short alias
    canonical = aliases.get(selector, selector)
    if "/" in canonical:
        return canonical
    # Bare product: use default_profile
    product = registry.get("products", {}).get(selector)
    if product:
        default = product.get("default_profile") or next(
            iter((product.get("profiles") or {}).keys()), None
        )
        if default:
            return f"{selector}/{default}"
    return None


def _all_profile_selectors(registry: dict[str, Any]) -> set[str]:
    selectors: set[str] = set()
    for product, data in (registry.get("products") or {}).items():
        for profile in (data.get("profiles") or {}).keys():
            selectors.add(f"{product}/{profile}")
    return selectors


def scan_test_scripts(
    scripts_dir: Path,
    registry: dict[str, Any],
) -> dict[tuple[str, str, str], set[str]]:
    """Scan ``test-*.sh`` for source/target/objects/scope triples.

    Returns ``{(source, target, scope): {object_type, ...}}``. Scope is
    the union of scopes exercised across tests for the (source, target)
    pair; object_type defaults to all three when no --objects flag is set.
    """
    aliases = registry.get("aliases") or {}
    coverage: dict[tuple[str, str, str], set[str]] = {}
    if not scripts_dir.is_dir():
        return coverage
    for script in sorted(scripts_dir.glob("test-*.sh")):
        text = script.read_text()
        sources = RE_SOURCE.findall(text)
        targets = RE_TARGET.findall(text)
        objects = RE_OBJECTS.findall(text)
        scopes = RE_SCOPE.findall(text)
        if not sources or not targets:
            continue
        # Union objects + scopes across the script body
        obj_set = _union_objects(objects)
        scope_set = _union_scopes(scopes)
        for src in sources:
            for tgt in targets:
                src_canonical = resolve_selector(src, aliases, registry)
                tgt_canonical = resolve_selector(tgt, aliases, registry)
                if not src_canonical or not tgt_canonical:
                    continue
                if src_canonical == tgt_canonical:
                    continue  # skip self-migrations in coverage
                for scope in scope_set:
                    key = (src_canonical, tgt_canonical, scope)
                    coverage.setdefault(key, set()).update(obj_set)
    return coverage


def _union_objects(values: list[str]) -> set[str]:
    """Expand --objects flag values to the OBJECT_TYPES union.

    Recognised keywords: skills, instructions, mcp, rules, config,
    project-mcp, all-portable, all, and negation prefixes.
    """
    objects: set[str] = set()
    for value in values:
        for token in value.split(","):
            token = token.strip().lower()
            if not token:
                continue
            if token in {"all-portable", "all"}:
                return set(OBJECT_TYPES)
            if token in {"skills", "agents"}:
                objects.add("skills")
            elif token in {"instructions", "rules", "config", "settings"}:
                objects.add("instructions")
            elif token in {"mcp", "project-mcp", "stdio-mcp"}:
                objects.add("mcp")
    return objects or set(OBJECT_TYPES)


def _union_scopes(values: list[str]) -> set[str]:
    scopes: set[str] = set()
    for value in values:
        for token in value.split(","):
            token = token.strip().lower()
            if token in {"user", "project", "local", "both"}:
                if token == "both":
                    scopes.update({"user", "project"})
                else:
                    scopes.add(token)
            elif token == "all":
                scopes.update({"user", "project"})
    return scopes or set(SCOPES)


def supported_objects(profile_data: dict[str, Any]) -> set[str]:
    """Return the object types a profile surfaces (across all scopes)."""
    surfaces = profile_data.get("surfaces") or {}
    return {obj for obj in OBJECT_TYPES if surfaces.get(obj)}


def scope_objects(profile_data: dict[str, Any]) -> dict[str, set[str]]:
    """Return ``{scope: {object_type, ...}}`` for a profile."""
    out: dict[str, set[str]] = {s: set() for s in SCOPES}
    for obj_type in OBJECT_TYPES:
        for surf in profile_data.get("surfaces", {}).get(obj_type, []) or []:
            scope = surf.get("scope", "").lower()
            if scope in out:
                out[scope].add(obj_type)
    return out


def classify_pair(
    src_profile: dict[str, Any],
    tgt_profile: dict[str, Any],
    object_type: str,
    scope: str,
    src_selector: str,
    tgt_selector: str,
    coverage: dict[tuple[str, str, str], set[str]],
    overrides: dict[str, Any],
) -> str:
    """Return the tier string for one (src, tgt, scope, object_type) cell."""
    # 1. User override
    scope_obj_key = f"{scope}:{object_type}"
    for selector in (src_selector, tgt_selector):
        prof_overrides = overrides.get(selector) or {}
        if not prof_overrides:
            continue
        if isinstance(prof_overrides, dict):
            if scope_obj_key in prof_overrides:
                return prof_overrides[scope_obj_key]
            if object_type in prof_overrides:
                return prof_overrides[object_type]
    # 2. Manual policy if either side restricts writes
    src_policy = src_profile.get("migration_policy", "")
    tgt_policy = tgt_profile.get("migration_policy", "")
    if src_policy in MANUAL_POLICIES or tgt_policy in MANUAL_POLICIES:
        return TIER_MANUAL
    # 3. E2E Verified if a test exercises this pair + scope + object_type
    key = (src_selector, tgt_selector, scope)
    objects = coverage.get(key) or coverage.get((tgt_selector, src_selector, scope), set())
    if object_type in objects:
        return TIER_E2E
    # 4. Adapter-Compatible (both sides bidirectional-reviewed)
    if src_policy == "bidirectional-reviewed" and tgt_policy == "bidirectional-reviewed":
        return TIER_ADAPTER
    return TIER_MANUAL


def profile_summary(profile: dict[str, Any]) -> str:
    policy = profile.get("migration_policy", "unspecified")
    verified = profile.get("verified_at", "")
    sources = profile.get("sources") or []
    evidence = "; ".join(sources[:2])
    return f"policy={policy}; verified_at={verified}; sources={evidence}"


def build_fixture_index(scripts_dir: Path, registry: dict[str, Any]) -> dict[tuple[str, str], list[tuple[int, str]]]:
    """Scan ``test-*.sh`` once and return ``{(src, tgt): [(object_count, path), ...]}``.

    Also indexes the reverse direction so a fixture that uses ``--target A --source B``
    is found for the (B, A) lookup as well.
    """
    aliases = registry.get("aliases") or {}
    index: dict[tuple[str, str], list[tuple[int, str]]] = {}
    if not scripts_dir.is_dir():
        return index
    for script in sorted(scripts_dir.glob("test-*.sh")):
        text = script.read_text()
        srcs = RE_SOURCE.findall(text)
        tgts = RE_TARGET.findall(text)
        if not srcs or not tgts:
            continue
        objs = _union_objects(RE_OBJECTS.findall(text))
        rel = str(script.relative_to(REPO_ROOT))
        for src in srcs:
            src_canonical = resolve_selector(src, aliases, registry)
            if not src_canonical:
                continue
            for tgt in tgts:
                tgt_canonical = resolve_selector(tgt, aliases, registry)
                if not tgt_canonical:
                    continue
                if src_canonical == tgt_canonical:
                    continue
                index.setdefault((src_canonical, tgt_canonical), []).append((len(objs), rel))
                index.setdefault((tgt_canonical, src_canonical), []).append((len(objs), rel))
    return index


def generate(
    registry: dict[str, Any],
    paths_by_product: dict[str, list[tuple[str, str]]],
    coverage: dict[tuple[str, str, str], set[str]],
    overrides: dict[str, Any],
    fixture_index: dict[tuple[str, str], list[tuple[int, str]]],
    now: datetime,
) -> str:
    products = registry.get("products") or {}
    profiles = [
        (product, prof_name, prof_data)
        for product, pdata in sorted(products.items())
        for prof_name, prof_data in sorted((pdata.get("profiles") or {}).items())
    ]
    lines: list[str] = []
    lines.append("# Compatibility & Migration Matrix")
    lines.append("")
    lines.append(
        "Auto-generated from `skills/agent-skills-setup/references/registry-v2.json`, "
        "`references/ide-paths.tsv`, the E2E test scripts under `scripts/`, and "
        "`references/ide-tier-overrides.json`. Do not edit by hand — run "
        "`python3 skills/agent-skills-setup/scripts/generate-compatibility-matrix.py` "
        "to refresh. CI gate: `.github/workflows/matrix-freshness.yml`."
    )
    lines.append("")
    lines.append(f"Generated at: {now.strftime('%Y-%m-%dT%H:%M:%SZ')}")
    lines.append(f"Profiles indexed: {len(profiles)}")
    lines.append("")
    lines.append("## Tier definitions")
    lines.append("")
    lines.append(f"- **{TIER_E2E}** — a `scripts/test-*.sh` exercises this pair at the given scope + object type end-to-end.")
    lines.append(f"- **{TIER_ADAPTER}** — both profiles carry `migration_policy: bidirectional-reviewed` and the registry ships the required adapter, but no on-disk E2E fixture covers the pair yet.")
    lines.append(f"- **{TIER_MANUAL}** — at least one profile is `manual-template`, `official-api-or-rebuild-checklist`, `manual-rebuild`, `source-only`, or otherwise non-automatic; emit rebuild checklists via the official API/UI.")
    lines.append("")
    lines.append("## Source profiles")
    lines.append("")
    lines.append("| Profile | Policy | Verified | Object types (user / project) |")
    lines.append("|---|---|---|---|")
    for product, prof_name, prof in profiles:
        policy = prof.get("migration_policy", "unspecified")
        verified = prof.get("verified_at", "")
        scopes = scope_objects(prof)
        u = "/".join(sorted(scopes.get("user", set()))) or "-"
        p = "/".join(sorted(scopes.get("project", set()))) or "-"
        lines.append(f"| `{product}/{prof_name}` | `{policy}` | {verified} | {u} / {p} |")
    lines.append("")
    lines.append("## Per-pair matrix (one row per source/target/scope; cells show tier per object type)")
    lines.append("")
    # Only emit rows where the source supports something and the target accepts writes (non-source-only).
    emitted_rows = 0
    header = (
        "| source_profile | target_profile | scope | skills | instructions | mcp | evidence | test_fixture |"
    )
    separator = "|---|---|---|---|---|---|---|---|"
    lines.append(header)
    lines.append(separator)
    rows: list[str] = []
    for src_product, src_prof, src_data in profiles:
        src_selector = f"{src_product}/{src_prof}"
        src_policy = src_data.get("migration_policy", "")
        if src_policy == "source-only":
            continue  # cannot be a target, skip as a row emitter
        src_scopes = scope_objects(src_data)
        for tgt_product, tgt_prof, tgt_data in profiles:
            if src_selector == f"{tgt_product}/{tgt_prof}":
                continue  # self-migration not interesting in the per-pair view
            tgt_selector = f"{tgt_product}/{tgt_prof}"
            tgt_scopes = scope_objects(tgt_data)
            shared_scopes = [
                s for s in SCOPES if src_scopes.get(s) and tgt_scopes.get(s)
            ]
            for scope in shared_scopes:
                src_objs = src_scopes.get(scope, set())
                tgt_objs = tgt_scopes.get(scope, set())
                shared_objs = src_objs & tgt_objs
                if not shared_objs:
                    continue
                cells = []
                for obj_type in OBJECT_TYPES:
                    if obj_type not in shared_objs:
                        cells.append(TIER_NOT_SURFACED)
                        continue
                    tier = classify_pair(
                        src_data, tgt_data, obj_type, scope,
                        src_selector, tgt_selector,
                        coverage, overrides,
                    )
                    cells.append(tier)
                # Pick the strongest evidence / test fixture per row
                evidence = profile_summary(src_data) + " | " + profile_summary(tgt_data)
                test_fixture = _best_test_fixture(fixture_index, src_selector, tgt_selector)
                row = (
                    f"| `{src_selector}` | `{tgt_selector}` | {scope} | "
                    f"{cells[0]} | {cells[1]} | {cells[2]} | "
                    f"{evidence[:160]} | {test_fixture} |"
                )
                rows.append(row)
                emitted_rows += 1
    rows.sort()
    lines.extend(rows)
    lines.append("")
    lines.append(f"Total pair rows: {emitted_rows}")
    lines.append("")
    lines.append("## Path table (from `references/ide-paths.tsv`)")
    lines.append("")
    lines.append("| product | surface_type | path |")
    lines.append("|---|---|---|")
    for product, entries in sorted(paths_by_product.items()):
        for surface_type, file_path in sorted(entries):
            lines.append(f"| {product} | {surface_type} | `{file_path}` |")
    lines.append("")
    lines.append("## Regeneration")
    lines.append("")
    lines.append("```bash")
    lines.append("python3 skills/agent-skills-setup/scripts/generate-compatibility-matrix.py --check")
    lines.append("```")
    lines.append("")
    return "\n".join(lines) + "\n"


def _best_test_fixture(
    fixture_index: dict[tuple[str, str], list[tuple[int, str]]],
    src_selector: str,
    tgt_selector: str,
) -> str:
    """Return the canonical ``test-*.sh`` fixture path with the broadest object
    coverage for ``(src, tgt)``; ``"-"`` when no fixture covers it."""
    candidates = fixture_index.get((src_selector, tgt_selector)) or []
    if not candidates:
        return "-"
    # Prefer the script covering the most object types, then alphabetical
    # path for determinism.
    candidates.sort(key=lambda item: (-item[0], item[1]))
    return candidates[0][1]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--registry",
        type=Path,
        default=REPO_ROOT / "skills/agent-skills-setup/references/registry-v2.json",
    )
    parser.add_argument(
        "--paths",
        type=Path,
        default=REPO_ROOT / "skills/agent-skills-setup/references/ide-paths.tsv",
    )
    parser.add_argument(
        "--overrides",
        type=Path,
        default=REPO_ROOT / "skills/agent-skills-setup/references/ide-tier-overrides.json",
    )
    parser.add_argument(
        "--scripts-dir",
        type=Path,
        default=REPO_ROOT / "skills/agent-skills-setup/scripts",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=REPO_ROOT / "docs/agent-skills-setup/compatibility-matrix.md",
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="Exit 1 if --output differs from the regenerated content.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    registry = load_registry(args.registry)
    paths_by_product = load_paths_tsv(args.paths)
    overrides = load_overrides(args.overrides)
    coverage = scan_test_scripts(args.scripts_dir, registry)
    fixture_index = build_fixture_index(args.scripts_dir, registry)
    now = datetime.now(timezone.utc)
    content = generate(
        registry=registry,
        paths_by_product=paths_by_product,
        coverage=coverage,
        overrides=overrides,
        fixture_index=fixture_index,
        now=now,
    )
    if args.check:
        if not args.output.exists():
            print(f"--check failed: {args.output} does not exist", file=sys.stderr)
            return 1
        committed = args.output.read_text()
        # The generation timestamp differs on every run; normalise it for the check.
        committed_normalised = re.sub(
            r"^Generated at: .*$",
            f"Generated at: {now.strftime('%Y-%m-%dT%H:%M:%SZ')}",
            committed,
            flags=re.MULTILINE,
        )
        if committed_normalised != content:
            print(
                f"--check failed: {args.output} is stale. Re-run without --check and commit the result.",
                file=sys.stderr,
            )
            return 1
        print(f"--check passed: {args.output} matches generated content.")
        return 0
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(content)
    print(f"Wrote {args.output}: {content.count(chr(10))} lines")
    return 0


if __name__ == "__main__":
    sys.exit(main())
