#!/usr/bin/env python3
"""Original/native allocated formatted strings and variadic argument handling."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
DEFINITIONS = [
    'Bool FormatCheck(U8 *text,U8 *expected){Bool ok=!StrCmp(text,expected);U8 *p=text;if(!ok){OutU8(0xE9,91);while(*p)OutU8(0xE9,*p++);OutU8(0xE9,93);OutU8(0xE9,10);}Free(text);return ok;}',
    'Bool FormatGrowCheck(){U8 *s=MAlloc(1025),*t;Bool ok;MemSet(s,65,1024);s[1024]=0;t=MStrPrint("%s",s);ok=!StrCmp(s,t);Free(t);Free(s);return ok;}',
]
CASES = [
    ('FormatCheck(MStrPrint("plain"),"plain");', ['1']),
    ('FormatCheck(MStrPrint("%d",0x7FFFFFFFFFFFFFFF),"9223372036854775807");', ['1']),
    ('FormatCheck(MStrPrint("%d",0x8000000000000000),"-9223372036854775808");', ['1']),
    ('FormatCheck(MStrPrint("%u",0xFFFFFFFFFFFFFFFF),"18446744073709551615");', ['1']),
    ('FormatCheck(MStrPrint("%X",0x123456789ABCDEF0),"123456789ABCDEF0");', ['1']),
    ('FormatGrowCheck;', ['1']),
    ('FormatCheck(MStrPrint("%%"),"%");', ['1']),
    ('FormatCheck(MStrPrint("%d",-42),"-42");', ['1']),
    ('FormatCheck(MStrPrint("%u",42),"42");', ['1']),
    ('FormatCheck(MStrPrint("%X",0xABCD),"ABCD");', ['1']),
    ('FormatCheck(MStrPrint("%x",0xABCD),"abcd");', ['1']),
    ('FormatCheck(MStrPrint("%b",10),"1010");', ['1']),
    ('FormatCheck(MStrPrint("%c",65),"A");', ['1']),
    ('FormatCheck(MStrPrint("%s","HolyC"),"HolyC");', ['1']),
    ('FormatCheck(MStrPrint("%05d",42),"00042");', ['1']),
    ('FormatCheck(MStrPrint("%5d",42),"   42");', ['1']),
    ('FormatCheck(MStrPrint("%-5d",42),"   42");', ['1']),
    ('FormatCheck(MStrPrint("%*d",5,42),"   42");', ['1']),
    ('FormatCheck(MStrPrint("%.3s","HolyC"),"HolyC");', ['1']),
    ('FormatCheck(MStrPrint("%f",1.5),"2");', ['1']),
    ('FormatCheck(MStrPrint("%.2f",1.5),"1.50");', ['1']),
    ('FormatCheck(MStrPrint("%s:%d:%X","value",42,255),"value:42:FF");', ['1']),
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
                  scope='Selected MStrPrint formatting, allocation/free and variadic arguments; not full formatting parity')
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
                'if(ok)Report("PASS original formatting\\n");else Report("FAIL original formatting\\n");\n' +
                'Report("DONE original formatting\\n");\n')
            iso = out / 'original.iso'
            subprocess.run([sys.executable, 'tools/build-iso.py', '--overlay',
                            'build/rebuild-test/overlay', '--overlay', str(overlay),
                            '--output', str(iso)], cwd=ROOT, check=True)
            subprocess.run([sys.executable, 'tools/guest-run.py', str(iso), '--out',
                            str(out / 'original'), '--timeout', '90'], cwd=ROOT, check=True)
            if 'PASS original formatting\n' not in (out / 'original/debug.log').read_text():
                raise ValueError('Missing original formatting verdict')
            report.update(platform='original x64 TempleOS',
                          definitions_sha256=hashlib.sha256(source.encode()).hexdigest())
        else:
            report['disk_sha256'] = sha(args.disk)
            commands = [('HashFind("MStrPrint",Fs->hash_table,HTT_FUN)!=0;', ['1'])]
            commands += [(source, []) for source in DEFINITIONS] + CASES
            if any(len(source)>255 for source, _ in commands):
                raise ValueError('Formatting fixture exceeds interactive line limit')
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
