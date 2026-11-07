#!/usr/bin/env python3
"""Observe original CmdLinePmt answer formatting and real input normalization."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import struct
import subprocess

ROOT = Path(__file__).resolve().parents[1]

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('disk', type=Path, nargs='?')
    ap.add_argument('--out', type=Path, required=True)
    args = ap.parse_args()
    out = args.out.resolve()
    if out.exists():
        ap.error('Use a fresh output directory')
    fixture = ROOT/'tests/guest/i386-command-prompt/Contract.HC'
    paths = [Path(__file__).resolve(), fixture] + [ROOT/('tools/'+name) for name in (
        'test-i386-autocomplete-interaction.py', 'test-i386-timeclock-reference.py',
        'test-i386-timeclock-welcome.py', 'build-iso.py',
        'package-i386-native-image.py', 'build-i386-kernel.py')]
    paths.append(ROOT/'Kernel/FontStd.HC')
    if args.disk:
        paths.append(args.disk.resolve())
    out.mkdir()
    pins = {str(p): sha(p) for p in paths}
    report = dict(result='running', input_sha256=pins,
                  scope='Six direct CmdLinePmt cases with real queued GetStr input: pending signed/unsigned/float/void answers, no pending answer, current directory, trailing whitespace and semicolon normalization, task prompt flag and document-role restoration. Not physical keyboard, debug/raw, task-exit or full terminal qualification.')
    (out/'fixture.HC').write_bytes(fixture.read_bytes())
    (out/'runner-source.py').write_bytes(Path(__file__).read_bytes())
    g = None
    try:
        if args.disk:
            image = out/'working.img'
            pack = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))
            before = pack['snapshot'](args.disk.read_bytes())[1]
            additions = {'/Probe/CommandPrompt.HC': fixture.read_bytes()}
            report['packaging'] = pack['package'](args.disk.resolve(), image, additions=additions)
        else:
            overlay = out/'overlay'
            overlay.mkdir()
            report['reference_sha256'] = runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
            (overlay/'Once.HC').write_bytes(fixture.read_bytes()+b'\nCPCheck;\n')
            image = out/'original.iso'
            subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(image)],cwd=ROOT,check=True)
        Guest = runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest']
        g = Guest(image, out/'guest', bool(args.disk), reference_cpus=1)
        if args.disk:
            g.wait('DONE native kernel startup\n')
            g.command('#include "C:/Probe/CommandPrompt.HC"')
            g.command('CPCheck;')
        if 'COMMAND PROMPT UNAVAILABLE\n' in g.collect():
            raise ValueError('CmdLinePmt is not bound in the native public symbol chain')
        g.wait('COMMAND PROMPT DONE\n')
        names=['prompt-state.bin','prompt-cwd.bin']+[f'prompt-line-{i}.bin' for i in range(6)]+[f'prompt-doc-{i}.DD' for i in range(6)]
        for name in names:(out/name).write_bytes((g.out/name).read_bytes())
        report['state']=list(struct.unpack('<24q',(out/'prompt-state.bin').read_bytes()))
        expected_lines=[b'  6*7;;\n',b'abc\n',b'Print("x;");;\n',b';;\n',b'\n',b'#define X 9\n']
        for i,want in enumerate(expected_lines):
            if (out/f'prompt-line-{i}.bin').read_bytes()!=want:raise ValueError('Input normalization differs: '+str(i))
        values=[55,-7,0x400E000000000000,0,55,-1]
        if report['state']!=[v for n in values for v in [n,0,0,1]]:raise ValueError('Prompt state differs')
        cwd=(out/'prompt-cwd.bin').read_bytes()
        prefixes=[b'',b'1.250000s ans=0xFFFFFFFFFFFFFFF9=-7\n',b'1.250000s ansf=      3.7500000\n',b'1.250000s\n',b'',b'1.250000s ans=0xFFFFFFFFFFFFFFFF=-1\n']
        for i,prefix in enumerate(prefixes):
            raw=(out/f'prompt-doc-{i}.DD').read_bytes()
            if not raw.startswith(prefix+cwd+b'>'):raise ValueError('Answer or directory prefix differs: '+str(i)+' '+repr(raw))
        if args.disk:
            g.command('6*7;');report['arithmetic_pixels']=g.result_pixels()
        g.close()
        g = None
        if args.disk:
            after = pack['snapshot'](image.read_bytes())[1]
            if {n for n in set(before)|set(after) if before.get(n)!=after.get(n)} != set(additions):
                raise ValueError('Unexpected filesystem changes')
            report['filesystem'] = runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['verify_mutated_volume'](image)
        report['result'] = 'pass'
    except BaseException as exc:
        report.update(result='fail',error=str(exc))
        raise
    finally:
        if g:
            try:
                g.close()
            except Exception as exc:
                report.update(result='fail',cleanup_error=str(exc))
        report['inputs_unchanged'] = all(p.is_file() and sha(p)==pins[str(p)] for p in paths)
        if not report['inputs_unchanged']:
            report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')

if __name__ == '__main__':
    main()
