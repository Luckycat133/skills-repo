#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEVICE_RESTORE_TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$DEVICE_RESTORE_TEST_ROOT"' EXIT
if command -v cygpath >/dev/null 2>&1; then
    DEVICE_RESTORE_TEST_ROOT="$(cygpath -w "$DEVICE_RESTORE_TEST_ROOT")"
    SCRIPT_DIR="$(cygpath -w "$SCRIPT_DIR")"
fi
export DEVICE_RESTORE_TEST_ROOT SCRIPT_DIR

python3 -B - <<'PY'
import copy
import hashlib
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

sys.dont_write_bytecode = True
root = Path(os.environ['DEVICE_RESTORE_TEST_ROOT']).resolve()
scripts = Path(os.environ['SCRIPT_DIR'])
helper = scripts / 'device-restore.py'
sys.path.insert(0, str(scripts))
from acb.bundle import ACBManifest, ACB_SCHEMA_VERSION, write_bundle

packet = root / 'packet 中文 with spaces'
runtime = packet / 'skill/scripts'
runtime.mkdir(parents=True)
shutil.copytree(scripts / 'acb', runtime / 'acb', ignore=shutil.ignore_patterns('__pycache__', '*.pyc'))
shutil.copy2(scripts / 'skill_secret_scanner.py', runtime / 'skill_secret_scanner.py')
(packet / 'skill/references').mkdir()
(packet / 'skill/references/registry-v2.json').write_text('{}\n')
fake = r'''import json, sys
from pathlib import Path
args = sys.argv[1:]
def option(name):
    return args[args.index(name) + 1]
if args[0] == "verify":
    output = Path(option("--manifest"))
    assert "--registry" not in args
    assert output.is_file()
elif "--plan-out" in args:
    output = Path(option("--plan-out"))
    assert not output.exists()
    output.write_text(json.dumps({"fixture_plan": True, "argv": args}))
else:
    assert "--plan-in" in args and "--yes" in args
    plan = Path(option("--plan-in"))
    assert json.loads(plan.read_text())["fixture_plan"] is True
    output = Path(option("--manifest-out"))
    output.write_text(json.dumps({"fixture_manifest": True}))
with (output.parent / "calls.jsonl").open("a") as stream:
    stream.write(json.dumps(args, ensure_ascii=False) + "\n")
print(json.dumps({"ok": True, "fixture_only": True, "argv": args}))
'''
(runtime / 'context-migrator.py').write_text(fake)
write_bundle(
    bundle_root=packet / 'bundles/same-id.acb',
    manifest=ACBManifest(schema_version=ACB_SCHEMA_VERSION, bundle_id='same-second-fixture',
                         created_at='2026-10-16T00:00:00Z', source_platform={},
                         inventory_summary={}, objects=[]),
    inventory_rows=[], compatibility={}, requirements={}, secrets_required=[], reauth=[], rebuild=[],
)


def recipe(identifier, kind='user-global'):
    scopes = ['project'] if kind == 'project' else ['user']
    common = ['<PYTHON>', '-B', '<MIGRATOR>', 'restore', '<BUNDLE>',
              '--source', 'fixture/cli', '--target', 'fixture/cli',
              '--workspace', '<WORKSPACE>', '--scope', ','.join(scopes), '--objects', 'skills']
    return {'id': identifier, 'kind': kind, 'bundle': 'bundles/same-id.acb',
            'registry': 'skill/references/registry-v2.json', 'source': 'fixture/cli',
            'target': 'fixture/cli', 'scopes': scopes, 'objects': ['skills'],
            'plan_only': [*common, '--plan-only', '--plan-out', '<STATE_DIR>/restore.plan.json', '--json'],
            'apply_saved': [*common, '--plan-in', '<STATE_DIR>/restore.plan.json',
                            '--manifest-out', '<STATE_DIR>/restore.manifest.json', '--yes', '--json'],
            'verify': ['<PYTHON>', '-B', '<MIGRATOR>', 'verify', '--manifest', '<STATE_DIR>/restore.manifest.json', '--json']}


index = {'schema_version': 1, 'source_path': '/unused-source-path',
         'recipes': [recipe('global-one'), recipe('global-two'), recipe('project-one', 'project')]}
