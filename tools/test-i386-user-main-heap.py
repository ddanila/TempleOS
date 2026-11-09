#!/usr/bin/env python3
"""Measure native main-heap bytes/allocations across actual User lifetimes."""
import argparse,hashlib,json,runpy,struct
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def main():
 ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('disk',type=Path);ap.add_argument('--out',required=True,type=Path);a=ap.parse_args();out=a.out.resolve()
 if out.exists():ap.error('Use a fresh output directory')
 fixture=ROOT/'tests/guest/i386-user-main-heap/Contract.HC';inputs=[a.disk.resolve(),fixture,Path(__file__).resolve()]+[ROOT/('tools/'+n) for n in ['test-i386-autocomplete-interaction.py','test-i386-timeclock-welcome.py','package-i386-native-image.py','build-i386-kernel.py']]+[ROOT/'Kernel/FontStd.HC',ROOT/'Kernel/I386/Scheduler.HH',ROOT/'Kernel/I386/Heap.HH']
 sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();out.mkdir();pins={str(p):sha(p) for p in inputs};(out/'fixture.HC').write_bytes(fixture.read_bytes());(out/'runner-source.py').write_bytes(Path(__file__).read_bytes());g=None
 report=dict(result='running',input_sha256=pins,scope='Native physical main-heap bytes and allocation counts across two warm and three measured actual User create/Kill cycles; caller data/code sizes recorded. No arbitrary callbacks/legacy view/all-resource/C1-C5 qualification.')
 try:
  pack=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'));image=out/'working.img';report['packaging']=pack['package'](a.disk.resolve(),image,additions={'/Probe/UserMainHeap.HC':fixture.read_bytes()+b'\nUMProbe;\n'});before=pack['snapshot'](image.read_bytes())[1]
  g=runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest'](image,out/'guest',True);g.wait('DONE native kernel startup\n');g.command('#include "C:/Probe/UserMainHeap.HC"',timeout=300);g.wait('USER MAIN HEAP DONE\n');text=g.collect()
  raw=(g.out/'user-main-heap.bin').read_bytes();(out/'user-main-heap.bin').write_bytes(raw);values=struct.unpack('<24q',raw);report['values']=values;report['live_deltas']=[values[i+2]-values[i] for i in (0,8,16)]
  if 'USER MAIN HEAP MASK 63\n' not in text or any(values[i]!=values[i+4] or values[i+1]!=values[i+5] for i in (0,8,16)):raise ValueError('Main heap does not restore exactly')
  g.command('6*7;');report['fresh_result']=g.result_pixels();g.close();g=None
  if pack['snapshot'](image.read_bytes())[1]!=before:raise ValueError('Files changed')
  report.update(result='pass',files_unchanged=True)
 except Exception as exc:report.update(result='fail',error=str(exc));raise
 finally:
  if g:g.close()
  report['inputs_unchanged']=all(sha(Path(p))==h for p,h in pins.items())
  if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
  (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
if __name__=='__main__':main()
