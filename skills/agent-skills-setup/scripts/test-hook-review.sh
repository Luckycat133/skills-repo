#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK_REVIEW_TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$HOOK_REVIEW_TEST_ROOT"' EXIT
export SCRIPT_DIR HOOK_REVIEW_TEST_ROOT
"${HOOK_REVIEW_PYTHON:-python3}" -B - <<'PY'
import hashlib
import json
import os
import sys
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, os.environ['SCRIPT_DIR'])
from acb.hook_review import collect_hook_review

root = Path(os.environ['HOOK_REVIEW_TEST_ROOT']).resolve()
scripts = root / 'scripts'
scripts.mkdir()
marker = root / 'must-not-run'
good = scripts / 'safe script.py'
good.write_text("from pathlib import Path\nPath(" + repr(str(marker)) + ").touch()\n")
good.chmod(0o751)
secret = scripts / 'private.sh'
secret.write_text('export API_KEY="synthetic-hook-sensitive-literal"\n')
missing = scripts / 'missing.py'
binary = scripts / 'native'
binary.write_bytes(b'\xcf\xfa\xed\xfe\0native')
link = scripts / 'linked.py'
link.symlink_to(good)
broken = scripts / 'broken.py'
broken.symlink_to(missing)
external = root / 'external.py'
external.write_text('print("external")\n')
source = root / 'settings.json'
source.write_text(json.dumps({
    'apiKey': 'synthetic-unselected-sibling-literal',
    'hooks': {
        'state': {'trusted_hash': 'source-machine-only-hash'},
        'trust': {'anything': 'machine trust'},
        'approval_policy': 'source policy',
        'permission_mode': 'source mode',
        'auth_status': 'source account status',
        'PermissionRequest': [{'command': 'echo review-required'}],
        'SessionStart': [{'hooks': [{'type': 'command', 'command': 'python3 ' + repr(str(good))}]}],
        'Stop': [{'command': ['python3', str(secret), str(missing), str(binary), str(link),
                              str(broken), str(external), '${HOME}/dynamic.sh']}],
    },
    'notify': ['/Applications/Example.app/Contents/MacOS/notifier'],
}))
baseline = {str(p): hashlib.sha256(p.read_bytes()).hexdigest()
            for p in (source, good, secret, binary, external)}
files, tasks = collect_hook_review(source, {'format': 'json', 'fields': ['hooks', 'notify'],
                                            'dependency_roots': [str(scripts)]})
report = json.loads(files['hooks-review.json'])
assert report['activation'] == 'pending-native-review' and report['review_only'] is True
hooks = report['fields'][0]['value']
assert set(hooks) == {'SessionStart', 'Stop', 'PermissionRequest'}, hooks
assert 'synthetic-unselected-sibling-literal' not in str(files)
assert 'synthetic-hook-sensitive-literal' not in str(files)
assert 'source-machine-only-hash' not in str(files)
assert not marker.exists()
records = {row['source_path']: row for row in report['dependencies']}
assert records[str(good)]['status'] == 'captured-review-only'
assert records[str(good)]['reference'] == str(good)
assert records[str(good)]['mode'] == 0o751
assert files[records[str(good)]['payload_path']] == good.read_bytes()
assert records[str(secret)]['status'] == 'dependency-secret-or-nontext-rejected'
assert records[str(missing)]['status'] == 'dependency-not-present'
assert records[str(binary)]['status'] == 'external-native-binary-not-captured'
assert records[str(link)]['status'] == 'dependency-symlink-not-captured'
assert records[str(broken)]['status'] == 'dependency-symlink-not-captured'
assert records[str(external)]['status'] == 'dependency-outside-explicit-roots'
assert records['/Applications/Example.app/Contents/MacOS/notifier']['status'] == 'external-native-binary-not-captured'
assert any(row['reason'] == 'hook-dynamic-reference-needs-review' for row in tasks)
assert baseline == {str(p): hashlib.sha256(p.read_bytes()).hexdigest()
                    for p in (source, good, secret, binary, external)}
