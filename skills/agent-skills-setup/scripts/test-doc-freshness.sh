#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

python3 "$SCRIPT_DIR/check-doc-freshness.py" \
    --registry "$SKILL_DIR/references/registry-v2.json" \
    --checks "$SKILL_DIR/references/doc-freshness-checks.json" \
    --today 2026-08-17 \
    --report "$TMP_ROOT/report.json" > "$TMP_ROOT/stdout.json"

python3 - "$TMP_ROOT/report.json" <<'PY'
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert report["ok"] is True
assert report["online"] is False
assert report["results"] == []
PY

python3 - \
    "$SKILL_DIR/references/doc-freshness-checks.json" \
    "$TMP_ROOT/bad-checks.json" <<'PY'
import json
import sys
from pathlib import Path

document = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
document["checks"][0]["url"] = "http://insecure.example.test"
Path(sys.argv[2]).write_text(json.dumps(document), encoding="utf-8")
PY

if python3 "$SCRIPT_DIR/check-doc-freshness.py" \
    --registry "$SKILL_DIR/references/registry-v2.json" \
    --checks "$TMP_ROOT/bad-checks.json" \
    --today 2026-08-13 > "$TMP_ROOT/bad.log"; then
    echo "FAIL: insecure freshness URL passed" >&2
    exit 1
fi
grep -Fq 'URL must use HTTPS' "$TMP_ROOT/bad.log"

python3 - "$SCRIPT_DIR" "$TMP_ROOT" "$SCRIPT_DIR/../../.." <<'PY'
from __future__ import annotations

import copy
from contextlib import redirect_stdout
import io
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import textwrap
from unittest.mock import patch

scripts, root, repo = map(Path, sys.argv[1:])
sys.path.insert(0, str(scripts))
import doc_freshness

registry_path = root / "fixture-registry.json"
checks_path = root / "fixture-checks.json"
report_path = root / "fixture-report.json"
today = "2026-08-17"
source = {
    "schema_version": 2,
    "products": {
        "demo": {
            "lifecycle": "active",
            "profiles": {
                # Child first: inheritance must not depend on mapping order.
                "cli": {"inherits": "ide"},
                "ide": {"support_level": "partial", "verified_at": "2020-01-01", "sources": ["https://example.invalid/ide"]},
                "manual": {"support_level": "manual", "verified_at": "2020-01-01", "sources": ["https://example.invalid/manual"]},
                "source": {"support_level": "source-only", "verified_at": "2020-01-01", "sources": ["https://example.invalid/source"]},
            },
        },
    },
}
checks = {"schema_version": 1, "checks": [{"id": "demo", "url": "https://example.invalid/docs", "required_terms": ["skills"]}]}

def reset(registry=source, check_document=checks):
    registry_path.write_text(json.dumps(registry), encoding="utf-8")
    checks_path.write_text(json.dumps(check_document), encoding="utf-8")
    report_path.unlink(missing_ok=True)
    return registry_path.read_bytes()

def arguments(*extra):
    return ["--registry", str(registry_path), "--checks", str(checks_path), "--today", today, "--report", str(report_path), *extra]

def run(*extra):
    result = subprocess.run([sys.executable, str(scripts / "check-doc-freshness.py"), *arguments(*extra)], capture_output=True, text=True)
    assert report_path.is_file(), result.stderr
    return result.returncode, json.loads(report_path.read_text(encoding="utf-8"))

original = reset()
status, report = run()
assert status == 1 and report["ok"] is False
assert registry_path.read_bytes() == original
assert set(report["stale_profiles"]) == {"demo/cli", "demo/ide", "demo/manual", "demo/source"}
assert report["demoted_profiles"] == []
print("OK stale check fails, persists evidence, and leaves registry bytes unchanged")

