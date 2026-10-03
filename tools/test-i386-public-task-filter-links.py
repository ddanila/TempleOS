#!/usr/bin/env python3
"""Original/native public task input-filter links and retirement."""
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
        'Bool FilterSelf(CTask *t=NULL){if(!t)t=Fs;return t->next_input_filter_task==t&&t->last_input_filter_task==t;}',
        'I64 FilterResult=0;',
        'CTask *FilterOwner;',
        'U0 FilterWorker(U8 *data){CTask *t=Fs,*p=FilterOwner;if(!FilterSelf){FilterResult=-1;return;}p->next_input_filter_task=p->last_input_filter_task=t;t->next_input_filter_task=t->last_input_filter_task=p;FilterResult=1;}',
        'Bool FilterCase(){I64 end=cnts.jiffies+2000;FilterOwner=Fs;FilterResult=0;Spawn(&FilterWorker,0,"Filter",-1,Fs,8192);while(!FilterResult&&cnts.jiffies<end)Yield;Yield;return FilterResult==1&&FilterSelf;}',
    ]
    commands = [(source, []) for source in definitions]
    commands.append(('FilterSelf;', ['1']))
    commands += [('FilterCase;', ['1']) for _ in range(10)]
    commands.append(('6*7;', ['42']))
    if any(len(source.encode('ascii')) > 255 for source, _ in commands):
        raise ValueError('Filter contract exceeds the interactive line limit')
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
        source = '\n'.join(source for source, _ in commands[:5]) + '\n'
        (overlay / 'Definitions.HC').write_text(source)
        (overlay / 'Once.HC').write_text('''U0 Report(U8 *text){while(*text)OutU8(0xE9,*text++);}
#include "T:/Definitions.HC"
Report("START original public task filter links\\n");
Bool ok=FilterSelf;I64 i;for(i=0;i<10&&ok;i++)ok=FilterCase;
if(ok)Report("PASS original public task filter links\\n");
else Report("FAIL original public task filter links\\n");
Report("DONE original public task filter links\\n");
''')
        iso = out / 'original.iso'
        subprocess.run([sys.executable, 'tools/build-iso.py', '--overlay',
                        'build/rebuild-test/overlay', '--overlay', str(overlay),
                        '--output', str(iso)], cwd=ROOT, check=True)
        subprocess.run([sys.executable, 'tools/guest-run.py', str(iso), '--out',
                        str(out / 'original'), '--timeout', '90'], cwd=ROOT, check=True)
        if 'PASS original public task filter links\n' not in (out / 'original/debug.log').read_text():
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
    report.update(checker_sha256=checker, cases=11,
                  scope='Root/child input-filter self-links and ten linked-child retirements restoring the parent ring; not input-filter job execution or message routing')
    (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
