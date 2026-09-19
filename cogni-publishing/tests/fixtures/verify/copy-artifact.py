#!/usr/bin/env python3
"""Offline test bridge: select a committed artifact by its exact frozen inputs; never render."""
import argparse,hashlib,json,shutil,sys
from pathlib import Path
plugin=Path(__file__).resolve().parents[3]
sys.path.insert(0,str(plugin/'scripts'))
import render_core as core
parser=argparse.ArgumentParser()
parser.add_argument('command',nargs='?')
for key in ('target','brief','composition','theme','out'):parser.add_argument('--'+key,required=True)
parser.add_argument('--attempt',type=int,default=1)
parser.add_argument('--findings-file')
parser.add_argument('--generated-at');parser.add_argument('--run-id')
a=parser.parse_args()
if a.attempt > 1:
 assert a.findings_file and json.loads(Path(a.findings_file).read_text()), 'Repair must receive previous findings'
brief=json.loads(Path(a.brief).read_text());comp=json.loads(Path(a.composition).read_text())
theme=core.resolve_theme(a.theme,comp['design_system'])
key=hashlib.sha256(json.dumps([a.target,brief,comp,theme.digest],sort_keys=True).encode()).hexdigest()[:16]
source=Path(__file__).parent/'artifact-samples'/key
if not source.is_dir():
 print(json.dumps({'success':False,'data':{'findings':[{'code':'stub-unfit','unit':'u-options','message':'No admitted offline fixture for this variant'}]},'error':'fixture-unavailable'}));sys.exit(1)
out=Path(a.out);out.mkdir(parents=True,exist_ok=True)
artifact='index.html' if a.target=='html' else 'deck.pptx'
shutil.copyfile(source/artifact,out/artifact)
shutil.copyfile(a.brief,out/'brief.json');shutil.copyfile(a.composition,out/'composition.json')
(out/'theme.json').write_text(json.dumps({'slug':theme.slug,'digest':theme.digest}))
(out/'host.json').write_text(json.dumps({'host':'offline-test','skill':'test-platform-stub','live':False}))
(out/'review-record.json').write_text(json.dumps({'fixture':True,'findings':[]}))
def record(name):return {'path':name,'sha256':'sha256:'+hashlib.sha256((out/name).read_bytes()).hexdigest()}
fingerprint=comp['normalized_brief_ref']['content_fingerprint'];units=[u['id'] for u in comp['units']]
provenance={'artifact_type':'render-provenance','artifact_version':'1','artifact_id':'offline-fixture:'+key,
 'renderer':{'kind':'platform','name':'test-platform-stub','version':'test-fixture','target':a.target,'host':'offline-test'},
 'design_system':comp['design_system'],'inputs':{k:record(k+'.json') for k in ('brief','composition','theme')},
 'content_fingerprint':fingerprint,'outputs':{'artifact':record(artifact)},'reproducible':False,'live_proof':False,
 'run':{'id':'fixture:'+key,'host':'offline-test','skill':'test-platform-stub','live':False,'evidence':record('host.json')},
 'attempts':[{'attempt':i,'findings':[],'preserve':{'differences':[]},'content_fingerprint_before':fingerprint,
 'content_fingerprint_after':fingerprint,'unit_ids_before':units,'unit_ids_after':units} for i in range(1,a.attempt+1)],
 'review':dict(record('review-record.json'),open_findings=[],coverage={'all_units':True,'all_slides':True,'overview':True}),
 'applicability':{k:{'applicable':False,'reason':'Offline fixture; not a host execution','evidence':[]} for k in ('theme','fonts','runtime')}}
(out/'provenance.json').write_text(json.dumps(provenance,indent=2)+'\n')
print(json.dumps({'success':True,'data':{'artifact':str(out/artifact)},'error':None}))
