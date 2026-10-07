#!/usr/bin/env python3
"""Cancel a running TaskExe worker while its master is suspended."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]


def commands():
    return [('CTask *wm_worker,*wm_killer;Bool wm_entered,wm_killed,wm_ok;I64 wm_count,wm_base,wm_root,wm_delta,wm_root_delta;', []), ('U0 WMBody(){wm_entered=TRUE;Sleep(10000);}', []), ('U0 WMWorker(U8 *data){while(TRUE){JobsHndlr(GetRFlags);Yield;}}', []), ('U0 WMKill(U8 *data){while(!wm_entered)Yield;Kill(wm_worker);wm_killed=TRUE;}', []), ('U0 WMDrain(){I64 i;for(i=0;i<8;i++)Yield;FlushMsgs(Fs);}', []), ('Bool WMResult(CJob *job){I64 result=123;return job&&Bt(&job->flags,JOBf_DONE)&&!IsSuspended(Fs)&&JobResScan(job,&result)&&!result;}', []), ('U0 WMOne(){CJob *job;wm_entered=wm_killed=FALSE;wm_worker=Spawn(&WMWorker,NULL,"Wait worker",-1,Fs);wm_killer=Spawn(&WMKill,NULL,"Job killer",-1,Fs);job=TaskExe(wm_worker,Fs,"WMBody;",1<<JOBf_WAKE_MASTER);wm_ok=WMResult(job);}', []), ('Bool WMFinish(){while(!wm_killed||TaskValidate(wm_killer))Yield;wm_count++;WMDrain;return wm_ok&&!TaskValidate(wm_worker);}', []), ('Bool WMCycle(){WMOne;return WMFinish;}', []), ('Bool WMRepeat(){I64 i;if(!WMCycle)return FALSE;wm_base=Fs->data_heap->used_u8s;wm_root=adam_task->data_heap->used_u8s;for(i=0;i<10;i++)if(!WMCycle)return FALSE;return Fs->data_heap->used_u8s==wm_base&&adam_task->data_heap->used_u8s==wm_root;}', []), ('WMRepeat;', ['1']), ('wm_count;', ['11']), ('6*7;', ['42'])]


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
                  scope='Actual TaskExe wake-master cancellation: separate killer retires executing sleeping worker, surviving master resumes, done request returns zero, all helpers retire and exact caller/root heap across ten measured cycles; selected cancellation, not general popup UI')
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
