#!/usr/bin/env python3
"""Original/native public task suspension, job metadata and wake flags."""
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
        'Bool SuspRoot(){I64 f=Fs->task_flags,w=Fs->wake_jiffy;Bool ok;ok=!Suspend&&IsSuspended&&Suspend&&Suspend(NULL,FALSE)&&!IsSuspended&&!Suspend(NULL,FALSE);return ok&&Fs->task_flags==f&&Fs->wake_jiffy==w;}',
        'Bool SuspInvalid(){CTask *t=CAlloc(sizeof(CTask));Bool ok=!Suspend(t)&&!IsSuspended(t);Free(t);return ok;}',
        'I64 SuspStage=0;',
        'CTask *SuspTask;',
        'U0 SuspWorker(U8 *data){SuspStage=1;}',
        'Bool SuspStart(){SuspTask=Spawn(&SuspWorker,0,"Suspension",-1,Fs,8192);return SuspTask&&!Suspend(SuspTask)&&IsSuspended(SuspTask);}',
        'Bool SuspSkipped(){I64 i;for(i=0;i<10;i++)Yield;return !SuspStage&&IsSuspended(SuspTask);}',
        'Bool SuspResume(){I64 end=cnts.jiffies+2000;Bool ok=Suspend(SuspTask,FALSE);while(!SuspStage&&cnts.jiffies<end)Yield;return ok&&SuspStage==1;}',
    ]
    commands = [(source, []) for source in definitions]
    commands += [(name+';', ['1']) for name in ('SuspRoot','SuspInvalid','SuspStart','SuspSkipped','SuspResume')]
    commands.append(('6*7;', ['42']))
    if any(len(source.encode('ascii')) > 255 for source, _ in commands):
        raise ValueError('Suspension contract exceeds the interactive line limit')
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
        source = '\n'.join(source for source, _ in commands[:8]) + '\n'
        (overlay / 'Definitions.HC').write_text(source)
        (overlay / 'Once.HC').write_text('''U0 Report(U8 *text){while(*text)OutU8(0xE9,*text++);}
#include "T:/Definitions.HC"
Report("START original public task suspension\\n");
Bool ok=SuspRoot&&SuspInvalid&&SuspStart&&SuspSkipped&&SuspResume;
if(ok)Report("PASS original public task suspension\\n");
else Report("FAIL original public task suspension\\n");
Report("DONE original public task suspension\\n");
''')
        iso = out / 'original.iso'
        subprocess.run([sys.executable, 'tools/build-iso.py', '--overlay',
                        'build/rebuild-test/overlay', '--overlay', str(overlay),
                        '--output', str(iso)], cwd=ROOT, check=True)
        subprocess.run([sys.executable, 'tools/guest-run.py', str(iso), '--out',
                        str(out / 'original'), '--timeout', '90'], cwd=ROOT, check=True)
        if 'PASS original public task suspension\n' not in (out / 'original/debug.log').read_text():
            raise ValueError('Missing original public message verdict')
        report = {'result': 'pass', 'platform': 'original x64 TempleOS',
                  'definitions_sha256': hashlib.sha256(source.encode()).hexdigest()}
    else:
        disk_hash = sha(args.disk)
        runner = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input']
        behavior = runner(args.disk, out / 'behavior', cpu='486,-fpu', qmp_stdio=True,
                          startup_check={'status': 'ok', 'answers': [], 'commands': [('HashFind("MAlloc",Fs->hash_table,HTT_FUN)!=0;', ['1']),
                                                                       ('HashFind("Suspend",Fs->hash_table,HTT_FUN)!=0;', ['1'])] + commands})
        if sha(args.disk) != disk_hash:
            raise ValueError('Public message test changed the input disk')
        report = {'result': 'pass', 'behavior': behavior,
                  'disk_sha256': disk_hash, 'source_disk_unchanged': True}
    if sha(Path(__file__)) != checker:
        raise ValueError('Public message checker changed during execution')
    report.update(checker_sha256=checker, cases=5,
                  scope='Suspend previous-state return, default caller, invalid signature rejection, scheduler skips suspended child and resumes it; wake deadline and unrelated caller flags preserved')
    (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
