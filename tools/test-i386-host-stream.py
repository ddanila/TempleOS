#!/usr/bin/env python3
"""Check host execution and target flag restoration in the x64-to-386 compiler."""
import argparse,hashlib,json,runpy,struct,subprocess
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def main():
 ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('--bootstrap',type=Path,default=ROOT/'build/rebuild-test');ap.add_argument('--out',type=Path,required=True);a=ap.parse_args();out=a.out.resolve();boot=a.bootstrap.resolve()
 if out.exists():ap.error('Use a fresh output directory')
 fixture=ROOT/'tests/guest/i386-host-stream/Once.HC';manifest=json.loads((boot/'result.json').read_text());assert manifest['result']=='pass'
 paths=[fixture,Path(__file__).resolve(),boot/'result.json',ROOT/'tools/build-iso.py',ROOT/'tools/guest-run.py']
 for name,rel in [('Compiler.BIN','Compiler/Compiler.BIN'),('Kernel.BIN','0000Boot/0000Kernel.BIN.C')]:
  p=boot/'overlay'/rel;assert hashlib.sha256(p.read_bytes()).hexdigest()==manifest['generations'][-1][name];paths.append(p)
 sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();out.mkdir();pins={str(p):sha(p) for p in paths};(out/'fixture.HC').write_bytes(fixture.read_bytes());(out/'runner-source.py').write_bytes(Path(__file__).read_bytes());r=dict(result='running',input_sha256=pins,bootstrap_revision=manifest['revision'],scope='x64 compiler executes 386 AOT #exe against host symbols/width, resumes 32-bit target layout, restores both target flags after a thrown stream, and emits an identical module after recovery.')
 try:
  iso=out/'original.iso';subprocess.run(['python3','tools/build-iso.py','--overlay',str(boot/'overlay'),'--overlay',str(fixture.parent),'--output',str(iso)],check=True,cwd=ROOT)
  subprocess.run(['python3','tools/guest-run.py',str(iso),'--qmp-stdio','--out',str(out/'guest'),'--timeout','180'],check=True,cwd=ROOT)
  mask=struct.unpack('<q',(out/'guest/host-stream-mask.bin').read_bytes())[0];r['mask']=mask;assert mask==31,mask
  module=(out/'guest/host-stream.t32m').read_bytes();_,count,records=struct.unpack_from('<III',module,16);exports={};ranges=[]
  for i in range(count):
   k,o,n,l=struct.unpack_from('<4I',module,records+i*16)
   if k in (1,3):exports[module[n:n+l].decode()]=(k,o)
   if k==4:ranges.append((o,n))
  assert exports['HSHostSize'][0]==exports['HSTargetPointer'][0]==3 and exports['HSTargetSize'][0]==1
  hs=exports['HSHostSize'][1];ptr=exports['HSTargetPointer'][1]
  assert struct.unpack_from('<q',module,32+hs)[0]==8
  assert struct.unpack_from('<q',module,32+exports['HSHostCall'][1])[0]==6
  assert (hs,8) in ranges and (ptr,4) in ranges and module[32+ptr:36+ptr]==bytes(4)
  r.update(result='pass',host_pointer_bytes=8,target_pointer_bytes=4,module_sha256=hashlib.sha256(module).hexdigest())
 except Exception as e:r.update(result='fail',error=str(e));raise
 finally:
  r['inputs_unchanged']=all(p.is_file() and sha(p)==pins[str(p)] for p in paths)
  if not r['inputs_unchanged']:r.update(result='fail',error='Inputs changed')
  (out/'result.json').write_text(json.dumps(r,indent=2)+'\n')
if __name__=='__main__':main()
