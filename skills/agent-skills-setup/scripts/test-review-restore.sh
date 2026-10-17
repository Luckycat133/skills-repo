#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REVIEW_RESTORE_TEST="$(mktemp -d)"
trap 'rm -rf "$REVIEW_RESTORE_TEST"' EXIT
export SCRIPT_DIR REVIEW_RESTORE_TEST PYTHONDONTWRITEBYTECODE=1
"${REVIEW_RESTORE_PYTHON:-python3}" -B - <<'PY'
from pathlib import Path
import hashlib,json,os,subprocess,sys
root=Path(os.environ['REVIEW_RESTORE_TEST']).resolve();scripts=Path(os.environ['SCRIPT_DIR']);home=root/'home';home.mkdir();source=root/'source';source.mkdir();packet=root/'packet'
def write(path,text):path.parent.mkdir(parents=True,exist_ok=True);path.write_text(text)
write(source/'model.json',json.dumps({'model':'source-choice','credential':'SOURCE_OPAQUE_CREDENTIAL_NOT_FOR_TRANSFER'}))
write(source/'mcp.json',json.dumps({'mcpServers':{'fixture':{'command':'fixture-cli','args':['--cwd','/source/project']}}}))
write(source/'skills/fixture/SKILL.md','---\nname: fixture\ndescription: Reviewed configuration fixture.\n---\nKeep this context. See [sibling](../sibling/SKILL.md), [directory](scripts/) and [missing](../absent/SKILL.md).\n')
write(source/'skills/sibling/SKILL.md','---\nname: sibling\ndescription: Sibling context fixture.\n---\nShared context.\n')
write(source/'skills/fixture/scripts/proof.sh','#!/bin/sh\ntouch "DO_NOT_EXECUTE_CAPTURED_SCRIPT"\n');(source/'skills/fixture/scripts/proof.sh').chmod(0o755)
write(source/'RULE.md','Project root /source/project should be remapped.\n')
clients=[{'id':x,'label':x,'native_profiles':[]} for x in ('antigravity','tuanjie','workbuddy')]
review=[{'id':'antigravity','label':'antigravity','sources':[{'id':'model','kind':'preferences','path':str(source/'model.json'),'format':'json','fields':[['model']]},{'id':'mcp','kind':'mcp','path':str(source/'mcp.json'),'container':'mcpServers'}]}, {'id':'tuanjie','label':'tuanjie','sources':[{'id':'skills','kind':'skills','path':str(source/'skills')}]}, {'id':'workbuddy','label':'workbuddy','sources':[{'id':'rule','kind':'text','path':str(source/'RULE.md')}]}]
spec=root/'scope.json';spec.write_text(json.dumps({'schema_version':1,'clients':clients,'review':{'schema_version':1,'clients':review}}))
env=dict(os.environ,HOME=str(home),PYTHONDONTWRITEBYTECODE='1');env.pop('CODEX_HOME',None)
def call(script,*args,ok=True):
 r=subprocess.run([sys.executable,'-I','-B',str(script),*map(str,args)],env=env,cwd=root,capture_output=True,text=True)
 assert 'SOURCE_OPAQUE_CREDENTIAL_NOT_FOR_TRANSFER' not in r.stdout+r.stderr
 assert 'TARGET_OPAQUE_CREDENTIAL_KEEP_LOCAL' not in r.stdout+r.stderr
 d=json.loads(r.stdout);assert (r.returncode==0)==ok and bool(d['ok'])==ok,(r.returncode,d,r.stderr)
 return d
