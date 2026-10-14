#!/usr/bin/env python3
"""Require nonresident DolDoc diagnostics and exercise their delivered dispatcher."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil
import struct

ROOT = Path(__file__).resolve().parents[1]
CHECKS = {'NativeDocAllocationCaught','NativeDocAllocationPut','NativeDocAllocationNewLine',
          'NativeDocAllocationSave','NativeDocRecordSaveCheck','NativeDocBinarySaveCheck',
          'NativeDocAllocationCoreCheck','NativeDocClipPasteAtomicCheck'}

def exports(path):
    data = path.read_bytes()
    _,count,records = struct.unpack_from('<III',data,16)
    return {data[p:p+n].decode() for i in range(count)
            for kind,offset,p,n in [struct.unpack_from('<4I',data,records+16*i)] if kind==1}

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk',type=Path)
    parser.add_argument('--out',type=Path,required=True)
    args=parser.parse_args()
    image,out=args.disk.resolve(),args.out.resolve()
    if out.exists():parser.error('Use a fresh output directory')
    out.mkdir(parents=True)
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    console=image.parent/'exports/ConsoleRuntime.t32m'
    pins={str(p):sha(p) for p in [image,console,Path(__file__).resolve(),ROOT/'tools/i386-kernel-input.py']}
    report=dict(result='running',input_sha256=pins,
                scope='Diagnostic code absent from resident console, delivered module checks and repeated load/run/unload; cancellation/reentrancy and native generations remain separate qualification')
    try:
        retained=CHECKS&exports(console)
        if retained:raise ValueError('Diagnostic routines remain resident: '+', '.join(sorted(retained)))
        diagnostic=image.parent/'exports/DocDiagnosticRuntime.t32m'
        if not CHECKS<=exports(diagnostic):raise ValueError('Diagnostic module omitted checks')
        pins[str(diagnostic)]=sha(diagnostic)
        work=out/'working.img';shutil.copyfile(image,work)
        report['behavior']=runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input'](
            work,out/'qemu',snapshot=False,ram_mib=64,cpu='486,-fpu',qmp_stdio=True,
            startup_check={'status':'ok','answers':[],
                           'commands':[('6*7;',['42']),('DocAllocationCheck;',['13']),
                                       ('DocAllocationCheck;',['13']),('6*7;',['42'])],
                           'rejection_prefixes':('INPUT REJECT ',),'command_timeout':120})
        log=(out/'qemu/debug.log').read_text()
        boot=log.split('DONE native kernel startup\n',1)[0]
        if 'DOC DIAGNOSTIC loaded\n' in boot:raise ValueError('Normal boot loaded diagnostics')
        if log.count('DOC DIAGNOSTIC loaded\n')!=2 or log.count('DOC DIAGNOSTIC unloaded\n')!=2:
            raise ValueError('Missing balanced repeated diagnostic lifecycle')
        report['result']='pass'
    except Exception as exc:
        report.update(result='fail',error=str(exc));raise
    finally:
        report['inputs_unchanged']=all(sha(Path(p))==h for p,h in pins.items())
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
if __name__=='__main__':main()
