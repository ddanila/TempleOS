#!/usr/bin/env python3
"""Original/native task display-mode queries; helper restores the display flags."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
DEFINITIONS = [
    'Bool RawBitCheck(Bool set){I64 flags=Fs->display_flags;Bool ok;if(set)Bts(&Fs->display_flags,DISPLAYf_NOT_RAW);else Btr(&Fs->display_flags,DISPLAYf_NOT_RAW);ok=IsRaw==!set;Fs->display_flags=flags;return ok;}',
]
CASES = [
    ('IsRaw==!Bt(&Fs->display_flags,DISPLAYf_NOT_RAW);', ['1']),
    ('RawBitCheck(TRUE);', ['1']),
    ('IsRaw==!Bt(&Fs->display_flags,DISPLAYf_NOT_RAW);', ['1']),
    ('RawBitCheck(FALSE);', ['1']),
    ('IsRaw==!Bt(&Fs->display_flags,DISPLAYf_NOT_RAW);', ['1']),
    ('6*7==42;', ['1']),
]


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
                  scope='IsRaw reflects current task DISPLAYf_NOT_RAW for both states; not Raw switching/rendering parity')
    try:
        if args.original:
            overlay = out / 'overlay'
            overlay.mkdir(exist_ok=True)
            source = '\n'.join(DEFINITIONS) + '\n'
            (overlay / 'Definitions.HC').write_text(source)
            checks = '\n'.join('if(!(' + source[:-1] + ')){ok=FALSE;Report("CASE ' + str(index) + '\\n");}' for index, (source, _) in enumerate(CASES))
            (overlay / 'Once.HC').write_text(
                'U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}' + '\n' +
                '#include "T:/Definitions.HC"\nBool ok=TRUE;\n' + checks + '\n' +
                'if(ok)Report("PASS original display query\\n");else Report("FAIL original display query\\n");\n' +
                'Report("DONE original display query\\n");\n')
            iso = out / 'original.iso'
            subprocess.run([sys.executable, 'tools/build-iso.py', '--overlay',
                            'build/rebuild-test/overlay', '--overlay', str(overlay),
                            '--output', str(iso)], cwd=ROOT, check=True)
            subprocess.run([sys.executable, 'tools/guest-run.py', str(iso), '--out',
                            str(out / 'original'), '--timeout', '90'], cwd=ROOT, check=True)
            if 'PASS original display query\n' not in (out / 'original/debug.log').read_text():
                raise ValueError('Missing original display query verdict')
            report.update(platform='original x64 TempleOS',
                          definitions_sha256=hashlib.sha256(source.encode()).hexdigest())
        else:
            report['disk_sha256'] = sha(args.disk)
            commands = [('HashFind("IsRaw",Fs->hash_table,HTT_FUN)!=0;', ['1'])]
            commands += [(source, []) for source in DEFINITIONS] + CASES
            if any(len(source)>255 for source, _ in commands):
                raise ValueError('Display query fixture exceeds interactive line limit')
            runner = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input']
            report['behavior'] = runner(args.disk, out / 'behavior', cpu='486,-fpu',
                qmp_stdio=True, startup_check={'status':'ok','answers':[], 'commands':commands})
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
