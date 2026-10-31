#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

python3 - "$SCRIPT_DIR" <<'PY'
import hashlib
import importlib.util
import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path
from unittest import mock

scripts = Path(sys.argv[1])
sys.path.insert(0, str(scripts))
from acb.bundle import verify_bundle
from migration_core import PlanItem, SurfacePath, apply_plan, atomic_write, hash_path, rollback_manifest, verify_manifest


def surface(path, boundary):
    relative = path.relative_to(boundary).as_posix()
    return SurfacePath("fixture", "cli", "skills", "project", "directory", relative,
                       path, boundary, "agent-skill", "validate-then-atomic-copy",
                       "canonical", relative, 0)


with tempfile.TemporaryDirectory(prefix="atomic-write-newline-") as temporary:
    target = Path(temporary) / "mixed newline 文本.md"
    rendered = "# 审查迁移\n保留 LF 行\n保留 CRLF 行\r\nUnicode: 中文 café 🐈\n"
    expected_bytes = rendered.encode("utf-8")
    original_fdopen = os.fdopen

    def windows_fdopen(descriptor, mode="r", *arguments, **keywords):
        if "b" not in mode and "newline" not in keywords:
            keywords["newline"] = "\r\n"
        return original_fdopen(descriptor, mode, *arguments, **keywords)

    with mock.patch("migration_core.os.fdopen", side_effect=windows_fdopen):
        atomic_write(target, rendered)
    assert target.read_bytes() == expected_bytes, "atomic text write changed reviewed UTF-8 bytes"
    assert hash_path(target) == hashlib.sha256(expected_bytes).hexdigest(), "written bytes differ from preview hash"
    print("OK atomic text write preserves mixed newlines, Unicode and preview hash under Windows defaults")


