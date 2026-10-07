#!/usr/bin/env python3
"""Kill a worker during actual TaskExe source execution and check both heaps."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]


def commands(without_job=False):
    rows = [('CTask *jc_worker;Bool jc_entered,jc_retired,jc_ok;I64 jc_count,jc_base,jc_root,jc_delta,jc_root_delta;', []), ('U0 JCBody(){jc_entered=TRUE;Sleep(10000);}', []), ('U0 JCWorker(U8 *data){while(TRUE){JobsHndlr(GetRFlags);Yield;}}', []), ('U0 JCDrain(){I64 i;for(i=0;i<8;i++)Yield;FlushMsgs(Fs);}', []), ('U0 JCStart(){jc_entered=FALSE;jc_worker=Spawn(&JCWorker,NULL,"Job cancel",-1,Fs);TaskExe(jc_worker,NULL,"JCBody;",1<<JOBf_FREE_ON_COMPLETE);while(!jc_entered)Yield;}', []), ('U0 JCOne(){JCStart;Kill(jc_worker);jc_count++;jc_retired=jc_retired&&!TaskValidate(jc_worker);JCDrain;}', []), ('U0 JCMeasure(){I64 i;JCOne;jc_base=Fs->data_heap->used_u8s;jc_root=adam_task->data_heap->used_u8s;for(i=0;i<10;i++)JCOne;jc_delta=Fs->data_heap->used_u8s-jc_base;jc_root_delta=adam_task->data_heap->used_u8s-jc_root;}', []), ('U0 JCRun(){jc_count=0;jc_retired=TRUE;JCMeasure;jc_ok=jc_retired&&!jc_delta&&!jc_root_delta;}', []), ('JCRun;', []), ('"Job cancel retired:%d caller:%d root:%d\\n",jc_count,jc_delta,jc_root_delta;', ['Job cancel retired:11 caller:0 root:0']), ('jc_ok;', ['1']), ('6*7;', ['42'])]
    if without_job:
        rows[2] = ('U0 JCWorker(U8 *data){jc_entered=TRUE;while(TRUE){JobsHndlr(GetRFlags);Yield;}}', [])
        rows[4] = ('U0 JCStart(){jc_entered=FALSE;jc_worker=Spawn(&JCWorker,NULL,"Job cancel",-1,Fs);while(!jc_entered)Yield;}', [])
    return rows


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--without-job', action='store_true', help='Paired worker retirement control without TaskExe')
    args = parser.parse_args()
    if args.out.exists():
        parser.error('Use a fresh output directory')
    args.out.mkdir(parents=True)
    helper = ROOT / 'tools/i386-kernel-input.py'
    sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
    pins = {str(p.resolve()): sha(p) for p in (args.disk, helper, Path(__file__))}
    report = dict(result='running', input_sha256=pins, disk_policy='writable copy', without_job=args.without_job,
                  scope='Actual TaskExe worker sets entry marker then sleeps in job source; Kill during execution, warmup plus ten measured retirements, exact caller/root heap after draining and continued console; null master/free-on-complete, not waiting-master completion')
    (args.out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
    try:
        disk = args.out / 'working.img'
        shutil.copyfile(args.disk, disk)
        report['behavior'] = runpy.run_path(str(helper))['run_input'](
            disk, args.out / 'behavior', cpu='486,-fpu', qmp_stdio=True, snapshot=False,
            startup_check={'status': 'ok', 'answers': [], 'commands': commands(args.without_job)})
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
