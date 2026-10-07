#!/usr/bin/env python3
"""Retire a worker inside nested TaskExe execution and check both jobs."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]


def commands():
    return [('CTask *jc_worker;Bool jc_entered,jc_retired,jc_ok;I64 jc_count,jc_base,jc_root,jc_delta,jc_root_delta;', []), ('U0 JCBody(){jc_entered=TRUE;Sleep(10000);}', []), ('U0 JCOuter(){TaskExe(Fs,NULL,"JCBody;",1<<JOBf_FREE_ON_COMPLETE);JobsHndlr(GetRFlags);}', []), ('U0 JCWorker(U8 *data){while(TRUE){JobsHndlr(GetRFlags);Yield;}}', []), ('U0 JCDrain(){I64 i;for(i=0;i<8;i++)Yield;FlushMsgs(Fs);}', []), ('U0 JCStart(){jc_entered=FALSE;jc_worker=Spawn(&JCWorker,NULL,"Job cancel",-1,Fs);TaskExe(jc_worker,NULL,"JCOuter;",1<<JOBf_FREE_ON_COMPLETE);while(!jc_entered)Yield;}', []), ('U0 JCOne(){JCStart;Kill(jc_worker);jc_count++;jc_retired=jc_retired&&!TaskValidate(jc_worker);JCDrain;}', []), ('U0 JCMeasure(){I64 i;JCOne;jc_base=Fs->data_heap->used_u8s;jc_root=adam_task->data_heap->used_u8s;for(i=0;i<10;i++)JCOne;jc_delta=Fs->data_heap->used_u8s-jc_base;jc_root_delta=adam_task->data_heap->used_u8s-jc_root;}', []), ('U0 JCRun(){jc_count=0;jc_retired=TRUE;JCMeasure;jc_ok=jc_retired&&!jc_delta&&!jc_root_delta;}', []), ('JCRun;', []), ('"Job cancel retired:%d caller:%d root:%d\\n",jc_count,jc_delta,jc_root_delta;', ['Job cancel retired:11 caller:0 root:0']), ('jc_ok;', ['1']), ('6*7;', ['42'])]


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
                  scope='Nested TaskExe retirement: outer void job queues inner job and dispatches it; inner sleeps after entry marker, Kill worker with two active requests, warmup plus ten measured cycles and exact caller/root heap; null masters/free-on-complete, not waiting-master or popup UI')
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
