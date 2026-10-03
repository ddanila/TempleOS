#!/usr/bin/env python3
"""Original-behavior oracle for queued descendants when a parent returns."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]


def behavior_commands():
    commands = [
        ('class CDescProbe{CTask *parent,*child;I64 ready,ticks;Bool wait_child,exit_now,tree,sleep;};', []),
        ('CDescProbe *DescState=CAlloc(sizeof(CDescProbe));', []),
        ('Bool DescHas(CTask *p,CTask *t){CTask *end=(&p->next_child_task)(U8 *)-offset(CTask.next_sibling_task),*c=p->next_child_task;I64 n=0;while(c&&c!=end&&n++<128){if(c==t)return TRUE;c=c->next_sibling_task;}return FALSE;}', []),
        ('U0 DescLeaf(U8 *data){CDescProbe *p=data;while(TRUE){p->ticks++;if(p->sleep)Sleep(100000);else Yield;}}', []),
        ('U0 DescBranch(U8 *data){Spawn(&DescLeaf,data,"Leaf",-1,Fs,8192);while(TRUE)Yield;}', []),
        ('CTask *DescChild(CDescProbe *p){if(p->tree)return Spawn(&DescBranch,p,"Branch",-1,Fs,8192);return Spawn(&DescLeaf,p,"Leaf",-1,Fs,8192);}', []),
        ('U0 DescParent(U8 *data){CDescProbe *p=data;p->child=DescChild(p);if(p->wait_child)while(!p->ticks)Yield;p->ready=1;if(p->exit_now)Exit;}', []),
        ('U0 DescReset(Bool wait,Bool quit,Bool tree,Bool sleep){DescState->ready=DescState->ticks=0;DescState->wait_child=wait;DescState->exit_now=quit;DescState->tree=tree;DescState->sleep=sleep;}', []),
        ('Bool DescStart(Bool wait=FALSE,Bool quit=FALSE,Bool tree=FALSE,Bool sleep=FALSE){DescReset(wait,quit,tree,sleep);DescState->parent=Spawn(&DescParent,DescState,"Parent",-1,Fs,8192);return DescState->parent!=0;}', []),
        ('Bool DescDone(){I64 end=cnts.jiffies+2000;while(DescHas(Fs,DescState->parent)&&cnts.jiffies<end)Yield;return DescState->ready&&!DescHas(Fs,DescState->parent)&&(DescState->wait_child||!DescState->ticks);}', []),
        ('Bool DescStill(){I64 n=DescState->ticks,i;for(i=0;i<20;i++)Yield;return DescState->ticks==n;}', []),
        ('DescStart;', ['1']),
        ('DescDone;', ['1']),
        ('DescStill;', ['1']),
        ('DescStart(TRUE);', ['1']),
        ('DescDone;', ['1']),
        ('DescStill;', ['1']),
        ('DescStart(TRUE,TRUE);', ['1']),
        ('DescDone;', ['1']),
        ('DescStill;', ['1']),
        ('DescStart(TRUE,FALSE,FALSE,TRUE);', ['1']),
        ('DescDone;', ['1']),
        ('DescStill;', ['1']),
        ('DescStart(TRUE,TRUE,TRUE,TRUE);', ['1']),
        ('DescDone;', ['1']),
        ('DescStill;', ['1']),
        ('Free(DescState);', []),
        ('6*7;', ['42']),
    ]
    if any(len(source.encode('ascii')) > 255 for source, _ in commands):
        raise ValueError('Descendant contract exceeds the interactive line limit')
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
        definitions = [s for s, _ in commands
                       if s.startswith(('class ', 'CDescProbe *', 'CTask *', 'Bool ', 'U0 '))]
        source = '\n'.join(definitions) + '\n'
        (overlay / 'Definitions.HC').write_text(source)
        (overlay / 'Once.HC').write_text('''U0 Report(U8 *text){while(*text)OutU8(0xE9,*text++);}
#include "T:/Definitions.HC"
Report("START original queued descendants\n");
I64 i;Bool ok=TRUE;
for(i=0;i<5;i++)if(!DescStart(i>0,i==2||i==4,i==4,i>=3)||!DescDone||!DescStill) {ok=FALSE;break;}
if(ok) {
  Free(DescState);
  Report("PASS original queued descendants\n");
} else Report("FAIL original queued descendants\n");
Report("DONE original queued descendants\n");
''')
        iso = out / 'original.iso'
        subprocess.run([sys.executable, 'tools/build-iso.py', '--overlay',
                        'build/rebuild-test/overlay', '--overlay', str(overlay),
                        '--output', str(iso)], cwd=ROOT, check=True)
        subprocess.run([sys.executable, 'tools/guest-run.py', str(iso), '--out',
                        str(out / 'original'), '--timeout', '90'], cwd=ROOT, check=True)
        if 'PASS original queued descendants\n' not in (out / 'original/debug.log').read_text():
            raise ValueError('Missing original descendant behavior verdict')
        report = {'result': 'pass', 'platform': 'original x64 TempleOS',
                  'definitions_sha256': hashlib.sha256(source.encode()).hexdigest()}
    else:
        disk_hash = sha(args.disk)
        runner = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input']
        behavior = runner(args.disk, out / 'behavior', cpu='486,-fpu', qmp_stdio=True,
                          startup_check={'status': 'ok', 'answers': [], 'commands': commands})
        if sha(args.disk) != disk_hash:
            raise ValueError('Descendant test changed the input disk')
        report = {'result': 'pass', 'behavior': behavior,
                  'disk_sha256': disk_hash, 'source_disk_unchanged': True}
    if sha(Path(__file__)) != checker:
        raise ValueError('Descendant checker changed during execution')
    report.update(checker_sha256=checker,
                  cases=5,
                  scope='Queued descendants on parent return/Exit, before entry, running, sleeping and a grandchild; not public Kill or dormant disposal')
    (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
