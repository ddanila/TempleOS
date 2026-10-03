#!/usr/bin/env python3
"""Original/native public task job-queue initialization."""
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
        'Bool QueueReady(CTask *t=NULL){CJobCtrl *c;if(!t)t=Fs;c=&t->srv_ctrl;return !c->flags&&c->next_waiting==(&c->next_waiting)(CJob *)&&c->last_waiting==c->next_waiting&&c->next_done==(&c->next_done)(CJob *)&&c->last_done==c->next_done;}',
        'I64 QueueResult=0;',
        'U0 QueueWorker(U8 *data){if(QueueReady)QueueResult=1;else QueueResult=-1;}',
        'Bool QueueChild(){CTask *t;I64 end;QueueResult=0;t=Spawn(&QueueWorker,0,"Queues",-1,Fs,8192);if(!t)return FALSE;end=cnts.jiffies+2000;while(!QueueResult&&cnts.jiffies<end)Yield;return QueueResult==1;}',
        'CTask *QueueOwner;',
        'U0 QueueAdd(Bool done){CJob *j=CAlloc(sizeof(CJob),QueueOwner),*h=&Fs->srv_ctrl.next_waiting;if(done)h=&Fs->srv_ctrl.next_done;j->aux_str=StrNew("queued job",QueueOwner);j->ctrl=&Fs->srv_ctrl;QueIns(j,h->last);}',
        'U0 QueueCleanupWorker(U8 *data){QueueAdd(FALSE);QueueAdd(FALSE);QueueAdd(TRUE);QueueResult=1;}',
        'Bool QueueDoneWait(){I64 end=cnts.jiffies+2000;while(!QueueResult&&cnts.jiffies<end)Yield;Yield;return QueueResult==1;}',
        'Bool QueueCleanup(){I64 used=Fs->data_heap->used_u8s;QueueOwner=Fs;QueueResult=0;Spawn(&QueueCleanupWorker,0,"Cleanup",-1,Fs,8192);return QueueDoneWait&&Fs->data_heap->used_u8s==used;}',
    ]
    commands = [(source, []) for source in definitions]
    commands.append(('QueueReady;', ['1']))
    commands += [('QueueChild;', ['1']) for _ in range(10)]
    commands.append(('QueueCleanup;', ['1']))
    commands.append(('6*7;', ['42']))
    if any(len(source.encode('ascii')) > 255 for source, _ in commands):
        raise ValueError('Queue contract exceeds the interactive line limit')
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
        source = '\n'.join(source for source, _ in commands[:9]) + '\n'
        (overlay / 'Definitions.HC').write_text(source)
        (overlay / 'Once.HC').write_text('''U0 Report(U8 *text){while(*text)OutU8(0xE9,*text++);}
#include "T:/Definitions.HC"
Report("START original public task queues\\n");
Bool ok=QueueReady;I64 i;for(i=0;i<10&&ok;i++)ok=QueueChild;
if(ok)ok=QueueCleanup;
if(ok)Report("PASS original public task queues\\n");
else Report("FAIL original public task queues\\n");
Report("DONE original public task queues\\n");
''')
        iso = out / 'original.iso'
        subprocess.run([sys.executable, 'tools/build-iso.py', '--overlay',
                        'build/rebuild-test/overlay', '--overlay', str(overlay),
                        '--output', str(iso)], cwd=ROOT, check=True)
        subprocess.run([sys.executable, 'tools/guest-run.py', str(iso), '--out',
                        str(out / 'original'), '--timeout', '90'], cwd=ROOT, check=True)
        if 'PASS original public task queues\n' not in (out / 'original/debug.log').read_text():
            raise ValueError('Missing original public message verdict')
        report = {'result': 'pass', 'platform': 'original x64 TempleOS',
                  'definitions_sha256': hashlib.sha256(source.encode()).hexdigest()}
    else:
        disk_hash = sha(args.disk)
        runner = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input']
        behavior = runner(args.disk, out / 'behavior', cpu='486,-fpu', qmp_stdio=True,
                          startup_check={'status': 'ok', 'answers': [], 'commands': [('HashFind("MAlloc",Fs->hash_table,HTT_FUN)!=0;', ['1']),
                                                                       ('HashFind("Spawn",Fs->hash_table,HTT_FUN)!=0;', ['1'])] + commands})
        if sha(args.disk) != disk_hash:
            raise ValueError('Public message test changed the input disk')
        report = {'result': 'pass', 'behavior': behavior,
                  'disk_sha256': disk_hash, 'source_disk_unchanged': True}
    if sha(Path(__file__)) != checker:
        raise ValueError('Public message checker changed during execution')
    report.update(checker_sha256=checker, cases=12,
                  scope='Public root and ten spawned children: empty waiting/done rings and unlocked flags; three queued jobs and auxiliary strings reclaimed from both rings on child exit; not public message delivery')
    (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
