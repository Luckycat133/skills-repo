#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEVICE_RECOVERY_ROOT="$(mktemp -d)"
trap 'rm -rf "$DEVICE_RECOVERY_ROOT"' EXIT
if command -v cygpath >/dev/null 2>&1; then
    DEVICE_RECOVERY_ROOT="$(cygpath -w "$DEVICE_RECOVERY_ROOT")"
    SCRIPT_DIR="$(cygpath -w "$SCRIPT_DIR")"
fi
export DEVICE_RECOVERY_ROOT SCRIPT_DIR
export HOME="$DEVICE_RECOVERY_ROOT"
export AGENT_SKILLS_PLATFORM=linux

python3 - <<'PY'
import hashlib
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

root = Path(os.environ['DEVICE_RECOVERY_ROOT']).resolve()
script = Path(os.environ['SCRIPT_DIR']) / 'context-migrator.py'
sys.path.insert(0, str(script.parent))
from migration_core import _core_plan_items
from acb.recovery import build_recovery

# Prior same-product plans may record temporary paths, with an optional
# scope prefix. Only the missing-source diagnostic is normalized.
for prefix in ('', 'project: ', 'user: '):
    source = {'resolved_path': '/fixture-stage/absent', 'canonical_path': '.fixture/absent'}
    old = {'reason': prefix + 'source path does not exist: /fixture-stage/absent', 'source': source}
    new = {'reason': prefix + 'source path does not exist: .fixture/absent', 'source': source}
    assert _core_plan_items([old]) == _core_plan_items([new])
    changed = {**new, 'reason': prefix + 'source path does not exist: different-surface'}
    assert _core_plan_items([old]) != _core_plan_items([changed])

coverage_fixture = build_recovery(
    bundle_id='fixture', platform={}, profiles={'fixture/cli'}, scopes={'user'},
    requested_objects={'skills'}, objects=[], file_map={}, files={},
    inventory=[{'product': 'fixture', 'profile': 'cli', 'scope': 'user+managed',
                'object_type': 'config', 'canonical_path': '/fixture-private/settings.json', 'exists': True}],
    review_tasks=[], exclusions=[], detection={}, failures=[], requirements={},
    reauth=[], review_requested=False, registry_sha256='fixture',
)
assert len(coverage_fixture['coverage']) == 1
assert '/fixture-private/' not in json.dumps(coverage_fixture)
assert coverage_fixture['coverage'][0]['canonical_path'] == '<external-source>'
print('OK legacy missing-source diagnostics retain identity; mixed scopes and private canonical paths stay portable')
old_home, new_home = root / 'old-home', root / 'new-home'
old_workspace, new_workspace = root / 'old-workspace', root / 'new-workspace'
for directory in (old_home, new_home, old_workspace, new_workspace):
    directory.mkdir()
sentinel = root / 'review-was-executed'
base_env = dict(os.environ, AGENT_SKILLS_PLATFORM='linux',
                AI_RECOVERY_EXECUTION_SENTINEL=str(sentinel))
base_env.pop('CLINE_DATA_DIR', None)


def write(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding='utf-8')


def cli(home, *arguments, success=True):
    result = subprocess.run([sys.executable, str(script), *map(str, arguments)],
                            env=dict(base_env, HOME=str(home)),
                            text=True, capture_output=True)
    try:
        output = json.loads(result.stdout)
    except json.JSONDecodeError:
        raise AssertionError(f'CLI did not emit JSON: {arguments}\n{result.stdout}\n{result.stderr}')
    if success:
        assert result.returncode == 0 and output.get('ok'), (arguments, output, result.stderr)
    else:
        assert result.returncode != 0 and not output.get('ok'), (arguments, output)
    return output


def tree_state(directory):
    return {path.relative_to(directory).as_posix(): (
                'file', hashlib.sha256(path.read_bytes()).hexdigest()) if path.is_file()
            else ('directory', None) for path in directory.rglob('*')}


def rewrite_checksums(bundle):
    payload = {path.relative_to(bundle).as_posix(): hashlib.sha256(path.read_bytes()).hexdigest()
               for path in bundle.rglob('*') if path.is_file() and path.name != 'checksums.json'}
    (bundle / 'checksums.json').write_text(json.dumps(payload, indent=2) + '\n')


skill = '''---
name: recovery-fixture
description: Device recovery regression fixture.
metadata:
  version: "1"
---
# Fixture
Preserve this instruction across devices.
'''
write(old_home / '.cline/skills/recovery-fixture/SKILL.md', skill)
write(old_home / '.cline/agents/reviewer.md', 'Review the intended change before activation.\n')
write(old_home / '.cline/data/workflows/check.md', 'Run a small reviewed project check.\n')
write(old_home / '.cline/hooks/on-start.sh', '#!/bin/sh\ntouch "$AI_RECOVERY_EXECUTION_SENTINEL"\n')
write(old_workspace / '.cline/skills/project-only/SKILL.md', skill.replace('recovery-fixture', 'project-only'))
write(old_workspace / '.cline/agents/project-only.md', 'PROJECT_SCOPE_MUST_STAY_OUT\n')
write(old_home / '.claude/skills/unrelated-profile/SKILL.md', skill.replace('recovery-fixture', 'unrelated-profile'))
write(new_workspace / 'keep.txt', 'Destination workspace content must survive.\n')

