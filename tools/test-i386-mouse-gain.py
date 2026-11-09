#!/usr/bin/env python3
"""Compare real PS/2 logical gain, odd counts, full reach and edge reversal."""
import argparse,hashlib,json,runpy,struct,subprocess,time
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
# All individual events fit standard signed three-byte motion. No feedback or
# synthetic coordinate assignment: the original and native receive the same deltas.
MOVES=[(40,20),(1,1),(1,1),(-1,-1),(-1,-1),(-40,-20)]+[(100,0)]*8+[(-1,0),(-1,0),(-16,0)]+[(0,100)]*6+[(0,-1),(0,-1),(0,-16)]+[(-100,-100)]*14+[(-6,0),(6,0)]+[(1,1),(1,1),(16,16)]+[(100,100)]*10+[(-1,-1),(-1,-1),(-16,-16)]+[(8,4),(1,1),(-1,-1),(-8,-4)]
assert len(MOVES)<=64
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
def verify(out,reference=None):
 raw=(out/'gain-rows.bin').read_bytes()
 if len(raw)!=len(MOVES)*96:raise ValueError('Gain records length differs')
 rows=list(struct.iter_unpack('<12q',raw))
 for i,r in enumerate(rows):
  if (out/f'gain-step-{i}.bin').read_bytes()!=raw[i*96:(i+1)*96]:raise ValueError('Gain per-step export differs')
  if not 0<=r[0]<640 or not 0<=r[1]<480 or (r[6],r[7])!=(r[0]//8,r[1]//8) or r[11]:raise ValueError('Invalid gain/button/text state')
 if reference is not None:
  wanted=(reference/'gain-rows.bin').read_bytes()
  if raw!=wanted:
   gold=list(struct.iter_unpack('<12q',wanted));bad=[i for i,(a,b) in enumerate(zip(rows,gold)) if a!=b]
   raise ValueError('Logical mouse differs at phases '+repr(bad))
 return rows

def main():
 ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('disk',type=Path,nargs='?');ap.add_argument('--reference',type=Path);ap.add_argument('--out',type=Path,required=True);a=ap.parse_args();out=a.out.resolve()
 if out.exists():ap.error('Use a fresh output directory')
 if a.disk and not a.reference:ap.error('Native requires passing original reference')
 fixture=ROOT/'tests/guest/i386-mouse-gain/Contract.HC';paths=[fixture,Path(__file__).resolve(),ROOT/'Kernel/FontStd.HC']+[ROOT/('tools/'+n) for n in ['build-iso.py','test-i386-timeclock-reference.py','test-i386-autocomplete-interaction.py','test-i386-timeclock-welcome.py','package-i386-native-image.py','build-i386-kernel.py']]
 if a.disk:
  rr=json.loads((a.reference/'result.json').read_text())
  if rr['result']!='pass' or not rr['inputs_unchanged'] or rr['fixture_sha256']!=sha(fixture):raise ValueError('Matching original required')
  verify(a.reference);paths += [a.disk.resolve(),a.reference/'result.json',a.reference/'gain-rows.bin']
 out.mkdir();pins={str(p):sha(p) for p in paths};(out/'fixture.HC').write_bytes(fixture.read_bytes());(out/'runner-source.py').write_bytes(Path(__file__).read_bytes());g=None
 report=dict(result='running',input_sha256=pins,fixture_sha256=sha(fixture),moves=MOVES,scope='Identical physical relative moves; original/native logical position/presnap/offset/text coordinates, odd counts, horizontal/vertical edges and reverse motion, public scale/grid interaction. Not wheel, ms_hard API, timestamp/speed parity, arbitrary bursts, full pointer raster or complete C1-C5 qualification.')
 try:
  invocation=f'MouseGainContract({len(MOVES)});'
  if a.disk:
   pack=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'));image=out/'working.img';report['packaging']=pack['package'](a.disk.resolve(),image,additions={'/Probe/MouseGain.HC':fixture.read_bytes()});before=pack['snapshot'](image.read_bytes())[1]
  else:
   overlay=out/'overlay';overlay.mkdir();report['reference_sha256']=runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
   (overlay/'Once.HC').write_bytes(b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;\n'+fixture.read_bytes()+b'\n'+invocation.encode()+b'\n')
   image=out/'original.iso';subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(image)],cwd=ROOT,check=True)
  Guest=runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest'];g=Guest(image,out/'guest',bool(a.disk))
  if a.disk:
   g.wait('DONE native kernel startup\n');g.command('AdamFile("C:/Adam/AutoComplete/MakeAC.HC",FALSE);');g.command('#include "C:/Probe/MouseGain.HC"');g.type(invocation);g.press('ret')
  for phase,(dx,dy) in enumerate(MOVES):
   g.wait(f'MG READY {phase}\n');g.call('input-send-event',events=[{'type':'rel','data':{'axis':'x','value':dx}},{'type':'rel','data':{'axis':'y','value':dy}}]);time.sleep(.3);g.press('n');g.wait(f'MG READY {phase+1}\n' if phase+1<len(MOVES) else 'MG DONE\n')
   (out/f'gain-step-{phase}.bin').write_bytes((g.out/f'gain-step-{phase}.bin').read_bytes())
  g.wait('MG DONE\n');(out/'gain-rows.bin').write_bytes((g.out/'gain-rows.bin').read_bytes())
  report['rows']=verify(out,a.reference if a.disk else None)
  if a.disk:g.command('6*7;');report['fresh_result']=g.result_pixels()
  g.close();g=None
  if a.disk:
   if pack['snapshot'](image.read_bytes())[1]!=before:raise ValueError('Gain contract changed files/metadata')
   report['files_unchanged']=True
  report['result']='pass'
 except Exception as exc:report.update(result='fail',error=str(exc));raise
 finally:
  if g:g.close()
  report['inputs_unchanged']=all(p.is_file() and sha(p)==h for p,h in ((Path(n),h) for n,h in pins.items()))
  if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
  (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
if __name__=='__main__':main()
