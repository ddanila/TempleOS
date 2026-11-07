#!/usr/bin/env python3
"""Exercise actual retained private-read functions with an independent tiny heap."""
import argparse
import ast
import hashlib
import json
from pathlib import Path
import re
import runpy
import struct

ROOT=Path(__file__).resolve().parents[1]
FIXTURE=ROOT/'tests/guest/i386-private-file-read/Contract.HC'


def export_offset(module,name):
    size,count,records=struct.unpack_from('<3I',module,16)
    offsets=[]
    for index in range(count):
        kind,offset,label,length=struct.unpack_from('<4I',module,records+16*index)
        if kind==1 and module[label:label+length]==name.encode():offsets.append(offset)
    if len(offsets)!=1 or not 0<=offsets[0]<size:
        raise ValueError('Missing unique bounded function export: '+name)
    return offsets[0]


def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('disk',type=Path);ap.add_argument('--archive',type=Path,required=True)
    ap.add_argument('--out',type=Path,required=True);args=ap.parse_args()
    disk,archive,out=args.disk.resolve(),args.archive.resolve(),args.out.resolve()
    if out.exists():ap.error('Use a fresh output directory')
    out.mkdir()
    paths=[disk,archive,FIXTURE,Path(__file__).resolve()]+[ROOT/'tools'/name for name in (
        'package-i386-native-image.py','build-i386-kernel.py',
        'test-i386-timeclock-welcome.py','i386-kernel-input.py')]+[ROOT/'Kernel/FontStd.HC']
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    pins={str(p):sha(p) for p in paths}
    report=dict(result='running',input_sha256=pins,ram_mib=8,accel='kvm',cpu='486,-fpu',
                scope='Native-only private file-read ownership, binary/expanded bytes, cache isolation, failure outputs and exact private-heap restoration; not full public API or desktop qualification')
    try:
        read=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['mutated_file_contents']
        files=read(disk,{'/Modules/I386/Kernel.t32m','/Modules/I386/ConsoleRuntime.t32m','/Kernel/I386/Heap.HH'})
        layout=re.sub(r'\s+','',files['/Kernel/I386/Heap.HH'].decode())
        if 'classCI386Heap{U8*base;U32size,used,peak,allocations,signature;};' not in layout:
            raise ValueError('Review fixture heap layout')
        kernel=files['/Modules/I386/Kernel.t32m'];console=files['/Modules/I386/ConsoleRuntime.t32m']
        metadata=disk.read_bytes()[528:544];magic,version,length,base=struct.unpack('<4I',metadata)
        if magic!=0x42323345 or version!=1 or base!=0x100000 or not 8<=length<=2039*512:
            raise ValueError('Invalid extended boot metadata')
        working=out/'candidate.img'
        additions={'/Probe/PrivateRead.HC':FIXTURE.read_bytes(),'/Probe/PrivatePacked.arc':archive.read_bytes()}
        report['packaging']=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['package'](disk,working,additions=additions)
        if read(working,set(additions))!=additions:raise ValueError('Packaged fixture bytes differ')
        names=['I386HeapInit','I386HeapFree','I386HeapValid','I386HeapSize','NativeResidentCopyHeap','NativeResidentReadBridge']
        def resolve(source,log):
            if '__READ_ARGS__' not in source:return source
            matches=re.findall(r'^CONSOLE ([0-9A-Fa-f]+) ',log.read_text(),re.M)
            if len(matches)!=1:raise ValueError('Missing unique loaded console base')
            console_base=int(matches[0],16)+8
            addresses={name:(base+8 if index<4 else console_base)+export_offset(kernel if index<4 else console,name)
                       for index,name in enumerate(names)}
            report['function_addresses']=addresses
            return source.replace('__READ_ARGS__',','.join(hex(addresses[name]) for name in names))
        path=ROOT/'tools/i386-kernel-input.py';tree=ast.parse(path.read_text(),filename=str(path))
        submits=[n for n in ast.walk(tree) if isinstance(n,ast.FunctionDef) and n.name=='submit']
        if len(submits)!=1 or not isinstance(submits[0].body[0],ast.Nonlocal):
            raise ValueError('Review input harness placeholder insertion')
        submits[0].body.insert(1,ast.parse('source=_private_read_resolve(source,log)').body[0])
        ast.fix_missing_locations(tree)
        (out/'instrumented-input-runner.py').write_text(ast.unparse(tree)+'\n')
        namespace={'__name__':'private_read_input','__file__':str(path),'_private_read_resolve':resolve}
        exec(compile(tree,str(path),'exec'),namespace)
        report['instrumentation']='Replace address placeholder before unchanged typing and result framebuffer assertions'
        commands=[('#include "C:/Probe/PrivateRead.HC"',[]),
                  ('PrivateReads(__READ_ARGS__);',['PASS private read ownership and failure','42'])]
        report['behavior']=namespace['run_input'](working,out/'guest',snapshot=False,cpu='486,-fpu',ram_mib=8,
            accel='kvm',qmp_stdio=True,welcome=True,
            startup_check={'status':'ok','answers':[],'commands':commands,'command_timeout':240})
        text=(out/'guest/debug.log').read_text()
        if text.count('PASS private read ownership and failure\n')!=1 or 'FAIL private read ' in text:
            raise ValueError('Missing unique fixture completion marker')
        report.update(result='pass',checks=30)
    except Exception as exc:
        report.update(result='fail',error=str(exc));raise
    finally:
        report['inputs_unchanged']=all(sha(Path(p))==value for p,value in pins.items())
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError(report['error'])

if __name__=='__main__':main()
