#!/usr/bin/env python3
"""Observe actual ExeCmdLine execution, answer state, title restoration and cleanup."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import struct
import subprocess

ROOT = Path(__file__).resolve().parents[1]
EXPECTED=struct.pack('<16Q',*([1]*16))
ORIGINAL_EXPECTED=struct.pack('<16Q',*([1]*11+[0]+[1]*4))

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('disk', type=Path, nargs='?')
    ap.add_argument('--out', type=Path, required=True)
    args = ap.parse_args()
    expected_bytes=EXPECTED if args.disk else ORIGINAL_EXPECTED
    out = args.out.resolve()
    if out.exists():
        ap.error('Use a fresh output directory')
    fixture = ROOT/('tests/guest/i386-public-expression/ExecuteLineContract.HC' if args.disk else 'tests/guest/i386-public-execute-line/Reference.HC')
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
                  scope='Actual ExeCmdLine: multiple statements, integer/F64 answer state, side effects, empty/load-only/block-stop modes, locked/transient title behavior, valid-case data/code heap recovery, syntax unwind and subsequent execution. Original normal API or direct native baseline; not source-loaded delivery qualification.')
    report['syntax_error_title_restore_expected']=bool(args.disk)
    (out/'fixture.HC').write_bytes(fixture.read_bytes())
    (out/'runner-source.py').write_bytes(Path(__file__).read_bytes())
    g = None
    try:
        if args.disk:
            image = out/'working.img'
            pack = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))
            before = pack['snapshot'](args.disk.read_bytes())[1]
            additions = {'/Probe/PublicExecuteLine.HC': fixture.read_bytes()}
            report['packaging'] = pack['package'](args.disk.resolve(), image, additions=additions)
        else:
            overlay = out/'overlay'
            overlay.mkdir()
            report['reference_sha256'] = runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
            (overlay/'Once.HC').write_bytes(fixture.read_bytes())
            image = out/'original.iso'
            subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(image)],cwd=ROOT,check=True)
        Guest = runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest']
        g = Guest(image, out/'guest', bool(args.disk), reference_cpus=1)
        if args.disk:
            g.wait('DONE native kernel startup\n')
            g.command('#include "C:/Probe/PublicExecuteLine.HC"')
        g.wait('PUBLIC EXECUTE LINE DONE\n')
        data=(g.out/'public-execute-line.bin').read_bytes()
        (out/'public-execute-line.bin').write_bytes(data)
        if data!=expected_bytes:
            actual=struct.unpack('<'+'Q'*(len(data)//8),data)
            expected=struct.unpack('<'+'Q'*(len(expected_bytes)//8),expected_bytes)
            report['mismatches']=[{'word':i,'actual':a,'expected':e} for i,(a,e) in enumerate(zip(actual,expected)) if a!=e]
            raise ValueError('Command-line execution differs; see raw records')
        report['state']=list(struct.unpack('<16Q',data))
        report['outputs']={'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest()}
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
        if g:g.screenshot('failure')
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