files, tasks = collect_hook_review(source, {'format': 'json', 'fields': ['hooks']})
assert not any(name.startswith('dependencies/') for name in files)
assert any(row['reason'] == 'dependency-outside-explicit-roots' for row in tasks)
# One sensitive selected field is excluded as a whole, without affecting its sibling.
source.write_text(json.dumps({'hooks': {'Stop': [{'command': 'API_KEY="literal-fixture-credential" /bad.sh'}]},
                             'notify': ['native-notifier']}))
files, tasks = collect_hook_review(source, {'format': 'json', 'fields': ['hooks', 'notify']})
assert [row['path'] for row in json.loads(files['hooks-review.json'])['fields']] == [['notify']]
assert any(row['reason'] == 'hook-field-secret-rejected' for row in tasks)
assert b'literal-fixture-credential' not in b''.join(files.values())
# JSONC and argv paths containing spaces remain literal; no parser executes code.
source.write_text('// reviewed JSONC\n' + json.dumps({'notify': ['python3', str(good)]}))
files, tasks = collect_hook_review(source, {'format': 'jsonc', 'fields': ['notify'],
                                            'dependency_roots': [str(scripts)]})
assert any(row['source_path'] == str(good) and row['status'] == 'captured-review-only'
           for row in json.loads(files['hooks-review.json'])['dependencies'])
assert not marker.exists()
# Preserve the raw ~/ token as well as its expanded source identity so the
# restorer can bind exactly that occurrence to an explicit destination path.
from unittest.mock import patch
source.write_text(json.dumps({'notify': ['python3', '~/scripts/safe script.py']}))
with patch.dict(os.environ, {'HOME': str(root)}):
    files, tasks = collect_hook_review(source, {'format': 'json', 'fields': ['notify'],
                                                'dependency_roots': [str(scripts)]})
report = json.loads(files['hooks-review.json'])
assert report['dependencies'][0]['source_path'] == str(good)
assert report['dependencies'][0]['reference'] == '~/scripts/safe script.py'
assert report['dependencies'][0]['status'] == 'captured-review-only'
# Relative and nested command dependencies must remain explicit unresolved
# tasks, even if a similarly named file exists beside the source settings.
(root / 'hooks').mkdir()
(root / 'hooks' / 'missing.py').write_text('raise RuntimeError("must not execute")\n')
relative_commands = ['python3 hooks/missing.py', './local-hook', 'node notify.mjs',
                     'sh -c "python3 hooks/nested.py"', 'sh -c "./nested-local"',
                     'python3 --script=hooks/argument.py']
for command in relative_commands:
    source.write_text(json.dumps({'hooks': {'Stop': [{'command': command}]}}))
    files, tasks = collect_hook_review(source, {'format': 'json', 'fields': ['hooks'],
                                                'dependency_roots': [str(root)]})
    assert any(row['reason'] == 'hook-relative-reference-needs-review' for row in tasks), command
    assert json.loads(files['hooks-review.json'])['dependencies'] == []
    assert not any(name.startswith('dependencies/') for name in files)
for command in ['python3 $PROJECT_ROOT/hooks/notify.py', 'sh -c "node ${ROOT}/notify.js"']:
    source.write_text(json.dumps({'hooks': {'Stop': [{'command': command}]}}))
    files, tasks = collect_hook_review(source, {'format': 'json', 'fields': ['hooks']})
    assert any(row['reason'] == 'hook-dynamic-reference-needs-review' for row in tasks), command
