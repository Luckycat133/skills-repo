#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREPARE_SKILL_TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$PREPARE_SKILL_TEST_ROOT"' EXIT
if command -v cygpath >/dev/null 2>&1; then
    PREPARE_SKILL_TEST_ROOT="$(cygpath -w "$PREPARE_SKILL_TEST_ROOT")"
    SCRIPT_DIR="$(cygpath -w "$SCRIPT_DIR")"
fi
export PREPARE_SKILL_TEST_ROOT SCRIPT_DIR

"${PREPARE_SKILL_PYTHON:-python3}" -B - <<'PY'
import hashlib
import json
import os
import stat
import subprocess
import sys
from pathlib import Path

root = Path(os.environ['PREPARE_SKILL_TEST_ROOT']).resolve()
helper = Path(os.environ['SCRIPT_DIR']) / 'prepare-skill-source.py'
home = root / 'isolated-home'
home.mkdir()
environment = dict(os.environ, HOME=str(home), PYTHONDONTWRITEBYTECODE='1')
source = root / 'source skills 中文'
external = root / 'reviewed external source'


def write(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(data if isinstance(data, bytes) else data.encode('utf-8'))


def skill(path, name):
    data = f'---\nname: {name}\ndescription: Staging fixture.\n---\n# {name}\n'.encode()
    write(path / 'SKILL.md', data)
    return data


def state(directory):
    entries = {}
    for path in directory.rglob('*'):
        relative = path.relative_to(directory).as_posix()
        mode = stat.S_IMODE(path.lstat().st_mode)
        if path.is_symlink():
            entries[relative] = ('link', os.readlink(path), mode)
        elif path.is_file():
            entries[relative] = ('file', hashlib.sha256(path.read_bytes()).hexdigest(), mode)
        else:
            entries[relative] = ('directory', None, mode)
    return entries


def run(output, report, *arguments, success=True, selected_source=source):
    result = subprocess.run([sys.executable, '-B', str(helper), '--source', str(selected_source),
                             '--output', str(output), '--report', str(report), *map(str, arguments)],
                            env=environment, text=True, capture_output=True)
    assert 'Traceback' not in result.stderr, result.stderr
    assert literal not in result.stdout + result.stderr, 'CLI leaked a rejected secret value'
    payload = json.loads(result.stdout)
    assert (result.returncode == 0) == success and payload.get('ok') == success, payload
    return payload


good = skill(source / 'good', 'good')
script_bytes = b'#!/bin/sh\nprintf "reviewed fixture\\n"\n'
write(source / 'good/scripts/check.sh', script_bytes)
(source / 'good/scripts/check.sh').chmod(0o755)
write(source / 'good/.env.local', 'STAGING_ENV_MUST_REMAIN_AT_SOURCE\n')
write(source / 'good/scripts/__pycache__/check.cpython-312.pyc', b'\x00\x01generated cache fixture')
skill(source / 'secret-package', 'secret-package')
literal = 'synthetic-prepare-skill-fixture-value'
write(source / 'secret-package/references/example.md', 'password=' + literal + '\n')
skill(source / 'key-package', 'key-package')
write(source / 'key-package/provider.pem', 'Rejected sensitive filename fixture.\n')
skill(source / 'binary-package', 'binary-package')
write(source / 'binary-package/helper.bin', b'\x00\x01unsafe binary fixture')
write(source / 'notes/README.md', 'Not a Skill package.\n')
external_bytes = skill(external / 'external-package', 'external-package')
write(external / 'external-package/references/guide.md', 'External approved reference.\n')

links_available = True
try:
    (source / 'linked-package').symlink_to(external / 'external-package', target_is_directory=True)
    skill(source / 'cycle-package', 'cycle-package')
    (source / 'cycle-package/loop').symlink_to(source / 'cycle-package', target_is_directory=True)
    (source / 'self-loop').symlink_to(source / 'self-loop', target_is_directory=True)
    skill(source / 'nested-self-loop', 'nested-self-loop')
    (source / 'nested-self-loop/loop').symlink_to(source / 'nested-self-loop/loop', target_is_directory=True)
except (OSError, NotImplementedError):
    links_available = False
    print('SKIP symlink-specific assertions: platform cannot create directory links')

source_before, external_before = state(source), state(external)
output, report = root / 'stage-unapproved', root / 'unapproved.json'
result = run(output, report)
assert result['packages_staged'] == 1, result
assert (output / 'good/SKILL.md').read_bytes() == good
assert (output / 'good/scripts/check.sh').read_bytes() == script_bytes
if os.name != 'nt':
    assert stat.S_IMODE((output / 'good/scripts/check.sh').stat().st_mode) == 0o755
assert not (output / 'good/.env.local').exists()
details = json.loads(report.read_text())
entries = {row['name']: row for row in details['entries']}
assert details['not_installed'] is True and details['source_unchanged'] == 'read-only-operation'
assert entries['good']['status'] == 'staged-partial'
assert entries['good']['omissions'] == [
    {'path': 'good/.env.local', 'reason': 'environment-file-excluded'},
    {'path': 'good/scripts/__pycache__', 'reason': 'generated-cache-excluded'},
]
assert not (output / 'good/scripts/__pycache__').exists()
for name in ('secret-package', 'key-package', 'binary-package'):
    assert entries[name]['status'] == 'excluded'
    assert entries[name]['reason'] == 'secret-or-unsafe-binary'
    assert entries[name]['files'] == [] and not (output / name).exists(), name
assert entries['notes']['status'] == 'excluded' and not (output / 'notes').exists()
if links_available:
    for name in ('linked-package', 'cycle-package'):
        assert entries[name]['status'] == 'excluded'
        assert entries[name]['reason'] == 'unreadable-unsafe-or-resource-limited'
        assert not (output / name).exists()
    assert entries['self-loop']['status'] == 'excluded'
    assert entries['self-loop']['reason'] == 'unresolvable-link'
    assert entries['self-loop']['link_target'] is None
    assert entries['self-loop']['files'] == [] and not (output / 'self-loop').exists()
    assert entries['nested-self-loop']['status'] == 'excluded'
    assert entries['nested-self-loop']['reason'] == 'unreadable-unsafe-or-resource-limited'
    assert entries['nested-self-loop']['files'] == [] and not (output / 'nested-self-loop').exists()
assert literal not in report.read_text()
assert state(source) == source_before and state(external) == external_before
print('OK staging preserves bytes/modes; secret, sensitive-name and binary packages excluded atomically; source unchanged')

if links_available:
    approved, approved_report = root / 'approved-stage', root / 'approved.json'
    result = run(approved, approved_report, '--allow-linked-root', external)
    assert result['packages_staged'] == 2, result
    assert (approved / 'linked-package/SKILL.md').read_bytes() == external_bytes
    assert not (approved / 'linked-package').is_symlink()
    assert not any(path.is_symlink() for path in approved.rglob('*'))
    approved_entries = {row['name']: row for row in json.loads(approved_report.read_text())['entries']}
    assert approved_entries['linked-package']['link_target'] == str(external / 'external-package')
    assert approved_entries['linked-package']['status'] == 'staged'
    assert approved_entries['cycle-package']['status'] == 'excluded'
    assert not (approved / 'cycle-package').exists()
    assert approved_entries['self-loop']['reason'] == 'unresolvable-link'
    assert approved_entries['nested-self-loop']['status'] == 'excluded'
    assert not (approved / 'self-loop').exists() and not (approved / 'nested-self-loop').exists()
    assert state(source) == source_before and state(external) == external_before
    print('OK reviewed links materialize; directory cycles and top-level/nested self-links retain explicit exclusions')

# A single Skill source keeps its internal layout without a second package name.
single = root / 'single-source'
single_bytes = skill(single, 'single-source')
write(single / 'references/guide.md', 'Single package reference.\n')
single_before = state(single)
single_output, single_report = root / 'single-stage', root / 'single.json'
run(single_output, single_report, selected_source=single)
assert (single_output / 'SKILL.md').read_bytes() == single_bytes
assert (single_output / 'references/guide.md').read_text() == 'Single package reference.\n'
assert not (single_output / 'single-source').exists()
assert state(single) == single_before
print('OK direct Skill root retains package-relative layout')

# Collision and overlap checks precede staging, preserving every existing tree.
saved_stage, saved_report = state(output), report.read_bytes()
run(output, root / 'collision-output.json', success=False)
assert not (root / 'collision-output.json').exists()
run(root / 'collision-report-stage', report, success=False)
assert not (root / 'collision-report-stage').exists()
same = root / 'same-output-and-report'
run(same, same, success=False)
assert not same.exists()
nested = root / 'nested-output'
run(nested, nested / 'report.json', success=False)
assert not nested.exists()
run(source / 'stage', root / 'source-overlap.json', success=False)
assert not (source / 'stage').exists() and not (root / 'source-overlap.json').exists()
run(root / 'external-overlap-stage', external / 'report.json', '--allow-linked-root', external, success=False)
assert not (root / 'external-overlap-stage').exists() and not (external / 'report.json').exists()
assert state(output) == saved_stage and report.read_bytes() == saved_report
assert state(source) == source_before and state(external) == external_before
print('OK existing outputs/reports and overlapping paths fail without replacement or source changes')

# The current entrypoint has no dry-run mode: unsupported flags must not be
# mistaken for successful planning or create staging/report artifacts.
dry_output, dry_report = root / 'dry-stage', root / 'dry.json'
dry = subprocess.run([sys.executable, '-B', str(helper), '--source', str(source),
                      '--output', str(dry_output), '--report', str(dry_report), '--dry-run'],
                     env=environment, text=True, capture_output=True)
assert dry.returncode != 0 and 'unrecognized arguments' in dry.stderr
assert not dry_output.exists() and not dry_report.exists()
assert state(source) == source_before and state(external) == external_before and state(home) == {}
print('OK unsupported dry-run fails before writes; staging never installs into source or HOME')

# sanitize-review is an explicit, inert-copy workflow. The strict assertions
# above remain unchanged; secrets must never silently alter the original tree.
review_source = root / 'review-source'
safe_body = skill(review_source / 'complete', 'complete')
write(review_source / 'complete/references/guide.md', 'Safe complete reference.\n')
skill(review_source / 'redacted', 'redacted')
redacted_original = ('# Preserve safe prose\npassword="' + literal + ' with spaces"\n'
    + 'token=wrapper(decode("literalCredential123456"))\n'
    + 'Authorization: Bearer opaqueCredentialValue0123456789\n'
    + 'postgres://olduser:oldcredentialvalue@host.invalid/db\n'
    + 'tail prose must survive\n').encode()
write(review_source / 'redacted/references/settings.md', redacted_original)
write(review_source / 'redacted/SOURCE.json', json.dumps({
    'source_url': 'https://origin.invalid/repository', 'revision': 'a1b2c3d4',
    'unknown_metadata': {'api_key': literal},
}))
skill(review_source / 'partial', 'partial')
write(review_source / 'partial/SKILL.md',
      '---\nname: partial\ndescription: Partial package fixture.\n---\n'
      'Read [unsafe binary](scripts/tool.bin), [lost](references/not-present.md) and [safe](references/safe.md).\n')
write(review_source / 'partial/references/safe.md', 'Keep this source body.\n')
write(review_source / 'partial/scripts/tool.bin', b'\x00\x01unsafe executable data')
write(review_source / 'partial/private.pem', b'-----BEGIN PRIVATE KEY-----\nprivate-material\n')
write(review_source / 'partial/.env', 'PASSWORD=' + literal + '\n')
write(review_source / 'partial/references/unclosed.md', 'password="' + literal)
write(review_source / 'partial/SOURCE.json', json.dumps({
    'source': {'url': 'https://origin.invalid/partial', 'revision': 'b2c3d4e5'},
    'private_extra': {'password': literal},
}))
skill(review_source / '@org/namespaced', 'namespaced')
write(review_source / '@org/namespaced/references/guide.md', 'Namespace content.\n')
repair_root = root / 'repair-root'
repair_two = root / 'repair-two'
skill(repair_root / '@org/recovered', 'recovered')
write(repair_root / '@org/recovered/SOURCE.json', json.dumps({
    'original_path': '/old/cache/@org/recovered', 'source_url': 'https://origin.invalid/recovered',
    'revision': 'c3d4e5f6',
}))
for repair in (repair_root, repair_two):
    skill(repair / '@org/ambiguous', 'ambiguous')
    write(repair / '@org/ambiguous/SOURCE.json', json.dumps({
        'source_path': '/old/cache/@org/ambiguous', 'revision': 'd4e5f6a7',
    }))
skill(repair_root / '@org/unproven', 'unproven')
write(repair_root / '@org/unproven/SOURCE.json', json.dumps({
    'source_url': 'https://origin.invalid/unproven', 'revision': 'e5f6a7b8',
}))
if links_available:
    (review_source / '@org/recovered').symlink_to('/old/cache/@org/recovered', target_is_directory=True)
    (review_source / '@org/ambiguous').symlink_to('/old/cache/@org/ambiguous', target_is_directory=True)
    (review_source / '@org/unproven').symlink_to('/old/cache/@org/unproven', target_is_directory=True)
    (review_source / 'loop').symlink_to(review_source, target_is_directory=True)
    # Matching provenance cannot authorize reading an entrypoint symlink.
    unsafe_origin = repair_root / '@org/linked-entrypoint'
    unsafe_origin.mkdir(parents=True)
    outside_entrypoint = root / 'outside-entrypoint.md'
    write(outside_entrypoint, '---\nname: linked-entrypoint\ndescription: Outside roots.\n---\n')
    (unsafe_origin / 'SKILL.md').symlink_to(outside_entrypoint)
    write(unsafe_origin / 'SOURCE.json', json.dumps({'original_path': '/old/cache/@org/linked-entrypoint'}))
    (review_source / '@org/linked-entrypoint').symlink_to('/old/cache/@org/linked-entrypoint', target_is_directory=True)
review_before, repair_before, repair_two_before = state(review_source), state(repair_root), state(repair_two)
review_stage, review_report = root / 'sanitize-review-stage', root / 'sanitize-review.json'
run(review_stage, review_report, '--sanitize-review', '--allow-linked-root', repair_root,
    '--allow-linked-root', repair_two, selected_source=review_source)
details = json.loads(review_report.read_text())
entries = {item['name']: item for item in details['entries']}
assert details['mode'] == 'sanitize-review' and details['inert_review_only'] is True
assert details['automatic_restore'] is False and details['not_installed'] is True
assert entries['complete']['complete'] is True and entries['complete']['status'] == 'staged'
assert (review_stage / 'complete/SKILL.md').read_bytes() == safe_body
redacted = entries['redacted']
assert redacted['complete'] is True and redacted['status'] == 'staged-partial'
assert redacted['redactions'] and not redacted['omissions']
assert redacted['source_metadata'] == {'source_url': 'https://origin.invalid/repository', 'revision': 'a1b2c3d4'}
staged_body = (review_stage / 'redacted/references/settings.md').read_text()
for private in (literal, 'literalCredential123456', 'opaqueCredentialValue0123456789', 'olduser', 'oldcredentialvalue'):
    assert private not in staged_body
assert '# Preserve safe prose' in staged_body and 'tail prose must survive' in staged_body
file_report = next(file for file in redacted['files'] if file['path'] == 'redacted/references/settings.md')
assert file_report['source_sha256'] == hashlib.sha256(redacted_original).hexdigest()
assert file_report['sha256'] == hashlib.sha256(staged_body.encode()).hexdigest()
assert file_report['source_sha256'] != file_report['sha256']
partial = entries['partial']
assert partial['complete'] is False and partial['status'] == 'staged-partial'
assert (review_stage / 'partial/SKILL.md').is_file()
assert (review_stage / 'partial/references/safe.md').read_text() == 'Keep this source body.\n'
for excluded in ('scripts/tool.bin', 'private.pem', '.env', 'references/unclosed.md'):
    assert not (review_stage / 'partial' / excluded).exists()
    assert 'partial/' + excluded in partial['missing_files']
assert {row['path'] for row in partial['missing_references']} >= {
    'partial/scripts/tool.bin', 'partial/references/not-present.md'}
assert partial['next_actions'] and partial['source_metadata']['source']['revision'] == 'b2c3d4e5'
assert entries['@org/namespaced']['complete'] is True
assert (review_stage / '@org/namespaced/SKILL.md').is_file()
assert literal not in review_report.read_text()
assert not any(path.is_symlink() for path in review_stage.rglob('*'))
if links_available:
    recovered = entries['@org/recovered']
    assert recovered['complete'] is True and recovered['link_rebound']['kind'] == 'SOURCE-exact-original-path-and-SKILL-name'
    assert (review_stage / '@org/recovered/SKILL.md').is_file()
    for name in ('@org/ambiguous', '@org/unproven', '@org/linked-entrypoint', 'loop'):
        assert entries[name]['status'] == 'excluded' and entries[name]['complete'] is False
        assert entries[name]['next_actions'] and not (review_stage / name).exists()
    assert len(entries['@org/ambiguous']['recovery_candidates']) == 2
    assert entries['@org/unproven']['recovery_candidates'][0]['source_metadata']['revision'] == 'e5f6a7b8'
assert state(review_source) == review_before
assert state(repair_root) == repair_before and state(repair_two) == repair_two_before

sys.path.insert(0, str(helper.parent))
from acb.bundle import scan_object_bytes
for path in review_stage.rglob('*'):
    if path.is_file():
        scan_object_bytes(path.read_bytes(), path.relative_to(review_stage).as_posix())
scan_object_bytes(review_report.read_bytes(), 'staging-report.json')
print('OK sanitize-review preserves safe package bodies, redacts exact literals, and records original/staged hashes and partial dependencies')
print('OK namespaces are discovered, cycles stay inert, and broken links rebind only with unique exact origin and Skill identity proof')

import importlib.util
spec = importlib.util.spec_from_file_location('prepare_skill_source_fixture', helper)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
limited_source = root / 'limited-source'
skill(limited_source / 'bounded', 'bounded')
write(limited_source / 'bounded/too-large.txt', 'x' * 256)
write(limited_source / 'bounded/deep/one/two/guide.md', 'Too deep.\n')
limited_before = state(limited_source)
module.MAX_FILE_SIZE = 128
module.MAX_DIR_DEPTH = 3
limited_stage, limited_report = root / 'limited-stage', root / 'limited-report.json'
limited = module.prepare(limited_source, limited_stage, limited_report, [], sanitize_review=True)
bounded = limited['entries'][0]
assert bounded['complete'] is False and bounded['status'] == 'staged-partial'
assert any(item['reason'] == 'file-size-limit' for item in bounded['omissions'])
assert any(item['reason'] == 'resource-or-depth-limit' for item in bounded['omissions'])
assert (limited_stage / 'bounded/SKILL.md').is_file()
assert state(limited_source) == limited_before
module.MAX_BUNDLE_FILES = 1
count_stage, count_report = root / 'count-stage', root / 'count-report.json'
counted = module.prepare(limited_source, count_stage, count_report, [], sanitize_review=True)
assert counted['files_staged'] == 0
assert any(item['reason'] == 'resource-or-depth-limit' for item in counted['entries'][0]['omissions'])
assert not any(item['complete'] for item in counted['entries'])
scan_object_bytes(helper.read_bytes(), helper.name)
print('OK review file/depth/count limits keep explicit omissions; runtime source passes unchanged credential scanner')
print('Prepare Skill source tests passed')
PY
