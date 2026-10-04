#!/usr/bin/env python3
"""Observe the boot kernel's private heap via read-only QMP around FileFind cycles.

Load an instrumented in-memory copy of the input harness; live harness files
remain unchanged. The original submit body and VGA checks still execute.
"""
import ast
import hashlib
from pathlib import Path
import runpy
import struct
import time

ROOT=Path(__file__).resolve().parents[1]


def observed_input(disk, report, private=True):
    build=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))
    module=build['mutated_file_contents'](disk,{'/Modules/I386/Kernel.t32m'}).get('/Modules/I386/Kernel.t32m')
    if private and (not module or len(module)<32):raise ValueError('Missing kernel module for private heap observation')
    size,count,records=struct.unpack_from('<III',module,16)
    offsets=[];ranges=[]
    for index in range(count):
        kind,offset,name,length=struct.unpack_from('<4I',module,records+16*index)
        if kind==3 and module[name:name+length]==b'kernel_heap':offsets.append(offset)
        if kind==4:ranges.append((offset,name))
    if len(offsets)!=1 or offsets[0]+24>size or not any(a<=offsets[0] and offsets[0]+24<=a+n for a,n in ranges):
        raise ValueError('Kernel heap is not one bounded data export')
    address=0x11000+8+offsets[0]
    evidence=dict(address=address,kernel_module_sha256=hashlib.sha256(module).hexdigest())
    report['private_heap_observation']=evidence

    def observe(phase,source,command,out):
        if not private or not source.startswith('FindRecovery('):return
        def sample():
            path=out/('kernel-heap-'+phase+'.bin')
            command('pmemsave',val=address,size=24,filename=str(path))
            values=struct.unpack('<6I',path.read_bytes())
            base,capacity,used,peak,allocations,signature=values
            if signature!=0x48323349 or not capacity or used>capacity or base+capacity>8*1024*1024:
                raise ValueError('Private heap snapshot has invalid signature/bounds')
            return dict(base=base,capacity=capacity,used=used,peak=peak,allocations=allocations,signature=signature)
        if phase=='before':
            evidence['before']=sample();return
        deadline=time.monotonic()+10
        while True:
            evidence['after']=sample()
            if all(evidence['before'][field]==evidence['after'][field] for field in ('base','capacity','used','allocations','signature')):
                evidence['result']='pass';return
            if time.monotonic()>=deadline:
                evidence['result']='fail';raise ValueError('FileFind cycles did not recover private heap bytes/allocation count')
            time.sleep(.05)

    def source_rows(image):
        data=build['mutated_file_contents'](image,{'/Kernel/I386/PublicFiles.HH'}).get('/Kernel/I386/PublicFiles.HH')
        if data is None:raise ValueError('Missing source-view fixture')
        lines=data.decode('latin1').split('\n')
        starts=[i for i,line in enumerate(lines) if line.startswith('public _extern _DIR I64 Dir(')]
        if len(starts)!=1:raise ValueError('Dir declaration is not unique')
        rows=['TempleOS i386','Help: C:/Kernel/I386/PublicFiles.HH','']
        for line in lines[starts[0]:]:
            rows.extend([line[i:i+80] for i in range(0,len(line)+1,80)])
        return rows

    path=ROOT/'tools/i386-kernel-input.py';source=path.read_text()
    evidence['input_harness_sha256']=hashlib.sha256(source.encode()).hexdigest()
    tree=ast.parse(source,filename=str(path))
    matches=[node for node in ast.walk(tree) if isinstance(node,ast.FunctionDef) and node.name=='submit']
    if len(matches)!=1 or not isinstance(matches[0].body[0],ast.Nonlocal):
        raise ValueError('Input harness submit structure changed; review observer insertion')
    views=[node for node in ast.walk(tree) if isinstance(node,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='dir_source_rows' for t in node.targets)]
    if len(views)!=1:raise ValueError('Source-view oracle structure changed')
    views[0].value=ast.parse('_file_find_source_rows(disk)',mode='eval').body
    target=matches[0]
    target.body.insert(1,ast.parse('_file_find_observe("before",source,command,out)').body[0])
    target.body.append(ast.parse('_file_find_observe("after",source,command,out)').body[0])
    ast.fix_missing_locations(tree)
    namespace={'__name__':'file_find_observed_input','__file__':str(path),'_file_find_observe':observe,'_file_find_source_rows':source_rows}
    exec(compile(tree,str(path),'exec'),namespace)
    return namespace['run_input']
