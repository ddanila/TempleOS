#!/usr/bin/env python3
"""Check the fixed mouse packet queue's coalescing, edges, order, wrap and overflow."""
import argparse,hashlib,json,runpy,struct
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
def main():
 ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('disk',type=Path);ap.add_argument('--out',type=Path,required=True);a=ap.parse_args();out=a.out.resolve()
 if out.exists():ap.error('Use a fresh output directory')
 fixture=ROOT/'tests/guest/i386-mouse-event-queue/Contract.HC';core=ROOT/'Kernel/I386/MouseEventQueue.HC'
 paths=[a.disk.resolve(),fixture,core,Path(__file__).resolve(),ROOT/'Kernel/FontStd.HC']+[ROOT/('tools/'+n) for n in ('package-i386-native-image.py','build-i386-kernel.py','test-i386-autocomplete-interaction.py','test-i386-timeclock-welcome.py')]
 out.mkdir();pins={str(p):sha(p) for p in paths};(out/'fixture.HC').write_bytes(fixture.read_bytes());(out/'core.HC').write_bytes(core.read_bytes());(out/'runner-source.py').write_bytes(Path(__file__).read_bytes());guest=None
 report=dict(result='running',input_sha256=pins,scope='Exact queue implementation compiled with private probe names: empty pop preserves output, motion coalesces, press position/time retained, both-button edges ordered, 200 wrap cycles, 64-edge capacity/overflow reset, guard bytes and no task heap allocation. Not IRQ integration, mouse timing or whole input qualification.')
 try:
  pack=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'));before=pack['snapshot'](a.disk.read_bytes())[1]
  compiled=core.read_text()
  for old,new in [('CI386MouseEvents','CMouseQueueProbeEvents'),('CI386MouseEvent','CMouseQueueProbeEvent'),('I386MouseEventPush','MouseQueueProbePush'),('I386MouseEventPop','MouseQueueProbePop')]:compiled=compiled.replace(old,new)
  (out/'compiled-core.HC').write_text(compiled)
  additions={'/Probe/MouseQueue.HC':fixture.read_bytes(),'/Probe/MouseQueueCore.HC':compiled.encode()};name='/Kernel/I386/MouseEventQueue.HC'
  if name in before:
   if before[name][2]!=core.read_bytes():raise ValueError('Delivered queue source differs')
  else:additions[name]=core.read_bytes()
  image=out/'working.img';report['packaging']=pack['package'](a.disk.resolve(),image,additions=additions);initial_files=pack['snapshot'](image.read_bytes())[1]
  Guest=runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest'];guest=Guest(image,out/'guest',True);guest.wait('DONE native kernel startup\n');guest.command('#include "C:/Probe/MouseQueue.HC"');guest.command('MouseQueueContract;')
  raw=(out/'guest/queue-mask.bin').read_bytes();(out/'queue-mask.bin').write_bytes(raw)
  initial_mouse=(out/'guest/initial-mouse.bin').read_bytes();(out/'initial-mouse.bin').write_bytes(initial_mouse)
  if raw!=struct.pack('<q',1023):raise ValueError('Mouse queue contract differs: '+repr(struct.unpack('<q',raw)))
  if initial_mouse!=struct.pack('<5q',320,240,0,320,240):raise ValueError('Initial logical/hardware mouse state differs')
  guest.command('6*7;');report['fresh_result']=guest.result_pixels();guest.close();guest=None
  if pack['snapshot'](image.read_bytes())[1]!=initial_files:raise ValueError('Queue contract changed files/metadata')
  report.update(result='pass',mask=1023,files_unchanged=True)
 except Exception as exc:
  report.update(result='fail',error=str(exc));raise
 finally:
  if guest is not None:guest.close()
  report['inputs_unchanged']=all(p.is_file() and sha(p)==pins[str(p)] for p in paths)
  if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
  (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
if __name__=='__main__':main()
