#!/usr/bin/env python3
"""Check public GetStr against observed original-system input semantics."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]
COMMANDS = [
    ('U8 *InputResult;', []),
    ('In("alpha\\n");InputResult=GetStr;StrCmp(InputResult,"alpha")==0;', ['1']),
    ('Free(InputResult);In("\\n");InputResult=GetStr;StrLen(InputResult);', ['0']),
    ('Free(InputResult);In("\\n");InputResult=GetStr(NULL,"fallback");StrCmp(InputResult,"fallback")==0;', ['1']),
    ('Free(InputResult);In("alpha\\nbeta\\n\\x1B");InputResult=GetStr(NULL,NULL,GSF_WITH_NEW_LINE);StrCmp(InputResult,"alpha\\nbeta\\n")==0;', ['1']),
    ('Free(InputResult);In("discard\\x1C");InputResult=GetStr;StrLen(InputResult);', ['0']),
    ('Free(InputResult);In("discard\\x1C");InputResult=GetStr(NULL,"fallback");StrCmp(InputResult,"fallback")==0;', ['1']),
    ('Free(InputResult);6*7;', ['42'])]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    source, out = args.disk.resolve(), args.out.resolve()
    commands = list(COMMANDS)
    if out.exists():
        parser.error('Use a fresh output directory')
    sha = lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    runner = ROOT/'tools/i386-kernel-input.py'
    pins = {str(p):sha(p) for p in [source, runner, Path(__file__).resolve()]}
    out.mkdir(parents=True)
    working = out/'working.img'
    shutil.copyfile(source, working)
    report = dict(result='running', scope='Original GetStr six basic scripted-input cases; physical keyboard, editing, prompt formatting and task exit remain open',
                  input_sha256=pins, commands=commands)
    try:
        report['behavior'] = runpy.run_path(str(runner))['run_input'](
            working, out/'qemu', snapshot=False, ram_mib=64,
            cpu='486,-fpu', accel='tcg', qmp_stdio=True,
            startup_check={'status':'ok', 'answers':[], 'commands':commands,
                           'rejection_prefixes':('INPUT REJECT ',),
                           'command_timeout':120})
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
