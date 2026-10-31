#!/usr/bin/env python3
"""Overflow the hardware queue while its decoder is suspended, then recover input."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

ROOT = Path(__file__).resolve().parents[1]


def commands():
    definitions = [
        'U0 KeyLog(U8*s){while(*s)OutU8(0xE9,*s++);}',
        'CTask *kw,*kh;',
        'I64 KOff=offset(CTask.next_sibling_task);',
        'CTask *KHead(CTask*r){return (&r->next_child_task)(U8 *)-KOff;}',
        'U0 KInit(){CTask*r=Fs->parent_task;kw=r->next_child_task;kh=KHead(r);}',
        'Bool KEq(){return !StrCmp(kw->task_name,"Keyboard");}',
        'U0 KStep(){kw=kw->next_sibling_task;}',
        'Bool KNext(){if(kw==kh||KEq)return FALSE;KStep;return TRUE;}',
        'CTask *KLWorker(){KInit;while(KNext){}if(kw==kh)return NULL;return kw;}',
        'I64 KeyLossCalls=0;',
        'I64 KeyLossCall(U8*data){KeyLossCalls++;return 1;}',
        'CJob *KJob(){return CAlloc(sizeof(CJob));}',
        'U0 KSetup(CJob*j){j->job_code=JOBT_CALL;j->addr=&KeyLossCall;}',
        'U0 KAttach(CJob*j){j->ctrl=&Fs->srv_ctrl;j->flags=1<<JOBf_FREE_ON_COMPLETE;}',
        'U0 KEnqueue(CJob*j){QueIns(j,Fs->srv_ctrl.last_waiting);}',
        'U0 KeyLossQueue(){CJob*j=KJob();KSetup(j);KAttach(j);KEnqueue(j);}',
        'I64 ka,ks;',
        'Bool KRead(){return GetMsg(&ka,&ks,1<<MSG_KEY_DOWN)==MSG_KEY_DOWN;}',
        'Bool KCheck(){return ka==0&&(ks&127)==42;}',
        'Bool KeyLossPrime(){KeyLog("KEY LOSS prime\\n");return KRead&&KCheck;}',
        'U0 KHold(CTask*t){Suspend(t);KeyLog("KEY LOSS ready\\n");Sleep(2000);}',
        'U0 KRelease(CTask*t){KeyLossQueue;Suspend(t,FALSE);Yield;}',
        'U0 KDone(){KeyLog("KEY LOSS done\\n");}',
        'Bool KProceed(CTask*t){KHold(t);KRelease(t);KDone;return TRUE;}',
        'Bool KReady(CTask*t){return t&&KeyLossPrime;}',
        'Bool KeyLoss(){CTask*t=KLWorker;if(!KReady(t))return 0;return KProceed(t);}',
    ]
    history = ['TempleOS i386', 'HolyC console', '',
               ' '*33+'TempleOS V5.03', '', ' '*25+'Public Domain Operating System',
               '', 'Help & Index, Quick Start: Cmd line', '']
    def typed(source):
        text = '> ' + source
        return [text[index:index+79] for index in range(0,len(text)+1,79)]
    for source in definitions:
        history += typed(source)
    call = 'KeyLoss;'
    before = (history + typed(call))[-60:]
    after = (history + typed(call) + ['1', '> ', 'Input reset', '> '])[-60:]
    interaction = {'begin': 'KEY LOSS prime\n', 'end': 'KEY LOSS done\n',
                   'initial_rows': before, 'final_rows': after,
                   'preserve_history': True, 'events': [{'shift_key': 'a'}, {'wait_log': 'KEY LOSS ready\n'}] + [action for _ in range(40) for action in ({'key': 'a'}, {'delay': 0.01})]}
    return [(source, []) for source in definitions] + [(call, ['1', '> ', 'Input reset'], interaction), ('KeyLossCalls==1;', ['1']), ('I64 loss_recovered=42;loss_recovered;', ['42'])]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    disk_hash, checker = sha(args.disk), sha(Path(__file__))
    report = {'disk_sha256': disk_hash, 'checker_sha256': checker,
              'scope': 'Hardware raw-queue overflow, exactly one console reset, discarded Shift release, queued CALL preserved exactly once and recovered typing; not focused-child discontinuity notification'}
    try:
        runner = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input']
        report['behavior'] = runner(args.disk, out / 'behavior', cpu='486,-fpu', qmp_stdio=True, welcome=True,
            startup_check={'status': 'ok', 'answers': [], 'commands': commands(),
                           'pause_window_manager': False})
        resets = (out / 'behavior/debug.log').read_text().count('INPUT RESET\n')
        if resets != 1:
            raise ValueError(f'Expected one input reset, got {resets}')
        report['input_resets'] = resets
        if sha(Path(__file__)) != checker:
            raise ValueError('Keyboard checker changed during execution')
        if sha(args.disk) != disk_hash:
            raise ValueError('Keyboard checker modified the input disk')
        report['result'] = 'pass'
    except Exception as error:
        report.update(result='fail', error=str(error))
        raise
    finally:
        report['source_disk_unchanged'] = sha(args.disk) == disk_hash
        (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')


if __name__ == '__main__':
    main()
