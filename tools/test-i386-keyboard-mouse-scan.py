#!/usr/bin/env python3
"""Compare full keyboard scans/public state under synthetic and physical mouse buttons."""
import argparse,hashlib,json,runpy,struct,subprocess,time
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
def verify(out,reference=None):
 rows=list(struct.iter_unpack('<5q',(out/'keyboard-mouse-scan.bin').read_bytes()))
 expected=[]
 for phase in range(8):
  buttons=phase%4;flags=((buttons&1)<<16)|((buttons&2)<<16)
  for index in range(2):
   half=0x1e|(index<<8)|flags;scan=half|(half<<32)
   expected.append((2+index,97,scan,scan,buttons))
 if rows!=expected or (out/'keyboard-mouse-mask.bin').read_bytes()!=struct.pack('<q',7):raise ValueError('Full scan/public state/button/restoration differs: '+repr(rows))
 if reference and any((out/n).read_bytes()!=(reference/n).read_bytes() for n in ['keyboard-mouse-scan.bin','keyboard-mouse-mask.bin']):raise ValueError('Original scan state differs')
 return rows

def main():
 ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('disk',type=Path,nargs='?');ap.add_argument('--reference',type=Path);ap.add_argument('--out',type=Path,required=True);a=ap.parse_args();out=a.out.resolve()
 if out.exists():ap.error('Use a fresh output directory')
 if a.disk and not a.reference:ap.error('Native requires a passing original reference')
 fixture=ROOT/'tests/guest/i386-keyboard-mouse-scan/Contract.HC';paths=[fixture,Path(__file__).resolve(),ROOT/'Kernel/FontStd.HC']+[ROOT/('tools/'+n) for n in ['build-iso.py','test-i386-timeclock-reference.py','test-i386-autocomplete-interaction.py','test-i386-timeclock-welcome.py','package-i386-native-image.py','build-i386-kernel.py']]
 if a.disk:
  ref=json.loads((a.reference/'result.json').read_text());assert ref['result']=='pass' and ref['inputs_unchanged'] and ref['fixture_sha256']==sha(fixture);verify(a.reference)
  paths += [a.disk.resolve(),a.reference/'result.json',a.reference/'keyboard-mouse-scan.bin',a.reference/'keyboard-mouse-mask.bin']
 out.mkdir();pins={str(p):sha(p) for p in paths};(out/'fixture.HC').write_bytes(fixture.read_bytes());(out/'runner-source.py').write_bytes(Path(__file__).read_bytes());g=None;events=[]
 report=dict(result='running',input_sha256=pins,fixture_sha256=sha(fixture),scope='Real key down/up under all four synthetic and all four physical button combinations; exact 64-bit delivered and public keyboard scans, logical buttons, IF/caller/heap restoration. Not all keys, pending input/loss/focus permutations, MsgLoop or full C1-C5.')
 try:
  if a.disk:
   pack=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'));image=out/'working.img';report['packaging']=pack['package'](a.disk.resolve(),image,additions={'/Probe/KeyboardMouseScan.HC':fixture.read_bytes()});before=pack['snapshot'](image.read_bytes())[1]
  else:
   overlay=out/'overlay';overlay.mkdir();report['reference_sha256']=runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
   (overlay/'Once.HC').write_bytes(b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;\n'+fixture.read_bytes()+b'\nKeyboardMouseScan;\n');image=out/'original.iso';subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(image)],cwd=ROOT,check=True)
  Guest=runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest'];g=Guest(image,out/'guest',bool(a.disk))
  if a.disk:
   g.wait('DONE native kernel startup\n')
   for c in ['AdamFile("C:/Adam/AutoComplete/MakeAC.HC",FALSE);','AdamFile("C:/Adam/TaskSettings.HC",FALSE);','#include "C:/Probe/KeyboardMouseScan.HC"']:g.command(c)
   g.type('KeyboardMouseScan;');g.press('ret')
  def buttons(value):
   e=[{'type':'btn','data':{'button':b,'down':bool(value&(1<<i))}} for i,b in enumerate(['left','right'])];g.call('input-send-event',events=e);events.append(dict(buttons=value,events=e));time.sleep(.6)
  for phase in range(8):
   g.wait(f'KM READY {phase}\n')
   if phase>=4:buttons(phase%4)
   g.key('a',True);events.append(dict(phase=phase,key='a',down=True));g.wait(f'KM KEY {phase} 0\n')
   g.key('a',False);events.append(dict(phase=phase,key='a',down=False));g.wait(f'KM KEY {phase} 1\n')
  g.wait('KM RELEASE\n');buttons(0);g.press('q');g.wait('KM DONE\n')
  for n in ['keyboard-mouse-scan.bin','keyboard-mouse-mask.bin']:(out/n).write_bytes((g.out/n).read_bytes())
  report.update(rows=verify(out,a.reference if a.disk else None),mask=7)
  if a.disk:g.command('6*7;');report['fresh_result']=g.result_pixels()
  g.close();g=None
  if a.disk:assert pack['snapshot'](image.read_bytes())[1]==before;report['files_unchanged']=True
  report['result']='pass'
 except Exception as exc:report.update(result='fail',error=str(exc));raise
 finally:
  if g:g.close()
  (out/'events.json').write_text(json.dumps(events,indent=2)+'\n');report['inputs_unchanged']=all(p.is_file() and sha(p)==h for p,h in ((Path(n),h) for n,h in pins.items()))
  if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
  (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
if __name__=='__main__':main()
