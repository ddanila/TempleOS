#!/usr/bin/env python3
"""Check orphan detachment before dispatch and isolate a replacement task."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]


def commands(diagnostic=False):
    return [
        ('CTask *dm_worker,*dm_master;Bool dm_entered,dm_release,dm_done;I64 dm_base,dm_root,dm_delta,dm_root_delta;CJob *dm_job;CTask *dm_probe;', []),
        ('U0 DMBody(){dm_entered=TRUE;}', []),
        ('U0 DMWorker(U8 *data){while(!dm_release)Yield;JobsHndlr(GetRFlags);dm_done=TRUE;while(TRUE)Yield;}', []),
        ('U0 DMMaster(U8 *data){dm_job=TaskExe(dm_worker,Fs,"DMBody;",0);Exit;}', []),
        ('U0 DMDrain(){I64 i;for(i=0;i<8;i++)Yield;FlushMsgs(Fs);}', []),
        ('U0 DMStart(){dm_entered=dm_release=dm_done=FALSE;dm_worker=Spawn(&DMWorker,NULL,"Surviving worker",-1,Fs);dm_master=Spawn(&DMMaster,NULL,"Retired master",-1,Fs);}', []),
        ('U0 DMProbe(U8 *data){while(TRUE)Yield;}', []),
        ("U0 DMFinish(){dm_release=TRUE;while(!dm_done)Yield;if(!dm_entered||dm_probe->srv_ctrl.next_done!=&dm_probe->srv_ctrl.next_done)throw('Orphan');Kill(dm_worker);Kill(dm_probe);DMDrain;}", []),
        ('U0 DMOne(){DMStart;while(TaskValidate(dm_master))Yield;if(dm_job->master_task||!Bt(&dm_job->flags,JOBf_FREE_ON_COMPLETE))throw(\'Orphan\');dm_probe=Spawn(&DMProbe,NULL,"Replacement",-1,Fs);DMFinish;}', []),
        ('Bool DMRun(){I64 i;DMOne;dm_base=Fs->data_heap->used_u8s;dm_root=adam_task->data_heap->used_u8s;for(i=0;i<10;i++)DMOne;dm_delta=Fs->data_heap->used_u8s-dm_base;dm_root_delta=adam_task->data_heap->used_u8s-dm_root;return !dm_delta&&!dm_root_delta;}', []),
        ('Bool dm_ok;', []),
        ('U0 DMAudit(){dm_ok=DMRun;Print("DM heaps caller:%d root:%d\\n",dm_delta,dm_root_delta);}', []),
        ('DMAudit;', ['DM heaps caller:0 root:0']),
        ('dm_ok;', ['1']),
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
                  scope='Queued request loses master pointer and becomes free-on-complete before dispatch; subsequently spawned replacement task receives no completion; actual void body, both helpers retired, ten-cycle caller/root heaps; does not require allocator to reuse master address')
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
