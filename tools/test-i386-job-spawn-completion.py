#!/usr/bin/env python3
"""Execute queued spawn requests and retire their actual child tasks."""
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
        ('I64 sj_base,sj_root,sj_delta,sj_root_delta;Bool sj_ok,sj_entered;CTask *sj_child;', []),
        ('U0 SJChild(U8 *data){sj_entered=TRUE;while(TRUE)Yield;}', []),
        ('CJob *SJQueue(){CJob *job=CAlloc(sizeof(CJob),adam_task);job->aux_str=StrNew("Queued spawn",adam_task);job->job_code=JOBT_SPAWN_TASK;job->addr=&SJChild;job->flags=1<<JOBf_ADD_TO_QUE;job->master_task=Fs;job->ctrl=&Fs->srv_ctrl;SJInsert(job);return job;}', []),
        ('U0 SJDrain(){I64 i;for(i=0;i<8;i++)Yield;FlushMsgs(Fs);}', []),
        ("U0 SJResult(CJob *job){I64 res=-1;sj_child=job->spawned_task;if(!TaskValidate(sj_child)||!Bt(&job->flags,JOBf_DONE)||!JobResScan(job,&res)||res)throw('SpawnRes');}", []),
        ("U0 SJOne(){CJob *job;sj_entered=FALSE;job=SJQueue;JobsHndlr(GetRFlags);SJResult(job);while(!sj_entered)Yield;Kill(sj_child);SJDrain;if(TaskValidate(sj_child))throw('Retire');}", []),
        ('U0 SJMeasure(){I64 i;SJOne;sj_base=Fs->data_heap->used_u8s;sj_root=adam_task->data_heap->used_u8s;for(i=0;i<10;i++)SJOne;sj_delta=Fs->data_heap->used_u8s-sj_base;sj_root_delta=adam_task->data_heap->used_u8s-sj_root;}', []),
        ('U0 SJAudit(){SJMeasure;sj_ok=!sj_delta&&!sj_root_delta;Print("Spawn heaps caller:%d root:%d\\n",sj_delta,sj_root_delta);}', []),
        ('SJAudit;', ['Spawn heaps caller:0 root:0']),
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
                  scope='Queued JOBT_SPAWN_TASK creates actual child; valid spawned pointer, DONE and JobResScan zero result, body entry and retirement; warmup plus ten exact caller/root heap cycles and console survival; not allocator failure or wake-master coverage')
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
