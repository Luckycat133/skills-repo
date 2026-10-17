#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REVIEW_FIXTURE_DIR="$(mktemp -d)"
trap 'rm -rf "$REVIEW_FIXTURE_DIR"' EXIT
if command -v cygpath >/dev/null 2>&1; then
    REVIEW_FIXTURE_DIR="$(cygpath -w "$REVIEW_FIXTURE_DIR")"
    SCRIPT_DIR="$(cygpath -w "$SCRIPT_DIR")"
fi
export REVIEW_FIXTURE_DIR
export HOME="$REVIEW_FIXTURE_DIR"
export PYTHONPATH="$SCRIPT_DIR${PYTHONPATH:+:$PYTHONPATH}"

python3 - <<'PY'
import json
import os
from pathlib import Path
from unittest.mock import patch

from acb import bundle
from acb.review import collect_review_materials

root = Path(os.environ['REVIEW_FIXTURE_DIR']).resolve()


def row(source, object_type='command', **overrides):
    result = {
        'product': 'fixture', 'profile': 'ide', 'scope': 'user',
        'object_type': object_type, 'storage': 'directory' if source.is_dir() else 'file',
        'canonical_path': '~/.fixture/' + source.relative_to(root).as_posix(),
        'path': '~/.fixture/' + source.relative_to(root).as_posix(),
        'resolved_path': str(source), 'boundary': str(root),
        'policy': 'manual-rebuild', 'exists': source.exists(),
    }
    result.update(overrides)
    return result


def capture(rows):
    return collect_review_materials(rows, selected_profiles={'fixture/ide'}, scopes={'user'})


commands = root / 'commands'
commands.mkdir()
(commands / 'clean.md').write_text('Explain the current change.\n')
(commands / 'bad.md').write_text('password=synthetic-review-fixture-value\n')
(commands / '.env').write_text('Nothing secret, but filename is excluded.\n')
(commands / 'credentials.json').write_text('{}\n')
(commands / 'image.png').write_bytes(b'\x89PNG\x00binary')
symlinks = True
try:
    (commands / 'alias.md').symlink_to(commands / 'clean.md')
    (root / 'missing-alias').symlink_to(root / 'missing-target')
except (OSError, NotImplementedError):
    symlinks = False

hooks = root / 'hooks.json'
hooks.write_text('{"hooks": [{"command": "echo review-only"}]}\n')
same_a = root / 'a' / 'commands'
same_b = root / 'b' / 'commands'
for directory in (same_a, same_b):
    directory.mkdir(parents=True)
    (directory / 'different.md').write_text(directory.parent.name + '\n')

objects, manifests, mapping, tasks = capture([
    row(commands), row(hooks, 'hook', policy='disabled-draft-only'),
    row(same_a), row(same_b),
])
assert len(objects) == 4, objects
assert len(manifests) == 1, manifests
assert manifests[0]['surface'] == 'review'
assert manifests[0]['status'] == 'manual-rebuild'
assert set(mapping['review/fixture/ide/user']) == set(objects)
assert len(mapping['review/fixture/ide/user']) == len(objects)
enriched = bundle.enrich_manifest_object(manifests[0], objects, object_file_map=mapping)
assert len(enriched['files']) == 4
assert enriched['object_path'] == 'review/fixture/ide/user'
assert all(task['status'] == 'manual-rebuild' for task in tasks)
assert all(task['automatic_restore'] is False for task in tasks)
reasons = {task['reason'] for task in tasks}
assert {'secret-not-captured', 'sensitive-name-not-captured', 'binary-not-captured',
        'review-material-partially-captured', 'review-material-captured'} <= reasons
if symlinks:
    assert 'symlink-not-captured' in reasons
serialized = json.dumps([manifests, mapping, tasks])
assert str(root) not in serialized
assert 'synthetic-review-fixture-value' not in serialized
assert 'resolved_path' not in serialized
assert 'source' not in manifests[0]
print('OK standalone review capture, partial failures, grouped manifests and no execution source')

