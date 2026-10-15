#!/usr/bin/env python3
"""Require normal WinMgr to update control geometry without app-derived calls."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]
COMMANDS = [
    ('CCtrl *ad_ctrl;I64 ad_calls;Bool ad_context;', []),
    ('U0 ADUpdate(CCtrl *c){ad_calls++;ad_context=Fs==sys_winmgr_task&&Fs!=c->win_task;c->right=c->win_task->pix_width-2;}', []),
    ('U0 ADStart(){ad_calls=0;ad_context=FALSE;ad_ctrl=CAlloc(sizeof(CCtrl));ad_ctrl->type=CTRLT_GENERIC;ad_ctrl->win_task=Fs;ad_ctrl->update_derived_vals=&ADUpdate;QueIns(ad_ctrl,Fs->last_ctrl);}', []),
    ('I64 ADObserve(){I64 m=0;if(ad_calls>0&&ad_context)m|=1;if(ad_ctrl->right==Fs->pix_width-2)m|=2;QueRem(ad_ctrl);Free(ad_ctrl);return m;}', []),
    ('I64 ADRun(){ADStart;Sleep(250);return ADObserve;}', []),
    ('ADRun;', ['3']),
    ('6*7;', ['42']),
]
if any(len(command[0])>255 for command in COMMANDS):
    raise ValueError("Derived-control fixture exceeds the native input limit")


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
    report = dict(result='running', scope='Automatic derived-control callback, real manager context and derived width; no explicit geometry/presentation calls; not lifecycle or whole-desktop qualification',
                  input_sha256=pins, commands=serializable(commands), ram_mib=args.ram_mib)
    try:
        report['behavior'] = runpy.run_path(str(runner))['run_input'](
            working, out/'qemu', snapshot=False, ram_mib=args.ram_mib,
            cpu='486,-fpu', accel='tcg', qmp_stdio=True,
            startup_check={'status':'ok', 'answers':[], 'commands':commands,
                           'pause_window_manager':False,
                           'rejection_prefixes':('INPUT REJECT ',), 'rejected_answers':['0'],
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
