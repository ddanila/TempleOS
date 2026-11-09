#!/usr/bin/env python3
"""Compare original MsSet defaults, coordinates, grid, synthetic buttons and physical follow-up."""
import argparse,hashlib,json,runpy,struct,subprocess,time
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
MOVES={12:(4,6),13:(6,-4)}
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
def verify(out,reference=None):
 raw=(out/'set-rows.bin').read_bytes()
 if len(raw)!=16*2*17*8:raise ValueError('MsSet row count differs')
 rows=list(struct.iter_unpack('<17q',raw))
 keys=(out/'set-key-bits.bin').read_bytes()
 if keys!=b''.join(struct.pack('<2q',*rows[2*p+1][12:14]) for p in range(16)):raise ValueError('Delivered key button bits differ from settled public mouse state')
 if reference and keys!=(reference/'set-key-bits.bin').read_bytes():raise ValueError('Delivered key button bits differ from original')
 if (out/'set-mask.bin').read_bytes()!=struct.pack('<q',7):raise ValueError('MsSet restoration mask differs')
 if reference and raw!=(reference/'set-rows.bin').read_bytes():
  gold=list(struct.iter_unpack('<17q',(reference/'set-rows.bin').read_bytes()));bad=[i for i,(a,b) in enumerate(zip(rows,gold)) if a!=b];raise ValueError('MsSet state differs at rows '+repr(bad))
 return rows

def main():
 ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('disk',type=Path,nargs='?');ap.add_argument('--reference',type=Path);ap.add_argument('--out',type=Path,required=True);a=ap.parse_args();out=a.out.resolve()
 if out.exists():ap.error('Use a fresh output directory')
 if a.disk and not a.reference:ap.error('Native requires passing original reference')
 fixture=ROOT/'tests/guest/i386-mouse-set/Contract.HC';paths=[fixture,Path(__file__).resolve(),ROOT/'Kernel/FontStd.HC']+[ROOT/('tools/'+n) for n in ['build-iso.py','test-i386-timeclock-reference.py','test-i386-autocomplete-interaction.py','test-i386-timeclock-welcome.py','package-i386-native-image.py','build-i386-kernel.py']]
 if a.disk:
  ref=json.loads((a.reference/'result.json').read_text());assert ref['result']=='pass' and ref['inputs_unchanged'] and ref['fixture_sha256']==sha(fixture);verify(a.reference)
  paths += [a.disk.resolve(),a.reference/'result.json']+[a.reference/n for n in ['set-rows.bin','set-mask.bin','set-key-bits.bin']]
 out.mkdir();pins={str(p):sha(p) for p in paths};(out/'fixture.HC').write_bytes(fixture.read_bytes());(out/'runner-source.py').write_bytes(Path(__file__).read_bytes());g=None;events=[]
 report=dict(result='running',input_sha256=pins,fixture_sha256=sha(fixture),scope='Original MsSet immediate and settled public position/presnap/offset/text/button/key-scan state, defaults/invalid coordinates, scale/grid/speed quantization and physical movement/wheel/button follow-up; caller/heap restoration. Not full ms_hard, timing or C1-C5 qualification.')
 try:
  if a.disk:
   pack=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'));image=out/'working.img';report['packaging']=pack['package'](a.disk.resolve(),image,additions={'/Probe/MouseSet.HC':fixture.read_bytes()});before=pack['snapshot'](image.read_bytes())[1]
  else:
   overlay=out/'overlay';overlay.mkdir();report['reference_sha256']=runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
   (overlay/'Once.HC').write_bytes(b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;\n'+fixture.read_bytes()+b'\nMouseSetContract;\n');image=out/'original.iso';subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(image)],cwd=ROOT,check=True)
  Guest=runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest'];g=Guest(image,out/'guest',bool(a.disk))
  if a.disk:
   g.wait('DONE native kernel startup\n')
   for c in ['AdamFile("C:/Adam/AutoComplete/MakeAC.HC",FALSE);','AdamFile("C:/Adam/TaskSettings.HC",FALSE);','#include "C:/Probe/MouseSet.HC"']:g.command(c)
   g.type('MouseSetContract;');g.press('ret')
  for phase in range(16):
   g.wait(f'MT READY {phase}\n')
   if phase in MOVES:
    dx,dy=MOVES[phase];e=[{'type':'rel','data':{'axis':'x','value':dx}},{'type':'rel','data':{'axis':'y','value':dy}}];g.call('input-send-event',events=e);events.append(dict(phase=phase,events=e))
   if phase in (12,14):
    button='wheel-down' if phase==12 else 'left'
    for down in [True,False]:
     e=[{'type':'btn','data':{'button':button,'down':down}}];g.call('input-send-event',events=e);events.append(dict(phase=phase,events=e));time.sleep(.04)
   time.sleep(.6);g.press('n')
  g.wait('MT DONE\n')
  for n in ['set-rows.bin','set-mask.bin','set-key-bits.bin']:(out/n).write_bytes((g.out/n).read_bytes())
  report.update(rows=verify(out,a.reference if a.disk else None),mask=7,delivered_key_button_values=32)
  if a.disk:g.command('6*7;');report['fresh_result']=g.result_pixels()
  g.close();g=None
  if a.disk:
   assert pack['snapshot'](image.read_bytes())[1]==before;report['files_unchanged']=True
  report['result']='pass'
 except Exception as exc:report.update(result='fail',error=str(exc));raise
 finally:
  if g:g.close()
  (out/'set-events.json').write_text(json.dumps(events,indent=2)+'\n');report['inputs_unchanged']=all(p.is_file() and sha(p)==h for p,h in ((Path(n),h) for n,h in pins.items()))
  if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
  (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
if __name__=='__main__':main()