status, report = run("--demote-stale")
assert status == 0 and report["ok"] is True and not report["errors"]
assert set(report["demoted_profiles"]) == {"demo/ide", "demo/manual", "demo/source"}
updated = json.loads(registry_path.read_text(encoding="utf-8"))
profiles = updated["products"]["demo"]["profiles"]
assert profiles["ide"]["support_level"] == "stale-partial"
assert profiles["manual"]["support_level"] == "stale-manual"
assert profiles["source"]["support_level"] == "stale-source-only"
assert profiles["cli"] == {"inherits": "ide"}
assert doc_freshness.resolve_profile(profiles, "cli")["support_level"] == "stale-partial"
assert all(profiles[name]["verified_at"] == "2020-01-01" for name in ("ide", "manual", "source"))
demoted_bytes = registry_path.read_bytes()
status, report = run("--demote-stale")
assert status == 0 and not report["demoted_profiles"]
assert registry_path.read_bytes() == demoted_bytes
status, report = run()
assert status == 1 and report["stale_profiles"]
assert registry_path.read_bytes() == demoted_bytes
print("OK authorized demotion succeeds and is idempotent; stale dates stay visible to check mode")

curated = json.loads((scripts.parent / "references/registry-v2.json").read_text(encoding="utf-8"))
claude_cli = copy.deepcopy(curated["products"]["claude"]["profiles"]["code-cli"])
assert "support_level" not in claude_cli
claude_cli["verified_at"] = "2020-01-01"
contract_source = {
    "schema_version": 2,
    "support_contract": curated["support_contract"],
    "products": {"claude": {
        "lifecycle": "active", "default_profile": "code-cli",
        "profiles": {
            "inherited-cli": {"inherits": "code-cli"},
            "manual-cli": {"inherits": "code-cli", "migration_policy": "manual-rebuild"},
            "code-cli": claude_cli,
            "already-stale": {"migration_policy": "stale-manual", "verified_at": "2020-01-01", "sources": ["https://example.invalid/manual"]},
        },
    }},
}
from migration_core import Registry

for reverse_order in (False, True):
    fixture = copy.deepcopy(contract_source)
    if reverse_order:
        fixture["products"]["claude"]["profiles"] = dict(reversed(list(fixture["products"]["claude"]["profiles"].items())))
    original = reset(fixture)
    runtime = Registry(registry_path, root, home=root)
    profiles = fixture["products"]["claude"]["profiles"]
    for name, expected in (("code-cli", "partial"), ("inherited-cli", "partial"), ("manual-cli", "manual"), ("already-stale", "stale-manual")):
        assert runtime.profile_raw(f"claude/{name}")[2]["support_level"] == expected
        assert doc_freshness.effective_support_level(fixture, profiles, name) == expected
    status, report = run()
    assert status == 1 and registry_path.read_bytes() == original
    status, report = run("--demote-stale")
    assert status == 0 and report["ok"] is True
    assert set(report["demoted_profiles"]) == {"claude/code-cli", "claude/manual-cli"}
    updated = json.loads(registry_path.read_text(encoding="utf-8"))
    profiles = updated["products"]["claude"]["profiles"]
    assert profiles["code-cli"]["support_level"] == "stale-partial"
    assert profiles["manual-cli"]["support_level"] == "stale-manual"
    assert profiles["inherited-cli"] == fixture["products"]["claude"]["profiles"]["inherited-cli"]
    assert profiles["already-stale"] == fixture["products"]["claude"]["profiles"]["already-stale"]
    runtime = Registry(registry_path, root, home=root)
    for name in profiles:
        # Explicit inherited support takes precedence over policy defaults,
        # exactly as Registry._with_support specifies.
        assert doc_freshness.effective_support_level(updated, profiles, name) == runtime.profile_raw(f"claude/{name}")[2]["support_level"]
        assert doc_freshness.resolve_profile(profiles, name)["verified_at"] == "2020-01-01"
    demoted_bytes = registry_path.read_bytes()
    status, report = run("--demote-stale")
    assert status == 0 and not report["demoted_profiles"] and registry_path.read_bytes() == demoted_bytes
print("OK actual contract-only Claude support and inherited policy overrides demote without changing verified_at")

bad_checks = copy.deepcopy(checks)
bad_checks["checks"][0]["url"] = "http://example.invalid/docs"
original = reset(check_document=bad_checks)
status, report = run("--demote-stale")
assert status == 1 and report["ok"] is False
assert any("URL must use HTTPS" in error for error in report["errors"])
assert not report["demoted_profiles"] and registry_path.read_bytes() == original
print("OK other freshness errors reject demotion before registry writes")

