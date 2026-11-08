#!/usr/bin/env python3
"""Check compile-time literal ownership after controller release and allocator reuse."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import re
import struct
import subprocess

ROOT = Path(__file__).resolve().parents[1]
EXPECTED=struct.pack('<12Q',*([1]*12))
TREE={}
LITERAL=b'stream-side-effect-owner-0123456789\0'

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('disk', type=Path, nargs='?')
    ap.add_argument('--out', type=Path, required=True)
    ap.add_argument('--runtime-block', action='store_true', help='Exercise the same escape in ordinary runtime code')
    args = ap.parse_args()
    expected_bytes=EXPECTED
    out = args.out.resolve()
    if out.exists():
        ap.error('Use a fresh output directory')
    fixture = ROOT/'tests/guest/i386-stream-side-effect/Contract.HC'
    paths = [Path(__file__).resolve(), fixture] + [ROOT/('tools/'+name) for name in (
        'test-i386-autocomplete-interaction.py', 'test-i386-timeclock-reference.py',
        'test-i386-timeclock-welcome.py', 'build-iso.py',
        'package-i386-native-image.py', 'build-i386-kernel.py')]
    paths.append(ROOT/'Kernel/FontStd.HC')
    if args.disk:
        paths.append(args.disk.resolve())
    out.mkdir()
    pins = {str(p): sha(p) for p in paths}
    report = dict(result='running', input_sha256=pins, runtime_block=args.runtime_block,
                  scope='Normal ExePutS compile-time pointer literal stored in a global by a compound block that ends with a different result; controller release, 32 later compilations, public data/code heap churn, generated function access and exact literal bytes. Not full stream lifetime/failure/cancellation qualification')
    (out/'fixture.HC').write_bytes(fixture.read_bytes())
    (out/'runner-source.py').write_bytes(Path(__file__).read_bytes())
    g = None
    try:
        if args.disk:
            image = out/'working.img'
            pack = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))
            before = pack['snapshot'](args.disk.read_bytes())[1]
            additions = {'/Probe/StreamSideEffect.HC': fixture.read_bytes(),**TREE}
            report['packaging'] = pack['package'](args.disk.resolve(), image, additions=additions)
        else:
            overlay = out/'overlay'
            overlay.mkdir()
            report['reference_sha256'] = runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
            (overlay/'Once.HC').write_bytes(fixture.read_bytes()+(b'\nsl_runtime=TRUE;' if args.runtime_block else b'')+b'\nSLCheck;\nSLAfter;\n')
            for name,data in TREE.items():
                target=overlay/name.lstrip('/');target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(data)
            image = out/'original.iso'
            subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(image)],cwd=ROOT,check=True)
        Guest = runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest']
        g = Guest(image, out/'guest', bool(args.disk), reference_cpus=1)
        if args.disk:
            g.wait('DONE native kernel startup\n')
            g.command('#include "C:/Probe/StreamSideEffect.HC"')
            g.command('sl_runtime=TRUE;SLCheck;' if args.runtime_block else 'SLCheck;')
            g.command('SLAfter;')
        g.wait('STREAM SIDE EFFECT DONE\n')
        data=(g.out/'stream-side-effect.bin').read_bytes()
        (out/'stream-side-effect.bin').write_bytes(data)
        literal=(g.out/'stream-side-effect.txt').read_bytes();(out/'stream-side-effect.txt').write_bytes(literal)
        report['literal_sha256']=hashlib.sha256(literal).hexdigest()
        if data!=expected_bytes:
            actual=struct.unpack('<'+'Q'*(len(data)//8),data)
            expected=struct.unpack('<'+'Q'*(len(expected_bytes)//8),expected_bytes)
            report['mismatches']=[{'word':i,'actual':a,'expected':e} for i,(a,e) in enumerate(zip(actual,expected)) if a!=e]
            raise ValueError('Stream literal ownership differs; see raw records')
        if literal!=LITERAL:raise ValueError('Retained literal bytes differ')
        report['state']=list(struct.unpack('<12Q',data))
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
