#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REVIEW_RECOVERY_FIXTURE_ROOT="$(mktemp -d)"
trap 'rm -rf "$REVIEW_RECOVERY_FIXTURE_ROOT"' EXIT
export SCRIPT_DIR REVIEW_RECOVERY_FIXTURE_ROOT PYTHONDONTWRITEBYTECODE=1
"${REVIEW_RESTORE_PYTHON:-python3}" -B - <<'PY'
import importlib.util
import json
import os
import stat
import sys
from pathlib import Path

root = Path(os.environ['REVIEW_RECOVERY_FIXTURE_ROOT']).resolve()
home = root / 'home'
home.mkdir()
os.environ['HOME'] = str(home)
os.environ.pop('CODEX_HOME', None)
scripts = Path(os.environ['SCRIPT_DIR'])
sys.path.insert(0, str(scripts))
spec = importlib.util.spec_from_file_location('review_restore_recovery_fixture', scripts / 'review-restore.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
original_build = module.build_plan
original_write = module.private_write


def snapshot(paths):
    return {str(path): (path.read_bytes(), stat.S_IMODE(path.stat().st_mode)) if path.exists() else None for path in paths}


def transaction(name, *, new_first=False):
    directory = home / name
    directory.mkdir()
    first, second = directory / 'first.json', directory / 'second.json'
    if not new_first:
        first.write_bytes(b'{"fixture":"old-first","credential":"LOCAL_ONLY_FIXTURE"}\n')
        first.chmod(0o640)
    second.write_bytes(b'{"fixture":"old-second"}\n')
    second.chmod(0o600)
    before = snapshot([first, second])
    operations, outputs = [], {}
    for index, target in enumerate([first, second]):
        output = json.dumps({'fixture': 'applied-' + str(index)}).encode()
        mode = stat.S_IMODE(target.stat().st_mode) if target.exists() else 0o600
        operations.append({'client': 'fixture', 'source': str(index), 'kind': 'text',
                           'target': str(target), 'before': module.file_state(target),
                           'after_sha256': module.sha(output), 'mode': mode, 'status': 'ready'})
        outputs[str(target)] = output
    plan = {'schema_version': 1, 'packet_sha256': 'fixture', 'mapping_sha256': 'fixture',
            'roots': [str(home)], 'operations': operations, 'remaining_work': []}
    plan_path = root / (name + '.plan.json')
    plan_path.write_text(json.dumps(plan))
    module.build_plan = lambda packet, mapping: (plan, outputs)
    return first, second, before, plan_path, root / (name + '-state')


def apply(plan_path, state):
    return module.apply_plan(root / 'fixture-packet', root / 'fixture-mapping.json', plan_path, state)


for kind in ('corrupt', 'missing', 'symlink'):
    first, second, before, plan_path, state = transaction('backup-' + kind)
    apply(plan_path, state)
    assert stat.S_IMODE(state.stat().st_mode) == 0o700
    assert stat.S_IMODE((state / 'backups/0').stat().st_mode) == 0o600
    backup = state / 'backups/0'
    if kind == 'corrupt':
        backup.write_bytes(b'CORRUPTED_BACKUP_FIXTURE')
    elif kind == 'missing':
        backup.unlink()
    else:
        ordinary = root / 'same-hash-backup-fixture'
        ordinary.write_bytes(backup.read_bytes())
        backup.unlink()
        backup.symlink_to(ordinary)
    applied = snapshot([first, second])
    try:
        module.rollback(state)
    except (OSError, ValueError):
        pass
    else:
        raise AssertionError('unsafe backup was accepted: ' + kind)
    assert snapshot([first, second]) == applied, 'backup preflight wrote a target before rejecting ' + kind
print('OK rollback preflights every backup: damaged, missing and same-hash symlink backups cause zero target writes')

for drift in ('content', 'mode', 'symlink', 'new-file-content', 'none'):
    first, second, before, plan_path, state = transaction('failure-' + drift, new_first=drift == 'new-file-content')
    injected = [False]
    external = [None]

    def fail_second(path, data, **kwargs):
        if path == second and not injected[0]:
            injected[0] = True
            if drift in ('content', 'new-file-content'):
                first.write_bytes(b'{"fixture":"external-concurrent-edit"}\n')
            elif drift == 'mode':
                first.chmod(0o400)
            elif drift == 'symlink':
                external_file = root / 'external-link-fixture.json'
                external_file.write_bytes(b'{"fixture":"external-symlink-target"}\n')
                first.unlink()
                first.symlink_to(external_file)
            external[0] = snapshot([first, second])
            raise OSError('synthetic fixture write failure')
        return original_write(path, data, **kwargs)

    module.private_write = fail_second
    try:
        apply(plan_path, state)
    except (OSError, ValueError):
        pass
    else:
        raise AssertionError('injected failure was not reported')
    finally:
        module.private_write = original_write
    manifest = json.loads((state / 'manifest.json').read_text())
    if drift == 'none':
        assert snapshot([first, second]) == before, 'ordinary failed apply did not restore prior bytes and modes'
        assert manifest['status'] == 'failed-restored-previous-files'
    else:
        assert snapshot([first, second]) == external[0], 'automatic rollback clobbered a concurrent change: ' + drift
        assert manifest['status'] == 'failed-rollback-required'
print('OK automatic failure recovery preserves external byte/mode edits and new files, records required recovery, and restores unchanged outputs normally')
module.build_plan = original_build

# Metadata validity is independent of credential scanning and complete flags.
# This small packet isolates the real Skill planner from packet verification;
# the full packet/runtime checksum contract is covered by test-review-restore.sh.
packet = root / 'metadata-packet'
directory = packet / 'review/fixture/skills'
directory.mkdir(parents=True)
mapping = root / 'metadata-mapping.json'
mapping.write_text(json.dumps({'schema_version': 1, 'roots': [str(home)], 'entries': [
    {'client': 'fixture', 'source': 'skills', 'target': str(home / 'metadata-skills')}]}))
original_identity = module.packet_identity
module.packet_identity = lambda path: 'isolated-metadata-packet'
for label, body in {
    'duplicate-name': '---\nname: fixture\nname: conflict\ndescription: Conflicting metadata.\n---\nBody.\n',
    'missing-frontmatter': '# Missing frontmatter\nBody.\n',
    'invalid-name': '---\nname: INVALID NAME\ndescription: Invalid identity.\n---\nBody.\n',
    'empty-description': '---\nname: fixture\ndescription: ""\n---\nBody.\n',
}.items():
    data = body.encode()
    payload = directory / 'payload/SKILL.md'
    payload.parent.mkdir(exist_ok=True)
    payload.write_bytes(data)
    (directory / 'skill-packages.json').write_text(json.dumps({'entries': [{
        'name': 'fixture', 'complete': True, 'status': 'staged', 'omissions': [],
        'files': [{'path': 'SKILL.md', 'sha256': module.sha(data), 'mode': 0o600}]}]}))
    (packet / 'review/index.json').write_text(json.dumps({'clients': [{'id': 'fixture', 'sources': [{
        'id': 'skills', 'kind': 'skills', 'report': 'fixture/skills/report.json',
        'files': [{'path': 'fixture/skills/payload/SKILL.md', 'sha256': module.sha(data)}]}]}]}))
    try:
        invalid_plan, invalid_outputs = module.build_plan(packet, mapping)
    except ValueError:
        pass
    else:
        assert not invalid_outputs, 'invalid Skill metadata produced restore payload: ' + label
        assert invalid_plan['remaining_work'], 'invalid Skill metadata had no recovery task: ' + label
    assert not (home / 'metadata-skills').exists()
module.packet_identity = original_identity
print('OK duplicate, missing and invalid Skill metadata cannot be restored solely because capture was marked complete')

# Same-name MCP servers have destination-only authentication siblings. An
# explicit replacement may update the reviewed safe fields or reject a native
# transport conflict, but must not silently discard destination credentials.
module.packet_identity = lambda path: 'isolated-mcp-packet'
target = home / 'mcp-credential-sibling.json'
target.write_text(json.dumps({'mcpServers': {'fixture': {'command': 'fixture-cli', 'args': ['--old'],
    'env': {'API_KEY': 'TARGET_LOCAL_FIXTURE'}, 'headers': {'X-Auth': 'TARGET_LOCAL_FIXTURE'}}}}))
mcp_data = json.dumps({'server_name': 'fixture', 'definition': {'command': 'fixture-cli', 'args': ['--old'], 'timeout': 30},
    'required_credentials': [], 'omitted_fields': []}).encode()
source_file = directory / 'mcp-server.json'
source_file.write_bytes(mcp_data)
(packet / 'review/index.json').write_text(json.dumps({'clients': [{'id': 'fixture', 'sources': [{
    'id': 'mcp', 'kind': 'mcp', 'files': [{'path': 'fixture/skills/mcp-server.json', 'sha256': module.sha(mcp_data)}]}]}]}))
mapping.write_text(json.dumps({'schema_version': 1, 'roots': [str(home)], 'entries': [
    {'client': 'fixture', 'source': 'mcp', 'target': str(target), 'format': 'json',
     'container': 'mcpServers', 'conflict': 'replace'}]}))
original_target = target.read_bytes()
mcp_plan, mcp_outputs = module.build_plan(packet, mapping)
after = json.loads(mcp_outputs[str(target)])['mcpServers']['fixture']
assert after['env']['API_KEY'] == 'TARGET_LOCAL_FIXTURE'
assert after['headers']['X-Auth'] == 'TARGET_LOCAL_FIXTURE'
assert after['timeout'] == 30
assert target.read_bytes() == original_target
module.packet_identity = original_identity
print('OK same-identity MCP server updates preserve destination-only authentication fields')
for old, incoming in (
    ({'url': 'https://old-origin.invalid/mcp', 'headers': {'Authorization': 'TARGET_LOCAL_FIXTURE'}},
     {'url': 'https://new-origin.invalid/mcp'}),
    ({'command': 'old-fixture-cli', 'env': {'API_KEY': 'TARGET_LOCAL_FIXTURE'}},
     {'command': 'new-fixture-cli'}),
    ({'command': 'fixture-cli', 'args': ['--old'], 'env': {'API_KEY': 'TARGET_LOCAL_FIXTURE'}},
     {'command': 'fixture-cli', 'args': ['--new']}),
):
    document = {'mcpServers': {'fixture': old}}
    untouched = json.loads(json.dumps(document))
    try:
        module.merge_server(document, 'mcpServers', 'fixture', incoming, True)
    except ValueError:
        pass
    else:
        raise AssertionError('MCP identity changed while retaining destination credentials')
    assert document == untouched
print('OK existing MCP authentication is not silently rebound to a different endpoint, executable or argument list')
print('Review restore recovery tests passed')
PY