(packet / 'device-index.json').write_text(json.dumps(index))


def hashes(directory):
    return {path.relative_to(directory).as_posix(): hashlib.sha256(path.read_bytes()).hexdigest()
            for path in directory.rglob('*') if path.is_file()}


def seal(directory):
    entries = hashes(directory)
    entries.pop('PACKET-SHA256.json', None)
    (directory / 'PACKET-SHA256.json').write_text(json.dumps(entries, sort_keys=True))


fixture_home = root / 'isolated-home'
fixture_home.mkdir()
environment = dict(os.environ, HOME=str(fixture_home), PYTHONDONTWRITEBYTECODE='1')


def invoke(action, *arguments, destination=packet, success=True):
    result = subprocess.run([sys.executable, '-B', str(helper), action, '--packet', str(destination),
                             *map(str, arguments)], env=environment, text=True, capture_output=True)
    assert 'Traceback' not in result.stderr, result.stderr
    output = json.loads(result.stdout)
    assert (result.returncode == 0) == success and output.get('ok') == success, output
    return output


seal(packet)
before = hashes(packet)
assert invoke('verify')['packet_integrity'] == 'verified'
assert len(invoke('list')['recipes']) == 3
assert hashes(fixture_home) == {}
assert not list(packet.rglob('__pycache__'))
assert hashes(packet) == before
print('OK verify/list: closed packet and real ACB integrity, no IDE discovery or packet/cache writes')

state = root / 'external state 中文'
invoke('plan', '--recipe', 'project-one', '--state-dir', state, success=False)
assert not state.exists()
invoke('plan', '--recipe', 'project-one', '--state-dir', state,
       '--workspace', root / 'missing-project', success=False)
invoke('plan', '--recipe', 'global-one', '--state-dir', packet / 'unsafe-state', success=False)
invoke('plan', '--recipe', 'global-one', '--state-dir', root, success=False)
invoke('plan', '--recipe', 'global-one', '--state-dir', 'relative-state', success=False)
invoke('apply', '--recipe', 'global-one', '--state-dir', state, '--yes', success=False)
print('OK project mapping is mandatory, state is absolute/external, and apply needs a saved plan')

planned = invoke('plan', '--recipe', 'global-one', '--state-dir', state)
plan_path = Path(planned['plan'])
plan_hash = hashlib.sha256(plan_path.read_bytes()).hexdigest()
invoke('plan', '--recipe', 'global-one', '--state-dir', state, success=False)
invoke('apply', '--recipe', 'global-one', '--state-dir', state, success=False)
applied = invoke('apply', '--recipe', 'global-one', '--state-dir', state, '--yes')
assert applied['configuration_apply']['output']['fixture_only'] is True
assert applied['manifest_verify']['ok'] is True
assert applied['runtime_and_connectivity'] == 'not-run'
assert hashlib.sha256(plan_path.read_bytes()).hexdigest() == plan_hash
calls = [json.loads(line) for line in (plan_path.parent / 'calls.jsonl').read_text().splitlines()]
assert len(calls) == 3 and calls[2][0] == 'verify'
assert all('--registry' in argv for argv in calls[:2]) and '--registry' not in calls[2]
assert calls[1][calls[1].index('--plan-in') + 1] == str(plan_path)
invoke('apply', '--recipe', 'global-one', '--state-dir', state, '--yes', success=False)
second = invoke('plan', '--recipe', 'global-two', '--state-dir', state)
assert Path(second['plan']).parent != plan_path.parent
print('OK plan/apply/verify use the saved plan, preserve it, refuse duplicate execution, and isolate recipe state')

workspace = root / '工作项目 $(touch SHOULD_NOT_EXIST) ; spaces'
workspace.mkdir()
project = invoke('plan', '--recipe', 'project-one', '--state-dir', state, '--workspace', workspace)
project_plan = Path(project['plan'])
argv = json.loads(project_plan.read_text())['argv']
assert argv[argv.index('--workspace') + 1] == str(workspace)
assert not (workspace / 'SHOULD_NOT_EXIST').exists() and not (root / 'SHOULD_NOT_EXIST').exists()
project_plan.write_text(project_plan.read_text() + '\n')
invoke('apply', '--recipe', 'project-one', '--state-dir', state, '--workspace', workspace, '--yes', success=False)
assert hashes(packet) == before
print('OK Chinese/spaced/shell-looking paths remain literal argv; changed plans are rejected; packet stays unchanged')