bundle = root / 'device.acb'
snapshot = cli(old_home, 'snapshot', '--workspace', old_workspace,
               '--source', 'cline/ide', '--target', 'cline/ide', '--scope', 'user',
               '--include-review-materials', '--output', bundle, '--json')
assert snapshot['complete_environment'] is False
assert Path(snapshot['next_agent']).is_file() and Path(snapshot['recovery_report']).is_file()
cli(old_home, 'bundle-verify', bundle, '--json')
checksums = json.loads((bundle / 'checksums.json').read_text())
assert {'recovery.json', 'NEXT-AGENT.md'} <= checksums.keys()
for name in ('recovery.json', 'NEXT-AGENT.md'):
    assert checksums[name] == hashlib.sha256((bundle / name).read_bytes()).hexdigest()
report = json.loads((bundle / 'recovery.json').read_text())
assert report['scope']['profiles'] == ['cline/ide']
assert report['scope']['scopes'] == ['user']
assert report['scope']['review_materials_requested'] is True
assert all(item['product'] == 'cline' and item['profile'] == 'ide' and item['scope'] == 'user'
           for item in report['coverage'])
inventory = json.loads((bundle / 'inventory.json').read_text())
inventory_rows = inventory.get('surfaces', inventory.get('items', inventory.get('rows', [])))
assert inventory_rows, inventory
assert all(item['product'] == 'cline' and item['profile'] == 'ide' and item['scope'] == 'user'
           for item in inventory_rows)
manifest = json.loads((bundle / 'manifest.json').read_text())
review_objects = [item for item in manifest['objects'] if item['surface'] == 'review']
assert len(review_objects) == 1, review_objects
review_files = {item['path'] for item in review_objects[0]['files']}
assert len(review_files) == 3, review_files
all_bindings = [item['path'] for obj in manifest['objects'] for item in obj.get('files', [])]
assert all(all_bindings.count(path) == 1 for path in review_files)
assert review_files == {path.relative_to(bundle).as_posix()
                        for path in (bundle / 'objects/review').rglob('*') if path.is_file()}
captured_tasks = [task for task in report['review_materials'] if task.get('payload_path')]
assert len(captured_tasks) == 3
assert all(any(path.startswith(task['payload_path'] + '/') for path in review_files)
           for task in captured_tasks)
assert all(task['automatic_restore'] is False and task['next_action'] for task in captured_tasks)
report_text = (bundle / 'recovery.json').read_text()
assert str(old_home) not in report_text
assert report['source_workspace']['source_path'] == str(old_workspace)
assert 'PROJECT_SCOPE_MUST_STAY_OUT' not in ''.join(
    path.read_text() for path in (bundle / 'objects').rglob('*') if path.is_file())
assert not any('unrelated-profile' in path for path in all_bindings)
doctor = cli(old_home, 'doctor', bundle, '--json')
assert doctor['recovery']['bundle_id'] == report['bundle_id']
assert doctor['recovery']['tasks']
assert not sentinel.exists()
print('OK CLI snapshot: selected profile/scope, checksummed handoff, unique inert review bindings and doctor report')

before_manual = tree_state(old_home / '.cline/agents')
overlap = subprocess.run(
    [sys.executable, str(script), 'snapshot', '--workspace', str(old_workspace),
     '--source', 'cline/ide', '--target', 'cline/ide', '--scope', 'user',
     '--include-review-materials', '--output', str(old_home / '.cline/agents'), '--json'],
    env=dict(base_env, HOME=str(old_home)), capture_output=True, text=True,
)
assert overlap.returncode != 0 and 'overlaps' in overlap.stderr
assert tree_state(old_home / '.cline/agents') == before_manual
print('OK bundle outputs cannot replace an existing manual review surface')

# Existing callers keep their previous payload boundary, but receive an
# explicit checklist of uncovered surfaces rather than a complete-backup claim.
old_mode = root / 'without-review.acb'
cli(old_home, 'snapshot', '--workspace', old_workspace,
    '--source', 'cline/ide', '--target', 'cline/ide', '--scope', 'user',
    '--output', old_mode, '--json')
assert not (old_mode / 'objects/review').exists()
old_report = json.loads((old_mode / 'recovery.json').read_text())
assert old_report['scope']['review_materials_requested'] is False
assert any(item['exists'] and item['object_type'] == 'hooks'
           and item['capture_status'] != 'payload-saved' for item in old_report['coverage'])
assert old_report['tasks']
print('OK default snapshot does not broaden capture and explicitly records omissions')

