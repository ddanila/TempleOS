#!/usr/bin/env python3
"""Compare real PS/2 wheel state, focus control priority and deferred inhibition."""
import argparse,hashlib,json,runpy,struct,subprocess,time
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
WHEEL=['wheel-down','wheel-up','wheel-up','wheel-down',None,'wheel-down',None,'wheel-down']
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
def verify(out):
 rows=list(struct.iter_unpack('<7q',(out/'wheel-rows.bin').read_bytes()));calls=list(struct.iter_unpack('<5q',(out/'wheel-calls.bin').read_bytes()))
 wanted=[(1,1,1,1,1,0,0),(0,1,2,0,-1,0,0),(-1,1,3,-1,-1,0,0),(0,1,3,-1,-1,1,0),(0,1,4,0,1,0,0),(1,1,4,0,1,0,1),(1,1,5,1,1,0,0),(2,1,6,2,1,0,0)]
 expected=[(p,d,1,1,1) for p,d in [(0,1),(1,-1),(2,-1),(4,1),(6,1),(7,1)]]
 if rows!=wanted or calls!=expected or (out/'wheel-mask.bin').read_bytes()!=struct.pack('<q',15):raise ValueError('Wheel state/callback/inhibition/restoration differs: '+repr((rows,calls)))
 return rows,calls

def main():
 ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('disk',type=Path,nargs='?');ap.add_argument('--reference',type=Path);ap.add_argument('--out',type=Path,required=True);a=ap.parse_args();out=a.out.resolve()
 if out.exists():ap.error('Use a fresh output directory')
 if a.disk and not a.reference:ap.error('Native requires passing original reference')
 fixture=ROOT/'tests/guest/i386-mouse-wheel/Contract.HC';paths=[fixture,Path(__file__).resolve(),ROOT/'Kernel/FontStd.HC']+[ROOT/('tools/'+n) for n in ['build-iso.py','test-i386-timeclock-reference.py','test-i386-autocomplete-interaction.py','test-i386-timeclock-welcome.py','package-i386-native-image.py','build-i386-kernel.py']]
 if a.disk:
  ref=json.loads((a.reference/'result.json').read_text());assert ref['result']=='pass' and ref['inputs_unchanged'] and ref['fixture_sha256']==sha(fixture);verify(a.reference)
  paths += [a.disk.resolve(),a.reference/'result.json']+[a.reference/n for n in ['wheel-rows.bin','wheel-calls.bin','wheel-mask.bin']]
 out.mkdir();pins={str(p):sha(p) for p in paths};(out/'fixture.HC').write_bytes(fixture.read_bytes());(out/'runner-source.py').write_bytes(Path(__file__).read_bytes());g=None;events=[]
 report=dict(result='running',input_sha256=pins,fixture_sha256=sha(fixture),scope='Physical wheel positive/negative z and callback deltas, focused first control outside its hit rectangle, self/focus control inhibition/deferred deltas, yielding callback owner/IRQ identity, caller/heap restoration. Not all windows/scrollbars/wheel settings or complete input qualification.')
 try:
  if a.disk:
   pack=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'));image=out/'working.img';report['packaging']=pack['package'](a.disk.resolve(),image,additions={'/Probe/MouseWheel.HC':fixture.read_bytes()});before=pack['snapshot'](image.read_bytes())[1]
  else:
   overlay=out/'overlay';overlay.mkdir();report['reference_sha256']=runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
   (overlay/'Once.HC').write_bytes(b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;\n'+fixture.read_bytes()+b'\nMouseWheelContract;\n');image=out/'original.iso';subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(image)],cwd=ROOT,check=True)
  Guest=runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest'];g=Guest(image,out/'guest',bool(a.disk))
  if a.disk:
   g.wait('DONE native kernel startup\n')
   for c in ['AdamFile("C:/Adam/AutoComplete/MakeAC.HC",FALSE);','AdamFile("C:/Adam/TaskSettings.HC",FALSE);','#include "C:/Probe/MouseWheel.HC"']:g.command(c)
   g.type('MouseWheelContract;');g.press('ret')
  for phase,button in enumerate(WHEEL):
   g.wait(f'WH READY {phase}\n')
   if button:
    for down in [True,False]:g.call('input-send-event',events=[{'type':'btn','data':{'button':button,'down':down}}]);events.append(dict(phase=phase,button=button,down=down));time.sleep(.04)
   time.sleep(.6);g.press('n')
  g.wait('WH DONE\n')
  for n in ['wheel-rows.bin','wheel-calls.bin','wheel-mask.bin']:(out/n).write_bytes((g.out/n).read_bytes())
  rows,calls=verify(out);report.update(rows=rows,calls=calls,mask=15)
  if a.disk:g.command('6*7;');report['fresh_result']=g.result_pixels()
  g.close();g=None
  if a.disk:
   assert pack['snapshot'](image.read_bytes())[1]==before;report['files_unchanged']=True
  report['result']='pass'
 except Exception as exc:report.update(result='fail',error=str(exc));raise
 finally:
  if g:g.close()
  (out/'wheel-events.json').write_text(json.dumps(events,indent=2)+'\n');report['inputs_unchanged']=all(p.is_file() and sha(p)==h for p,h in ((Path(n),h) for n,h in pins.items()))
  if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
  (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
if __name__=='__main__':main()
