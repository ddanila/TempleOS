#!/usr/bin/env python3
"""Require executable InFile text routing and retired filter tasks for self and child recipients."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]


def commands():
    return [('U0 IFCReceive(I64 *s){I64 a,b,expected=65;if(s[0]&1)expected=66;if(ScanMsg(&a,&b,1<<2,Fs)==2){if(a!=expected||b)s[1]++;s[0]++;LBtr(&Fs->task_flags,TASKf_IDLE);}else LBts(&Fs->task_flags,TASKf_IDLE);}', []), ('U0 IFCRecipient(U8 *data){while(TRUE){IFCReceive(data(I64 *));Sleep(1);}}', []), ('CTask *ifc_child;I64 ifc_received[2];', []), ('U0 IFCStart(){ifc_received[0]=ifc_received[1]=0;ifc_child=Spawn(&IFCRecipient,ifc_received,"Input recipient",-1,Fs);}', []), ('IFCStart;', []), ('I64 IFCRun(){I64 n=ifc_received[0];XTalkStrWait(ifc_child,"%s","\\"AB\\";");return ifc_received[0]==n+2&&!ifc_received[1]&&ifc_child->last_input_filter_task==ifc_child&&!Bt(&ifc_child->task_flags,TASKf_FILTER_INPUT);}', []), ('IFCRun;', ['1']), ('I64 IFCRepeat(){I64 i,base=Fs->data_heap->used_u8s;for(i=0;i<10;i++){if(!IFCRun())return 0;Yield;}return Fs->data_heap->used_u8s==base;}', []), ('IFCRepeat;', ['1']), ('Kill(ifc_child);', ['1']), ('TaskValidate(ifc_child);', ['0']), ('6*7;', ['42'])]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    if args.out.exists():
        parser.error('Use a fresh output directory')
    args.out.mkdir(parents=True)
    helper = ROOT / 'tools/i386-kernel-input.py'
    sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
    pins = {str(p.resolve()): sha(p) for p in (args.disk, helper, Path(__file__))}
    report = dict(result='running', input_sha256=pins, disk_policy='writable copy',
                  scope='Actual executable child input through XTalkStrWait, recipient consumes and independently records key-down sequence before idle, restored filter links/bit, ten cycles with exact caller heap recovery, explicit child retirement and continued console use; not macro playback or fault coverage')
    (args.out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
    try:
        disk = args.out / 'working.img'
        shutil.copyfile(args.disk, disk)
        report['behavior'] = runpy.run_path(str(helper))['run_input'](
            disk, args.out / 'behavior', cpu='486,-fpu', qmp_stdio=True, snapshot=False,
            startup_check={'status': 'ok', 'answers': [], 'commands': commands()})
        report['result'] = 'pass'
    except Exception as error:
        report.update(result='fail', error=str(error))
        raise
    finally:
        changed = [path for path, digest in pins.items() if sha(Path(path)) != digest]
        if changed:
            report.update(result='fail', error='Input-filter prerequisite fixture inputs changed', changed_inputs=changed)
        (args.out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
    if report['result'] != 'pass':
        raise RuntimeError(report.get('error', 'Input-filter prerequisites failed'))


if __name__ == '__main__':
    main()
