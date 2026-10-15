#!/usr/bin/env python3
"""Require original public Refresh modes on normal native console views."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]
COMMANDS = [
    ('#include "/Kernel/I386/PublicUser.HH"', []),
    ('I64 RFZero(Bool pump){I64 n=winmgr.updates,m=0;Bool idle=Bt(&Fs->task_flags,TASKf_IDLE);Refresh(0,pump);if(winmgr.updates==n)m|=1;if(Bt(&Fs->task_flags,TASKf_IDLE)==idle)m|=2;if(Bt(&sys_semas[SEMA_JUST_PUMP_MSGS],0)==pump)m|=4;return m;}', []),
    ('U0 RFClear(){LBtr(&sys_semas[SEMA_JUST_PUMP_MSGS],0);}', []),
    ('I64 RFBefore(I64 count,Bool force,Bool idle,Bool full){CDoc *d=DocPut;LBEqu(&Fs->task_flags,TASKf_IDLE,idle);LBEqu(&d->flags,DOCf_DO_FULL_REFRESH,full);if(force)sys_winmgr_task->wake_jiffy=cnts.jiffies+100000;return winmgr.updates;}', []),
    ('I64 RFAfter(I64 n,I64 count,Bool idle,Bool full){CDoc *d=DocPut;I64 m=0;if(winmgr.updates>=n+count)m|=1;if(Bt(&Fs->task_flags,TASKf_IDLE)==idle)m|=2;if(Bt(&d->flags,DOCf_DO_FULL_REFRESH)==full)m|=4;LBtr(&Fs->task_flags,TASKf_IDLE);return m;}', []),
    ('I64 RFStep(I64 count,Bool force,Bool idle,Bool full){CDoc *d=DocPut;I64 n=RFBefore(count,force,idle,full),m;Refresh(count,force);m=RFAfter(n,count,idle,full);if(DocPut==d)m|=8;LBtr(&d->flags,DOCf_DO_FULL_REFRESH);return m;}', []),
    ('RFClear;RFZero(FALSE);', ['7']),
    ('RFClear;RFZero(TRUE);', ['7']),
    ('RFClear;RFStep(1,FALSE,FALSE,FALSE);', ['15']),
    ('RFStep(2,FALSE,TRUE,FALSE);', ['15']),
    ('RFStep(2,FALSE,FALSE,TRUE);', ['15']),
    ('RFStep(1,TRUE,FALSE,FALSE);', ['15']),
    ('I64 RFUploads(){I64 n;Bool ok;Suspend(sys_winmgr_task,TRUE);n=winmgr.updates;ok=NativeGraphicsPresent()&&NativeTextBasePresent();NativeTextBaseRestore;if(winmgr.updates!=n)ok=FALSE;Suspend(sys_winmgr_task,FALSE);return ok;}', []),
    ('RFUploads;', ['1']),
    ('6*7;', ['42']),
]
if any(len(command[0])>255 for command in COMMANDS):
    raise ValueError("Refresh modes fixture exceeds native input limit")


def serializable(value):
    if isinstance(value,dict):
        return {str(key):serializable(item) for key,item in value.items()}
    if isinstance(value,(list,tuple)):
        return [serializable(item) for item in value]
    if isinstance(value,set):
        return [serializable(item) for item in sorted(value)]
    return value


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--ram-mib',type=int,choices=(8,64),default=64)
    args = parser.parse_args()
    source, out = args.disk.resolve(), args.out.resolve()
    commands = list(COMMANDS)
    if out.exists():
        parser.error('Use a fresh output directory')
    sha = lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    runner = ROOT/'tools/i386-kernel-input.py'
    pins = {str(p):sha(p) for p in [source, runner, ROOT/'Kernel/FontStd.HC', Path(__file__).resolve()]}
    out.mkdir(parents=True)
    working = out/'working.img'
    shutil.copyfile(source, working)
    report = dict(result='running', scope='Native ordinary-view Refresh modes matched to pinned original: sync, pump request, one/two frame waits, force wake, idle/full-refresh and document identity; six ordinary modes without app presentation plus isolated raw/explicit uploads excluded from manager count; not full event/desktop qualification',
                  input_sha256=pins, commands=serializable(commands), ram_mib=args.ram_mib)
    try:
        report['behavior'] = runpy.run_path(str(runner))['run_input'](
            working, out/'qemu', snapshot=False, ram_mib=args.ram_mib,
            cpu='486,-fpu', accel='tcg', qmp_stdio=True,
            startup_check={'status':'ok', 'answers':[], 'commands':commands,
                           'pause_window_manager':False,
                           'rejection_prefixes':('INPUT REJECT ',), 
                           'command_timeout':120})
        report['result'] = 'pass'
    except Exception as exc:
        report.update(result='fail', error=str(exc))
        raise
    finally:
        report['inputs_unchanged'] = all(sha(Path(p)) == digest for p,digest in pins.items())
        if not report['inputs_unchanged']:
            report.update(result='fail', error='Native fixture inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':
        raise ValueError(report['error'])


if __name__=='__main__':
    main()
