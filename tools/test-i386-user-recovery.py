#!/usr/bin/env python3
"""Repeated User creation and retirement with exact shared public-pool recovery."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
BASE = runpy.run_path(str(ROOT / 'tools/test-i386-user-create.py'))
DEFINITIONS = BASE['DEFINITIONS'] + [
    'I64 UserPoolUsed,UserPoolReserved,UserRootCount;',
    'I64 UserCount(){CTask *r=Gs->seth_task,*e=(&r->next_child_task)(U8 *)-offset(CTask.next_sibling_task),*c=r->next_child_task;I64 n=0;while(c&&c!=e&&n<128){n++;c=c->next_sibling_task;}return n;}',
    'Bool UserRecover(){I64 i;for(i=0;i<20;i++)Yield;return !UserProbeHas&&UserCount==UserRootCount&&Fs->data_heap->bp->used_u8s==UserPoolUsed&&Fs->data_heap->bp->alloced_u8s==UserPoolReserved;}',
    'Bool UserBaseline(){UserPoolUsed=Fs->data_heap->bp->used_u8s;UserPoolReserved=Fs->data_heap->bp->alloced_u8s;UserRootCount=UserCount;return TRUE;}',
    'Bool UserCycle(Bool run){if(!UserProbeStart(run))return FALSE;if(run&&!UserProbeWait)return FALSE;return UserProbeStop&&UserRecover;}',
]
CASES = [('UserProbeStart(TRUE);', ['1']), ('UserProbeWait;', ['1']),
         ('UserProbeStop;', ['1']), ('UserBaseline;', ['1'])]
CASES += [('UserCycle(' + ('TRUE' if i % 2 else 'FALSE') + ');', ['1'])
          for i in range(8)]
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
                  scope='Eight warmed User create/kill cycles, alternating empty and executed startup, exact CPU-root child count and shared public-pool used/reserved recovery; not bootstrap allocator accounting, hotkeys or exhaustive recovery')
    try:
        if args.original:
            overlay = out / 'overlay'
            overlay.mkdir(exist_ok=True)
            source = '\n'.join(DEFINITIONS) + '\n'
            (overlay / 'Definitions.HC').write_text(source)
            checks = '\n'.join(
                'if(ok&&(' + command[:-1] + ')!=' + expected[0] +
                '){ok=FALSE;Report("CASE ' + str(index) + '\\n");}'
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
