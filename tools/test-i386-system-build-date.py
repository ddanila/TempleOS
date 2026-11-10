#!/usr/bin/env python3
"""Verify the public kernel build date against the actual linked image metadata."""
import argparse,hashlib,json,runpy,struct
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def main():
 ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('disk',type=Path);ap.add_argument('--native-kernel',action='store_true',help='Build the kernel twice natively at128MiB and compare all bytes except its fresh build date');ap.add_argument('--out',required=True,type=Path);a=ap.parse_args()
 disk=a.disk.resolve();out=a.out.resolve()
 if out.exists():ap.error('Use a fresh output directory')
 fixture=ROOT/'tests/guest/i386-system-build-date/Contract.HC';module=disk.parent/'exports/Kernel.t32m';flat=disk.parent/'exports/Kernel32.BIN'
 paths=[disk,fixture,module,flat,Path(__file__).resolve()]+[ROOT/('tools/'+n) for n in ('package-i386-native-image.py','test-i386-autocomplete-interaction.py','test-i386-timeclock-welcome.py','gen-i386-date.py')]
 sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();pins={str(p):sha(p) for p in paths};out.mkdir();(out/'runner-source.py').write_bytes(Path(__file__).read_bytes());(out/'fixture.HC').write_bytes(fixture.read_bytes());r=dict(result='running',native_kernel=a.native_kernel,input_sha256=pins,scope='Public sys_compile_time binds the linked kernel build timestamp, is stable while Now advances, and formats through the original date services. The actual HomeSys also loads in Adam with CCF_JUST_LOAD; executing complete desktop startup is a separate check.');g=None
 try:
  pack=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'));image=out/'working.img';code=fixture.read_bytes();pack['package'](disk,image,additions={'/Probe/BuildDate.HC':code});before=pack['snapshot'](image.read_bytes())[1]
  Guest=runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest'];g=Guest(image,out/'guest',True,ram_mib=128 if a.native_kernel else 64);g.wait('DONE native kernel startup\n')
  g.command('#include "/Kernel/I386/PublicUser.HH"');g.command('#include "C:/Probe/BuildDate.HC"');g.command('BDProbe;');g.wait('BUILD DATE DONE\n')
  for name in ('build-date.bin','build-date.txt'):(out/name).write_bytes((g.out/name).read_bytes())
  v=list(struct.unpack('<12q',(out/'build-date.bin').read_bytes()));r['values']=v
  m=module.read_bytes();_,count,records=struct.unpack_from('<III',m,16);offsets=[]
  for i in range(count):
   kind,o,n,l=struct.unpack_from('<4I',m,records+i*16)
   if kind==3 and m[n:n+l]==b'kernel_compile_time':offsets.append(o)
  assert len(offsets)==1,'Missing kernel build date export';offset=offsets[0];expected=struct.unpack_from('<q',m,32+offset)[0];r['kernel_timestamp']=expected;r['kernel_data_offset']=offset
  raw=flat.read_bytes();assert raw[8+offset:16+offset]==struct.pack('<q',expected)
  assert disk.read_bytes().count(raw)==1,'Linked kernel differs from source image'
  assert v[0]==v[4]==expected>0 and v[1]==0x100008+offset,(v,expected)
  assert v[3]>v[2] and v[3]>expected
  model=runpy.run_path(str(ROOT/'tools/gen-i386-date.py'))['decode'](expected>>32,expected&0xffffffff);fields=model[1].to_bytes(8,'little')
  assert v[5]==model[2] and v[6:]==[model[0],fields[7],fields[6],fields[4],fields[3],fields[2]]
  text=f'{fields[7]:02d}/{fields[6]:02d}/{model[0]%100:02d} {fields[4]:02d}:{fields[3]:02d}:{fields[2]:02d}'.encode();assert (out/'build-date.txt').read_bytes()==text
  g.command('Free(bd_text);bd_text=NULL;');g.command('AdamFile("::/Adam/AutoComplete/MakeAC.HC",FALSE);');g.command('BDHomeLoad;');g.wait('HOME LOAD DONE\n');r['home_sys_loaded']=True
  if a.native_kernel:
   for generation in (1,2):
    g.command(f"""if(I386BuildModule("C:/Kernel/I386/Kernel.HC","C:/Probe/NativeKernel-{generation}.t32m",TRUE)<=0)throw('KBuild',TRUE);""",timeout=1800)
   g.command(f"""if(sys_compile_time!=0x{expected:X})throw('BuildMut',TRUE);""")
  g.command('6*7;');r['fresh_result']=g.result_pixels();g.close();g=None
  after=pack['snapshot'](image.read_bytes())[1]
  if a.native_kernel:
   targets={f'/Probe/NativeKernel-{i}.t32m' for i in (1,2)};assert set(after)==set(before)|targets
   assert all(after[n]==v for n,v in before.items())
   def exports(blob):
    _,count,records=struct.unpack_from('<III',blob,16);found={}
    for i in range(count):
     kind,o,n,l=struct.unpack_from('<4I',blob,records+i*16)
     if kind in (1,3):found[blob[n:n+l].decode()]=(kind,o)
    return found
   originals=exports(m);comparable=[];builds=[]
   for generation in (1,2):
    generated=after[f'/Probe/NativeKernel-{generation}.t32m'][2];(out/f'NativeKernel-{generation}.t32m').write_bytes(generated)
    symbols=exports(generated);assert {n:v[0] for n,v in symbols.items()}=={n:v[0] for n,v in originals.items()}
    native_offset=symbols['kernel_compile_time'][1];stamp=struct.unpack_from('<q',generated,32+native_offset)[0]
    assert stamp>=v[3] and stamp>expected
    normalized=bytearray(generated);struct.pack_into('<q',normalized,32+native_offset,0);comparable.append(normalized)
    builds.append(dict(timestamp=stamp,bytes=len(generated),sha256=hashlib.sha256(generated).hexdigest()))
   assert builds[1]['timestamp']>builds[0]['timestamp'] and comparable[0]==comparable[1],'Native kernel builds differ beyond their build date'
   r['native_kernel_build']=dict(result='pass',builds=builds,all_other_module_bytes_equal=True,cross_export_names_and_kinds_equal=True)
   r['prior_files_unchanged']=True
  else:assert after==before;r['files_unchanged']=True
  r['result']='pass'
 except Exception as e:r.update(result='fail',error=str(e));raise
 finally:
  if g:g.close()
  r['inputs_unchanged']=all(p.is_file() and sha(p)==pins[str(p)] for p in paths)
  if not r['inputs_unchanged']:r.update(result='fail',error='Inputs changed')
  (out/'result.json').write_text(json.dumps(r,indent=2)+'\n')
if __name__=='__main__':main()
