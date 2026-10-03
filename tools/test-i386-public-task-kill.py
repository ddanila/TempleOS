#!/usr/bin/env python3
"""Original/native public Kill behavior, callbacks and caller break recovery."""
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
        'class CKillProbe{CTask *task;I64 kind,stage,calls,caught,errors;};',
        'CKillProbe *KillState=CAlloc(sizeof(CKillProbe));',
        'Bool KillHas(CTask *p,CTask *t){CTask *end=(&p->next_child_task)(U8 *)-offset(CTask.next_sibling_task),*c=p->next_child_task;I64 n=0;while(c&&c!=end&&n++<128){if(c==t)return TRUE;c=c->next_sibling_task;}return FALSE;}',
        "U0 KillRecover(){KillState->calls++;if(Fs->task_end_cb||Bt(&Fs->task_flags,TASKf_KILL_TASK))KillState->errors=1;throw('Resume',TRUE);}",
        'U0 KillWait(CKillProbe *p){while(p->stage!=3)Yield;}',
        "U0 KillWorker(U8 *data){CKillProbe *p=data;p->stage=1;if(p->kind==4)Fs->task_end_cb=&KillRecover;try{if(p->kind%4==2)Sleep(100000);KillWait(p);}catch{if(Fs->except_ch!='Resume')p->errors=2;p->caught++;Fs->catch_except=TRUE;p->stage=2;KillWait(p);}}",
        "Bool KillBreak(){try{Kill(KillState->task,TRUE,TRUE);KillState->errors=4;}catch{if(Fs->except_ch!='Break')KillState->errors=8;KillState->caught++;Fs->catch_except=TRUE;}return !KillState->errors&&KillState->caught==1&&KillHas(Fs,KillState->task);}",
        'Bool KillStart(I64 k){KillState->kind=k;KillState->stage=KillState->calls=KillState->caught=KillState->errors=0;KillState->task=Spawn(&KillWorker,KillState,"Kill",-1,Fs,8192);return KillState->task!=0;}',
        'Bool KillReady(){I64 end=cnts.jiffies+2000;while(KillState->stage!=1&&cnts.jiffies<end)Yield;return KillState->stage==1;}',
        'Bool KillDead(){I64 end=cnts.jiffies+2000;while(KillHas(Fs,KillState->task)&&cnts.jiffies<end)Yield;return !KillHas(Fs,KillState->task)&&!KillState->errors;}',
        'Bool KillAsync(){CTask *t=KillState->task;I64 w=t->wake_jiffy,f=t->task_flags;return Kill(t,FALSE)&&t->wake_jiffy==w&&t->task_flags==(f|(1<<TASKf_KILL_TASK));}',
        'Bool KillCancel(I64 k){if(k==0)return Kill(KillState->task,FALSE);if(k==3||k==7)LBts(&KillState->task->task_flags,TASKf_SUSPENDED);if(k==5&&!KillBreak)return FALSE;if(k>=6)return KillAsync;return Kill(KillState->task);}',
        'Bool KillResume(){return KillHas(Fs,KillState->task)&&KillState->stage==2&&KillState->calls==1&&KillState->caught==1&&!KillState->errors;}',
        'Bool KillStale(){return !Kill(KillState->task,FALSE);}',
        'Bool KillProtected(){return !Kill(NULL)&&!Kill(Gs->seth_task,FALSE);}',
        'Bool KillShift(){I64 a,b,r;FlushMsgs;LBts(&Fs->task_flags,TASKf_BREAK_TO_SHIFT_ESC);r=Kill(KillState->task,TRUE,TRUE);LBtr(&Fs->task_flags,TASKf_BREAK_TO_SHIFT_ESC);return !r&&ScanMsg(&a,&b)==MSG_KEY_DOWN&&a==CH_SHIFT_ESC&&b==0x20100000201;}',
    ]
    commands = [(source, []) for source in definitions]
    commands.append(('KillProtected;', ['1']))
    for kind in range(8):
        commands.append((f'KillStart({kind});', ['1']))
        if kind:
            commands.append(('KillReady;', ['1']))
        commands.append((f'KillCancel({kind});', ['1']))
        if kind == 4:
            commands.extend([('KillResume;', ['1']), ('KillState->stage=3;', [])])
        commands.extend([('KillDead;', ['1']), ('KillStale;', ['1'])])
    commands.extend([('KillStart(1);', ['1']), ('KillReady;', ['1']),
                     ('KillShift;', ['1']), ('KillHas(Fs,KillState->task);', ['1']),
                     ('Kill(KillState->task);', ['1']), ('KillDead;', ['1']),
                     ('KillStale;', ['1']), ('Free(KillState);', []), ('6*7;', ['42'])])
    if any(len(source.encode('ascii')) > 255 for source, _ in commands):
        raise ValueError('Task cancellation contract exceeds the interactive line limit')
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
        source = '\n'.join(source for source, _ in commands[:16]) + '\n'
        (overlay / 'Definitions.HC').write_text(source)
        (overlay / 'Once.HC').write_text('''U0 Report(U8 *text){while(*text)OutU8(0xE9,*text++);}
#include "T:/Definitions.HC"
Report("START original public task cancellation\\n");
I64 i;Bool ok=KillProtected;
for(i=0;i<8&&ok;i++) {
 if(!KillStart(i)) {ok=FALSE;break;}
 if(i&&!KillReady) {ok=FALSE;break;}
 if(!KillCancel(i)) {ok=FALSE;break;}
 if(i==4) {if(!KillResume)ok=FALSE;KillState->stage=3;}
 if(!KillDead||!KillStale)ok=FALSE;
}
if(ok)ok=KillStart(1)&&KillReady&&KillShift&&KillHas(Fs,KillState->task)&&Kill(KillState->task)&&KillDead&&KillStale;
if(ok) {Free(KillState);Report("PASS original public task cancellation\\n");}
else Report("FAIL original public task cancellation\\n");
Report("DONE original public task cancellation\\n");
''')
        iso = out / 'original.iso'
        subprocess.run([sys.executable, 'tools/build-iso.py', '--overlay',
                        'build/rebuild-test/overlay', '--overlay', str(overlay),
                        '--output', str(iso)], cwd=ROOT, check=True)
        subprocess.run([sys.executable, 'tools/guest-run.py', str(iso), '--out',
                        str(out / 'original'), '--timeout', '90'], cwd=ROOT, check=True)
        if 'PASS original public task cancellation\n' not in (out / 'original/debug.log').read_text():
            raise ValueError('Missing original task cancellation verdict')
        report = {'result': 'pass', 'platform': 'original x64 TempleOS',
                  'definitions_sha256': hashlib.sha256(source.encode()).hexdigest()}
    else:
        disk_hash = sha(args.disk)
        runner = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input']
        behavior = runner(args.disk, out / 'behavior', cpu='486,-fpu', qmp_stdio=True,
                          startup_check={'status': 'ok', 'answers': [], 'commands': [('HashFind("MAlloc",Fs->hash_table,HTT_FUN)!=0;', ['1']),
                                                                       ('HashFind("Kill",Fs->hash_table,HTT_FUN)!=0;', ['1'])] + commands})
        if sha(args.disk) != disk_hash:
            raise ValueError('Task cancellation test changed the input disk')
        report = {'result': 'pass', 'behavior': behavior,
                  'disk_sha256': disk_hash, 'source_disk_unchanged': True}
    if sha(Path(__file__)) != checker:
        raise ValueError('Task cancellation checker changed during execution')
    report.update(checker_sha256=checker, cases=9,
                  scope='Public Kill: pre-entry, running, sleeping, suspended, callback recovery, caller Break and Shift-Esc message delivery; null/protected/stale rejection and unchanged async wake/flags; not self-break or I/O cancellation')
    (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
