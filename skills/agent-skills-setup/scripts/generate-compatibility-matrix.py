#!/usr/bin/env python3
"""Generate ``docs/agent-skills-setup/compatibility-matrix.md`` from registry
data, IDE path tables, E2E test coverage, and human tier overrides.

Inputs (all paths relative to repo root unless absolute):
  --registry    references/registry-v2.json
  --paths       references/ide-paths.tsv
  --overrides   references/ide-tier-overrides.json
  --scripts-dir scripts   (scans test-*.sh)
  --output      docs/agent-skills-setup/compatibility-matrix.md

Tier rules:
  Missing surfaces produce "-". Manual overrides can lower any cell; no test
  or override can promote an unsupported object/scope adapter. Automatic cells
  use explicit, directional execution coverage for that object/scope, otherwise
  "Adapter-Compatible". MCP compatibility covers the reviewed local stdio
  subset only; remote transports need manual reconstruction.

Run --check to verify the output matches committed content (CI gate).
"""

from __future__ import annotations

import argparse
import json
import re
import shlex
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from migration_core import (
    AUTOMATIC_MIGRATION_POLICIES,
    AUTOMATIC_SURFACE_POLICIES,
    FORMAT_FEATURES,
    SOURCE_AUTOMATIC_SURFACE_POLICIES,
    mcp_adapter,
)

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

# Mapping from ide-paths.tsv surface keys to object types
TSV_SURFACE_TO_OBJECT = {
    "skills": "skills",
    "instructions": "instructions",
    "mcp": "mcp",
}


