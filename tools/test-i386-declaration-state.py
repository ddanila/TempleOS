#!/usr/bin/env python3
"""Check original class/global/function state across errors and redefinition."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

ROOT=Path(__file__).resolve().parents[1]
COMMANDS=[
 ('#include "/Kernel/I386/PublicUser.HH"',[]),
 ('extern class OriginalOpaque;class OriginalHolder{OriginalOpaque *p;I64 value;};OriginalHolder oh;oh.p=0;oh.value=42;',['42']),
 ('sizeof(OriginalOpaque);',['0']),('oh.value;',['42']),
 ('class OriginalOpaque{I64 value;};Unknown opaque_bad;',['Error: Undefined identifier at ']),
 ('sizeof(OriginalOpaque);',['8']),('oh.value;',['42']),
 ('class OriginalOpaque{I64 value;};OriginalOpaque original_item;',[]),
 ('sizeof(OriginalOpaque);',['8']),
 ('oh.p=&original_item;original_item.value=42;oh.p->value;',['42']),
 ('U8 *original_lost="bad";Unknown lost_bad;',['Error: Undefined identifier at ']),
 ('StrCmp(original_lost,"bad")==0;',['1']),('original_lost[1];',['97']),
 ('U8 *original_lost="ok";',[]),('StrCmp(original_lost,"ok")==0;',['1']),('original_lost[1];',['107']),
 ('I64 OriginalCount(){return 1;}I64 OriginalCaller(){return OriginalCount;}',[]),
 ('OriginalCount;',['1']),('OriginalCaller;',['1']),
 ('I64 OriginalCount(){return 2;}',[]),('OriginalCount;',['2']),('OriginalCaller;',['1']),
 ('I64 OriginalGood(){return 99;}I64 OriginalBad(){return original_missing;}',['Error: Invalid lval at ']),
 ('OriginalGood;',['99']),('HashFind("OriginalBad",Fs->hash_table,HTT_FUN)!=NULL;',['1']),
 ('6*7;',['42']),
]


def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('disk',type=Path)
 p.add_argument('--reference',type=Path,required=True);p.add_argument('--out',type=Path,required=True)
 args=p.parse_args();source=args.disk.resolve();ref=args.reference.resolve();out=args.out.resolve()
 if out.exists():p.error('Use a fresh output directory')
 reference=json.loads((ref/'result.json').read_text())
 if reference.get('result')!='pass' or not reference.get('inputs_unchanged') or len(reference.get('records',[]))!=8:
  raise ValueError('Passing original eight-case declaration state required')
 paths=[source,ref/'result.json',Path(__file__).resolve(),ROOT/'tools/i386-kernel-input.py']
 sha=lambda f:hashlib.sha256(f.read_bytes()).hexdigest();pins={str(f):sha(f) for f in paths}
 out.mkdir(parents=True);report=dict(result='fail',input_sha256=pins,commands=COMMANDS,
  scope='Original-derived completed class/global state after error, redefinition and retained caller binding; malformed-function placeholder lookup. Native final-answer presentation, 8 MiB KVM 486 without FPU/live WinMgr, exact pixels; not all declaration/API qualification.')
 try:
  run=runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input']
  report['behavior']=run(source,out/'qemu',snapshot=True,ram_mib=8,cpu='486,-fpu',accel='kvm',qmp_stdio=True,
   welcome=True,keep_window_manager=True,startup_check={'status':'ok','answers':[],'commands':COMMANDS,'pause_window_manager':False})
  report['result']='pass'
 except Exception as exc:report['error']=str(exc);raise
 finally:
  report['inputs_unchanged']=all(sha(Path(f))==h for f,h in pins.items())
  if not report['inputs_unchanged']:report['result']='fail'
  (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
 if report['result']!='pass':raise ValueError('Declaration state failed')


if __name__=='__main__':main()