for invalid_date in ("not-a-date", "2030-01-01"):
    invalid = copy.deepcopy(source)
    invalid["products"]["demo"]["profiles"] = {"ide": {"support_level": "partial", "verified_at": invalid_date, "sources": ["https://example.invalid/ide"]}}
    original = reset(invalid)
    status, report = run("--demote-stale")
    assert status == 1 and report["ok"] is False
    assert not report["stale_profiles"] and not report["demoted_profiles"]
    assert registry_path.read_bytes() == original
print("OK invalid and future dates are errors, not demotion evidence")

unsupported = copy.deepcopy(source)
unsupported["products"]["demo"]["profiles"] = {"ide": {"support_level": "full", "verified_at": "2020-01-01", "sources": ["https://example.invalid/ide"]}}
original = reset(unsupported)
status, report = run("--demote-stale")
assert status == 1 and report["stale_profiles"] == ["demo/ide"]
assert not report["demoted_profiles"] and registry_path.read_bytes() == original
print("OK unsupported downgrade levels remain failures without invented support states")

original = reset()
with patch.object(doc_freshness.os, "replace", side_effect=OSError("injected commit failure")), redirect_stdout(io.StringIO()):
    status = doc_freshness.main(arguments("--demote-stale"))
assert status == 1 and registry_path.read_bytes() == original
assert not list(root.glob(".fixture-registry.json.*"))
print("OK atomic registry commit failure preserves the original and removes staging")

original = reset()
with patch("socket.socket", side_effect=AssertionError("network access is forbidden")), redirect_stdout(io.StringIO()):
    status = doc_freshness.main(arguments())
assert status == 1 and registry_path.read_bytes() == original
checks_bytes = checks_path.read_bytes()
for input_path in (registry_path, checks_path):
    status = subprocess.run([
        sys.executable, str(scripts / "check-doc-freshness.py"),
        "--registry", str(registry_path), "--checks", str(checks_path), "--today", today,
        "--report", str(input_path),
    ], capture_output=True, text=True).returncode
    assert status == 1 and registry_path.read_bytes() == original and checks_path.read_bytes() == checks_bytes
print("OK check is offline and report output cannot overwrite either input")

# Exercise only the workflow's local evidence exporter; never execute checkout,
# git pushes, gh commands, or any network action from the YAML.
workflow = (repo / ".github/workflows/freshness.yml").read_text(encoding="utf-8")
assert re.search(r"(?m)^permissions:\n  contents: read$", workflow)
demotion = workflow.split("  stale-demotion:", 1)[1]
condition = re.search(r"(?m)^    if: (.+)$", demotion).group(1)
for gate in ("!cancelled()", "github.event_name == 'workflow_dispatch'", "inputs.demote_stale", "needs.freshness-check.outputs.stale_found == 'true'"):
    assert gate in condition, condition
assert "contents: write" in demotion and "pull-requests: write" in demotion
assert re.search(r"Upload freshness report\n        if: always\(\)", workflow)
assert re.search(r"Upload demotion report\n        if: always\(\)", workflow)
assert "--base main || true" not in demotion
assert "--online" not in workflow
exporter = re.search(r"Export stale evidence.*?python3 <<'PY'\n(.*?)\n          PY", workflow, flags=re.DOTALL).group(1)
exporter = textwrap.dedent(exporter)
compile(exporter, "freshness-evidence", "exec")
assert "steps.evidence.outputs.stale_found" in workflow
for stale, expected in ((["demo/ide"], "true"), ([], "false")):
    evidence_report = root / "freshness-report.json"
    evidence_report.write_text(json.dumps({"ok": False, "stale_profiles": stale}), encoding="utf-8")
    output = root / "github-output.txt"
    output.unlink(missing_ok=True)
    environment = dict(os.environ, GITHUB_OUTPUT=str(output))
    subprocess.run([sys.executable, "-c", exporter], cwd=root, env=environment, check=True)
    assert output.read_text(encoding="utf-8") == f"stale_found={expected}\n"
print("OK CI preserves failed reports and gates manual demotion on actual stale evidence")
PY

echo "Documentation freshness tests passed"
