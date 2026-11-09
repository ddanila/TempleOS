#!/usr/bin/env python3
"""Check original/native Budget recurrence boundaries and periodic-copy ownership."""
import argparse,hashlib,runpy,subprocess
from datetime import date,timedelta
from pathlib import Path
import struct,json
anchor=date(1998,9,4)
def encoded(d):return (730000+(d-anchor).days)<<32|4
cases=[(2,[date(1999,1,31),date(1999,3,3),date(1999,3,31),date(1999,5,1),date(1999,5,31)]),(3,[date(1999,12,31),date(2000,3,2),date(2000,5,1)]),(4,[date(1999,8,31),date(2000,3,2),date(2000,8,31)]),(5,[date(2000,2,29),date(2001,3,1),date(2002,3,1),date(2003,3,1)]),(2,[]),(2,[date(2000,1,31)]),(0,[]),(1,[date(2000,1,1)+timedelta(days=i//2) for i in range(5)]),(5,[date(y,1,1) for y in range(1951,1954)])]
expected=[];summary=[]
for periodic in [False,True]:
 for i,(kind,dates) in enumerate(cases):
  encoded_dates=[encoded(d)+(0x80000000 if i==7 and n%2 else 0) for n,d in enumerate(dates)]
  if periodic:encoded_dates=encoded_dates[1:]
  expected.extend([i,kind,int(periodic),len(encoded_dates)])
  for d in encoded_dates:expected.extend([d,0 if periodic else 4,0,0x4059000000000000,0 if periodic else 15,1,1])
  summary.append(dict(id=i,kind=kind,periodic=periodic,dates=[hex(d) for d in encoded_dates]))
def verify(data):
 want=struct.pack('<'+'Q'*len(expected),*expected)
 if data!=want:
  got=struct.unpack('<'+'Q'*(len(data)//8),data)
  diff=[(i,a,b) for i,(a,b) in enumerate(zip(got,expected)) if a!=b]
  raise ValueError({'actual_words':len(got),'expected_words':len(expected),'differences':diff[:20]})
 return summary

ROOT=Path(__file__).resolve().parents[1]
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
def main():
 ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('disk',type=Path,nargs='?');ap.add_argument('--reference',type=Path);ap.add_argument('--out',type=Path,required=True);a=ap.parse_args();out=a.out.resolve()
 if out.exists():ap.error('Use a fresh output directory')
 if a.disk and not a.reference:ap.error('Native requires --reference')
 fixture=ROOT/'tests/guest/i386-budget-boundaries/Contract.HC'
 paths=[Path(__file__).resolve(),fixture,ROOT/'docs/i386-compatibility-inventory.json',ROOT/'Kernel/FontStd.HC']+[ROOT/('tools/'+n) for n in ('test-i386-timeclock-reference.py','build-iso.py','guest-run.py','i386-budget-source.py','package-i386-native-image.py','build-i386-kernel.py','test-i386-autocomplete-interaction.py','test-i386-timeclock-welcome.py')]
 if a.disk:
  gold=a.reference.resolve();r=json.loads((gold/'result.json').read_text())
  if r.get('result')!='pass' or not r.get('inputs_unchanged') or r.get('fixture_sha256')!=sha(fixture):raise ValueError('Matching passing original required')
  paths += [a.disk.resolve(),gold/'result.json',gold/'boundaries.bin']
 out.mkdir(parents=True);pins={str(p):sha(p) for p in paths};(out/'fixture.HC').write_bytes(fixture.read_bytes());(out/'runner-source.py').write_bytes(Path(__file__).read_bytes())
 report=dict(result='running',fixture_sha256=sha(fixture),input_sha256=pins,scope='Direct original Budget expansion API, nine boundary schedules in template and periodic-copy modes: overflow day-of-month, leap day, reversed/equal ranges, Null, half-day interval and >2050 year mapping. Exact portable dates/type/flags/amount/string ownership/content/queue links; cleanup leaves entry queue empty. Constructed inputs, not real UI, persistent storage or heap profile.');guest=None
 try:
  if not a.disk:
   overlay=out/'overlay';overlay.mkdir();report['reference_sha256']=runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
   (overlay/'Once.HC').write_bytes(b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;\n#include "T:/Apps/Budget/Load.HC"\n'+fixture.read_bytes()+b'\nBoundaryContract;\n')
   image=out/'original.iso';subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(image)],cwd=ROOT,check=True);report['iso_sha256']=sha(image)
   subprocess.run(['python3','tools/guest-run.py',str(image),'--out',str(out/'guest'),'--qmp-stdio','--timeout','180'],cwd=ROOT,check=True)
  else:
   pack=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'));before=pack['snapshot'](a.disk.read_bytes())[1];source=runpy.run_path(str(ROOT/'tools/i386-budget-source.py'))['budget_source']
   for e in json.loads((ROOT/'docs/i386-compatibility-inventory.json').read_text())['entries']:
    if e['path'].startswith('Apps/Budget/') and before['/'+e['path']][2]!=source(e):raise ValueError('Budget source differs: '+e['path'])
   image=out/'working.img';report['packaging']=pack['package'](a.disk.resolve(),image,additions={'/Probe/BudgetBoundaries.HC':fixture.read_bytes()});initial=pack['snapshot'](image.read_bytes())[1]
   Guest=runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest'];guest=Guest(image,out/'guest',True);guest.wait('DONE native kernel startup\n')
   commands=['AdamFile("C:/Adam/AutoComplete/MakeAC.HC",FALSE);','AdamFile("C:/Adam/TaskSettings.HC",FALSE);','#include "C:/Apps/Budget/Load.HC"','#include "C:/Probe/BudgetBoundaries.HC"','BoundaryContract;','6*7;'];report['commands']=commands
   for c in commands:guest.command(c)
   guest.wait('DONE Budget boundaries\n');report['fresh_result']=guest.result_pixels();guest.close();guest=None
   if pack['snapshot'](image.read_bytes())[1]!=initial:raise ValueError('Boundary API changed filesystem bytes or metadata')
   report['files_unchanged']=True
  data=(out/'guest/boundaries.bin').read_bytes();report['cases']=verify(data);(out/'boundaries.bin').write_bytes(data)
  if a.disk and data!=(gold/'boundaries.bin').read_bytes():raise ValueError('Original/native expansion differs')
  report.update(result='pass',cases_checked=18,record_bytes=len(data))
 except Exception as exc:
  report.update(result='fail',error=str(exc))
  if a.disk and guest is not None and guest.p.poll() is None:
   try:
    guest.call('stop');guest.collect();(out/'failure-registers.txt').write_text(guest.call('human-monitor-command',**{'command-line':'info registers'}));guest.call('pmemsave',val=0,size=64*1024*1024,filename=str(out/'failure-memory.bin'));report['failure_capture']={n:sha(out/n) for n in ('failure-memory.bin','failure-registers.txt')}
   except Exception as err:report['capture_error']=str(err)
  raise
 finally:
  if guest is not None:guest.close()
  report['inputs_unchanged']=all(p.is_file() and sha(p)==pins[str(p)] for p in paths)
  if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
  (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
if __name__=='__main__':main()
