#!/usr/bin/env python3
"""Compare original MsSet mouse messages in managed and raw focused tasks."""
import argparse,hashlib,json,runpy,struct,subprocess,time
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
def verify(out,raw=False,reference=None):
 rows=list(struct.iter_unpack('<3q',(out/'set-message-rows.bin').read_bytes()));calls=list(struct.iter_unpack('<4q',(out/'set-message-calls.bin').read_bytes()))
 wanted=[(1,0,0),(2,1,0),(3,0,0),(4,0,1),(5,0,0),(5,0,0),(5,0,0),(6,0,0)]
 expected=[(p,c,80,96) for p,c in [(0,4),(1,5),(2,6),(3,9),(4,10)]]+[(7,4,96,120)]
 if rows!=wanted or calls!=expected or (out/'set-message-mask.bin').read_bytes()!=struct.pack('<q',7) or (out/'set-message-mode.bin').read_bytes()!=struct.pack('<2q',int(raw),int(raw)):raise ValueError('Synthetic mouse messages/state/mode/restoration differ: '+repr((rows,calls)))
 if reference and any((out/n).read_bytes()!=(reference/n).read_bytes() for n in ['set-message-rows.bin','set-message-calls.bin','set-message-mask.bin','set-message-mode.bin']):raise ValueError('Synthetic message reference differs')
 return rows,calls

def main():
 ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('disk',type=Path,nargs='?');ap.add_argument('--reference',type=Path);ap.add_argument('--raw',action='store_true');ap.add_argument('--out',type=Path,required=True);a=ap.parse_args();out=a.out.resolve()
 if out.exists():ap.error('Use a fresh output directory')
 if a.disk and not a.reference:ap.error('Native requires passing original reference')
 fixture=ROOT/'tests/guest/i386-mouse-set-messages/Contract.HC';paths=[fixture,Path(__file__).resolve(),ROOT/'Kernel/FontStd.HC']+[ROOT/('tools/'+n) for n in ['build-iso.py','test-i386-timeclock-reference.py','test-i386-autocomplete-interaction.py','test-i386-timeclock-welcome.py','package-i386-native-image.py','build-i386-kernel.py']]
 if a.disk:
  ref=json.loads((a.reference/'result.json').read_text());assert ref['result']=='pass' and ref['inputs_unchanged'] and ref['fixture_sha256']==sha(fixture);verify(a.reference,a.raw)
  paths += [a.disk.resolve(),a.reference/'result.json']+[a.reference/n for n in ['set-message-rows.bin','set-message-calls.bin','set-message-mask.bin','set-message-mode.bin']]
 out.mkdir();pins={str(p):sha(p) for p in paths};(out/'fixture.HC').write_bytes(fixture.read_bytes());(out/'runner-source.py').write_bytes(Path(__file__).read_bytes());g=None;events=[]
 report=dict(result='running',input_sha256=pins,fixture_sha256=sha(fixture),raw=a.raw,scope='MsSet-generated public mouse messages, default/no-op and transient set/reset, window coordinates, managed/raw requested and actual mode, IRQ/caller/heap restoration. No physical mouse events. Not all messages, controls or C1-C5 qualification.')
 try:
  if a.disk:
   pack=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'));image=out/'working.img';report['packaging']=pack['package'](a.disk.resolve(),image,additions={'/Probe/MouseSetMessages.HC':fixture.read_bytes()});before=pack['snapshot'](image.read_bytes())[1]
  else:
   overlay=out/'overlay';overlay.mkdir();report['reference_sha256']=runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
   (overlay/'Once.HC').write_bytes(b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;\n'+fixture.read_bytes()+f'\nMouseSetMessages({int(a.raw)});\n'.encode());image=out/'original.iso';subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(image)],cwd=ROOT,check=True)
  Guest=runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest'];g=Guest(image,out/'guest',bool(a.disk))
  if a.disk:
   g.wait('DONE native kernel startup\n')
   for c in ['AdamFile("C:/Adam/AutoComplete/MakeAC.HC",FALSE);','AdamFile("C:/Adam/TaskSettings.HC",FALSE);','#include "C:/Probe/MouseSetMessages.HC"']:g.command(c)
   g.type(f'MouseSetMessages({int(a.raw)});');g.press('ret')
  for phase in range(8):
   g.wait(f'MM READY {phase}\n');events.append(dict(phase=phase,key='n'));g.press('n')
  g.wait('MM DONE\n')
  for n in ['set-message-rows.bin','set-message-calls.bin','set-message-mask.bin','set-message-mode.bin']:(out/n).write_bytes((g.out/n).read_bytes())
  rows,calls=verify(out,a.raw,a.reference if a.disk else None);report.update(rows=rows,calls=calls,mask=7)
  if a.disk:g.command('6*7;');report['fresh_result']=g.result_pixels()
  g.close();g=None
  if a.disk:
   assert pack['snapshot'](image.read_bytes())[1]==before;report['files_unchanged']=True
  report['result']='pass'
 except Exception as exc:report.update(result='fail',error=str(exc));raise
 finally:
  if g:g.close()
  (out/'set-message-events.json').write_text(json.dumps(events,indent=2)+'\n');report['inputs_unchanged']=all(p.is_file() and sha(p)==h for p,h in ((Path(n),h) for n,h in pins.items()))
  if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
  (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
if __name__=='__main__':main()
