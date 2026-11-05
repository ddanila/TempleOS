#!/usr/bin/env python3
"""Run the builder's normal-boot isolation check with corrupt diagnostic modules."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import struct
ROOT=Path(__file__).resolve().parents[1]


def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('disk',type=Path)
 p.add_argument('--out',type=Path,required=True);p.add_argument('--accel',choices=('tcg','kvm'),default='tcg')
 args=p.parse_args();disk=args.disk.resolve();out=args.out.resolve()
 if out.exists():p.error('Use a fresh output directory')
 out.mkdir(parents=True);builder=ROOT/'tools/build-i386-kernel.py';helper=ROOT/'tools/i386-kernel-input.py'
 sha=lambda f:hashlib.sha256(f.read_bytes()).hexdigest()
 paths=[disk,Path(__file__).resolve(),builder,helper,ROOT/'Kernel/FontStd.HC']
 pins={str(f):sha(f) for f in paths};build=runpy.run_path(str(builder));console=runpy.run_path(str(helper))
 report=dict(result='fail',input_sha256=pins,scope='Actual shared builder helper: corrupt only both diagnostic-module magic bytes, normal 8 MiB 486 boot, exact welcome and command pixels, arithmetic 42 and live code heap. No replacement startup source; not complete rejection/install gate or 60-second startup qualification.')
 try:
  report['filesystem']=build['verify_mutated_volume'](disk)
  original=disk.read_bytes();root=struct.unpack_from('<q',original,2048*512+24)[0];files={}
  def walk(block,path):
   _,_,_,size,_=struct.unpack_from('<H38sqqQ',original,block*512)
   for offset in range(block*512+128,block*512+size,64):
    attr,raw,child,length,date=struct.unpack_from('<H38sqqQ',original,offset)
    name=raw.split(b'\0',1)[0].decode('ascii')
    if not name:break
    if attr&0x100:continue
    full=path+'/'+name
    if attr==0x810:walk(child,full)
    else:files[full]=dict(block=child,size=length)
  walk(root,'')
  offsets=[files[f'/Modules/I386/{name}.t32m']['block']*512 for name in ('CompilerProbe','CompilerProgramRuntimeProbe')]
  if any(original[pos:pos+4]!=b'T32M' for pos in offsets):raise ValueError('Expected actual diagnostic modules')
  run=console['run_input']
  def controlled(*args2,**kwargs):return run(*args2,accel=args.accel,**kwargs)
  console['run_input']=controlled
  report['behavior']=build['verify_normal_without_probe'](disk,{'files':files},out,console)
  changed=(out/'normal-without-probe/kernel.img').read_bytes()
  differences=[n for n,(a,b) in enumerate(zip(original,changed)) if a!=b]
  if len(changed)!=len(original) or sorted(differences)!=sorted(offsets) or any(changed[n]!=original[n]^0xFF for n in offsets):raise ValueError('Unexpected mutation outside diagnostic magic bytes')
  report['corrupted_offsets']=offsets;report['result']='pass'
 except Exception as exc:report['error']=str(exc);raise
 finally:
  report['inputs_unchanged']=all(sha(Path(f))==h for f,h in pins.items())
  if not report['inputs_unchanged']:report['result']='fail'
  (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
 if report['result']!='pass':raise ValueError('Normal boot probe independence failed')


if __name__=='__main__':main()
