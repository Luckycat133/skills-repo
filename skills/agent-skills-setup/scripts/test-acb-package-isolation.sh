#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_ISOLATION_ROOT="$(mktemp -d)"
trap 'rm -rf "$PACKAGE_ISOLATION_ROOT"' EXIT
if command -v cygpath >/dev/null 2>&1; then
    PACKAGE_ISOLATION_ROOT="$(cygpath -w "$PACKAGE_ISOLATION_ROOT")"
    SCRIPT_DIR="$(cygpath -w "$SCRIPT_DIR")"
fi
export PACKAGE_ISOLATION_ROOT SCRIPT_DIR

python3 - <<'PY'
import hashlib
import json
import os
import subprocess
import sys
from pathlib import Path

root = Path(os.environ['PACKAGE_ISOLATION_ROOT']).resolve()
script = Path(os.environ['SCRIPT_DIR']) / 'context-migrator.py'
home, workspace = root / 'home', root / 'workspace'
home.mkdir()
workspace.mkdir()
environment = dict(os.environ, HOME=str(home), AGENT_SKILLS_PLATFORM='linux',
                   PYTHONDONTWRITEBYTECODE='1')
registry = root / 'registry.json'


def write(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(data if isinstance(data, bytes) else data.encode('utf-8'))


def skill(path, name):
    data = f'---\nname: {name}\ndescription: Isolated package fixture.\n---\n# {name}\n'.encode()
    write(path / 'SKILL.md', data)
    return data


def product(name, path):
    return {'default_profile': 'cli', 'profiles': {'cli': {
        'migration_policy': 'bidirectional-reviewed',
        'detection': [{'type': 'file-signature', 'paths': [f'~/.{name}-installed']}],
        'surfaces': {'skills': [{'path': path, 'scope': 'user',
                                'storage': 'directory', 'format': 'agent-skill',
                                'policy': 'validate-then-atomic-copy'}]},
    }}}


def set_registry(products):
    registry.write_text(json.dumps({'schema_version': 2, 'products': products}), encoding='utf-8')


def cli(*arguments):
    result = subprocess.run([sys.executable, str(script), *map(str, arguments)],
                            env=environment, text=True, capture_output=True)
    assert literal not in result.stdout + result.stderr, 'CLI leaked rejected credential bytes'
    try:
        output = json.loads(result.stdout)
    except json.JSONDecodeError:
        raise AssertionError(('CLI JSON missing', arguments, result.returncode, result.stdout, result.stderr))
    return result.returncode, output


def snapshot(destination, *selection):
    return cli('snapshot', '--registry', registry, '--workspace', workspace,
               '--scope', 'user', '--objects', 'skills', '--output', destination,
               *selection, '--json')


def state(directory):
    result = {}
    for path in directory.rglob('*'):
        relative = path.relative_to(directory).as_posix()
        if path.is_symlink():
            result[relative] = ('symlink', os.readlink(path))
        elif path.is_file():
            result[relative] = ('file', hashlib.sha256(path.read_bytes()).hexdigest())
        else:
            result[relative] = ('directory', None)
    return result


literal = 'synthetic-package-isolation-fixture-value'
source = home / '.isolation-a/skills'
good_bytes = skill(source / 'good', 'good')
helper_bytes = b'#!/bin/sh\nprintf "portable fixture\\n"\n'
write(source / 'good/scripts/check.sh', helper_bytes)
try:
    (source / 'good/linked-reference.md').symlink_to(source / 'good/scripts/check.sh')
except (OSError, NotImplementedError):
    good_link_available = False
else:
    good_link_available = True
skill(source / 'bad', 'bad')
write(source / 'bad/docs/provider.md', 'password=' + literal + '\n')
skill(source / 'binarybad', 'binarybad')
write(source / 'binarybad/assets/helper.bin', b'\x00\x01\x02not-a-portable-text-asset')
write(source / 'conflict/SKILL.md', '---\nname: conflict\n'
      + '<' * 7 + ' HEAD\ndescription: First unresolved description.\n'
      + '=' * 7 + '\ndescription: Second unresolved description.\n'
      + '>' * 7 + ' fixture\n---\n# Conflict fixture\n')
write(source / 'conflict/references/keep-with-package.md', 'Exclude this sibling with the invalid metadata package.\n')
write(source / 'invalid-name/SKILL.md', '---\nname: Invalid_Name\ndescription: Invalid name fixture.\n---\n')
write(source / 'missing-description/SKILL.md', '---\nname: missing-description\n---\n')
multiline_bytes = b'''---
name: multiline
description: >-
  A valid multiline description
  remains portable and unchanged.
metadata:
  source: fixture
---
# Multiline fixture
'''
write(source / 'multiline/SKILL.md', multiline_bytes)
other_bytes = skill(home / '.isolation-b/skills/independent', 'independent')
single_bytes = skill(home / '.single-root', 'single-root')
single_reference = b'Keep the single-root reference layout.\n'
write(home / '.single-root/references/guide.md', single_reference)
for name in ('isolation-a', 'isolation-b'):
    write(home / f'.{name}-installed', 'Fixture installation proof.\n')
set_registry({
    'isolation-a': product('isolation-a', '~/.isolation-a/skills'),
    'isolation-b': product('isolation-b', '~/.isolation-b/skills'),
})
before = state(home)
bundle = root / 'packages.acb'
code, output = snapshot(bundle, '--all-installed')
assert code == 0 and output.get('ok'), output
assert state(home) == before, ('Snapshot changed original HOME bytes or links',
                              sorted(set(state(home)) ^ set(before)))
manifest = json.loads((bundle / 'manifest.json').read_text())
payloads = {row['path']: (bundle / row['path']).read_bytes()
            for obj in manifest['objects'] for row in obj.get('files', [])}
good_path = 'objects/skills/isolation-a/cli/user/home/.isolation-a/skills/good'
other_path = 'objects/skills/isolation-b/cli/user/home/.isolation-b/skills/independent'
assert good_path + '/SKILL.md' in payloads, sorted(payloads)
assert payloads[good_path + '/SKILL.md'] == good_bytes
assert payloads[good_path + '/scripts/check.sh'] == helper_bytes
assert payloads[other_path + '/SKILL.md'] == other_bytes
assert payloads['objects/skills/isolation-a/cli/user/home/.isolation-a/skills/multiline/SKILL.md'] == multiline_bytes
rejected_names = {'bad', 'binarybad', 'linked', 'conflict', 'invalid-name', 'missing-description'}
assert not any(any('/' + name + '/' in path for name in rejected_names) for path in payloads)
assert not any(path.name in rejected_names for path in (bundle / 'objects').rglob('*'))
report = json.loads((bundle / 'recovery.json').read_text())
details = report['collection_exclusions']
for name in ('bad', 'binarybad'):
    assert any(item.get('reason') == 'skill-package-rejected'
               and item.get('relative_path', '').endswith('/' + name)
               and item.get('next_action') for item in details), (name, details)
for name in ('conflict', 'invalid-name', 'missing-description'):
    assert any(item.get('reason') == 'skill-metadata-rejected'
               and item.get('relative_path', '').endswith('/' + name)
               and 'Source bytes were preserved' in item.get('next_action', '')
               and 'inert copy' in item.get('next_action', '') for item in details), (name, details)
assert output['collection_summary']['metadata_rejected'] == 3, output
if good_link_available:
    assert good_path + '/linked-reference.md' not in payloads
    assert any(item.get('reason') == 'symlink-not-followed'
               and item.get('relative_path', '').endswith('/good/linked-reference.md')
               for item in details), details
assert any(item['product'] == 'isolation-b' and item['capture_status'] == 'payload-saved'
           for item in report['coverage']), report['coverage']
assert literal.encode() not in b''.join(path.read_bytes() for path in bundle.rglob('*') if path.is_file())
code, verified = cli('bundle-verify', bundle, '--json')
assert code == 0 and verified.get('ok'), verified
print('OK bad packages excluded atomically with actionable reasons; clean packages/profiles and original HOME preserved')
print('OK conflicted/invalid metadata packages excluded as units; valid multiline metadata preserves exact bytes')

# A registered source may be one Skill root rather than a parent skills directory.
set_registry({'single': product('single', '~/.single-root')})
single_bundle = root / 'single.acb'
code, output = snapshot(single_bundle, '--source', 'single/cli', '--target', 'single/cli')
assert code == 0 and output.get('ok'), output
prefix = single_bundle / 'objects/skills/single/cli/user/home/.single-root'
assert (prefix / 'SKILL.md').read_bytes() == single_bytes
assert (prefix / 'references/guide.md').read_bytes() == single_reference
assert not (prefix / '.single-root').exists(), 'Single Skill root was nested twice'
assert state(home) == before
code, verified = cli('bundle-verify', single_bundle, '--json')
assert code == 0 and verified.get('ok'), verified
print('OK single-Skill root keeps its exact package layout')

# A capture with no safe package must either save a valid omission-only bundle
# or fail clearly; it must never claim a verified ready object with no files.
set_registry({'allbad': product('allbad', '~/.allbad/skills')})
skill(home / '.allbad/skills/bad', 'allbad')
write(home / '.allbad/skills/bad/docs/provider.md', 'password=' + literal + '\n')
before_allbad = state(home)
allbad_bundle = root / 'allbad.acb'
code, output = snapshot(allbad_bundle, '--source', 'allbad/cli', '--target', 'allbad/cli')
assert state(home) == before_allbad
if code == 0:
    assert output.get('ok'), output
    verify_code, verified = cli('bundle-verify', allbad_bundle, '--json')
    assert verify_code == 0 and verified.get('ok'), verified
    allbad_report = json.loads((allbad_bundle / 'recovery.json').read_text())
    assert any(item.get('reason') == 'skill-package-rejected'
               for item in allbad_report['collection_exclusions']), allbad_report
    assert not any(path.is_file() for path in (allbad_bundle / 'objects').rglob('*'))
    print('OK all-rejected package capture produces a valid explicit omission-only bundle')
else:
    assert not output.get('ok'), output
    assert 'no files' in json.dumps(output).lower(), output
    print('OBSERVED all-rejected package capture currently fails on ready manifest objects without files')

# A linked package must become an explicit omission without dropping safe
# siblings in the same selected profile.
set_registry({'linked': product('linked', '~/.linked/skills')})
linked_bytes = skill(home / '.linked/skills/good', 'linked-good')
try:
    (home / '.linked/skills/alias').symlink_to(home / '.linked/skills/good', target_is_directory=True)
except (OSError, NotImplementedError):
    print('SKIP directory symlink creation is unavailable on this platform')
else:
    before_linked = state(home)
    linked_bundle = root / 'linked.acb'
    code, output = snapshot(linked_bundle, '--source', 'linked/cli', '--target', 'linked/cli')
    assert code == 0 and output.get('ok'), output
    assert state(home) == before_linked
    prefix = linked_bundle / 'objects/skills/linked/cli/user/home/.linked/skills'
    assert (prefix / 'good/SKILL.md').read_bytes() == linked_bytes
    assert not (prefix / 'alias').exists()
    linked_report = json.loads((linked_bundle / 'recovery.json').read_text())
    assert any(task.get('reason') == 'symlink-not-followed'
               and task.get('relative_path', '').endswith('/alias')
               and task.get('next_action') for task in linked_report['tasks']), linked_report
    code, verified = cli('bundle-verify', linked_bundle, '--json')
    assert code == 0 and verified.get('ok'), verified
    print('OK linked package gets a task while safe sibling and source HOME remain intact')
PY
