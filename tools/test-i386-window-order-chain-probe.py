#!/usr/bin/env python3
"""Isolate derived-state update and one native window move before retirement."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]


def commands(diagnostic=False):
    return [
        ('CTask *wa,*wb,*wc;Bool wo_result;', []),
        ('U0 WI(U8 *data){while(TRUE)Yield;}', []),
        ('U0 WS(){wa=Spawn(&WI,NULL,"A",-1,Fs);wb=Spawn(&WI,NULL,"B",-1,Fs);wa->win_inhibit=wb->win_inhibit=0;wa->display_flags=wb->display_flags=0;}WS;', []),
        ('U0 WF(){wo_result=WinToTop(wa,FALSE)>0&&sys_winmgr_task->last_task==wa;sys_focus_task=Fs;}WF;', []),
        ('wo_result;', ['1']),
        ('U0 WI2(){wo_result=WinToTop(wa,FALSE)==0;sys_focus_task=Fs;}WI2;', []),
        ('wo_result;', ['1']),
        ('U0 WB(){sys_focus_task=wa;LBts(&wb->win_inhibit,0);WinToTop(wb,FALSE);wo_result=sys_focus_task==wa&&sys_winmgr_task->last_task==wb;sys_focus_task=Fs;}WB;', []),
        ('wo_result;', ['1']),
        ('U0 WT(){LBtr(&wb->win_inhibit,0);LBts(&wb->display_flags,DISPLAYf_WIN_ON_TOP);WinToTop(wa,FALSE);wo_result=sys_winmgr_task->last_task==wb&&sys_focus_task==wa;sys_focus_task=Fs;}WT;', []),
        ('wo_result;', ['1']),
        ('U0 WC(){LBtr(&wb->display_flags,DISPLAYf_WIN_ON_TOP);wc=Spawn(&WI,NULL,"Child",-1,wa);wc->win_inhibit=wc->display_flags=0;}WC;', []),
        ('U0 WH(){LBts(&wa->display_flags,DISPLAYf_CHILDREN_NOT_ON_TOP);WinToTop(wb,FALSE);WinToTop(wa,FALSE);wo_result=sys_winmgr_task->last_task==wa;sys_focus_task=Fs;}WH;', []),
        ('wo_result;', ['1']),
        ('U0 WR(){LBtr(&wa->display_flags,DISPLAYf_CHILDREN_NOT_ON_TOP);WinToTop(wb,FALSE);WinToTop(wa,FALSE);wo_result=sys_winmgr_task->last_task==wc&&sys_focus_task==wc;sys_focus_task=Fs;}WR;', []),
        ('wo_result;', ['1']),
        ('U0 WE(){sys_focus_task=Fs;Kill(wb);Kill(wa);}WE;', []),
        ('6*7;', ['42']),
    ]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--ram-mib',type=int,choices=(8,16),default=8)
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
                  diagnostic=args.diagnostic, ram_mib=args.ram_mib,
                  scope='Separate actual window calls: movement, idempotence, focus inhibition, always-on-top, child suppression and raising, retirement; per-command checkpoints; does not replace byte-exact full fixture or heap coverage')
    (args.out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
    try:
        disk = args.out / 'working.img'
        shutil.copyfile(args.disk, disk)
        report['behavior'] = runpy.run_path(str(helper))['run_input'](
            disk, args.out / 'behavior', cpu='486,-fpu', ram_mib=args.ram_mib, qmp_stdio=True, snapshot=False,
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