def damaged(name, change, reseal=True):
    target = root / name
    shutil.copytree(packet, target)
    change(target)
    if reseal:
        seal(target)
    return target


def change_recipe(target, mutate):
    document = copy.deepcopy(index)
    mutate(document['recipes'][0])
    (target / 'device-index.json').write_text(json.dumps(document))


# Captures may have no automatic restore recipe (empty/review-only content).
# Verify the union, including captures-only packets, while legacy indexes above
# remain valid without a captures key.
captured = damaged('with-captures', lambda path: None)
shutil.copytree(captured / 'bundles/same-id.acb', captured / 'bundles/review-only.acb')
capture_index = copy.deepcopy(index)
capture_index['captures'] = [
    {'id': 'automatic', 'bundle': 'bundles/same-id.acb'},
    {'id': 'review-only', 'bundle': 'bundles/review-only.acb'},
]
(captured / 'device-index.json').write_text(json.dumps(capture_index))
seal(captured)
verified = invoke('verify', destination=captured)
assert set(verified['bundle_errors']) == {'bundles/same-id.acb', 'bundles/review-only.acb'}
capture_index['recipes'] = []
(captured / 'device-index.json').write_text(json.dumps(capture_index))
seal(captured)
assert set(invoke('verify', destination=captured)['bundle_errors']) == {
    'bundles/same-id.acb', 'bundles/review-only.acb'}
(captured / 'bundles/review-only.acb/manifest.json').write_text('{}\n')
seal(captured)
rejected = invoke('verify', destination=captured, success=False)
assert rejected['bundle_errors']['bundles/review-only.acb']
for ordinal, value in enumerate((None, {}, [None], [{}],
                                [{'bundle': '../outside.acb'}],
                                [{'bundle': 'bundles/missing.acb'}])):
    def malformed_capture(path, value=value):
        document = copy.deepcopy(index)
        document['captures'] = value
        (path / 'device-index.json').write_text(json.dumps(document))
    malformed = damaged('malformed-captures-' + str(ordinal), malformed_capture)
    invoke('verify', destination=malformed, success=False)
print('OK verify covers recipe/capture bundle union and captures-only packets; malformed/missing/traversing captures rejected')


for label, mutate in (
    ('cross-product', lambda row: row.update(target='different/cli')),
    ('argv-target', lambda row: row['plan_only'].__setitem__(row['plan_only'].index('--target') + 1, 'different/cli')),
    ('all-installed', lambda row: row['plan_only'].append('--all-installed')),
    ('traversal', lambda row: row.update(bundle='../outside.acb')),
    ('state-traversal', lambda row: row['plan_only'].__setitem__(row['plan_only'].index('--plan-out') + 1, '<STATE_DIR>/../escape.json')),
    ('payload-execution', lambda row: row['plan_only'].__setitem__(2, '<BUNDLE>/objects/run.py')),
):
    target = damaged(label, lambda path, mutate=mutate: change_recipe(path, mutate))
    invoke('list', destination=target, success=False)

unclaimed = damaged('unclaimed', lambda path: (path / 'unclaimed.txt').write_text('extra'), reseal=False)
invoke('verify', destination=unclaimed, success=False)
changed = damaged('changed', lambda path: (path / 'skill/references/registry-v2.json').write_text('{"changed":true}'), reseal=False)
invoke('verify', destination=changed, success=False)
try:
    linked = damaged('symlink', lambda path: (path / 'linked').symlink_to(path / 'device-index.json'), reseal=False)
except (OSError, NotImplementedError):
    print('SKIP symlink creation unavailable')
else:
    invoke('verify', destination=linked, success=False)
assert hashes(packet) == before and hashes(fixture_home) == {}
print('OK cross-product/template mismatches, traversal, arbitrary execution, unclaimed/tampered files and symlinks rejected')
print('Device packet helper tests passed (fake migrator validates orchestration only; native restoration is not exercised)')
PY
