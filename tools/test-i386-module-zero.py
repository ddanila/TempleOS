#!/usr/bin/env python3
"""Compare source-module static initialization with original 386 AOT under poison controls."""
import argparse,hashlib,json,runpy,struct,subprocess
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def verify(data):
 _,count,records=struct.unpack_from('<III',data,16);exports={};ranges=[]
 for i in range(count):
  k,o,n,l=struct.unpack_from('<4I',data,records+16*i)
  if k==3:exports[data[n:n+l].decode()]=o
  if k==4:ranges.append((o,n))
 sizes={}
 for name in ('zi_byte','zi_integer','zi_pointer','zi_callback','zi_array','zi_record','zi_initialized_array','zi_explicit'):
  o=exports[name];span=next(n for start,n in ranges if start==o);raw=data[32+o:32+o+span];sizes[name]=span
  expected=bytes(span)
  if name=='zi_initialized_array':expected=bytes([7,9])+bytes(6);assert span==8
  if name=='zi_explicit':expected=struct.pack('<q',0x123456789abcdef);assert span==8
  assert raw==expected,(name,raw.hex(),expected.hex())
 assert sizes['zi_byte']==1 and sizes['zi_integer']==8 and sizes['zi_pointer']==sizes['zi_callback']==4 and sizes['zi_array']==37 and sizes['zi_record']==9
 return sizes
def main():
 ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('disk',nargs='?',type=Path);ap.add_argument('--out',required=True,type=Path);a=ap.parse_args();out=a.out.resolve()
 if out.exists():ap.error('Use a fresh output directory')
 fixture=ROOT/'tests/guest/i386-module-zero';paths=[Path(__file__).resolve(),*sorted(fixture.glob('*.HC'))]+[ROOT/('tools/'+n) for n in ('package-i386-native-image.py','test-i386-autocomplete-interaction.py','test-i386-timeclock-welcome.py','build-iso.py','guest-run.py','build-i386-kernel.py')]
 if a.disk:paths.append(a.disk.resolve())
 else:
  bootstrap=ROOT/'build/rebuild-test';manifest=json.loads((bootstrap/'result.json').read_text());assert manifest['result']=='pass';paths.append(bootstrap/'result.json')
  for name,rel in [('Compiler.BIN','Compiler/Compiler.BIN'),('Kernel.BIN','0000Boot/0000Kernel.BIN.C')]:
   p=bootstrap/'overlay'/rel;assert hashlib.sha256(p.read_bytes()).hexdigest()==manifest['generations'][-1][name];paths.append(p)
 sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();pins={str(p):sha(p) for p in paths};out.mkdir();(out/'runner-source.py').write_bytes(Path(__file__).read_bytes());g=None;r=dict(result='running',native=bool(a.disk),input_sha256=pins,scope='AOT/source-unit zero byte/integer/pointers/callback/array/record and explicit array initializer under enabled A5 JIT poison controls; explicit initialized scalar, control restoration, fresh42 and preserved prior native files. Not every storage class, failure or full C1-C5.')
 try:
  if a.disk:
   pack=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'));image=out/'working.img';pack['package'](a.disk.resolve(),image,additions={'/Probe/ZeroModule.HC':(fixture/'Module.HC').read_bytes(),'/Probe/ZeroContract.HC':(fixture/'Contract.HC').read_bytes()});before=pack['snapshot'](image.read_bytes())[1]
   Guest=runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest'];g=Guest(image,out/'guest',True);g.wait('DONE native kernel startup\n');g.command('#include "/Kernel/I386/PublicUser.HH"');g.command('#include "C:/Probe/ZeroContract.HC"');g.command('ZIProbe;',timeout=300);g.wait('MODULE ZERO DONE\n')
   (out/'module-zero-values.bin').write_bytes((g.out/'module-zero-values.bin').read_bytes());g.command('6*7;');r['fresh_result']=g.result_pixels();g.close();g=None
   after=pack['snapshot'](image.read_bytes())[1];assert all(after.get(n)==v for n,v in before.items());assert set(after)-set(before)<={'/Probe/ZeroModule.t32m'};r['prior_files_unchanged']=True
   if '/Probe/ZeroModule.t32m' in after:(out/'module-zero.t32m').write_bytes(after['/Probe/ZeroModule.t32m'][2])
  else:
   image=out/'original.iso';subprocess.run(['python3','tools/build-iso.py','--overlay',str(bootstrap/'overlay'),'--overlay',str(fixture),'--output',str(image)],cwd=ROOT,check=True)
   subprocess.run(['python3','tools/guest-run.py',str(image),'--qmp-stdio','--out',str(out/'guest'),'--timeout','180'],cwd=ROOT,check=True)
   for n in ('module-zero-values.bin','module-zero.t32m'):
    if (out/'guest'/n).exists():(out/n).write_bytes((out/'guest'/n).read_bytes())
  values=list(struct.unpack('<4q',(out/'module-zero-values.bin').read_bytes()));r['values']=values;assert values[0]>32 and values[3]==1,values
  r['storage_sizes']=verify((out/'module-zero.t32m').read_bytes());r['result']='pass'
 except Exception as e:r.update(result='fail',error=str(e));raise
 finally:
  if g:g.close()
  r['inputs_unchanged']=all(p.is_file() and sha(p)==pins[str(p)] for p in paths)
  if not r['inputs_unchanged']:r.update(result='fail',error='Inputs changed')
  (out/'result.json').write_text(json.dumps(r,indent=2)+'\n')
if __name__=='__main__':main()
