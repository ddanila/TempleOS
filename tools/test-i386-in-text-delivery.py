#!/usr/bin/env python3
"""Require actual In text delivery and retired input filters."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]


def commands():
    return [
        ('I64 ICScan(U8 *text){I64 a,b,i;for(i=0;text[i];i++)if(ScanMsg(&a,&b,1<<2,Fs)!=2||a!=text[i]||b)return 0;return ScanMsg(&a,&b,1<<2,Fs)==0;}', []),
        ('I64 ICState(){return Fs->last_input_filter_task==Fs&&Fs->next_input_filter_task==Fs&&!Bt(&Fs->task_flags,TASKf_FILTER_INPUT);}', []),
        ('I64 ICText(){FlushMsgs(Fs);In("%s:%d","A\\\"B\\\\C%",42);TaskWait(Fs,FALSE);return ICScan("A\\\"B\\\\C%:42")&&ICState;}', []),
        ('I64 ICEmpty(){FlushMsgs(Fs);In("%s","");TaskWait(Fs,FALSE);return ICScan("")&&ICState;}', []),
        ('ICText;', ['1']), ('ICEmpty;', ['1']),
        ('U0 ICDrain(){I64 i;for(i=0;i<8;i++)Yield;FlushMsgs(Fs);}', []),
        ('I64 ICRepeat(){I64 i,base,root;ICText;ICEmpty;ICDrain;base=Fs->data_heap->used_u8s;root=adam_task->data_heap->used_u8s;for(i=0;i<10;i++){if(!ICText||!ICEmpty)return 0;ICDrain;}return Fs->data_heap->used_u8s==base&&adam_task->data_heap->used_u8s==root;}', []),
        ('ICRepeat;', ['1']), ('6*7;', ['42']),
    ]


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
                  scope='Actual In text delivery: quotes/backslash/percent/integer and empty input, explicit wait, exact key-down sequence, restored filters, ten cycles with exact caller and root heap after draining; child ownership and allocation faults remain separate')
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
