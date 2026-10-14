#!/usr/bin/env python3
"""Require HolyC compile-time execution and StreamPrint source injection."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]
COMMANDS = [('I64 StreamCount=0;', []),
            ('#exe {StreamCount=StreamCount+1;}', []),
            ('StreamCount;', ['1']),
            ('#exe {StreamPrint("I64 StreamGenerated(){return 42;}");}', []),
            ('StreamGenerated;', ['42']),
            ('I64 StreamExpression(){return #exe {StreamPrint("6*7");};}', []),
            ('StreamExpression;', ['42']),
            ('StreamCount;', ['1'])]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--nested-includes', action='store_true',
                        help='Also verify original directory macros across include/cwd changes')
    args = parser.parse_args()
    source, out = args.disk.resolve(), args.out.resolve()
    commands = list(COMMANDS)
    fixtures = {}
    if args.nested_includes:
        fixtures = {
            '/Probe/SOuter.HC':'Cd(__DIR__);;\nU8 *StreamOuterDir(){return __DIR__;}\n#include "SDir/Inner.HC"\nU8 *StreamRestoredDir(){return __DIR__;}\n',
            '/Probe/SDir/Inner.HC':'Cd(__DIR__);;\nU8 *StreamInnerDir(){return __DIR__;}\n'}
        commands += [('DirMk("C:/Probe/SDir");', ['1'])]
        for path, text in fixtures.items():
            commands.append((f'FileWrite("C:{path}",{json.dumps(text)},{len(text.encode())})>0;', ['1']))
        commands += [('#include "C:/Probe/SOuter.HC"', ['1','1']),
                     ('StrCmp(StreamOuterDir,"C:/Probe")==0;', ['1']),
                     ('StrCmp(StreamInnerDir,"C:/Probe/SDir")==0;', ['1']),
                     ('StrCmp(StreamRestoredDir,"C:/Probe")==0;', ['1']),
                     ('Cd("C:/");', ['1']), ('StreamGenerated;', ['42'])]
    if any(len(text.encode())>255 for text,_ in commands):
        raise ValueError('Stream fixture exceeds console line limit')
    if out.exists():
        parser.error('Use a fresh output directory')
    sha = lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    runner = ROOT/'tools/i386-kernel-input.py'
    pins = {str(p):sha(p) for p in [source, runner, Path(__file__).resolve()]}
    out.mkdir(parents=True)
    working = out/'working.img'
    shutil.copyfile(source, working)
    report = dict(result='running', scope='Compile-time side effects, source injection and expression-context restoration; not exhaustive stream-block, nested-include or unwind qualification',
                  input_sha256=pins, commands=commands, nested_includes=args.nested_includes)
    try:
        report['behavior'] = runpy.run_path(str(runner))['run_input'](
            working, out/'qemu', snapshot=False, ram_mib=64,
            cpu='486,-fpu', accel='tcg', qmp_stdio=True,
            startup_check={'status':'ok', 'answers':[], 'commands':commands,
                           'rejected_answers':['0'], 'rejection_prefixes':('INPUT REJECT ',),
                           'command_timeout':120})
        if fixtures:
            files = runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['mutated_file_contents'](working,set(fixtures))
            if files != {path:text.encode() for path,text in fixtures.items()}:
                raise ValueError('Persisted directory fixture differs from submitted source')
        report['result'] = 'pass'
    except Exception as exc:
        report.update(result='fail', error=str(exc))
        raise
    finally:
        report['inputs_unchanged'] = all(sha(Path(p)) == digest for p,digest in pins.items())
        if not report['inputs_unchanged']:
            report.update(result='fail', error='Native fixture inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':
        raise ValueError(report['error'])


if __name__=='__main__':
    main()
