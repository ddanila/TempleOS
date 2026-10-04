#!/usr/bin/env python3
"""Original/native public job dispatch, job metadata and wake flags."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]


def behavior_commands():
    definitions = [
        'CJob *DispatchJob;',
        'I64 DispatchCall(U8 *data){return data(I64)+7;}',
        "I64 DispatchThrow(U8 *data){throw('JobTest',TRUE);return 99;}",
        'U0 DispatchQueue(){DispatchJob=CAlloc(sizeof(CJob));DispatchJob->ctrl=&Fs->srv_ctrl;DispatchJob->job_code=JOBT_CALL;DispatchJob->addr=&DispatchCall;DispatchJob->fun_arg=35;QueIns(DispatchJob,Fs->srv_ctrl.last_waiting);}',
        'Bool DispatchDone(I64 res){return Fs->srv_ctrl.next_done==DispatchJob&&DispatchJob->res==res&&Bt(&DispatchJob->flags,JOBf_DISPATCHED)&&Bt(&DispatchJob->flags,JOBf_DONE)&&!Fs->srv_ctrl.flags;}',
        'U0 DispatchFree(){QueRem(DispatchJob);Free(DispatchJob->aux_str);Free(DispatchJob);}',
        'Bool DispatchOrdinary(){DispatchQueue;return JobsHndlr(GetRFlags)==1&&DispatchDone(42)&&JobsHndlr(GetRFlags)==0;}',
        'Bool DispatchException(){DispatchQueue;DispatchJob->addr=&DispatchThrow;return JobsHndlr(GetRFlags)==1&&DispatchDone(0);}',
        'Bool DispatchSource(){DispatchQueue;DispatchJob->job_code=JOBT_EXE_STR;DispatchJob->aux_str=StrNew("6*7;");return JobsHndlr(GetRFlags)==1&&DispatchDone(42);}',
        'Bool DispatchMasterDone(){return JobsHndlr(GetRFlags)==1&&DispatchDone(42)&&!IsSuspended&&sys_focus_task==Fs;}',
        'Bool DispatchMaster(){CTask *old=sys_focus_task;Bool ok;DispatchQueue;DispatchJob->master_task=Fs;DispatchJob->flags=1<<JOBf_WAKE_MASTER|1<<JOBf_FOCUS_MASTER;Suspend;ok=DispatchMasterDone;sys_focus_task=old;return ok;}',
        'I64 DispatchStage=0;Bool DispatchStop=FALSE;',
        'I64 DispatchWorker(U8 *data){DispatchStage=data(I64);while(!DispatchStop)Yield;DispatchStage=43;return 0;}',
        'U0 DispatchSpawnQueue(){DispatchQueue;DispatchJob->job_code=JOBT_SPAWN_TASK;DispatchJob->addr=&DispatchWorker;DispatchJob->fun_arg=42;DispatchJob->aux1=Fs;DispatchJob->aux2=8192;DispatchJob->flags=256;}',
        'Bool DispatchSpawn(){DispatchSpawnQueue;return JobsHndlr(GetRFlags)==1&&DispatchDone(0)&&DispatchJob->spawned_task&&DispatchJob->spawned_task->parent_task==Fs;}',
        'Bool DispatchRun(){I64 end=cnts.jiffies+2000;while(!DispatchStage&&cnts.jiffies<end)Yield;return DispatchStage==42;}',
        'Bool DispatchFinish(){I64 end=cnts.jiffies+2000;DispatchStop=TRUE;while(DispatchStage!=43&&cnts.jiffies<end)Yield;return DispatchStage==43;}',
    ]
    commands = [(source, []) for source in definitions]
    for name in ('DispatchOrdinary','DispatchException','DispatchSource','DispatchMaster'):
        answers=['1']
        if name=='DispatchSource': answers=['42','1']
        commands += [(name+';', answers), ('DispatchFree;', [])]
    commands += [('DispatchSpawn;', ['1']), ('DispatchRun;', ['1']),
                 ('DispatchFinish;', ['1']), ('DispatchFree;', []), ('6*7;', ['42'])]
    if any(len(source.encode('ascii')) > 255 for source, _ in commands):
        raise ValueError('Dispatch contract exceeds the interactive line limit')
    return commands


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path, nargs='?')
    parser.add_argument('--original', action='store_true')
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    if args.original == (args.disk is not None):
        parser.error('Specify either --original or an i386 disk')
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    (out / 'result.json').unlink(missing_ok=True)
    sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
    checker = sha(Path(__file__))
    commands = behavior_commands()
    if args.original:
        overlay = out / 'overlay'
        overlay.mkdir(exist_ok=True)
        source = '\n'.join(source for source, _ in commands[:17]) + '\n'
        (overlay / 'Definitions.HC').write_text(source)
        (overlay / 'Once.HC').write_text('''U0 Report(U8 *text){while(*text)OutU8(0xE9,*text++);}
#include "T:/Definitions.HC"
Report("START original public job dispatch\\n");
Bool ok=DispatchOrdinary;DispatchFree;
if(ok){ok=DispatchException;DispatchFree;}
if(ok){ok=DispatchSource;DispatchFree;}
if(ok){ok=DispatchMaster;DispatchFree;}
if(ok){ok=DispatchSpawn;if(ok)ok=DispatchRun;if(!DispatchFinish)ok=FALSE;DispatchFree;}
if(ok)Report("PASS original public job dispatch\\n");
else Report("FAIL original public job dispatch\\n");
Report("DONE original public job dispatch\\n");
''')
        iso = out / 'original.iso'
        subprocess.run([sys.executable, 'tools/build-iso.py', '--overlay',
                        'build/rebuild-test/overlay', '--overlay', str(overlay),
                        '--output', str(iso)], cwd=ROOT, check=True)
        subprocess.run([sys.executable, 'tools/guest-run.py', str(iso), '--out',
                        str(out / 'original'), '--timeout', '90'], cwd=ROOT, check=True)
        if 'PASS original public job dispatch\n' not in (out / 'original/debug.log').read_text():
            raise ValueError('Missing original public message verdict')
        report = {'result': 'pass', 'platform': 'original x64 TempleOS',
                  'definitions_sha256': hashlib.sha256(source.encode()).hexdigest()}
    else:
        disk_hash = sha(args.disk)
        runner = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input']
        behavior = runner(args.disk, out / 'behavior', cpu='486,-fpu', qmp_stdio=True,
                          startup_check={'status': 'ok', 'answers': [], 'commands': [('HashFind("MAlloc",Fs->hash_table,HTT_FUN)!=0;', ['1']),
                                                                       ('HashFind("JobsHndlr",Fs->hash_table,HTT_FUN)!=0;', ['1'])] + commands})
        if sha(args.disk) != disk_hash:
            raise ValueError('Public message test changed the input disk')
        report = {'result': 'pass', 'behavior': behavior,
                  'disk_sha256': disk_hash, 'source_disk_unchanged': True}
    if sha(Path(__file__)) != checker:
        raise ValueError('Public message checker changed during execution')
    report.update(checker_sha256=checker, cases=5,
                  scope='JobsHndlr callback argument/result, callback exception, queued source result, master focus/wake and spawned-child parent/argument/lifecycle; not scanning, free/exit completion flags or macro recording')
    (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