def load_registry(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def load_overrides(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {"tiers": {}}
    data = json.loads(path.read_text(encoding="utf-8"))
    return data.get("tiers", {}) or {}


def load_paths_tsv(path: Path) -> dict[str, list[tuple[str, str]]]:
    """Return ``{product: [(surface_type, path), ...]}`` from the TSV."""
    if not path.exists():
        return {}
    paths: dict[str, list[tuple[str, str]]] = {}
    for line in path.read_text(encoding="utf-8").splitlines()[1:]:
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
    """Collect explicit directional execution coverage, never file-wide unions.

    Dynamic/Python fixtures and saved-plan chains are conservatively unindexed.
    A preview, legacy conversion, or expected-failure conditional is not public
    end-to-end execution evidence.
    """
    coverage: dict[tuple[str, str, str], set[str]] = {}
    if not scripts_dir.is_dir():
        return coverage
    for script in sorted(scripts_dir.glob("test-*.sh")):
        for source, target, scopes, objects in _script_executions(script, registry):
            for scope in scopes:
                coverage.setdefault((source, target, scope), set()).update(objects)
    return coverage


def _literal_option(tokens: list[str], option: str) -> str | None:
    for index, token in enumerate(tokens):
        if token == option and index + 1 < len(tokens):
            return tokens[index + 1]
        if token.startswith(option + "="):
            return token.partition("=")[2]
    return None


def _script_executions(
    script: Path,
    registry: dict[str, Any],
) -> list[tuple[str, str, set[str], set[str]]]:
    aliases = registry.get("aliases") or {}
    executions: list[tuple[str, str, set[str], set[str]]] = []
    text = re.sub(r"\\\r?\n", " ", script.read_text(encoding="utf-8"))
    for line in text.splitlines():
        try:
            lexer = shlex.shlex(line, posix=True, punctuation_chars=";&|")
            lexer.whitespace_split = True
            tokens = list(lexer)
        except ValueError:
            continue
        # A tolerated failure is not successful execution evidence. Avoid
        # inferring the control-flow semantics of arbitrary fallback blocks.
        if "||" in tokens:
            continue
        segments: list[list[str]] = [[]]
        for token in tokens:
            if token and all(character in ";&|" for character in token):
                segments.append([])
            else:
                segments[-1].append(token)
        for command in segments:
            if not any(token in {"migrate", "restore"} for token in command):
                continue
            if any(token in {"legacy", "--plan-only", "--dry-run", "if", "!"} for token in command):
                continue
            if "--yes" not in command:
                continue
            source = _literal_option(command, "--source")
            target = _literal_option(command, "--target")
            objects_value = _literal_option(command, "--objects")
            scope_value = _literal_option(command, "--scope")
            if not all((source, target, objects_value, scope_value)):
                continue
            source_selector = resolve_selector(source, aliases, registry)
            target_selector = resolve_selector(target, aliases, registry)
            if not source_selector or not target_selector or source_selector == target_selector:
                continue
            objects = _union_objects([objects_value])
            scopes = _union_scopes([scope_value])
            if objects and scopes:
                executions.append((source_selector, target_selector, scopes, objects))
    return executions


def _union_objects(values: list[str]) -> set[str]:
    """Expand --objects flag values to the OBJECT_TYPES union.

    Recognised keywords match public automatic object selectors. Unrecognised
    or unrelated objects never imply coverage of the portable trio.
    """
    objects: set[str] = set()
    for value in values:
        for token in value.split(","):
            token = token.strip().lower()
            if not token:
                continue
            if token in {"all-portable", "all-inventory"}:
                return set(OBJECT_TYPES)
            if token in OBJECT_TYPES:
                objects.add(token)
    return objects


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
    return scopes


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


def _automatic_surface(surface: dict[str, Any], object_type: str, *, source: bool) -> bool:
    policies = SOURCE_AUTOMATIC_SURFACE_POLICIES if source else AUTOMATIC_SURFACE_POLICIES
    if surface.get("policy") not in policies:
        return False
    format_name = str(surface.get("format", ""))
    storage = surface.get("storage")
    if object_type == "skills":
        return format_name == "agent-skill" and storage in {"directory", "hierarchy"}
    if object_type == "instructions":
        return format_name in FORMAT_FEATURES and storage in {
            "file", "directory", "hierarchy", "precedence-files",
        }
    if object_type == "mcp":
        if not mcp_adapter(format_name)["automatic"]:
            return False
        if storage not in {"file", "config-subobject"}:
            return False
        # The shared runtime adapter supports these JSON/JSONC server maps,
        # not arbitrary native containers or remote transport schemas.
        if format_name.partition(":")[2] not in {"", "mcpServers", "servers", "mcp"}:
            return False
        transports = surface.get("transports", surface.get("transport", "stdio"))
        if isinstance(transports, str):
            transports = [transports]
        return isinstance(transports, list) and bool(transports) and set(transports) <= {"stdio"}
    return False


def automatic_object_pair(
    src_profile: dict[str, Any],
    tgt_profile: dict[str, Any],
    object_type: str,
    scope: str,
) -> bool:
    """Check scope-specific runtime adapter boundaries before test promotion.

    Multiple surfaces may resolve according to local existence/precedence. A
    static matrix cannot promise automatic conversion if any such surface needs
    reconstruction; the runtime plan decides the selected content's eligibility.
    """
    for profile, source in ((src_profile, True), (tgt_profile, False)):
        if profile.get("migration_policy") not in AUTOMATIC_MIGRATION_POLICIES:
            return False
        surfaces = [
            surface
            for surface in profile.get("surfaces", {}).get(object_type, [])
            if surface.get("scope", "").lower() == scope
        ]
        if not surfaces or not all(
            _automatic_surface(surface, object_type, source=source)
            for surface in surfaces
        ):
            return False
    return True


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
    # Preserve human downgrades; upgrades cannot create a missing adapter.
    scope_obj_key = f"{scope}:{object_type}"
    selected_overrides: list[str] = []
    for selector in (src_selector, tgt_selector):
        prof_overrides = overrides.get(selector) or {}
        if isinstance(prof_overrides, dict):
            if scope_obj_key in prof_overrides:
                selected_overrides.append(prof_overrides[scope_obj_key])
            elif object_type in prof_overrides:
                selected_overrides.append(prof_overrides[object_type])
    for downgrade in (TIER_NA, TIER_MANUAL):
        if downgrade in selected_overrides:
            return downgrade

    src_policy = src_profile.get("migration_policy", "")
    tgt_policy = tgt_profile.get("migration_policy", "")
    if src_policy in MANUAL_POLICIES or tgt_policy in MANUAL_POLICIES:
        return TIER_MANUAL
    if not automatic_object_pair(src_profile, tgt_profile, object_type, scope):
        return TIER_MANUAL
    if selected_overrides:
        return selected_overrides[0]

    # Only explicit coverage of this direction, scope, and object can promote it.
    key = (src_selector, tgt_selector, scope)
    objects = coverage.get(key, set())
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
    """Index the same explicit directional executions used for tier coverage."""
    index: dict[tuple[str, str], list[tuple[int, str]]] = {}
    if not scripts_dir.is_dir():
        return index
    for script in sorted(scripts_dir.glob("test-*.sh")):
        try:
            rel = str(script.relative_to(REPO_ROOT))
        except ValueError:
            rel = str(script)
        for source, target, _scopes, objects in _script_executions(script, registry):
            index.setdefault((source, target), []).append((len(objects), rel))
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
    lines.append(f"- **{TIER_E2E}** — an explicit directional execution fixture covers this automatic object at the given scope; preview, legacy-only, and unrelated object tests do not promote it.")
    lines.append(f"- **{TIER_ADAPTER}** — both profiles and the selected object/scope surfaces have reviewed runtime adapters, but no explicit directional execution fixture is indexed.")
    lines.append(f"- **{TIER_MANUAL}** — a profile, surface policy, native format, or declared transport requires reconstruction. Test coverage cannot promote an unsupported adapter; human downgrades remain effective.")
    lines.append("MCP automatic tiers cover the reviewed local stdio JSON/JSONC subset only. Remote MCP, unsupported activation semantics, local conflicts, and actual content eligibility are decided by the saved runtime plan.")
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
        committed = args.output.read_text(encoding="utf-8")
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
    args.output.write_text(content, encoding="utf-8")
    print(f"Wrote {args.output}: {content.count(chr(10))} lines")
    return 0


if __name__ == "__main__":
    sys.exit(main())
