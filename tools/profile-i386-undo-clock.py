#!/usr/bin/env python3
"""Read-only clock/queue observation around the failing batched undo fixture."""
import argparse
import ast
import hashlib
import json
from pathlib import Path
import runpy
import struct
import time

ROOT=Path(__file__).resolve().parents[1]


def observed_input(disk, report):
    build=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))
    module=build['mutated_file_contents'](disk,{'/Modules/I386/Kernel.t32m'})['/Modules/I386/Kernel.t32m']
    image=disk.read_bytes()
    if image[528:532]!=b'E32B':raise ValueError('Requires qualified extended boot metadata')
    base=struct.unpack_from('<I',image,540)[0]+8
    size,count,records=struct.unpack_from('<III',module,16)
    exports={};ranges=[]
    for index in range(count):
        kind,offset,name,length=struct.unpack_from('<4I',module,records+16*index)
        if kind==3:exports[module[name:name+length].decode('ascii')]=offset
        if kind==4:ranges.append((offset,name))
    offsets={name:exports[name] for name in ('cnts','kernel_input')}
    for name,length in [('cnts',8),('kernel_input',12)]:
        offset=offsets[name]
        if not any(a<=offset and offset+length<=a+n for a,n in ranges):
            raise ValueError('Observer data export lacks bounded range: '+name)
    addresses={name:base+offset for name,offset in offsets.items()}
    report.update(addresses=addresses,kernel_module_sha256=hashlib.sha256(module).hexdigest(),observations=[])
    start=min(addresses.values());end=max(addresses['cnts']+8,addresses['kernel_input']+12)
    if end-start>65536:raise ValueError('Unexpected observation data span')

    def observe(phase,action,command,out):
        ordinal=len(report['observations'])
        path=out/('undo-clock-'+str(ordinal)+'.bin')
        command('pmemsave',val=start,size=end-start,filename=str(path))
        data=path.read_bytes()
        jiffies=struct.unpack_from('<q',data,addresses['cnts']-start)[0]
        head,count,dropped=struct.unpack_from('<3I',data,addresses['kernel_input']-start)
        if jiffies<0 or head>=64 or count>64:raise ValueError('Invalid observed clock/queue bounds')
        report['observations'].append(dict(phase=phase,action=action,host_monotonic=time.monotonic(),
                                          jiffies=jiffies,queue_head=head,queue_count=count,dropped=dropped))

    path=ROOT/'tools/i386-kernel-input.py';source=path.read_text()
    report['harness_sha256']=hashlib.sha256(source.encode()).hexdigest()
    tree=ast.parse(source,filename=str(path))
    loops=[node for node in ast.walk(tree) if isinstance(node,ast.For)
           and isinstance(node.target,ast.Name) and node.target.id=='action']
    if len(loops)!=1:raise ValueError('Review changed input event loop before instrumenting')
    loops[0].body.insert(0,ast.parse('_undo_observe("before",action,command,out)').body[0])
    loops[0].body.append(ast.parse('_undo_observe("after",action,command,out)').body[0])
    ast.fix_missing_locations(tree)
    namespace={'__name__':'undo_observed_input','__file__':str(path),'_undo_observe':observe}
    exec(compile(tree,str(path),'exec'),namespace)
    return namespace['run_input'],addresses['cnts']


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk',type=Path)
    parser.add_argument('--out',type=Path,required=True)
    args=parser.parse_args()
    if args.out.exists():parser.error('Use a fresh output directory')
    args.out.mkdir(parents=True)
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    pins={str(p.resolve()):sha(p) for p in (args.disk,Path(__file__),ROOT/'tools/i386-kernel-input.py',ROOT/'tools/test-i386-doldoc-undo-timing.py')}
    report=dict(result='running',input_sha256=pins,
                scope='Read-only QMP clock/queue samples around unchanged VGA undo assertions; sampling may perturb timing, not benchmark or qualification')
    try:
        runner,address=observed_input(args.disk,report)
        checks=runpy.run_path(str(ROOT/'tools/test-i386-doldoc-undo-timing.py'))['commands']()
        checks.insert(0,(f'(&cnts+0)(U64)=={address};',['1']))
        report['behavior']=runner(args.disk,args.out/'behavior',cpu='486,-fpu',qmp_stdio=True,
            startup_check={'status':'ok','answers':[],'commands':checks})
        report['result']='pass'
    except Exception as error:
        report.update(result='fail',error=str(error))
        raise
    finally:
        if any(sha(Path(p))!=digest for p,digest in pins.items()):report.update(result='fail',error='Observer inputs changed')
        (args.out/'result.json').write_text(json.dumps(report,indent=2)+'\n')


if __name__=='__main__':main()
