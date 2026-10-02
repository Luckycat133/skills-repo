#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REGISTRY_PATH="${SCRIPT_DIR}/../references/registry-v2.json"

cd "$SCRIPT_DIR"

python3 - "$REGISTRY_PATH" <<'PYEOF'
import json
import sys
import tempfile
from pathlib import Path

registry_path = Path(sys.argv[1])
sys.path.insert(0, str(registry_path.parent.parent / "scripts"))

from migration_core import (  # noqa: E402
    Registry,
    apply_plan,
    build_plan,
    compute_object_id,
    canonical_relative_path,
)

data = json.loads(registry_path.read_text(encoding="utf-8"))

# Direct: object_id is sha256(product|profile|scope|canonical)[:16]
oid = compute_object_id(
    product="cline",
    profile="ide",
    scope="user",
    canonical_path=".cline/skills",
)
assert len(oid) == 16
assert oid == compute_object_id(
    product="cline", profile="ide", scope="user",
    canonical_path=".cline/skills",
), "oid must be deterministic"
print(f"OK compute_object_id deterministic ({oid})")

# Different canonical path -> different id
oid_other = compute_object_id(
    product="cline",
    profile="ide",
    scope="user",
    canonical_path=".cline/skills/sub",
)
assert oid != oid_other
print("OK distinct canonical paths produce distinct object_ids")

# canonical_relative_path normalizes
path_a = canonical_relative_path(Path("/home/u/.cline/skills"), Path("/home/u"))
path_b = canonical_relative_path(Path("/home/u/.cline/skills/"), Path("/home/u"))
assert path_a == ".cline/skills" == path_b, (path_a, path_b)
print("OK canonical_relative_path normalizes")

# Alias equivalence: vscode resolves to copilot/vscode; the planner
# emits the same object_id for both selectors because it uses the
# resolved source surface.
temporary = tempfile.TemporaryDirectory(prefix="oid-tests-")
test_root = Path(temporary.name)
ws = test_root / "workspace"
home = test_root / "home"
ws.mkdir()
home.mkdir()
# Pin the POSIX layout the fixtures create; on win32 the registry would
# otherwise resolve cline surfaces to %APPDATA% and miss the tree.
import os as _os
_os.environ.setdefault("AGENT_SKILLS_PLATFORM", "linux")
(ws / ".cline/skills/test-skill").mkdir(parents=True)
(ws / ".cline/skills/test-skill/SKILL.md").write_text(
    "---\nname: test-skill\ndescription: d.\nmetadata:\n  version: '1'\n---\n",
    encoding="utf-8",
)
(ws / ".cline/rules").mkdir(parents=True, exist_ok=True)
(ws / ".cline/rules/test-rule.md").write_text(
    "---\npaths:\n  - 'src/**/*.ts'\n---\ntest\n", encoding="utf-8",
)
(ws / ".cline/mcp.json").write_text(
    '{"mcpServers":{"demo":{"command":"demo"}}}', encoding="utf-8",
)

registry = Registry(registry_path, ws, home)

plan_vscode, _ = build_plan(registry, "vscode", "forge/cli", ["skills"], "project")
plan_copilot, _ = build_plan(registry, "copilot/vscode", "forge/cli", ["skills"], "project")
assert plan_vscode, plan_copilot
for a, b in zip(plan_vscode, plan_copilot):
    if a.object_id:
        assert a.object_id == b.object_id, (a.object_id, b.object_id, a.object_type)
print("OK vscode and copilot/vscode produce identical object_ids (alias equivalence)")

# Repeat-run idempotency: build the same plan twice, object_ids match.
plan_a, _ = build_plan(registry, "cline/ide", "forge/cli", ["skills"], "project")
plan_b, _ = build_plan(registry, "cline/ide", "forge/cli", ["skills"], "project")
assert [item.object_id for item in plan_a] == [item.object_id for item in plan_b]
print("OK repeated build_plan calls produce identical object_ids")

# End-to-end: apply lands on a basename-preserved path.
manifest, mp = apply_plan(plan_a, ws, ws / "manifest.json")
summary = manifest["summary"]
assert summary.get("applied", 0) >= 1
# Skill write should land at forge/skills/test-skill (preserves basename).
skill_dst = ws / ".forge" / "skills" / "test-skill" / "SKILL.md"
if not skill_dst.exists():
    tgt = [
        (
            i.object_type,
            i.status,
            str(i.target.resolved_path) if i.target else None,
        )
        for i in plan_a
    ]
    landed = [str(p) for p in ws.rglob("SKILL.md")]
    raise SystemExit(
        f"skill did not land at {skill_dst}; plan={tgt}; landed={landed}; summary={summary}"
    )