# A review-only bundle has useful handoff data but cannot silently count as an
# applied migration when no automatic writer has an eligible object.
review_home = root / 'review-only-home'
write(review_home / '.cline/agents/review-only.md', 'Manual review only.\n')
review_bundle = root / 'review-only.acb'
cli(review_home, 'snapshot', '--workspace', old_workspace,
    '--source', 'cline/ide', '--target', 'cline/ide', '--scope', 'user',
    '--include-review-materials', '--output', review_bundle, '--json')
noop = cli(new_home, 'restore', review_bundle, '--workspace', new_workspace,
           '--source', 'cline/ide', '--target', 'cline/ide', '--scope', 'user', '--yes', '--json', success=False)
assert 'no eligible items' in noop.get('error', ''), noop
assert not sentinel.exists()
print('OK review-only restore refuses a silent no-op')

# Restore sources must survive both moving the bundle and removing every
# original source file. The two restore invocations are separate processes.
moved = root / 'transferred' / 'device.acb'
moved.parent.mkdir()
shutil.move(str(bundle), str(moved))
shutil.rmtree(old_home)
shutil.rmtree(old_workspace)
assert not old_home.exists() and not old_workspace.exists()
before_home = tree_state(new_home)
before_workspace = tree_state(new_workspace)
before_bundle = tree_state(moved)
plan = root / 'reviewed-plan.json'
preview = cli(new_home, 'restore', moved, '--workspace', new_workspace,
              '--source', 'cline/ide', '--target', 'cline/ide', '--scope', 'user',
              '--plan-only', '--plan-out', plan, '--json')
assert plan.is_file() and preview['stage'] == 'plan'
assert tree_state(new_home) == before_home
assert tree_state(new_workspace) == before_workspace
assert tree_state(moved) == before_bundle
dry_plan, dry_manifest, dry_extract = root / 'dry-plan.json', root / 'dry-manifest.json', root / 'dry-extract'
dry = cli(new_home, 'restore', moved, '--workspace', new_workspace,
          '--source', 'cline/ide', '--target', 'cline/ide', '--scope', 'user',
          '--plan-only', '--dry-run', '--plan-out', dry_plan,
          '--manifest-out', dry_manifest, '--restore-root', dry_extract, '--json')
assert dry['dry_run'] is True
assert not dry_plan.exists() and not dry_manifest.exists() and not dry_extract.exists()
assert tree_state(new_home) == before_home
assert tree_state(new_workspace) == before_workspace
assert tree_state(moved) == before_bundle
assert not sentinel.exists()
print('OK transferred bundle plans without original device; plan-only and dry-run preserve destination and bundle')

applied = cli(new_home, 'restore', moved, '--workspace', new_workspace,
              '--plan-in', plan, '--yes', '--manifest-out', root / 'applied.json', '--json')
cli(new_home, 'verify', '--manifest', applied['manifest'], '--json')
assert (new_home / '.cline/skills/recovery-fixture/SKILL.md').read_text() == skill
assert (new_workspace / 'keep.txt').read_text() == 'Destination workspace content must survive.\n'
assert not any((new_home / '.cline' / folder).exists() for folder in ('agents', 'hooks', 'data/workflows'))
assert not sentinel.exists()
assert applied['remaining_work']
assert applied['acceptance_layers'] == {
    'bundle_integrity': 'passed', 'configuration_write': 'verified',
    'native_discovery': 'not-run', 'runtime_and_connectivity': 'not-run',
}
assert tree_state(moved) == before_bundle
print('OK saved-plan restore and verify recover Skill bytes; review material stays inert and runtime checks remain pending')

# Integrity hashes alone cannot legalize credentials added to handoff reports.
for filename in ('recovery.json', 'NEXT-AGENT.md'):
    tampered = root / ('tampered-' + filename.replace('.', '-') + '.acb')
    shutil.copytree(moved, tampered)
    target = tampered / filename
    if filename.endswith('.json'):
        payload = json.loads(target.read_text())
        payload['operator_note'] = 'password=synthetic-device-recovery-fixture'
        target.write_text(json.dumps(payload) + '\n')
    else:
        target.write_text(target.read_text() + '\npassword=synthetic-device-recovery-fixture\n')
    rewrite_checksums(tampered)
    rejected = cli(new_home, 'bundle-verify', tampered, '--json', success=False)
    assert any('secret' in error.lower() or 'credential' in error.lower()
               for error in rejected['errors']), rejected
print('OK recomputed checksums cannot bypass secret scanning in either handoff report')

legacy = root / 'legacy.acb'
shutil.copytree(moved, legacy)
for filename in ('recovery.json', 'NEXT-AGENT.md'):
    (legacy / filename).unlink()
rewrite_checksums(legacy)
legacy_doctor = cli(new_home, 'doctor', legacy, '--json')
assert legacy_doctor['recovery']['stage'] == 'legacy-bundle'
assert legacy_doctor['recovery']['complete_environment'] is False
assert legacy_doctor['recovery']['tasks']
print('OK older ACB directories without recovery reports remain readable with an explicit legacy checklist')
PY
