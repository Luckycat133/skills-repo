#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

python3 - "$SCRIPT_DIR" "$SKILL_DIR/references/registry-v2.json" "$TMP_ROOT" <<'PY'
import json
import sys
from pathlib import Path

sys.path.insert(0, sys.argv[1])
from migration_core import (
    PlanItem,
    Registry,
    apply_plan,
    build_plan,
    build_plan_document,
    emit_mcp_document,
    mcp_adapter,
    parse_mcp_document,
    rollback_manifest,
    verify_manifest,
)

jsonc = r'''
{
  // a comment outside strings
  "mcpServers": {
    "demo": {
      "command": "demo//literal",
      "args": ["--safe",],
    },
  },
}
'''
servers = parse_mcp_document(jsonc, "jsonc:mcpServers")
assert len(servers) == 1
assert servers[0].command == "demo//literal"
assert servers[0].args == ["--safe"]
rendered_jsonc, _ = emit_mcp_document(servers, "jsonc:servers")
assert set(json.loads(rendered_jsonc)) == {"servers"}

for source_format in (
    "json5:mcpServers",
    "toml:mcp_servers",
    "yaml:mcpServers",
    "xml:mcpServers",
    "lua:mcpServers",
):
    adapter = mcp_adapter(source_format)
    assert adapter["automatic"] is False
    try:
        parse_mcp_document("{}", source_format)
    except ValueError as error:
        assert "dedicated reviewed reconstruction adapter" in str(error)
    else:
        raise AssertionError(f"{source_format} used a generic JSON fallback")

workspace = Path(sys.argv[3]) / "workspace"
home = Path(sys.argv[3]) / "home"
workspace.mkdir()
home.mkdir()
(workspace / ".cline").mkdir()
(workspace / ".cline/skills").mkdir()
(workspace / ".cline/skills/fixture-skill").mkdir()
(workspace / ".cline/skills/fixture-skill/SKILL.md").write_text(
    "---\nname: fixture-skill\ndescription: Test skill\nmetadata:\n  version: '1'\n---\n# fixture\n",
    encoding="utf-8",
)
(workspace / ".cline/rules").mkdir()
(workspace / ".cline/rules/rule.md").write_text(
    "# Rule\n",
    encoding="utf-8",
)
(workspace / ".cline/mcp.json").write_text(
    '{"mcpServers":{"demo":{"command":"demo"}}}\n',
    encoding="utf-8",
)
registry = Registry(Path(sys.argv[2]), workspace, home)

plan, _ = build_plan(
    registry,
    "cline/ide",
    "codex/cli",
    ["mcp"],
    "project",
)
assert plan[0].status == "manual-rebuild"
assert "manual-template" in plan[0].reason
assert plan[0].manual_actions

cloud = build_plan_document(
    registry,
    "cline/ide",
    "trae/ide",
    ["skills", "instructions", "mcp"],
    "project",
)
# trae/ide: skills -> ready, instructions -> manual-rebuild (format mismatch),
# mcp -> manual-rebuild (not mapped)
statuses = {item["status"] for item in cloud["items"]}
assert "ready" in statuses, statuses
assert "manual-rebuild" in statuses, statuses
assert "invalid" not in statuses, statuses
# Rebuild manifest includes manual-rebuild items (may have empty actions for unmapped)
assert len(cloud["rebuild_manifest"]["items"]) >= 1
assert "literal-secret" not in json.dumps(cloud)

(workspace / ".cline/mcp.json").write_text(
    '{"mcpServers":{"remote":{"type":"streamableHttp","url":"https://example.test/mcp","headers":{"Authorization":"Bearer literal-secret"}}}}\n',
    encoding="utf-8",
)
remote = build_plan_document(
    registry,
    "cline/ide",
    "forge/cli",
    ["mcp"],
    "project",
)
assert remote["items"][0]["status"] == "manual-rebuild"
assert "dedicated target-profile transport adapter" in remote["items"][0]["reason"]
assert "literal-secret" not in json.dumps(remote)

# Claude project MCP was present in the legacy path map but absent from v2.
# Exercise both profiles, safe previews, round-trip mapping, and rollback.
for profile_name in ("code-cli", "desktop-code"):
    project = (Path(sys.argv[3]) / profile_name).resolve()
    project.mkdir()
    cline_file = project / ".cline" / "mcp.json"
    cline_file.parent.mkdir()
    source_bytes = b'{"mcpServers":{"demo":{"command":"demo","args":["--safe"]}}}\n'
    cline_file.write_bytes(source_bytes)
    claude_file = project / ".mcp.json"
    original_target = b'{"keep":true,"mcpServers":{"retained":{"command":"retain"}}}\n'
    claude_file.write_bytes(original_target)
    scoped = Registry(Path(sys.argv[2]), project, home)
    selector = f"claude/{profile_name}"
    preview = build_plan_document(scoped, "cline/ide", selector, ["mcp"], "project")
    assert len(preview["items"]) == 1, preview
    assert preview["items"][0]["status"] == "ready", preview
    assert preview["items"][0]["target"]["resolved_path"] == str(claude_file)
    changes = preview["items"][0]["review_preview"]["changes"]
    assert changes[0]["added"] == ["demo"] and changes[0]["removed"] == ["retained"]
    assert claude_file.read_bytes() == original_target
    assert not (project / ".agent-context-migration").exists()

    forward = [PlanItem.from_dict(item) for item in preview["items"]]
    _, forward_manifest = apply_plan(forward, project)
    result = json.loads(claude_file.read_bytes())
    assert result["keep"] is True
    assert set(result["mcpServers"]) == {"demo"}, result
    assert verify_manifest(forward_manifest) == []
    assert cline_file.read_bytes() == source_bytes

    reverse, _ = build_plan(scoped, selector, "cline/ide", ["mcp"], "project")
    assert len(reverse) == 1 and reverse[0].status == "ready", reverse
    _, reverse_manifest = apply_plan(reverse, project)
    assert set(json.loads(cline_file.read_bytes())["mcpServers"]) == {"demo"}
    assert verify_manifest(reverse_manifest) == []
    assert rollback_manifest(reverse_manifest) == 1
    assert cline_file.read_bytes() == source_bytes
    assert rollback_manifest(forward_manifest) == 1
    assert claude_file.read_bytes() == original_target

    claude_file.write_text("{broken", encoding="utf-8")
    invalid, _ = build_plan(scoped, selector, "cline/ide", ["mcp"], "project")
    assert invalid[0].status == "invalid", invalid
    try:
        apply_plan(invalid, project, strict=True)
    except ValueError:
        pass
    else:
        raise AssertionError("invalid Claude project MCP was applied")
    assert cline_file.read_bytes() == source_bytes
PY

echo "MCP adapter, Claude project round-trip, and cloud rebuild tests passed"
