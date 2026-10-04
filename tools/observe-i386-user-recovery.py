#!/usr/bin/env python3
"""Observe User retirement counters without asserting an unproven recovery invariant."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
BASE = runpy.run_path(str(ROOT / 'tools/test-i386-user-recovery.py'))
DEFINITIONS = BASE['DEFINITIONS'] + [
    'U0 UserObserveLog(U8 *s){while(*s)OutU8(0xE9,*s++);}',
    'U0 UserObserve(I64 step){U8 s[256];StrPrint(s,"USER POOL %d %d %d %d %d %d\\n",step,UserCount,Fs->data_heap->bp->used_u8s,Fs->data_heap->bp->alloced_u8s,Fs->data_heap->used_u8s,Gs->seth_task->data_heap->used_u8s);UserObserveLog(s);}',
]
CASES = [('UserObserve(0);', [])]
for i in range(9):
    CASES += [('UserProbeStart(' + ('TRUE' if i % 2 else 'FALSE') + ');', ['1'])]
    if i % 2: CASES += [('UserProbeWait;', ['1'])]
    CASES += [('UserProbeStop;', ['1']), ('UserObserve(' + str(i+1) + ');', [])]
CASES += [('6*7;', ['42'])]


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
    sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
    checker = sha(Path(__file__))
    report = dict(result='fail', checker_sha256=checker,
                  scope='Observation only: nine User create/kill cycles, child counts, shared public-pool and task heap counters; a pass means functional cycles completed, not resource recovery')
    try:
        if args.original:
            overlay = out / 'overlay'
            overlay.mkdir(exist_ok=True)
            source = '\n'.join(DEFINITIONS) + '\n'
            (overlay / 'Definitions.HC').write_text(source)
            checks = '\n'.join(
                ('if(ok&&(' + command[:-1] + ')!=' + expected[0] +
                '){ok=FALSE;Report("CASE ' + str(index) + '\\n");}' if expected else command)
                for index, (command, expected) in enumerate(CASES))
            (overlay / 'Once.HC').write_text(
                'U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}' + '\n' +
                '#include "T:/Definitions.HC"\nReport("START original User creation\\n");\n' +
                'Bool ok=TRUE;\n' + checks + '\n' +
                'if(ok)Report("PASS original User creation\\n");' +
                'else Report("FAIL original User creation\\n");\n' +
                'Report("DONE original User creation\\n");\n')
            iso = out / 'original.iso'
            subprocess.run([sys.executable, 'tools/build-iso.py', '--overlay',
                            'build/rebuild-test/overlay', '--overlay', str(overlay),
                            '--output', str(iso)], cwd=ROOT, check=True)
            subprocess.run([sys.executable, 'tools/guest-run.py', str(iso), '--out',
                            str(out / 'original'), '--timeout', '90'], cwd=ROOT, check=True)
            if 'PASS original User creation\n' not in (out / 'original/debug.log').read_text():
                raise ValueError('Missing original User verdict')
            report.update(platform='original x64 TempleOS',
                          definitions_sha256=hashlib.sha256(source.encode()).hexdigest())
        else:
            report['disk_sha256'] = sha(args.disk)
            commands = [('HashFind("User",Fs->hash_table,HTT_FUN)!=0;', ['1'])]
            commands += [(source, []) for source in DEFINITIONS] + CASES
            if any(len(source)>255 for source, _ in commands):
                raise ValueError('User fixture exceeds interactive line limit')
            runner = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input']
            report['behavior'] = runner(args.disk, out / 'behavior', cpu='486,-fpu',
                qmp_stdio=True, startup_check={'status':'ok','answers':[], 'commands':commands,
                    'command_timeout':120})
        log_path = out / ('original/debug.log' if args.original else 'behavior/debug.log')
        rows = [list(map(int, match)) for match in re.findall(
            r'^USER POOL (-?\d+) (-?\d+) (-?\d+) (-?\d+) (-?\d+) (-?\d+)$',
            log_path.read_text(), re.M)]
        if len(rows) != 10 or [row[0] for row in rows] != list(range(10)):
            raise ValueError('Missing or unordered User pool observations')
        report['observation_columns'] = ['cycle', 'root_children', 'pool_used',
                                        'pool_reserved', 'caller_heap_used',
                                        'root_heap_used']
        report['observations'] = rows
        report['result'] = 'pass' 
    except Exception as error:
        report['error'] = str(error)
        raise
    finally:
        if args.disk:
            report['source_disk_unchanged'] = sha(args.disk)==report.get('disk_sha256')
            if not report['source_disk_unchanged']:
                report.update(result='fail', error='Source disk changed')
        if sha(Path(__file__)) != checker:
            report.update(result='fail', error='Checker changed during execution')
        (out / 'result.json').write_text(json.dumps(report, indent=2)+'\n')
    if report['result'] != 'pass':
        raise SystemExit(1)


if __name__ == '__main__':
    main()
