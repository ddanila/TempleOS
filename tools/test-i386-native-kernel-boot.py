#!/usr/bin/env python3
"""Link/install an emitted native kernel through guest APIs and boot its exact image."""
import argparse,hashlib,json,runpy,struct
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def main():
 ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('disk',type=Path);ap.add_argument('module',type=Path);ap.add_argument('--out',required=True,type=Path);a=ap.parse_args();out=a.out.resolve();disk=a.disk.resolve();module=a.module.resolve()
 if out.exists():ap.error('Use a fresh output directory')
 paths=[disk,module,Path(__file__).resolve()]+[ROOT/('tools/'+n) for n in ('i386-kernel-input.py','package-i386-native-image.py','build-i386-kernel.py','i386_boot_area.py')]+[ROOT/'Kernel/FontStd.HC']
 sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();pins={str(p):sha(p) for p in paths};out.mkdir();(out/'runner-source.py').write_bytes(Path(__file__).read_bytes());r=dict(result='running',input_sha256=pins,scope='One emitted native Kernel module linked with existing five boot helpers, installed through I386InstallBootImage onto a copied full source volume, then booted on486,-fpu. Native kernel date/address and welcome/42 pixels; all resident providers remain from the cross image. Not a complete native generation or full C1-C5 qualification.')
 try:
  m=module.read_bytes();_,count,records=struct.unpack_from('<III',m,16);offsets=[]
  for i in range(count):
   k,o,n,l=struct.unpack_from('<4I',m,records+16*i)
   if k==3 and m[n:n+l]==b'kernel_compile_time':offsets.append(o)
  assert len(offsets)==1;offset=offsets[0];stamp=struct.unpack_from('<q',m,32+offset)[0];assert stamp>0
  pack=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'));source=out/'source.img';pack['package'](disk,source,additions={'/Probe/BootKernel.t32m':m})
  target=out/'target.img';initial=bytearray(disk.read_bytes());initial[:2048*512]=bytes(2048*512);target.write_bytes(initial)
  before=pack['snapshot'](bytes(initial))[1]
  run=runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input']
  commands=[('U0 KBStage(){I64 n;U8 *m=FileRead("C:/Probe/BootKernel.t32m",&n);if(!FileWrite("D:/Modules/I386/Kernel.t32m",m,n))throw(\'KWrite\');Free(m);}',[]),('KBStage;',[]),('I386BuildBootImage("C:/Probe/BootKernel.t32m","C:/Modules/I386/","C:/Probe/BootKernel.bin")>0;',['1']),('I386InstallBootImage("C:/","D:/","C:/Probe/BootKernel.bin");',['1']),('6*7;',['42'])]
  assert all(len(c)<256 for c,_ in commands)
  r['publication']=run(source,out/'publication',target_disk=target,snapshot=False,ram_mib=64,cpu='486,-fpu',accel='kvm',qmp_stdio=True,welcome=True,managed_pointer=True,keep_window_manager=True,startup_check={'status':'ok','answers':[],'commands':commands,'pause_window_manager':False,'command_timeout':300})
  files=pack['snapshot'](source.read_bytes())[1];flat=files['/Probe/BootKernel.bin'][2];(out/'Kernel32.BIN').write_bytes(flat)
  assert flat[8+offset:16+offset]==struct.pack('<q',stamp)
  area=runpy.run_path(str(ROOT/'tools/i386_boot_area.py'))['expected_boot_area'](source.read_bytes(),flat);installed=target.read_bytes();assert installed[:len(area)]==area
  after=pack['snapshot'](installed)[1];assert set(after)==set(before)
  assert after['/Modules/I386/Kernel.t32m'][2]==m
  assert all(after[n]==v for n,v in before.items() if n!='/Modules/I386/Kernel.t32m')
  r['independent_boot']=run(target,out/'boot',snapshot=True,ram_mib=64,cpu='486,-fpu',accel='kvm',qmp_stdio=True,welcome=True,managed_pointer=True,keep_window_manager=True,startup_check={'status':'ok','answers':[],'commands':[(f'sys_compile_time==0x{stamp:X};',['1']),(f'&sys_compile_time==0x{0x100008+offset:X};',['1']),('6*7;',['42'])],'pause_window_manager':False,'command_timeout':120})
  assert target.read_bytes()==installed
  r.update(result='pass',kernel_timestamp=stamp,kernel_public_address=0x100008+offset,flat_bytes=len(flat),flat_sha256=sha(out/'Kernel32.BIN'),target_sha256=sha(target),prior_target_files_preserved=True,installed_image_unchanged_by_boot=True)
 except Exception as e:r.update(result='fail',error=str(e));raise
 finally:
  r['inputs_unchanged']=all(p.is_file() and sha(p)==pins[str(p)] for p in paths)
  if not r['inputs_unchanged']:r.update(result='fail',error='Inputs changed')
  (out/'result.json').write_text(json.dumps(r,indent=2)+'\n')
if __name__=='__main__':main()
