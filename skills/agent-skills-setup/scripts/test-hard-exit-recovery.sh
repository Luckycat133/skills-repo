#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python3 - "$SCRIPT_DIR" <<'PY'
import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

scripts = Path(sys.argv[1])
sys.path.insert(0, str(scripts))
from migration_core import path_state, hash_path, recover_transaction, verify_manifest, rollback_manifest

child = r'''
import os,sys
from pathlib import Path
sys.path.insert(0, sys.argv[1])
import migration_core as m
root=Path(sys.argv[2]); phase=sys.argv[3]
def surface(path):
    relative=path.relative_to(root).as_posix()
    return m.SurfacePath("fixture", "cli", "skills", "project", "directory", relative,
        path, root, "agent-skill", "validate-then-atomic-copy", "canonical", relative, 0)
source=surface(root/"source");target=surface(root/"target")
item=m.PlanItem("skills", "ready", "fixture", source, target)
item.expected_source_state=m.path_state(source.resolved_path)
item.expected_target_state=m.path_state(target.resolved_path)
if phase == "source-mode": (root/"source/demo/run.sh").chmod(0o644)
if phase == "target-mode": (root/"target/demo/run.sh").chmod(0o644)
orig=m.os.replace
count=0
def replace(a,b):
    global count
    orig(a,b)
    if Path(a)==root/"target/demo" and phase=="gap": os._exit(86)
    if Path(b)==root/"target/demo" and phase=="installed": os._exit(86)
    if Path(b)==root/"manifest.json" and phase=="manifest": os._exit(86)
m.os.replace=replace
if phase == "rollback-copy":
    original_write=m.atomic_write
    original_copytree=m.shutil.copytree
    def fail_manifest(path,text):
        if path==root/"manifest.json": raise OSError("injected manifest failure")
        original_write(path,text)
    def crash_copytree(source,target,*args,**kwargs):
        if Path(target).name=="restored":
            Path(target).mkdir()
            m.shutil.copy2(Path(source)/"SKILL.md",Path(target)/"SKILL.md")
            os._exit(88)
        return original_copytree(source,target,*args,**kwargs)
    m.atomic_write=fail_manifest
    m.shutil.copytree=crash_copytree
m.apply_plan([item], root, manifest_path=root/"manifest.json")
'''

def setup(root):
    for name,body in (("source","new"),("target","old")):
        p=root/name/"demo";p.mkdir(parents=True)
        (p/"SKILL.md").write_text("---\nname: demo\ndescription: Fixture\n---\n"+body+"\n")
        (p/"run.sh").write_text("echo "+body+"\n");(p/"run.sh").chmod(0o755)

def run(root, phase):
    r=subprocess.run([sys.executable,"-c",child,str(scripts),str(root),phase],capture_output=True,text=True)
    assert r.returncode == (0 if phase=="success" else 88 if phase=="rollback-copy" else 86), (r.stdout,r.stderr)
    return next((root/".agent-context-migration/backups").iterdir()) / "recovery.json"

for phase in ("gap","installed","manifest","success","rollback-copy"):
    with tempfile.TemporaryDirectory() as d:
        root=Path(d);setup(root);before=path_state(root/"target/demo")
        journal=run(root,phase)
        if phase in ("gap","installed","rollback-copy"):
            assert not (root/"manifest.json").exists()
            refusal=subprocess.run([sys.executable,str(scripts/"context-migrator.py"),"recover","--journal",str(journal)], capture_output=True,text=True)
            assert refusal.returncode != 0 and "requires --yes" in refusal.stderr
            assert recover_transaction(journal)==1
            assert path_state(root/"target/demo")==before
            assert recover_transaction(journal)==0
        else:
            if phase=="manifest":
                try: recover_transaction(journal)
                except ValueError as e: assert "committed" in str(e)
                else: raise AssertionError("committed operation accepted for recovery")
            else:
                assert not journal.exists()
            assert [p.name for p in (root/"target").iterdir() if (p/"SKILL.md").is_file()]==["demo"]
            assert not verify_manifest(root/"manifest.json")
            assert rollback_manifest(root/"manifest.json")==1
            assert path_state(root/"target/demo")==before
    print("OK hard-exit phase",phase)

# A first installation is undone to absence, without inventing an old tree.
with tempfile.TemporaryDirectory() as d:
    root=Path(d);setup(root);shutil.rmtree(root/"target/demo")
    journal=run(root,"installed")
    assert recover_transaction(journal)==1
    assert not (root/"target/demo").exists()
    print("OK first-install recovery restores absence")

# Changes after the interrupted apply must never be overwritten.
for changed in ("target", "backup"):
    with tempfile.TemporaryDirectory() as d:
        root=Path(d);setup(root);journal=run(root,"installed")
        data=json.loads(journal.read_text());entry=data["entries"][0]
        p=root/"target/demo" if changed=="target" else Path(entry["backup"])
        (p/"run.sh").write_text("edited after interruption")
        state=path_state(root/"target/demo")
        try: recover_transaction(journal)
        except ValueError as e: assert "changed" in str(e)
        else: raise AssertionError("edited tree accepted")
        assert path_state(root/"target/demo")==state
    print("OK refused edited",changed)

# A hard exit during recovery is itself recoverable.
with tempfile.TemporaryDirectory() as d:
    root=Path(d);setup(root);before=path_state(root/"target/demo");journal=run(root,"installed")
    recovery_child = r'''
import os,sys
from pathlib import Path
sys.path.insert(0,sys.argv[1])
import migration_core as m
orig=m.os.replace
def crash(a,b):
 orig(a,b)
 if Path(a)==Path(sys.argv[3]): os._exit(87)
m.os.replace=crash
m.recover_transaction(Path(sys.argv[2]))
'''
    result=subprocess.run([sys.executable,"-c",recovery_child,str(scripts),str(journal),str(root/"target/demo")])
    assert result.returncode==87
    assert recover_transaction(journal)==1
    assert path_state(root/"target/demo")==before
    print("OK recovery interrupted and safely retried")

if os.name != "nt":
    for phase in ("source-mode", "target-mode"):
        with tempfile.TemporaryDirectory() as d:
            root=Path(d);setup(root)
            result=subprocess.run([sys.executable,"-c",child,str(scripts),str(root),phase],capture_output=True,text=True)
            assert result.returncode != 0 and "changed while staging" in result.stderr, result.stderr
            assert not (root/"manifest.json").exists()
            assert (root/"target/demo/run.sh").read_text()=="echo old\n"
        print("OK staged plan refuses",phase)
    with tempfile.TemporaryDirectory() as d:
        root=Path(d);setup(root);run(root,"success")
        target=root/"target/demo/run.sh";digest=hash_path(root/"target/demo");before=path_state(root/"target/demo")
        target.chmod(0o644)
        assert hash_path(root/"target/demo")==digest
        assert path_state(root/"target/demo")!=before
        assert verify_manifest(root/"manifest.json")
        try: rollback_manifest(root/"manifest.json")
        except ValueError: pass
        else: raise AssertionError("chmod accepted by rollback")
        target.chmod(0o755)
        manifest=json.loads((root/"manifest.json").read_text())
        (Path(manifest["changes"][0]["backup"])/"run.sh").chmod(0o644)
        try: rollback_manifest(root/"manifest.json")
        except ValueError as e: assert "backup" in str(e)
        else: raise AssertionError("chmod backup accepted")
    print("OK mode-only drift detected; content digest remains compatible")
else:
    print("SKIP POSIX chmod semantics on Windows")
PY
