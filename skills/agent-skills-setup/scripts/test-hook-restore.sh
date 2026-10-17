#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK_RESTORE_TEST="$(mktemp -d)"
trap 'rm -rf "$HOOK_RESTORE_TEST"' EXIT
export SCRIPT_DIR HOOK_RESTORE_TEST PYTHONDONTWRITEBYTECODE=1
"${HOOK_RESTORE_PYTHON:-python3}" -I -B - <<'PY'
from pathlib import Path
import json,os,subprocess,sys,hashlib
scripts=Path(os.environ['SCRIPT_DIR']);root=Path(os.environ['HOOK_RESTORE_TEST']).resolve();src=root/'source';home=root/'home';src.mkdir();home.mkdir();(src/'hooks').mkdir()
script=src/'hooks/proof.py';script.write_text('from pathlib import Path\nPath("DO_NOT_EXECUTE").touch()\n');script.chmod(0o755)
settings=src/'settings.json';settings.write_text(json.dumps({'model':'source-model','password':'SYNTHETIC_SOURCE_SECRET_SIBLING','hooks':{'SessionStart':[{'hooks':[{'type':'command','command':'python3 "'+str(script)+'"'}]}],'state':{'trusted_hash':'DO_NOT_TRANSFER_TRUST'}}}))
source_before={str(p):hashlib.sha256(p.read_bytes()).hexdigest() for p in src.rglob('*') if p.is_file()}
spec=root/'scope.json';spec.write_text(json.dumps({'schema_version':1,'clients':[{'id':'claude-code','label':'Claude Code','native_profiles':[]}],'review':{'schema_version':1,'clients':[{'id':'claude-code','label':'Claude Code','sources':[{'id':'preferences','path':str(settings),'kind':'preferences','format':'json','fields':[['model']]},{'id':'hooks','path':str(settings),'kind':'hooks','format':'json','fields':['hooks'],'dependency_roots':[str(src/'hooks')],'classification':'activation-bearing'}]}]}}))
env=dict(os.environ,HOME=str(home));env.pop('CODEX_HOME',None)
def cli(helper,*args,ok=True):
 r=subprocess.run([sys.executable,'-I','-B',str(helper),*map(str,args)],env=env,cwd=root,capture_output=True,text=True);d=json.loads(r.stdout);assert (r.returncode==0)==ok and d['ok']==ok,(d,r.stderr);return d
packet=root/'packet';cli(scripts/'device-export.py','--spec',spec,'--output',packet)
assert not any(b'SYNTHETIC_SOURCE_SECRET_SIBLING' in p.read_bytes() or b'DO_NOT_TRANSFER_TRUST' in p.read_bytes() for p in packet.rglob('*') if p.is_file())
target=home/'settings.json';before={'credential':'KEEP_TARGET_SECRET','hooks':{'SessionStart':[{'hooks':[{'type':'command','command':'echo KEEP_EXISTING_UNRELATED_HOOK'}]}],'Stop':[{'hooks':[]}],'state':{'local-trust':'keep-on-target'}}};target.write_text(json.dumps(before))
installed_dependency=home/'different-hooks/custom.py'
entry={'client':'claude-code','source':'hooks','target':str(target),'format':'json','conflict':'replace','path_map':{str(src):str(home)},'dependency_targets':{str(script):str(installed_dependency)}}
mapping=root/'mapping.json';m={'schema_version':1,'roots':[str(home)],'entries':[{'client':'claude-code','source':'preferences','target':str(target),'format':'json','conflict':'replace'},entry]};mapping.write_text(json.dumps(m));tool=packet/'skill/scripts/review-restore.py';plan=root/'pending.json';cli(tool,'plan','--packet',packet,'--mapping',mapping,'--plan-out',plan)
d=json.loads(plan.read_text());assert any(x['reason']=='hook-definition-captured-needs-native-review' for x in d['remaining_work']);assert not (home/'hooks').exists();assert json.loads(target.read_text())==before
entry['activation_reviewed']=True;mapping.write_text(json.dumps(m));ready=root/'ready.json';cli(tool,'plan','--packet',packet,'--mapping',mapping,'--plan-out',ready);state=root/'state';cli(tool,'apply','--packet',packet,'--mapping',mapping,'--plan-in',ready,'--state-dir',state,'--yes');cli(tool,'verify','--state-dir',state)
d=json.loads(target.read_text());assert d['credential']==before['credential'] and d['hooks']['state']==before['hooks']['state'] and 'Stop' in d['hooks'];assert d['hooks']['SessionStart'][0]==before['hooks']['SessionStart'][0]
commands=[hook['command'] for group in d['hooks']['SessionStart'] for hook in group.get('hooks',[])]
assert len(commands)==2 and commands[0]=='echo KEEP_EXISTING_UNRELATED_HOOK'
restored_command=next(command for command in commands if str(installed_dependency) in command)
assert restored_command=='python3 \"'+str(installed_dependency)+'\"', restored_command
assert not (home/'hooks/proof.py').exists() and installed_dependency.exists()
assert d['model']=='source-model';assert installed_dependency.stat().st_mode&0o777==0o755;assert not (root/'DO_NOT_EXECUTE').exists()
# Replanning merges the same event idempotently without duplicating a hook.
repeat=root/'repeat.json';cli(tool,'plan','--packet',packet,'--mapping',mapping,'--plan-out',repeat)
assert all(operation['status']=='unchanged' for operation in json.loads(repeat.read_text())['operations'])
cli(tool,'rollback','--state-dir',state,'--yes');assert json.loads(target.read_text())==before and not installed_dependency.exists()
assert source_before=={str(p):hashlib.sha256(p.read_bytes()).hexdigest() for p in src.rglob('*') if p.is_file()}
# Missing external commands cannot be activated merely through a review flag.
entry['dependency_targets']={};mapping.write_text(json.dumps(m));missing=root/'missing.json';cli(tool,'plan','--packet',packet,'--mapping',mapping,'--plan-out',missing);d=json.loads(missing.read_text());assert any(x['reason']=='hook-dependency-target-review-required' for x in d['remaining_work']);assert not any(x['kind']=='hook-dependency' for x in d['operations'])
# Relative dependencies must remain pending even after explicit native review.
settings.write_text(json.dumps({'model':'source-model','hooks':{'SessionStart':[{'hooks':[{'type':'command','command':'python3 hooks/missing.py'}]}]}}))
relative_before=hashlib.sha256(settings.read_bytes()).hexdigest()
relative_packet=root/'relative-packet';cli(scripts/'device-export.py','--spec',spec,'--output',relative_packet)
relative_plan=root/'relative-plan.json';relative_tool=relative_packet/'skill/scripts/review-restore.py'
cli(relative_tool,'plan','--packet',relative_packet,'--mapping',mapping,'--plan-out',relative_plan)
relative_data=json.loads(relative_plan.read_text())
assert any(task['reason']=='hook-relative-reference-needs-review' for task in relative_data['remaining_work'])
assert any(task['reason']=='hook-source-exclusions-require-reconstruction' for task in relative_data['remaining_work'])
assert not any(operation['kind'] in {'hooks','hook-dependency'} for operation in relative_data['operations'])
assert json.loads(target.read_text())==before and hashlib.sha256(settings.read_bytes()).hexdigest()==relative_before
assert not (root/'DO_NOT_EXECUTE').exists()
print('OK Hook definition + dependency capture, explicit native review, custom dependency command binding, same-event preservation/deduplication, relative dependency activation blocking, executable modes, shared sibling/trust preservation, no source execution and rollback')
PY