print("OK apply preserves source basename on the target tree")

# Same-name collision: stage two instructions with the same basename
# at different scopes; the apply must produce distinct target paths via
# the object_id short suffix.
collision_ws = test_root / "collision"
(collision_ws / ".cline/rules").mkdir(parents=True, exist_ok=True)
(collision_ws / ".cline/rules/shared.md").write_text(
    "---\npaths:\n  - 'src/**/*.ts'\n---\nfirst\n", encoding="utf-8",
)
(collision_ws / ".cline/rules/sub").mkdir(parents=True)
(collision_ws / ".cline/rules/sub/shared.md").write_text(
    "---\npaths:\n  - 'lib/**/*.ts'\n---\nsecond\n", encoding="utf-8",
)
registry2 = Registry(registry_path, collision_ws, home)
plan_coll, collision_losses = build_plan(registry2, "cline/ide", "cline/ide", ["instructions"], "project")
assert len(plan_coll) == 1 and plan_coll[0].status == "ready-lossy", plan_coll
assert "hierarchy" in {
    loss.field for loss in collision_losses.items
}, collision_losses.to_dict()
# All items should have distinct object_ids.
ids = [item.object_id for item in plan_coll]
assert len(set(ids)) == len(ids), f"collisions in ids: {ids}"
# Accept this fixture's reviewed flattening; verify neither body is overwritten.
manifest2, _ = apply_plan(
    plan_coll, collision_ws, collision_ws / "manifest2.json",
    accept_loss_ids={"0:instructions"},
)
assert manifest2["summary"].get("applied-lossy") == 1, manifest2["summary"]
target_dir = collision_ws / ".cline" / "rules"
written = sorted(p.name for p in target_dir.iterdir() if p.is_file())
assert len(written) >= 2, f"expected both collision files, got {written}"
assert len(manifest2["changes"]) == 2, manifest2["changes"]
contents = [Path(change["path"]).read_text(encoding="utf-8") for change in manifest2["changes"]]
assert any("\nfirst\n" in text and "src/**/*.ts" in text for text in contents), contents
assert any("\nsecond\n" in text and "lib/**/*.ts" in text for text in contents), contents
print(f"OK collision pathnames produced distinct files: {written}")

# Cross-scope separation: user vs project scopes yield different ids.
user_id = compute_object_id(
    product="cline",
    profile="ide",
    scope="user",
    canonical_path=".cline/skills",
)
proj_id = compute_object_id(
    product="cline",
    profile="ide",
    scope="project",
    canonical_path=".cline/skills",
)
assert user_id != proj_id
print("OK cross-scope ids do not collide")

# Unselected target siblings remain intact; migration does not prune them.
stale_ws = test_root / "stale-target"
(stale_ws / ".cline/skills").mkdir(parents=True, exist_ok=True)
stale_target = stale_ws / ".forge/skills/stale-skill/SKILL.md"
stale_target.parent.mkdir(parents=True)
stale_target.write_text(
    "---\nname: stale-skill\ndescription: stale.\nmetadata:\n  version: '1'\n---\n",
    encoding="utf-8",
)
stale_before = stale_target.read_bytes()
# Plan with a *different* skill so stale-skill is not part of the run.
(stale_ws / ".cline/skills/fresh-skill/SKILL.md").parent.mkdir(parents=True, exist_ok=True)
(stale_ws / ".cline/skills/fresh-skill/SKILL.md").write_text(
    "---\nname: fresh-skill\ndescription: fresh.\nmetadata:\n  version: '1'\n---\n",
    encoding="utf-8",
)
registry3 = Registry(registry_path, stale_ws, home)
plan_stale, _ = build_plan(registry3, "cline/ide", "forge/cli", ["skills"], "project")
manifest3, mp3 = apply_plan(plan_stale, stale_ws, stale_ws / "manifest3.json")
fresh_dst = stale_ws / ".forge" / "skills" / "fresh-skill" / "SKILL.md"
assert fresh_dst.exists()
assert stale_target.read_bytes() == stale_before
print("OK fresh skill landed and the unselected target sibling remained intact")

temporary.cleanup()
print()
print("Stable object id tests passed")
PYEOF
