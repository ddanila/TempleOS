#!/usr/bin/env python3
"""Check raw-console restoration against yielding graphics ownership and cancellation."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]
COMMANDS = [('CTask *rp_holder,*rp_waiter;I64 rp_mode,rp_stage,rp_before;Bool '
  'rp_release,rp_holder_done,rp_entered,rp_done,rp_recursive,rp_blocked,rp_cancelled;',
  []),
 ('U0 RPDraw(CDC '
  '*dc){NativeTextBaseRestore;rp_recursive=!NativeGraphicsPresent();rp_stage=1;while(!rp_release)Yield;}',
  []),
 ('U0 RPHolder(U8 *data){NativeGraphicsPresent(&RPDraw);rp_holder_done=TRUE;}', []),
 ('U0 RPWaiter(U8 *data){rp_entered=TRUE;NativeTextBaseRestore;rp_done=TRUE;}', []),
 ('U0 RPTurn(){I64 i;for(i=0;i<8;i++)Yield;}', []),
 ('U0 RPWaitStart(){rp_entered=rp_done=FALSE;rp_waiter=Spawn(&RPWaiter,NULL,"Raw '
  'waiter",-1,Fs,8192);while(!rp_entered)Yield;RPTurn;}',
  []),
 ('Bool RPBlocked(){return !rp_done&&TaskValidate(rp_waiter)&&TaskValidate(rp_holder);}', []),
 ('U0 RPStart(I64 '
  'mode){FlushMsgs;rp_before=Fs->data_heap->used_u8s;rp_mode=mode;rp_stage=0;rp_release=rp_holder_done=rp_recursive=FALSE;rp_holder=Spawn(&RPHolder,NULL,"Raw '
  'holder",-1,Fs,8192);while(!rp_stage)Yield;}',
  []),
 ('U0 '
  'RPCancel(){rp_cancelled=TRUE;if(rp_mode&2){rp_cancelled=Kill(rp_waiter,TRUE,FALSE)&&!rp_done;RPTurn;RPWaitStart;rp_cancelled=rp_cancelled&&RPBlocked;}}',
  []),
 ('Bool RPStop(){if(rp_mode&1)return '
  'Kill(rp_holder,TRUE,FALSE)&&!rp_holder_done;rp_release=TRUE;while(TaskValidate(rp_holder))Yield;return '
  'rp_holder_done;}',
  []),
 ('I64 RPFinish(){I64 '
  'm=0;if(rp_stage==1&&rp_recursive)m|=1;if(rp_blocked)m|=2;if(RPStop)m|=4;while(TaskValidate(rp_waiter))Yield;RPTurn;FlushMsgs;if(rp_done)m|=8;if(rp_cancelled)m|=16;return '
  'm;}',
  []),
 ('I64 RPRun(I64 mode){I64 '
  'm;RPStart(mode);RPWaitStart;rp_blocked=RPBlocked;RPCancel;m=RPFinish;if(Fs->data_heap->used_u8s==rp_before)m|=32;if(NativeGraphicsStart)m|=64;if(!rp_blocked)NativeTextBaseRestore;return '
  'm;}',
  []),
 ('RPRun(0);', ['127']),
 ('RPRun(1);', ['127']),
 ('RPRun(2);', ['127']),
 ('RPRun(3);', ['127']),
 ('I64 rp_retry=NativeGraphicsPresent;NativeTextBaseRestore;rp_retry;', ['1']),
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
    report = dict(result='running', scope='Raw-console restoration waits for a yielding frame, same-task deferral retains ownership, waiter cancellation, holder completion/kill, exact parent heap and full-console pixels; not focus lifetime or automatic refresh',
                  input_sha256=pins, commands=commands)
    try:
        report['behavior'] = runpy.run_path(str(runner))['run_input'](
            working, out/'qemu', snapshot=False, ram_mib=64,
            cpu='486,-fpu', accel='tcg', qmp_stdio=True,
            startup_check={'status':'ok', 'answers':[], 'commands':commands,
                           'rejection_prefixes':('INPUT REJECT ',), 'rejected_answers':['125'],
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