with tempfile.TemporaryDirectory(prefix="runtime-transactions-") as temporary:
    root = Path(temporary).resolve()
    workspace = root / "workspace"
    fixture_home = root / "home"
    workspace.mkdir()
    fixture_home.mkdir()
    environment = dict(os.environ, HOME=str(fixture_home), AGENT_SKILLS_PLATFORM="linux")

    def skill(path, name, body):
        path.mkdir(parents=True, exist_ok=True)
        (path / "SKILL.md").write_text(
            f"---\nname: {name}\ndescription: Fixture {name}\n---\n{body}\n", encoding="utf-8"
        )

    def profile(product):
        base = f".{product}"
        definitions = {
            "skills": ("skills", "directory", "agent-skill", "validate-then-atomic-copy"),
            "instructions": ("rules.md", "file", "agents-md", "semantic-ir-with-loss-report"),
            "mcp": ("mcp.json", "file", "json:mcpServers", "profile-version-adapter"),
            "plugins": ("plugins", "directory", "opaque", "preserve-package"),
            "handoff": ("handoff.json", "file", "json", "session-summary-handoff"),
        }
        return {
            "default_profile": "cli",
            "profiles": {"cli": {
                "migration_policy": "bidirectional-reviewed",
                "detection": [{"type": "file-signature", "paths": [f".{product}-installed"]}],
                "surfaces": {
                    kind: [{"path": f"{base}/{name}", "scope": "project", "storage": storage,
                            "format": format_name, "policy": policy}]
                    for kind, (name, storage, format_name, policy) in definitions.items()
                },
            }},
        }

    registry = root / "registry.json"
    registry.write_text(json.dumps({
        "schema_version": 2,
        "products": {
            **{name: profile(name) for name in ("source-a", "source-b", "destination")},
            "old-source": {"alias_of": {"product": "source-a", "profile": "cli"}},
        },
    }), encoding="utf-8")

    def cli(command, *arguments, success=True):
        result = subprocess.run(
            [sys.executable, str(scripts / "context-migrator.py"), command,
             *map(str, arguments), "--json"], env=environment, text=True, capture_output=True,
        )
        if success:
            assert result.returncode == 0, (command, result.stdout, result.stderr)
        else:
            assert result.returncode != 0, (command, result.stdout, result.stderr)
        assert "Traceback" not in result.stderr, result.stderr
        return json.loads(result.stdout) if result.stdout.strip() else None

    common = ("--workspace", workspace, "--registry", registry, "--scope", "project")
    for name in ("first", "second"):
        skill(workspace / ".source-a/skills" / name, name, f"# Distinct {name}")
    (workspace / ".source-a/rules.md").write_text("# Review external inputs\n", encoding="utf-8")
    for product, server in (("source-a", "alpha"), ("source-b", "beta")):
        (workspace / f".{product}").mkdir(exist_ok=True)
        (workspace / f".{product}/mcp.json").write_text(json.dumps({
            "mcpServers": {server: {"command": "node", "args": [f"{server}.js"]}},
        }), encoding="utf-8")
        (workspace / f".{product}-installed").mkdir()

    # Capture by a deprecated selector: only its resolved source may enter inventory.
    named_bundle = root / "named.acb"
    cli("snapshot", *common, "--source", "old-source", "--target", "destination/cli",
        "--output", named_bundle)
    rows = json.loads((named_bundle / "inventory.json").read_text())['rows']
    assert rows and {row["product"] for row in rows} == {"source-a"}, rows

    bundle = root / "device.acb"
    cli("snapshot", *common, "--all-installed", "--output", bundle)
    expected_skills = {
        name: (workspace / ".source-a/skills" / name / "SKILL.md").read_bytes()
        for name in ("first", "second")
    }
    for product in ("source-a", "source-b"):
        (workspace / f".{product}-installed").rmdir()
        shutil.rmtree(workspace / f".{product}")
    (workspace / ".destination-installed").mkdir()
    plan = root / "restore-plan.json"
    preview = cli("restore", bundle, *common, "--all-installed", "--plan-only", "--plan-out", plan,
                  "--restore-root", root / "preview-extraction")
    assert preview["plan_document"]["items"] and preview["plan_document"]["plan_sha256"] == preview["plan_sha256"]
    assert not (root / "preview-extraction").exists()
    assert not (workspace / ".destination").exists()
    reviewed = json.loads(plan.read_text(encoding="utf-8"))
    previews = [change for item in reviewed["items"] for change in (item.get("review_preview") or {}).get("changes", [])]
    skill_previews = [change for change in previews if Path(change["path"]).name in expected_skills]
    assert len(skill_previews) == 2, previews
    assert {Path(change["path"]).resolve() for change in skill_previews} == {
        workspace / ".destination/skills" / name for name in expected_skills
    }, skill_previews
    assert all(not Path(item["source"]["resolved_path"]).exists() for item in reviewed["items"])
    instruction_items = [item for item in reviewed["items"] if item["object_type"] == "instructions"]
    assert len(instruction_items) == 1 and instruction_items[0]["status"] == "ready-lossy", instruction_items
    assert all(item["status"] == "ready" for item in reviewed["items"] if item["object_type"] != "instructions")
    loss_id = next(f"{index}:instructions" for index, item in enumerate(reviewed["items"])
                   if item["object_type"] == "instructions")

    result = cli("restore", bundle, *common, "--plan-in", plan, "--yes", "--include", "lossy")
    assert result["stage"] == "verify" and result["plan"] == str(plan)
    assert result["plan_sha256"] == reviewed["plan_sha256"]
    assert result["summary"].get("applied-lossy") == 1, result
    for name in ("first", "second"):
        actual = workspace / ".destination/skills" / name / "SKILL.md"
        assert actual.read_bytes() == expected_skills[name]
    servers = json.loads((workspace / ".destination/mcp.json").read_text())["mcpServers"]
    assert set(servers) == {"alpha", "beta"}, servers
    assert (workspace / ".destination/rules.md").read_text() == "# Review external inputs\n"
    manifest = Path(result["manifest"])
    assert verify_manifest(manifest) == []
    rollback_manifest(manifest)
    assert not (workspace / ".destination/skills/first").exists()
    # The generic apply entry point must replay the same ACB plan too.
    applied = cli("apply", plan, "--registry", registry, "--bundle", bundle,
                  "--accept-loss", loss_id, "--yes")
    assert json.loads((workspace / ".destination/mcp.json").read_text())["mcpServers"] == servers
    rollback_manifest(Path(applied["manifest"]))
    cli("apply", plan, "--registry", registry, "--yes", success=False)
    print("OK exact multi-Skill, file Instructions, merged MCP and generic apply replay")

    # Drift rejection and dry-run leave target surfaces and extraction paths unchanged.
    dry_root = root / "dry-extraction"
    dry_plan = root / "dry-plan.json"
    cli("restore", bundle, *common, "--all-installed", "--dry-run", "--plan-out", dry_plan,
        "--restore-root", dry_root)
    assert not dry_root.exists() and not dry_plan.exists()
    (workspace / ".destination/rules.md").write_text("Changed after review\n", encoding="utf-8")
    cli("restore", bundle, *common, "--plan-in", plan, "--yes", success=False)
    assert (workspace / ".destination/rules.md").read_text() == "Changed after review\n"
    (workspace / ".destination/rules.md").unlink()
    bundle_bytes = {p.relative_to(bundle): p.read_bytes() for p in bundle.rglob('*') if p.is_file()}
    cli("restore", bundle, *common, "--all-installed", "--plan-only", "--plan-out", bundle / "manifest.json", success=False)
    cli("restore", bundle, *common, "--all-installed", "--plan-only", "--restore-root", bundle, success=False)
    assert bundle_bytes == {p.relative_to(bundle): p.read_bytes() for p in bundle.rglob('*') if p.is_file()}
    print("OK preview, dry-run, stale-target refusal and artifact overlap preserve inputs")

    # Plugins preserve bytes; handoff capture always applies the portable whitelist.
    plugins = workspace / ".source-a/plugins"
    plugins.mkdir(parents=True)
    image_bytes = b"\x89PNG\r\n\x1a\n\x00\xff"
    (plugins / "icon.png").write_bytes(image_bytes)
    (plugins / "run.sh").write_text("#!/usr/bin/env bash\nprintf 'fixture\\n'\n", encoding="utf-8")
    (plugins / "run.sh").chmod(0o755)
    (workspace / ".source-a/handoff.json").write_text(json.dumps({
        "reviewed_summary": "Reviewed work", "git_branch": "feature/portable",
        "selected_files": ["src/main.py", "src/a..b.py", "../outside", "/private", "C:\\private.txt"],
        "patch": None, "session_state": {"opaque": "omitted"}, "raw": "omitted",
    }), encoding="utf-8")
    opt_bundle = root / "opt-in.acb"
    opt_args = (*common, "--source", "source-a/cli", "--target", "destination/cli",
                "--objects", "plugins,handoff")
    cli("snapshot", *opt_args, "--output", opt_bundle, success=False)
    assert not opt_bundle.exists()
    cli("snapshot", *opt_args, "--include-plugins", "--include-session", "--output", opt_bundle)
    portable_files = list((opt_bundle / "objects/handoff").rglob('handoff.json'))
    portable = json.loads(portable_files[0].read_text())
    assert set(portable) == {"reviewed_summary", "git_branch", "selected_files", "patch"}
    assert portable['selected_files'] == ['src/a..b.py', 'src/main.py'], portable
    opt_preview = cli("restore", opt_bundle, *opt_args, "--plan-only")
    assert all(item['review_preview'] for item in opt_preview['plan_document']['items'])
    extraction = root / "approved-extraction"
    cli("restore", opt_bundle, *opt_args, "--yes", "--restore-root", extraction, success=False)
    assert not (workspace / ".destination/plugins").exists() and not extraction.exists()
    opt_result = cli("restore", opt_bundle, *opt_args, "--yes", "--include-plugins", "--include-session", "--restore-root", extraction)
    assert extraction.exists() and not opt_result['restore']['dry_run']
    assert (workspace / ".destination/plugins/icon.png").read_bytes() == image_bytes
    restored_handoff = json.loads((workspace / ".destination/handoff.json").read_text())
    assert restored_handoff == portable, restored_handoff
    print("OK explicit plugin/session flags, binary plugin asset and portable handoff round-trip")

    # ACB sources must ignore the destination device's environment overrides.
    definitions = json.loads(registry.read_text())
    definitions['products']['source-a']['profiles']['cli']['surfaces']['mcp'][0].update(
        override_env='FIXTURE_SOURCE_DATA', override_relative_path='mcp.json'
    )
    registry.write_text(json.dumps(definitions), encoding='utf-8')
    override_root = root / 'override-data'
    override_root.mkdir()
    override_file = override_root / 'mcp.json'
    environment['FIXTURE_SOURCE_DATA'] = str(override_root)
    override_file.write_text('{"mcpServers":{"bundled":{"command":"node"}}}', encoding='utf-8')
    override_bundle, override_plan = root / 'override.acb', root / 'override-plan.json'
    cli('snapshot', *common, '--source', 'old-source', '--target', 'destination/cli',
        '--objects', 'mcp', '--output', override_bundle)
    override_file.write_text('{"mcpServers":{"local":{"command":"python3"}}}', encoding='utf-8')
    cli('restore', override_bundle, *common, '--all-installed', '--objects', 'mcp',
        '--plan-only', '--plan-out', override_plan)
    override_result = cli('restore', override_bundle, '--workspace', workspace, '--registry', registry,
                          '--plan-in', override_plan, '--yes')
    assert set(json.loads((workspace / '.destination/mcp.json').read_text())['mcpServers']) == {'bundled'}
    rollback_manifest(Path(override_result['manifest']))

    # The saved plan owns its alias selector and local scope during replay.
    for product in ('source-a', 'destination'):
        definitions['products'][product]['profiles']['cli']['surfaces']['mcp'][0]['scope'] = 'local'
    registry.write_text(json.dumps(definitions), encoding='utf-8')
    local_bundle, local_plan = root / 'local.acb', root / 'local-plan.json'
    local_args = ('--workspace', workspace, '--registry', registry, '--scope', 'local',
                  '--source', 'old-source', '--target', 'destination/cli', '--objects', 'mcp')
    cli('snapshot', *local_args, '--output', local_bundle)
    cli('restore', local_bundle, *local_args, '--plan-only', '--plan-out', local_plan)
    cli('restore', local_bundle, '--workspace', workspace, '--registry', registry, '--plan-in', local_plan, '--yes')
    assert set(json.loads((workspace / '.destination/mcp.json').read_text())['mcpServers']) == {'local'}
    print('OK bundle sources ignore device overrides and saved alias/local scope replay')

    # Rollback checks all backup prerequisites before touching any target.
    source_root = root / "rollback-source"
    target_root = root / "rollback-target"
    source_root.mkdir()
    target_root.mkdir()
    items = []
    for name in ('one', 'two'):
        skill(source_root / name, name, "New content")
        skill(target_root / name, name, "Original content")
        items.append(PlanItem('skills', 'ready', 'fixture', surface(source_root / name, source_root), surface(target_root / name, target_root)))
    items.insert(0, PlanItem('hooks', 'manual-rebuild', 'review externally'))
    journal, journal_path = apply_plan(items, workspace)
    assert [(item['plan_index'], item['object_id']) for item in journal['items']] == [(0, '0:hooks'), (1, '1:skills'), (2, '2:skills')]
    before = {p: p.read_bytes() for p in target_root.rglob('SKILL.md')}
    backup = Path(journal['changes'][0]['backup'])
    original_backup = (backup / 'SKILL.md').read_bytes()
    (backup / 'SKILL.md').write_text('Altered backup\n', encoding='utf-8')
    try:
        rollback_manifest(journal_path)
    except ValueError as error:
        assert 'changed rollback backup' in str(error)
    else:
        raise AssertionError('rollback accepted an altered backup')
    assert before == {p: p.read_bytes() for p in target_root.rglob('SKILL.md')}
    (backup / 'SKILL.md').write_bytes(original_backup)
    shutil.rmtree(backup)
    try:
        rollback_manifest(journal_path)
    except ValueError as error:
        assert 'missing rollback backup' in str(error)
    else:
        raise AssertionError('rollback accepted a missing backup')
    assert before == {p: p.read_bytes() for p in target_root.rglob('SKILL.md')}
    print("OK rollback altered/missing-backup refusal preserves every target and manifest indices")

    # Corrupt metadata returns verification errors instead of accepting an empty bundle.
    invalid_bundle = root / "invalid.acb"
    (invalid_bundle / "objects").mkdir(parents=True)
    (invalid_bundle / "checksums.json").write_text('{}', encoding="utf-8")
    assert verify_bundle(invalid_bundle)
    (invalid_bundle / "checksums.json").write_text('[]', encoding="utf-8")
    assert verify_bundle(invalid_bundle)
    print("OK missing/invalid bundle metadata fails closed")

    if importlib.util.find_spec('cryptography'):
        same_key = root / "same.key"
        cli('bundle-keygen', '--out-private', same_key, '--out-public', same_key, success=False)
        assert not same_key.exists()
        private_key, public_key = root / 'private.key', root / 'public.key'
        cli('bundle-keygen', '--out-private', private_key, '--out-public', public_key)
        original_private = private_key.read_bytes()
        cli('bundle-keygen', '--out-private', private_key, '--out-public', root / 'another-public.key', success=False)
        assert private_key.read_bytes() == original_private
        cli('bundle-sign', bundle, '--key', private_key)
        assert cli('bundle-verify', bundle, '--trusted-key', public_key)['signature_verified']
        (bundle / 'signature.json').write_text('[]', encoding='utf-8')
        cli('bundle-verify', bundle, '--trusted-key', public_key, success=False)
        print('OK key generation preserves existing keys and malformed signature fails closed')
    else:
        print('SKIP Ed25519 fixture: optional cryptography dependency unavailable')

    link = root / 'output-link'
    untouched = root / 'untouched'
    untouched.mkdir()
    try:
        link.symlink_to(untouched, target_is_directory=True)
    except OSError:
        print('SKIP symlink fixture: platform disallows creating symlinks')
    else:
        cli('snapshot', *common, '--source', 'source-a/cli', '--target', 'destination/cli', '--output', link, success=False)
        assert not list(untouched.iterdir())
        print('OK output symlink refusal preserves unrelated destination')

print('Runtime transaction and replay tests passed')
PY
