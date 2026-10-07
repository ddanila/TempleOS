#!/usr/bin/env python3
"""Complete a TaskExe job after its master retires and check ownership."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]


def commands(diagnostic=False):
    result = contract_commands()
    if diagnostic:
        result[6] = ('U0 DMOne(){DMStart;Print("DM started\\n");while(TaskValidate(dm_master)||!dm_entered)Yield;Print("DM master retired\\n");dm_release=TRUE;while(!dm_done)Yield;Print("DM job completed\\n");Kill(dm_worker);DMDrain;}', [])
    # Print only after the measured workload so diagnostics do not enter its
    # heap baseline. Keep the independent success assertion as a separate input.
    result[8:9] = [
        ('Bool dm_ok;', []),
        ('U0 DMAudit(){dm_ok=DMRun;Print("DM heaps caller:%d root:%d\\n",dm_delta,dm_root_delta);}', []),
        ('DMAudit;', ['DM heaps caller:0 root:0']),
        ('dm_ok;', ['1']),
    ]
    return result


def contract_commands():
    return [('CTask *dm_worker,*dm_master;Bool dm_entered,dm_release,dm_done;I64 dm_base,dm_root,dm_delta,dm_root_delta;', []), ('U0 DMBody(){dm_entered=TRUE;while(!dm_release)Yield;}', []), ('U0 DMWorker(U8 *data){while(TRUE){JobsHndlr(GetRFlags);if(dm_entered&&dm_release)dm_done=TRUE;Yield;}}', []), ('U0 DMMaster(U8 *data){TaskExe(dm_worker,Fs,"DMBody;",0);Exit;}', []), ('U0 DMDrain(){I64 i;for(i=0;i<8;i++)Yield;FlushMsgs(Fs);}', []), ('U0 DMStart(){dm_entered=dm_release=dm_done=FALSE;dm_worker=Spawn(&DMWorker,NULL,"Surviving worker",-1,Fs);dm_master=Spawn(&DMMaster,NULL,"Retired master",-1,Fs);}', []), ('U0 DMOne(){DMStart;while(TaskValidate(dm_master)||!dm_entered)Yield;dm_release=TRUE;while(!dm_done)Yield;Kill(dm_worker);DMDrain;}', []), ('Bool DMRun(){I64 i;DMOne;dm_base=Fs->data_heap->used_u8s;dm_root=adam_task->data_heap->used_u8s;for(i=0;i<10;i++)DMOne;dm_delta=Fs->data_heap->used_u8s-dm_base;dm_root_delta=adam_task->data_heap->used_u8s-dm_root;return !dm_delta&&!dm_root_delta;}', []), ('DMRun;', ['1']), ('6*7;', ['42'])]


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
                  scope='Actual TaskExe master exits before sibling worker completes; release paused void job after master invalid, retire worker, ten measured cycles exact caller/root heap and continued console; normal completion with retired master, not popup UI')
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