call(scripts/'device-export.py','--spec',spec,'--output',packet)
cli=packet/'skill/scripts/review-restore.py'
write(home/'anti/settings.json',json.dumps({'model':'target-default','credential':'TARGET_OPAQUE_CREDENTIAL_KEEP_LOCAL','keep':{'nested':3}}))
entries=[{'client':'antigravity','source':'model','target':str(home/'anti/settings.json'),'format':'json','conflict':'replace'}, {'client':'antigravity','source':'mcp','target':str(home/'anti/mcp.json'),'format':'json','container':'mcpServers','path_map':{'/source/project':str(home/'project')}}, {'client':'tuanjie','source':'skills','target':str(home/'tuanjie/skills')}, {'client':'workbuddy','source':'rule','target':str(home/'buddy/RULE.md'),'layout':'file','path_map':{'/source/project':str(home/'project')}}]
mapping=root/'mapping.json';mapping.write_text(json.dumps({'schema_version':1,'roots':[str(home)],'entries':entries}));plan=root/'review.plan.json';state=root/'state'
source_before={str(f):hashlib.sha256(f.read_bytes()).hexdigest() for f in source.rglob('*') if f.is_file()};target_before=(home/'anti/settings.json').read_bytes();packet_before={str(f.relative_to(packet)):hashlib.sha256(f.read_bytes()).hexdigest() for f in packet.rglob('*') if f.is_file()}
call(cli,'plan','--packet',packet,'--mapping',mapping,'--plan-out',plan)
planned=json.loads(plan.read_text())
reference_tasks=[row for row in planned['remaining_work'] if row['reason']=='unresolved-package-reference']
assert reference_tasks and all('/absent/' in row['target'] for row in reference_tasks),reference_tasks
assert not any(row['reason'] in {'partial-package-needs-review','sanitized-review-source-materialized'} for row in planned['remaining_work'])
assert (home/'anti/settings.json').read_bytes()==target_before and not (home/'tuanjie').exists()
assert 'TARGET_OPAQUE_CREDENTIAL_KEEP_LOCAL' not in plan.read_text() and 'SOURCE_OPAQUE_CREDENTIAL_NOT_FOR_TRANSFER' not in plan.read_text()
call(cli,'apply','--packet',packet,'--mapping',mapping,'--plan-in',plan,'--state-dir',state,'--yes')
assert json.loads((home/'anti/settings.json').read_text())=={'model':'source-choice','credential':'TARGET_OPAQUE_CREDENTIAL_KEEP_LOCAL','keep':{'nested':3}}
assert json.loads((home/'anti/mcp.json').read_text())['mcpServers']['fixture']['args']==['--cwd',str(home/'project')]
assert (home/'tuanjie/skills/fixture/SKILL.md').read_bytes()==(source/'skills/fixture/SKILL.md').read_bytes()
assert (home/'tuanjie/skills/sibling/SKILL.md').is_file()
assert (home/'tuanjie/skills/fixture/scripts/proof.sh').stat().st_mode&0o777==0o755
assert str(home/'project') in (home/'buddy/RULE.md').read_text() and not (root/'DO_NOT_EXECUTE_CAPTURED_SCRIPT').exists()
call(cli,'verify','--state-dir',state)
call(cli,'apply','--packet',packet,'--mapping',mapping,'--plan-in',plan,'--state-dir',state,'--yes',ok=False)
call(cli,'rollback','--state-dir',state,'--yes');assert (home/'anti/settings.json').read_bytes()==target_before and not (home/'anti/mcp.json').exists()
assert source_before=={str(f):hashlib.sha256(f.read_bytes()).hexdigest() for f in source.rglob('*') if f.is_file()}
assert packet_before=={str(f.relative_to(packet)):hashlib.sha256(f.read_bytes()).hexdigest() for f in packet.rglob('*') if f.is_file()}
print('OK self-contained captured review restore merges selected fields, preserves credentials/siblings/modes, remaps paths, verifies and rolls back without executing code')
# Changed destinations and symlink escapes fail before writes.
plan2=root/'drift.plan.json';call(cli,'plan','--packet',packet,'--mapping',mapping,'--plan-out',plan2)
write(home/'anti/settings.json','{"model":"changed-after-review"}')
call(cli,'apply','--packet',packet,'--mapping',mapping,'--plan-in',plan2,'--state-dir',root/'drift-state','--yes',ok=False)
assert not (root/'drift-state').exists()
escaped=root/'outside';escaped.mkdir();(home/'link').symlink_to(escaped,target_is_directory=True)
bad=json.loads(mapping.read_text());bad['entries'][0]['target']=str(home/'link/settings.json');badmap=root/'bad.json';badmap.write_text(json.dumps(bad))
call(cli,'plan','--packet',packet,'--mapping',badmap,'--plan-out',root/'bad.plan',ok=False);assert list(escaped.iterdir())==[]
print('OK destination drift, attempted replay and symlink escapes are rejected without source or packet writes')
# Distinct record identities preserve target API-key siblings and reject ambiguity.
sys.path.insert(0,str(scripts));import importlib.util
sp=importlib.util.spec_from_file_location('review_restore',scripts/'review-restore.py');module=importlib.util.module_from_spec(sp);sp.loader.exec_module(module)
document={'models':[{'name':'chosen','model':'old','apiKey':'KEEP_LOCAL'},{'name':'other','model':'untouched'}]}
payload={'records':[{'path':['models'],'source_length':1,'items':[{'index':0,'fields':[{'path':['name'],'value':'chosen'},{'path':['model'],'value':'new'}]}]}]};pending=[]
module.merge_preferences(document,payload,{'conflict':'replace'},pending)
assert document['models']==[{'name':'chosen','model':'new','apiKey':'KEEP_LOCAL'},{'name':'other','model':'untouched'}]
assert module.render(document,'json')
try:
 module.merge_preferences({'models':[{'name':'chosen'},{'name':'chosen'}]},payload,{},[])
except ValueError:pass
else:raise AssertionError('ambiguous identities allowed')
print('OK model catalogs merge by stable identity and preserve unselected model credentials')
yaml_document={'name':'Local','models':[{'name':'chosen','roles':['chat','edit'],'apiKey':'KEEP_LOCAL'}],'localOnly':True}
assert module._decode_preferences(module.render(yaml_document,'yaml'),'yaml')==yaml_document
try:
 import tomllib
except ImportError:
 print('SKIP TOML roundtrip on Python < 3.11; safe CLI failure is checked by the recovery suite')
else:
 toml_document={'model':'chosen','credential':'KEEP_LOCAL','provider':{'endpoint':'https://example.invalid'},'models':[{'name':'one','nested':{'enabled':True}}]}
 assert module._decode_preferences(module.render(toml_document,'toml'),'toml')==toml_document
write(home/'anti/settings.json',target_before.decode())
multi=json.loads(mapping.read_text());multi['entries'][1]['target']=str(home/'anti/settings.json')
multi_path=root/'multi.mapping.json';multi_path.write_text(json.dumps(multi));multi_plan=root/'multi.plan.json'
call(cli,'plan','--packet',packet,'--mapping',multi_path,'--plan-out',multi_plan)
ops=json.loads(multi_plan.read_text())['operations'];assert len([op for op in ops if op['target']==str(home/'anti/settings.json')])==1
call(cli,'apply','--packet',packet,'--mapping',multi_path,'--plan-in',multi_plan,'--state-dir',root/'multi-state','--yes')
merged=json.loads((home/'anti/settings.json').read_text());assert merged['model']=='source-choice' and merged['credential']=='TARGET_OPAQUE_CREDENTIAL_KEEP_LOCAL' and 'fixture' in merged['mcpServers']
print('OK YAML/TOML preserve parsed siblings; multiple captured sources merge into one shared settings transaction')
PY
