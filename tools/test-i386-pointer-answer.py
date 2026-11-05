#!/usr/bin/env python3
"""Check exact native pointer answers against independently captured public state."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

ROOT=Path(__file__).resolve().parents[1]
COMMANDS=[
 ('#include "/Kernel/I386/PublicUser.HH"',[]),
 ('U8 *lost="bad";Unknown pointer_bad;',['Error: Undefined identifier at ']),
 ('lost;',{'pointer_symbol':'lost','literal':'bad'}),('lost[1];',['97']),
 ('U8 *lost="ok";',[]),('lost;',{'pointer_symbol':'lost','literal':'ok'}),
 ('lost[1];',['107']),('6*7;',['42']),
]


def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('disk',type=Path)
 p.add_argument('--reference',type=Path,required=True);p.add_argument('--out',type=Path,required=True)
 args=p.parse_args();disk=args.disk.resolve();ref=args.reference.resolve();out=args.out.resolve()
 if out.exists():p.error('Use a fresh output directory')
 reference=json.loads((ref/'result.json').read_text());records=reference.get('records',[])
 if reference.get('result')!='pass' or not reference.get('inputs_unchanged') or len(records)!=8 or records[3][2:]!=[1,97] or records[4][2:]!=[1,107]:
  raise ValueError('Passing original declaration-state reference required')
 paths=[disk,ref/'result.json',Path(__file__).resolve(),ROOT/'tools/i386-kernel-input.py',
        ROOT/'tools/i386-pointer-oracle.py',ROOT/'Kernel/FontStd.HC']
 sha=lambda f:hashlib.sha256(f.read_bytes()).hexdigest();pins={str(f):sha(f) for f in paths}
 out.mkdir(parents=True);report=dict(result='fail',input_sha256=pins,commands=COMMANDS,
  scope='Original-derived global survival and redefinition; native nonzero pointer presentation at 8 MiB KVM 486,-fpu/live WinMgr. Atomic physical captures independently validate public task/hash/type/storage/literal and consumed answer state, then exact pixels. Native numeric formatting retained; not all pointers/compiler APIs.')
 try:
  report['behavior']=runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input'](
   disk,out/'qemu',snapshot=True,cpu='486,-fpu',ram_mib=8,accel='kvm',qmp_stdio=True,welcome=True,
   keep_window_manager=True,startup_check={'status':'ok','answers':[],'commands':COMMANDS,'pause_window_manager':False})
  if len(report['behavior'].get('pointer_oracles',[]))!=2:raise ValueError('Missing independent pointer evidence')
  report['result']='pass'
 except Exception as exc:report['error']=str(exc);raise
 finally:
  report['inputs_unchanged']=all(sha(Path(f))==h for f,h in pins.items())
  if not report['inputs_unchanged']:report['result']='fail'
  (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
 if report['result']!='pass':raise ValueError('Pointer answer workflow failed')


if __name__=='__main__':main()
