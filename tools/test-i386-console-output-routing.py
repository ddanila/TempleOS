#!/usr/bin/env python3
"""Check native packed bytes, silent output and the synthetic input-filter output branch."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]


def commands():
    return [('PutChars(0x420041);PutChars(10);', ['AB']), ('U0 COSilent(){Bool old=LBts(&Fs->display_flags,DISPLAYf_SILENT);try{Print("hidden");}catch{LBEqu(&Fs->display_flags,DISPLAYf_SILENT,old);}LBEqu(&Fs->display_flags,DISPLAYf_SILENT,old);}', []), ('COSilent;', []), ('Bool co_old;CTask *co_last;', []), ('U0 CORestore(){LBEqu(&Fs->task_flags,TASKf_INPUT_FILTER_TASK,co_old);Fs->last_input_filter_task=co_last;}', []), ('U0 COEmit(){co_old=LBts(&Fs->task_flags,TASKf_INPUT_FILTER_TASK);co_last=Fs->last_input_filter_task;Fs->last_input_filter_task=Fs;try{Print("AB");}catch{CORestore;}CORestore;}', []), ('I64 COScan(){I64 a,b;if(ScanMsg(&a,&b)!=MSG_KEY_DOWN||a!=65||b)return 0;if(ScanMsg(&a,&b)!=MSG_KEY_DOWN||a!=66||b)return 0;return ScanMsg()==0;}', []), ('I64 CORun(){I64 base;FlushMsgs;base=Fs->data_heap->used_u8s;COEmit;return COScan && Fs->data_heap->used_u8s==base;}', []), ('CORun;', ['1']), ('6*7;', ['42'])]


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
                  scope='Packed zero byte, silent display and synthetic self-linked filter output routing with queue consumption and exact task heap recovery; not spawned filters or playback')
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
