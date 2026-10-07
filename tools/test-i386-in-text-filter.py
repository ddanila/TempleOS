#!/usr/bin/env python3
"""Run In synchronously inside an actual input filter and check both heaps."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]


def commands():
    return [('I64 IFScan(){I64 a,b,i;U8 *s="Filter";for(i=0;s[i];i++)if(ScanMsg(&a,&b,1<<2,Fs)!=2||a!=s[i]||b)return 0;return ScanMsg(&a,&b,1<<2,Fs)==0;}', []), ('Bool IFState(){return Fs->last_input_filter_task==Fs&&Fs->next_input_filter_task==Fs&&!Bt(&Fs->task_flags,TASKf_FILTER_INPUT);}', []), ('U0 IFDrain(){I64 i;for(i=0;i<8;i++)Yield;FlushMsgs(Fs);}', []), ('Bool IFOne(){FlushMsgs(Fs);InStr("%s","In(\\"%s\\",\\"Filter\\");");TaskWait(Fs,FALSE);return IFScan&&IFState;}', []), ('Bool IFRepeat(){I64 i,base,root;if(!IFOne)return FALSE;IFDrain;base=Fs->data_heap->used_u8s;root=adam_task->data_heap->used_u8s;for(i=0;i<10;i++){if(!IFOne)return FALSE;IFDrain;}return Fs->data_heap->used_u8s==base&&adam_task->data_heap->used_u8s==root;}', []), ('IFOne;', ['1']), ('IFRepeat;', ['1']), ('6*7;', ['42'])]


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
                  scope='In called by actual InStr filter source: exact Filter key-downs, restored links/flag, initial plus ten cycles and exact caller/root heap after draining; no synchronous fault or active cancellation coverage')
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
