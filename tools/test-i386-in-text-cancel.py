#!/usr/bin/env python3
"""Cancel queued In jobs and require exact caller/root heap recovery."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]


def commands():
    return [
        ('CTask *ic_filter;I64 ic_base,ic_root;Bool ic_queued,ic_retired;', []),
        ('Bool ICState(){return Fs->last_input_filter_task==Fs&&Fs->next_input_filter_task==Fs&&!Bt(&Fs->task_flags,TASKf_FILTER_INPUT);}', []),
        ('U0 ICQueue(){ic_base=Fs->data_heap->used_u8s;ic_root=adam_task->data_heap->used_u8s;In("%s","Queued");ic_filter=Fs->last_input_filter_task;ic_queued=ic_filter!=Fs&&TaskValidate(ic_filter);}', []),
        ('Bool ICCancel(){Kill(ic_filter);ic_retired=!TaskValidate(ic_filter);return ic_queued&&ic_retired&&ICState;}', []),
        ('U0 ICDrain(){I64 i;for(i=0;i<8;i++)Yield;FlushMsgs(Fs);}', []),
        ('Bool ICOne(){I64 f=GetRFlags;Bool ok;FlushMsgs(Fs);SetRFlags(f&~512);ICQueue;ok=ICCancel;SetRFlags(f);ICDrain;return ok&&Fs->data_heap->used_u8s==ic_base&&adam_task->data_heap->used_u8s==ic_root;}', []),
        ('Bool ICRepeat(){I64 i;for(i=0;i<10;i++)if(!ICOne)return FALSE;return TRUE;}', []),
        ('ICOne;', ['1']), ('ICRepeat;', ['1']), ('6*7;', ['42']),
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
                  scope='Queued In cancellation: IRQ-masked submit and Kill before filter entry, initial plus ten repetitions, exact caller/root heap and restored filter links/flag; no active execution cancellation coverage')
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