# Even registry compatibility aliases with the same canonical basename retain
# separate payloads; a duplicate inventory row does not duplicate the payload.
alias_rows = [
    row(same_a, canonical_path='~/.fixture/commands', path='~/.fixture/commands'),
    row(same_b, canonical_path='~/.fixture/commands', path='~/.fixture/commands'),
]
alias_objects, alias_manifest, alias_map, alias_tasks = capture([*alias_rows, alias_rows[0]])
assert len(alias_objects) == 2 and len(alias_manifest) == 1
assert len(alias_map['review/fixture/ide/user']) == 2
assert len(alias_tasks) == 2
assert {data.decode().strip() for data in alias_objects.values()} == {'a', 'b'}

excluded_rows = [
    row(hooks, 'hook', storage='config-subobject'),
    row(hooks, 'hook', storage='shared-config'),
    row(hooks, 'hook', policy='never-migrate'),
    row(hooks, 'hook', policy='forbidden-regenerate'),
    row(hooks, 'hook', policy='source-only'),
    row(hooks, 'hook', policy='cloud-rebuild'),
    row(hooks, 'hook', profile='other'),
    row(hooks, 'hook', scope='project'),
    row(hooks, 'mcp'),
    row(root / 'absent', 'prompt'),
]
if symlinks:
    excluded_rows.append(row(root / 'missing-alias', 'prompt'))
excluded_objects, excluded_manifests, excluded_map, excluded_tasks = capture(excluded_rows)
assert not excluded_objects and not excluded_manifests and not excluded_map
assert {task['reason'] for task in excluded_tasks} >= {
    'shared-or-unsupported-storage', 'excluded-by-policy', 'source-missing',
}
assert len(excluded_tasks) == 7 + int(symlinks), excluded_tasks
assert not any(task['profile'] == 'other' or task['scope'] == 'project' for task in excluded_tasks)
if symlinks:
    assert any(task['reason'] == 'symlink-not-captured' for task in excluded_tasks)
print('OK profile/scope allowlist, shared configurations and forbidden policies excluded; missing sources explicit')

plain = root / 'plain.md'
plain.write_text('small text\n')
for limit, value, expected in (
    ('MAX_FILE_SIZE', 2, 'file-size-limit'),
    ('MAX_TOTAL_SIZE', 2, 'total-size-limit'),
    ('MAX_BUNDLE_FILES', 0, 'file-count-limit'),
):
    with patch.object(bundle, limit, value):
        output, manifest, mapped, failed = capture([row(plain, 'agent')])
    assert not output and not manifest and not mapped, limit
    assert any(task['reason'] == expected for task in failed), (limit, failed)

deep = root / 'deep'
(deep / 'nested').mkdir(parents=True)
(deep / 'nested' / 'note.md').write_text('review\n')
with patch.object(bundle, 'MAX_DIR_DEPTH', 0):
    output, _, _, failed = capture([row(deep, 'workflow')])
assert not output and any(task['reason'] == 'directory-depth-limit' for task in failed)
with patch.object(bundle, 'MAX_DIR_DEPTH', 7):
    output, _, _, failed = capture([row(plain, 'agent'), row(deep, 'workflow')])
assert len(output) == 1 and all(len(Path(path).parts) <= 7 for path in output)
assert any(task['reason'] == 'directory-depth-limit' for task in failed)
with patch('acb.review.os.open', side_effect=PermissionError(str(root) + '/PRIVATE')):
    output, _, _, failed = capture([row(plain, 'agent')])
assert not output and any(task['reason'] == 'source-unreadable' for task in failed)
assert str(root) not in json.dumps(failed) and 'PRIVATE' not in json.dumps(failed)
print('OK file, total, count and depth limits; exceptions never copied into reports')

output, _, _, tasks = capture([row(plain, 'agent', canonical_path=str(plain))])
assert output
assert tasks[-1]['canonical_path'] == '<external-source>'
assert str(root) not in json.dumps(tasks)
if hasattr(os, 'mkfifo'):
    fifo = root / 'fifo'
    os.mkfifo(fifo)
    output, _, _, tasks = capture([row(fifo, 'prompt')])
    assert not output and tasks[-1]['reason'] == 'nonregular-file-not-captured'
if symlinks:
    alias = root / 'linked-parent'
    alias.symlink_to(commands, target_is_directory=True)
    output, _, _, tasks = capture([row(alias / 'clean.md', 'prompt')])
    assert not output and tasks[-1]['reason'] == 'symlink-not-captured'
print('OK absolute canonical paths removed, nonregular files and symlink ancestors refused')
PY
