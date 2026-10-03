#!/usr/bin/env python3
"""Original/native one-shot task exit callbacks and exception recovery."""
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
        'class CEndProbe{CTask *task,*child;I64 kind,stage,calls,caught,errors;};',
        'CEndProbe *EndState=CAlloc(sizeof(CEndProbe));',
        'Bool EndHas(CTask *p,CTask *t){CTask *end=(&p->next_child_task)(U8 *)-offset(CTask.next_sibling_task),*c=p->next_child_task;I64 n=0;while(c&&c!=end&&n++<128){if(c==t)return TRUE;c=c->next_sibling_task;}return FALSE;}',
        'U0 EndChild(U8 *data){CEndProbe *p=data;p->stage=3;}',
        'U0 EndCheck(){CEndProbe *p=EndState;p->calls++;if(Fs->task_end_cb||Fs->wake_jiffy||Bt(&Fs->task_flags,TASKf_KILL_TASK)||Bt(&Fs->task_flags,TASKf_SUSPENDED)||Bt(&Fs->task_flags,TASKf_AWAITING_MSG))p->errors=1;}',
        'U0 EndExit(){EndCheck;EndState->stage=2;Exit;}',
        "U0 EndThrow(){EndCheck;throw('Resume',TRUE);}",
        'U0 EndWorker(U8 *data){CEndProbe *p=data;Fs->task_end_cb=&EndExit;p->stage=1;if(p->kind==1)Exit;}',
        "U0 EndResume(U8 *data){CEndProbe *p=data;Fs->task_end_cb=&EndThrow;try{Exit;}catch{if(Fs->except_ch!='Resume')p->errors=2;p->caught++;Fs->catch_except=TRUE;}p->child=Spawn(&EndChild,p,\"Child\",-1,Fs,8192);while(p->stage!=3)Yield;}",
        'U0 EndWait(U8 *data){CEndProbe *p=data;Fs->task_end_cb=&EndExit;try{p->stage=1;while(TRUE)Yield;}catch{p->errors=4;Fs->catch_except=TRUE;}}',
        'U0 EndParent(U8 *data){CEndProbe *p=data;p->child=Spawn(&EndWait,p,"Child",-1,Fs,8192);while(p->stage!=1)Yield;}',
        'CTask *EndSpawn(I64 k){if(k==2)return Spawn(&EndResume,EndState,"Resume",-1,Fs,8192);if(k==3)return Spawn(&EndParent,EndState,"Parent",-1,Fs,8192);return Spawn(&EndWorker,EndState,"End",-1,Fs,8192);}',
        'Bool EndStart(I64 k){EndState->kind=k;EndState->stage=EndState->calls=EndState->caught=EndState->errors=0;EndState->task=EndSpawn(k);return EndState->task!=0;}',
        'Bool EndDone(){I64 end=cnts.jiffies+2000;while(EndHas(Fs,EndState->task)&&cnts.jiffies<end)Yield;return !EndHas(Fs,EndState->task)&&!EndState->errors&&EndState->calls==1&&EndState->caught==(EndState->kind==2)&&EndState->stage==2+(EndState->kind==2);}',
    ]
    commands = [(source, []) for source in definitions]
    for kind in range(4):
        commands.extend([(f'EndStart({kind});', ['1']), ('EndDone;', ['1'])])
    commands.extend([('Free(EndState);', []), ('6*7;', ['42'])])
    if any(len(source.encode('ascii')) > 255 for source, _ in commands):
        raise ValueError('Task end callback contract exceeds the interactive line limit')
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
        source = '\n'.join(source for source, _ in commands[:14]) + '\n'
        (overlay / 'Definitions.HC').write_text(source)
        (overlay / 'Once.HC').write_text('''U0 Report(U8 *text){while(*text)OutU8(0xE9,*text++);}
#include "T:/Definitions.HC"
Report("START original task end callbacks\\n");
I64 i;Bool ok=TRUE;
for(i=0;i<4;i++)if(!EndStart(i)||!EndDone) {ok=FALSE;Report("Case failed\\n");break;}
if(ok) {Free(EndState);Report("PASS original task end callbacks\\n");}
else Report("FAIL original task end callbacks\\n");
Report("DONE original task end callbacks\\n");
''')
        iso = out / 'original.iso'
        subprocess.run([sys.executable, 'tools/build-iso.py', '--overlay',
                        'build/rebuild-test/overlay', '--overlay', str(overlay),
                        '--output', str(iso)], cwd=ROOT, check=True)
        subprocess.run([sys.executable, 'tools/guest-run.py', str(iso), '--out',
                        str(out / 'original'), '--timeout', '90'], cwd=ROOT, check=True)
        if 'PASS original task end callbacks\n' not in (out / 'original/debug.log').read_text():
            raise ValueError('Missing original task exception verdict')
        report = {'result': 'pass', 'platform': 'original x64 TempleOS',
                  'definitions_sha256': hashlib.sha256(source.encode()).hexdigest()}
    else:
        disk_hash = sha(args.disk)
        runner = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input']
        behavior = runner(args.disk, out / 'behavior', cpu='486,-fpu', qmp_stdio=True,
                          startup_check={'status': 'ok', 'answers': [], 'commands': commands})
        if sha(args.disk) != disk_hash:
            raise ValueError('Task end callback test changed the input disk')
        report = {'result': 'pass', 'behavior': behavior,
                  'disk_sha256': disk_hash, 'source_disk_unchanged': True}
    if sha(Path(__file__)) != checker:
        raise ValueError('Task end callback checker changed during execution')
    report.update(checker_sha256=checker, cases=4,
                  scope='One-shot callbacks on return, explicit Exit, exception recovery and descendant cancellation; not public Kill')
    (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
