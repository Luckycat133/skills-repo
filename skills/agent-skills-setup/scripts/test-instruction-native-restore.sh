#!/usr/bin/env bash
# Native instruction placement survives same-product restore without false loss.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

python3 - "$SCRIPT_DIR" <<'PY'
import copy
import hashlib
import json
import os
import shutil
import subprocess
import sys
import tempfile
from dataclasses import replace
from pathlib import Path

scripts = Path(sys.argv[1])
sys.path.insert(0, str(scripts))
from migration_core import Registry, _render_instruction_source, verify_manifest

with tempfile.TemporaryDirectory(prefix='native-instruction-') as temporary:
    root = Path(temporary)
    old_workspace, new_workspace = root / 'source', root / 'destination'
    old_home, new_home = root / 'old-home', root / 'new-home'
    for directory in (old_workspace, new_workspace, old_home, new_home):
        directory.mkdir()
    original = '# Native instructions\r\n\r\nPreserve whitespace.   \r\n\r\n'.encode('utf-8')
    (old_workspace / 'CLAUDE.md').write_bytes(original)
    registry_data = json.loads((scripts.parent / 'references/registry-v2.json').read_text())
    source_profile = copy.deepcopy(registry_data['products']['claude']['profiles']['code-cli'])
    source_profile.update(platforms={}, detection=[], surfaces={'instructions': [{
        'path': 'CLAUDE.md', 'scope': 'project', 'storage': 'hierarchy',
        'format': 'agents-md', 'policy': 'semantic-ir-with-loss-report',
    }]})
    registry_data['products'] = {
        'claude': {'default_profile': 'code-cli', 'profiles': {'code-cli': source_profile}},
        'cline': {'default_profile': 'ide', 'profiles': {'ide': copy.deepcopy(source_profile)}},
    }
    registry_file = root / 'registry.json'
    registry_file.write_text(json.dumps(registry_data))
    source_registry = Registry(registry_file, old_workspace, old_home)
    target_registry = Registry(registry_file, new_workspace, new_home)
    source = source_registry.surfaces('claude/code-cli', 'instructions')[0]
    target = target_registry.surfaces('claude/code-cli', 'instructions')[0]
    rendered, losses = _render_instruction_source(source, target, source.resolved_path)
    assert not losses.lossy and rendered.encode() == original
    for changed in (
        replace(target, product='cline'), replace(target, profile='other'),
        replace(target, scope='user'), replace(target, storage='file'),
        replace(target, source_format='cline-rule'),
        replace(target, canonical_path='OTHER.md'), replace(target, path='OTHER.md'),
        replace(target, location_role='compatibility'),
    ):
        _, report = _render_instruction_source(source, changed, source.resolved_path)
        assert report.lossy, changed
    shared_source = replace(source, storage='config-subobject')
    shared_target = replace(target, storage='config-subobject')
    _, report = _render_instruction_source(shared_source, shared_target, source.resolved_path)
    assert report.lossy

    # Same native placement does not bypass genuine unknown fields or invalid
    # activation semantics; only an otherwise lossless container is preserved.
    conditional = old_workspace / 'conditional.md'
    conditional.write_text('---\npaths: src/**\nfutureField: preserve-review\n---\nReview this file.\n')
    conditional_source = replace(source, resolved_path=conditional, path='conditional.md', canonical_path='conditional.md', source_format='claude-rule')
    conditional_target = replace(target, resolved_path=new_workspace / 'conditional.md', path='conditional.md', canonical_path='conditional.md', source_format='claude-rule')
    _, report = _render_instruction_source(conditional_source, conditional_target, conditional)
    assert any(item.field == 'futureField' for item in report.items)
    conditional.write_text('---\nalwaysApply: unsupported\n---\nReview this file.\n')
    try:
        _render_instruction_source(replace(conditional_source, source_format='cursor-mdc'),
                                   replace(conditional_target, source_format='cursor-mdc'), conditional)
    except ValueError:
        pass
    else:
        raise AssertionError('invalid activation was accepted as a native copy')

    def cli(home, *arguments, success=True):
        result = subprocess.run(
            [sys.executable, '-B', str(scripts / 'context-migrator.py'), *map(str, arguments), '--registry', str(registry_file), '--json'],
            env=dict(os.environ, HOME=str(home), USERPROFILE=str(home), AGENT_SKILLS_PLATFORM='linux'),
            capture_output=True, text=True,
        )
        if not success:
            assert result.returncode != 0, result.stdout
            return result
        assert result.returncode == 0, (result.stdout, result.stderr)
        output = json.loads(result.stdout)
        assert output.get('ok'), output
        return output

    bundle, plan, manifest = root / 'context.acb', root / 'plan.json', root / 'manifest.json'
    cli(old_home, 'snapshot', '--workspace', old_workspace, '--source', 'claude/code-cli', '--target', 'claude/code-cli',
        '--scope', 'project', '--objects', 'instructions', '--output', bundle)
    shutil.rmtree(old_workspace)
    cli(new_home, 'restore', bundle, '--workspace', new_workspace, '--source', 'claude/code-cli', '--target', 'claude/code-cli',
        '--scope', 'project', '--objects', 'instructions', '--plan-only', '--plan-out', plan)
    document = json.loads(plan.read_text())
    assert len(document['items']) == 1 and document['items'][0]['status'] == 'ready', document
    assert not document['loss_report']['items'], document
    preview = document['items'][0]['review_preview']['changes'][0]
    assert preview['post_sha256'] == hashlib.sha256(original).hexdigest()
    (new_workspace / 'CLAUDE.md').write_text('Destination drift must be rejected.\n')
    failed = cli(new_home, 'restore', bundle, '--workspace', new_workspace, '--source', 'claude/code-cli', '--target', 'claude/code-cli',
                 '--scope', 'project', '--objects', 'instructions', '--plan-in', plan, '--manifest-out', manifest, '--yes', success=False)
    assert not manifest.exists() and (new_workspace / 'CLAUDE.md').read_text().startswith('Destination drift')
    assert 'changed' in failed.stdout + failed.stderr or 'drift' in failed.stdout + failed.stderr
    (new_workspace / 'CLAUDE.md').unlink()
    cli(new_home, 'restore', bundle, '--workspace', new_workspace, '--source', 'claude/code-cli', '--target', 'claude/code-cli',
        '--scope', 'project', '--objects', 'instructions', '--plan-in', plan, '--manifest-out', manifest, '--yes')
    assert (new_workspace / 'CLAUDE.md').read_bytes() == original
    assert not verify_manifest(manifest)
    assert any(item['outcome'] == 'applied' for item in json.loads(manifest.read_text())['items'])

    # Cross-product same-text-format remains lossy and is not authorized by --yes.
    cross_workspace = root / 'cross-destination'
    cross_workspace.mkdir()
    cross_plan, cross_manifest = root / 'cross-plan.json', root / 'cross-manifest.json'
    cli(new_home, 'restore', bundle, '--workspace', cross_workspace, '--source', 'claude/code-cli', '--target', 'cline/ide',
        '--scope', 'project', '--objects', 'instructions', '--plan-only', '--plan-out', cross_plan)
    cross = json.loads(cross_plan.read_text())
    assert cross['items'][0]['status'] == 'ready-lossy'
    assert any(item['field'] == 'hierarchy' for item in cross['loss_report']['items'])
    cli(new_home, 'restore', bundle, '--workspace', cross_workspace, '--source', 'claude/code-cli', '--target', 'cline/ide',
        '--scope', 'project', '--objects', 'instructions', '--plan-in', cross_plan, '--manifest-out', cross_manifest, '--yes', success=False)
    assert not (cross_workspace / 'CLAUDE.md').exists()
    print('PASS: same-native instruction restore preserves hierarchy and bytes; real losses and destination drift remain guarded')
PY
