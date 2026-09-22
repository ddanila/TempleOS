#!/usr/bin/env python3
"""Confirm selected native assertions detect isolated executable-code faults."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

ROOT=Path(__file__).resolve().parents[1]
HARNESS=runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))
# Native HolyC uses eight-byte argument slots, callee cleanup, EDX:EAX results.
# Replace the actual public entry, after boot, with false/return and preserve its
# calling convention. Each QEMU process owns disposable RAM and a disk snapshot.
MUTATIONS={
    'control-hit-test':dict(symbol='CtrlInside',answer='-4',
                            description='Control hit testing always reports outside'),
    'horizontal-resize':dict(symbol='WinHorz',answer='-14',
                             description='Horizontal resizing silently does nothing'),
}


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk',type=Path,nargs='?',default=ROOT/'build/i386-kernel/kernel.img')
    parser.add_argument('--out',type=Path,default=ROOT/'build/i386-mutations')
    parser.add_argument('--mutation',action='append',choices=MUTATIONS)
    args=parser.parse_args()
    args.out.mkdir(parents=True,exist_ok=True)
    report={'result':'inconclusive','disk_sha256':hashlib.sha256(args.disk.read_bytes()).hexdigest(),
            'harness_sha256':hashlib.sha256((ROOT/'tools/i386-kernel-input.py').read_bytes()).hexdigest(),
            'mutations':{}}
    result_path=args.out/'result.json'
    result_path.unlink(missing_ok=True)
    try:
        print('Checking unmodified windows baseline',flush=True)
        report['baseline']=HARNESS['run_input'](args.disk,args.out/'baseline',groups=['windows'])
        for name in args.mutation or MUTATIONS:
            spec=MUTATIONS[name]
            # 31 c0 31 d2 c2 18 00 = xor eax,eax; xor edx,edx; ret 24.
            source=f'I64 InjectFault(){{U8 *p=&{spec["symbol"]};*p(U32 *)=0xD231C031;*(p+4)(U16 *)=0x18C2;p[6]=0;return *p(U32 *)==0xD231C031&&*(p+4)(U16 *)==0x18C2&&p[6]==0;}}InjectFault;'
            mutation=dict(source=source,checkpoint='window-service-check',answers=[spec['answer']])
            print(f'Injecting {name}: {spec["description"]}',flush=True)
            entry=dict(spec)
            try:
                HARNESS['run_input'](args.disk,args.out/name,groups=['windows'],mutation=mutation)
            except HARNESS['MutationDetected'] as exc:
                entry.update(result='detected',evidence=str(exc))
            except Exception as exc:
                entry.update(result='inconclusive',error=f'{type(exc).__name__}: {exc}')
            else:
                entry.update(result='survived')
            report['mutations'][name]=entry
            print(f'{name}: {entry["result"]}',flush=True)
        report['result']='pass' if all(x['result']=='detected' for x in report['mutations'].values()) else 'fail'
    except Exception as exc:
        report['error']=f'{type(exc).__name__}: {exc}'
    finally:
        report['disk_unchanged']=hashlib.sha256(args.disk.read_bytes()).hexdigest()==report['disk_sha256']
        if not report['disk_unchanged']: report['result']='fail'
        result_path.write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps(report,indent=2))
    return 0 if report['result']=='pass' else 1


if __name__=='__main__': raise SystemExit(main())