source.write_text(json.dumps({'notify': ['native-notifier', '-send', 'hello', '-title', 'ready']}))
files, tasks = collect_hook_review(source, {'format': 'json', 'fields': ['notify']})
assert tasks == [] and json.loads(files['hooks-review.json'])['dependencies'] == []
for interpreter in ['python3', 'node', 'bash']:
    source.write_text(json.dumps({'notify': [interpreter]}))
    files, tasks = collect_hook_review(source, {'format': 'json', 'fields': ['notify']})
    assert tasks == [] and json.loads(files['hooks-review.json'])['dependencies'] == []
assert not marker.exists()
# Large/count/aggregate limits are deterministic and do not weaken field scanning.
large = scripts / 'large.py'
large.write_text('x' * 5000)
source.write_text(json.dumps({'notify': [str(large)]}))
with patch('acb.hook_review.MAX_FILE_SIZE', 4096):
    files, tasks = collect_hook_review(source, {'format': 'json', 'fields': ['notify'],
                                                'dependency_roots': [str(scripts)]})
    assert any(row['reason'] == 'dependency-file-too-large' for row in tasks)
source.write_text(json.dumps({'notify': [str(good)]}))
with patch('acb.hook_review.MAX_TOTAL_SIZE', 1):
    files, tasks = collect_hook_review(source, {'format': 'json', 'fields': ['notify'],
                                                'dependency_roots': [str(scripts)]})
    assert any(row['reason'] == 'dependency-total-size-limit' for row in tasks)
source.write_text(json.dumps({'notify': [str(scripts / ('missing-' + str(i) + '.py')) for i in range(130)]}))
files, tasks = collect_hook_review(source, {'format': 'json', 'fields': ['notify'],
                                            'dependency_roots': [str(scripts)]})
assert sum(row['reason'] == 'dependency-count-limit' for row in tasks) == 2
root_link = root / 'linked-root'
root_link.symlink_to(scripts, target_is_directory=True)
source.write_text(json.dumps({'notify': [str(good)]}))
files, tasks = collect_hook_review(source, {'format': 'json', 'fields': ['notify'],
                                            'dependency_roots': [str(root_link)]})
assert any(row['reason'] == 'invalid-hook-dependency-root' for row in tasks)
assert not any(name.startswith('dependencies/') for name in files)
# Bounded explicit selectors and stable errors never reveal parser source text.
for fields in ([], ['apiKey'], [['hooks']], ['hooks', 'hooks']):
    files, tasks = collect_hook_review(source, {'format': 'json', 'fields': fields})
    assert tasks[0]['reason'] == 'invalid-hook-review-fields'
source.write_text('{ private source syntax secret')
files, tasks = collect_hook_review(source, {'format': 'json', 'fields': ['hooks']})
assert tasks[0]['reason'] == 'hook-source-unreadable-or-invalid'
assert 'private source syntax' not in str(tasks)
source.unlink()
source.symlink_to(good)
files, tasks = collect_hook_review(source, {'format': 'json', 'fields': ['hooks']})
assert tasks[0]['reason'] == 'hook-source-not-regular-or-too-large'
source.unlink()
source.write_text('[hooks.state]\ntrusted_hash="source-machine-only-hash"\n[hooks.SessionStart]\ncommand="echo ready"\n')
try:
    import tomllib
except ModuleNotFoundError:
    files, tasks = collect_hook_review(source, {'format': 'toml', 'fields': ['hooks']})
    assert tasks[0]['reason'] == 'tomllib-unavailable'
else:
    files, tasks = collect_hook_review(source, {'format': 'toml', 'fields': ['hooks']})
    assert set(json.loads(files['hooks-review.json'])['fields'][0]['value']) == {'SessionStart'}
with patch('acb.hook_review._decode_preferences', side_effect=ModuleNotFoundError('private error')):
    files, tasks = collect_hook_review(source, {'format': 'toml', 'fields': ['hooks']})
    assert tasks[0]['reason'] == 'tomllib-unavailable' and 'private error' not in str(tasks)
print('OK inert hook field capture, dependency bounds, secret/trust exclusion, no source execution/writes, stable parser fallback')
PY
