#!/usr/bin/env python3
"""Check stale focus uploads after a yielding frame, including terminal retirement."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]
COMMANDS = [('#include "/Kernel/I386/PublicUser.HH"', []),
 ('CTask *fp_one,*fp_two,*fp_old,*fp_new,*fp_holder;I64 fp_before,fp_entered,fp_mode;Bool '
  'fp_release,fp_stage,fp_old_done,fp_new_done,fp_holder_done,fp_blocked,fp_suspended;',
  []),
 ('U0 FPLog(U8 *s){while(*s)OutU8(0xE9,*s++);}', []),
 ('U0 FPTurn(){I64 i;for(i=0;i<8;i++)Yield;}', []),
 ('U0 FPDraw(CDC *dc){fp_stage=TRUE;while(!fp_release)Yield;}', []),
 ('U0 FPHolder(U8 *data){NativeGraphicsPresent(&FPDraw);fp_holder_done=TRUE;}', []),
 ('U0 FPOld(U8 *data){fp_entered|=1;WinFocus(fp_one);fp_old_done=TRUE;}', []),
 ('U0 FPNew(U8 *data){fp_entered|=2;WinFocus(fp_two);fp_new_done=TRUE;}', []),
 ('U0 '
  'FPTerminals(){fp_one=Spawn(&UserCmdLine,NULL,"FocusOne",-1,Fs,8192);fp_two=Spawn(&UserCmdLine,NULL,"FocusTwo",-1,Fs,8192);TaskWait(fp_one,TRUE);TaskWait(fp_two,TRUE);}',
  []),
 ('U0 FPInit(I64 '
  'mode){FlushMsgs;fp_before=Fs->data_heap->used_u8s;fp_mode=mode;fp_entered=0;fp_release=fp_stage=fp_old_done=fp_new_done=fp_holder_done=FALSE;FPTerminals;}',
  []),
 ('U0 FPStart(){fp_holder=Spawn(&FPHolder,NULL,"Focus '
  'holder",-1,Fs,8192);while(!fp_stage)Yield;fp_old=Spawn(&FPOld,NULL,"Older '
  'focus",-1,Fs,8192);while(!(fp_entered&1))Yield;FPTurn;fp_blocked=!fp_old_done;}',
  []),
 ('U0 FPCompete(){fp_new=Spawn(&FPNew,NULL,"Latest '
  'focus",-1,Fs,8192);while(!(fp_entered&2))Yield;FPTurn;fp_blocked=fp_blocked&&!fp_new_done;Suspend(fp_old,TRUE);fp_suspended=IsSuspended(fp_old);if(fp_mode)Kill(fp_one,TRUE,FALSE);}',
  []),
 ('U0 '
  'FPRelease(){fp_release=TRUE;while(TaskValidate(fp_holder)||!fp_new_done)Yield;Suspend(fp_old,FALSE);while(TaskValidate(fp_old)||TaskValidate(fp_new))Yield;FPTurn;}',
  []),
 ('U0 FPObserve(){if(fp_mode)FPLog("FOCUS WAIT observe 1\\n");else FPLog("FOCUS WAIT observe '
  '0\\n");while(sys_focus_task!=Fs)Yield;FPLog("FOCUS WAIT return\\n");}',
  []),
 ('U0 '
  'FPClean(){if(TaskValidate(fp_one))Kill(fp_one,TRUE,FALSE);Kill(fp_two,TRUE,FALSE);while(TaskValidate(fp_one)||TaskValidate(fp_two))Yield;FPTurn;FlushMsgs;}',
  []),
 ('I64 FPState(){I64 '
  'm=0;if(fp_stage&&!fp_holder_done)m|=1;if(fp_blocked)m|=2;if(fp_suspended&&TaskValidate(fp_old))m|=4;return '
  'm;}',
  []),
 ('I64 FPFinish(I64 '
  'm){if(fp_old_done&&fp_new_done&&sys_focus_task==fp_two)m|=8;FPObserve;FPClean;if(fp_holder_done&&sys_focus_task==Fs)m|=16;if(Fs->data_heap->used_u8s==fp_before)m|=32;if(NativeGraphicsStart)m|=64;return '
  'm;}',
  []),
 ('I64 FPRun(I64 mode){I64 m;FPInit(mode);FPStart;FPCompete;m=FPState;FPRelease;return FPFinish(m);}', []),
 ('FPRun(0);',
  ['127'],
  {'begin': 'FOCUS WAIT observe 0\n',
   'end': 'FOCUS WAIT return\n',
   'events': [],
   'exit_keys': ['ctrl', 'alt', 'n'],
   'final_rows': ['TempleOS i386', 'HolyC console', 'Task: FocusTwo', '', '> '],
   'initial_rows': ['TempleOS i386', 'HolyC console', 'Task: FocusTwo', '', '> '],
   'preserve_history': True}),
 ('FPRun(1);',
  ['127'],
  {'begin': 'FOCUS WAIT observe 1\n',
   'end': 'FOCUS WAIT return\n',
   'events': [],
   'exit_keys': ['ctrl', 'alt', 'n'],
   'final_rows': ['TempleOS i386', 'HolyC console', 'Task: FocusTwo', '', '> '],
   'initial_rows': ['TempleOS i386', 'HolyC console', 'Task: FocusTwo', '', '> '],
   'preserve_history': True}),
 ('6*7;', ['42'])]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    source, out = args.disk.resolve(), args.out.resolve()
    commands = list(COMMANDS)
    if out.exists():
        parser.error('Use a fresh output directory')
    sha = lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    runner = ROOT/'tools/i386-kernel-input.py'
    pins = {str(p):sha(p) for p in [source, runner, Path(__file__).resolve()]}
    out.mkdir(parents=True)
    working = out/'working.img'
    shutil.copyfile(source, working)
    report = dict(result='running', scope='Two queued focus requests behind a yielding frame: suspend older request, present newer terminal first, resume stale request last; latest terminal full pixels, live/retired old terminal, task retirement and exact parent heap; not automatic refresh',
                  input_sha256=pins, commands=commands)
    try:
        report['behavior'] = runpy.run_path(str(runner))['run_input'](
            working, out/'qemu', snapshot=False, ram_mib=64,
            cpu='486,-fpu', accel='tcg', qmp_stdio=True,
            startup_check={'status':'ok', 'answers':[], 'commands':commands,
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
