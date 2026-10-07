#!/usr/bin/env python3
"""Catch a queued spawn failure inside a real outer TaskExe dispatch."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]


def commands(diagnostic=False):
    return [
        ('U0 SJInsert(CJob *job){I64 flags=GetRFlags;SetRFlags(flags&~512);QueIns(job,Fs->srv_ctrl.last_waiting);SetRFlags(flags);}', []),
        ('I64 sj_base,sj_root,sj_delta,sj_root_delta;Bool sj_caught,sj_ok;Bool sj_outer;', []),
        ('U0 SJQueue(){CJob *job=CAlloc(sizeof(CJob),adam_task);job->aux_str=StrNew("Invalid spawn",adam_task);job->job_code=JOBT_SPAWN_TASK;job->flags=1<<JOBf_FREE_ON_COMPLETE;job->ctrl=&Fs->srv_ctrl;SJInsert(job);}', []),
        ("U0 SJOne(){sj_caught=FALSE;SJQueue;try{JobsHndlr(GetRFlags);}catch{if(Fs->except_ch=='Task'){sj_caught=TRUE;Fs->catch_except=TRUE;}}if(!sj_caught)throw('NoFault');}", []),
        ('U0 SJOuter(){SJOne;sj_outer=TRUE;}', []),
        ('U0 SJNestedOne(){sj_outer=FALSE;TaskExe(Fs,NULL,"SJOuter;",1<<JOBf_FREE_ON_COMPLETE);JobsHndlr(GetRFlags);if(!sj_outer)throw(\'Outer\');}', []),
        ('U0 SJMeasure(){I64 i;SJNestedOne;sj_base=Fs->data_heap->used_u8s;sj_root=adam_task->data_heap->used_u8s;for(i=0;i<10;i++)SJNestedOne;sj_delta=Fs->data_heap->used_u8s-sj_base;sj_root_delta=adam_task->data_heap->used_u8s-sj_root;}', []),
        ('Bool SJRun(){SJMeasure;return !sj_delta&&!sj_root_delta;}', []),
        ('U0 SJAudit(){sj_ok=SJRun;Print("Spawn fault heaps caller:%d root:%d\\n",sj_delta,sj_root_delta);}', []),
        ('SJAudit;', ['Spawn fault heaps caller:0 root:0']),
        ('sj_ok;', ['1']),
        ('6*7;', ['42']),
    ]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--diagnostic', action='store_true',
                        help='Print phase boundaries without changing the heap assertions')
    args = parser.parse_args()
    if args.out.exists():
        parser.error('Use a fresh output directory')
    args.out.mkdir(parents=True)
    helper = ROOT / 'tools/i386-kernel-input.py'
    sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
    pins = {str(p.resolve()): sha(p) for p in (args.disk, helper, Path(__file__))}
    report = dict(result='running', input_sha256=pins, disk_policy='writable copy',
                  diagnostic=args.diagnostic,
                  scope='Outer TaskExe dispatch catches inner invalid queued spawn Task exception and continues; both free-on-complete requests recover exact caller/root heaps over ten measured nested failures; console survival; not allocator fault coverage or successful spawn coverage')
    (args.out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
    try:
        disk = args.out / 'working.img'
        shutil.copyfile(args.disk, disk)
        report['behavior'] = runpy.run_path(str(helper))['run_input'](
            disk, args.out / 'behavior', cpu='486,-fpu', qmp_stdio=True, snapshot=False,
            startup_check={'status': 'ok', 'answers': [], 'commands': commands(args.diagnostic)})
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
