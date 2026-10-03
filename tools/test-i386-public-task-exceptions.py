#!/usr/bin/env python3
"""Original/native structured exception behavior inside publicly spawned tasks."""
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
        'class CTryProbe{CTask *parent,*child;I64 kind,stage,caught,errors;};',
        'CTryProbe *TryState=CAlloc(sizeof(CTryProbe));',
        'Bool TryHas(CTask *p,CTask *t){CTask *end=(&p->next_child_task)(U8 *)-offset(CTask.next_sibling_task),*c=p->next_child_task;I64 n=0;while(c&&c!=end&&n++<128){if(c==t)return TRUE;c=c->next_sibling_task;}return FALSE;}',
        "U0 TrySimple(U8 *data){CTryProbe *p=data;try{Yield;throw('Probe',TRUE);}catch{if(Fs->except_ch!='Probe')p->errors=1;p->caught++;Fs->catch_except=TRUE;}p->stage=2;}",
        "U0 TryInner(CTryProbe *p){try{Yield;throw('Inner',TRUE);}catch{if(Fs->except_ch!='Inner')p->errors=2;p->caught++;Fs->catch_except=TRUE;}throw('Outer',TRUE);}",
        "U0 TryNested(U8 *data){CTryProbe *p=data;try{TryInner(p);}catch{if(Fs->except_ch!='Outer')p->errors=4;p->caught++;Fs->catch_except=TRUE;}p->stage=2;}",
        'U0 TryExit(U8 *data){CTryProbe *p=data;try{p->stage=2;Exit;p->errors=8;}catch{p->errors=16;Fs->catch_except=TRUE;}p->stage=3;}',
        'U0 TryWait(U8 *data){CTryProbe *p=data;try{p->stage=1;while(TRUE)Yield;}catch{p->errors=32;Fs->catch_except=TRUE;}p->stage=3;}',
        'U0 TryParent(U8 *data){CTryProbe *p=data;p->child=Spawn(&TryWait,p,"Try child",-1,Fs,8192);while(p->stage!=1)Yield;p->stage=2;}',
        'CTask *TrySpawn(I64 kind){if(!kind)return Spawn(&TrySimple,TryState,"Try",-1,Fs,8192);if(kind==1)return Spawn(&TryNested,TryState,"Nested",-1,Fs,8192);return Spawn(&TryExit,TryState,"Exit",-1,Fs,8192);}',
        'Bool TryStart(I64 kind){TryState->kind=kind;TryState->stage=TryState->caught=TryState->errors=0;if(kind==3)TryState->parent=Spawn(&TryParent,TryState,"Parent",-1,Fs,8192);else TryState->parent=TrySpawn(kind);return TryState->parent!=0;}',
        'Bool TryCount(){return TryState->caught==(TryState->kind==0)+2*(TryState->kind==1);}',
        'Bool TryDone(){I64 end=cnts.jiffies+2000;while(TryHas(Fs,TryState->parent)&&cnts.jiffies<end)Yield;return !TryHas(Fs,TryState->parent)&&TryState->stage==2&&!TryState->errors&&TryCount;}',
    ]
    commands = [(source, []) for source in definitions]
    for kind in range(4):
        commands.extend([(f'TryStart({kind});', ['1']), ('TryDone;', ['1'])])
    commands.extend([('Free(TryState);', []), ('6*7;', ['42'])])
    if any(len(source.encode('ascii')) > 255 for source, _ in commands):
        raise ValueError('Task exception contract exceeds the interactive line limit')
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
        source = '\n'.join(source for source, _ in commands[:13]) + '\n'
        (overlay / 'Definitions.HC').write_text(source)
        (overlay / 'Once.HC').write_text('''U0 Report(U8 *text){while(*text)OutU8(0xE9,*text++);}
#include "T:/Definitions.HC"
Report("START original task exceptions\\n");
I64 i;Bool ok=TRUE;
for(i=0;i<4;i++)if(!TryStart(i)||!TryDone) {ok=FALSE;break;}
if(ok) {Free(TryState);Report("PASS original task exceptions\\n");}
else Report("FAIL original task exceptions\\n");
Report("DONE original task exceptions\\n");
''')
        iso = out / 'original.iso'
        subprocess.run([sys.executable, 'tools/build-iso.py', '--overlay',
                        'build/rebuild-test/overlay', '--overlay', str(overlay),
                        '--output', str(iso)], cwd=ROOT, check=True)
        subprocess.run([sys.executable, 'tools/guest-run.py', str(iso), '--out',
                        str(out / 'original'), '--timeout', '90'], cwd=ROOT, check=True)
        if 'PASS original task exceptions\n' not in (out / 'original/debug.log').read_text():
            raise ValueError('Missing original task exception verdict')
        report = {'result': 'pass', 'platform': 'original x64 TempleOS',
                  'definitions_sha256': hashlib.sha256(source.encode()).hexdigest()}
    else:
        disk_hash = sha(args.disk)
        runner = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input']
        behavior = runner(args.disk, out / 'behavior', cpu='486,-fpu', qmp_stdio=True,
                          startup_check={'status': 'ok', 'answers': [], 'commands': commands})
        if sha(args.disk) != disk_hash:
            raise ValueError('Task exception test changed the input disk')
        report = {'result': 'pass', 'behavior': behavior,
                  'disk_sha256': disk_hash, 'source_disk_unchanged': True}
    if sha(Path(__file__)) != checker:
        raise ValueError('Task exception checker changed during execution')
    report.update(checker_sha256=checker, cases=4,
                  scope='Caught/nested exceptions, Exit inside try and descendant cancellation with active try; not uncaught exception policy')
    (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
