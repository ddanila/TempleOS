#!/usr/bin/env python3
"""Compare 64-bit multiply, negate and pre/post increment carry with the original."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import struct
import subprocess

ROOT = Path(__file__).resolve().parents[1]
def expected_output():
    mask=(1<<64)-1
    patterns=[0,1,0x80000000,0x100000000,0x8000000000000000,
              mask,0x89ABCDEF01234567,0x0123456789ABCDEF]
    signed=lambda a:a if a<(1<<63) else a-(1<<64)
    values=[]
    for kind in range(2):
        for a in patterns:
            for b in patterns:
                product=a*b if not kind else signed(a)*signed(b)
                cf=int(product>mask) if not kind else int(not -(1<<63)<=product<(1<<63))
                value=(a*b)&mask
                values.extend([value,value,cf])
    for kind in range(2):
        for a in patterns:
            product=a*a if not kind else signed(a)*signed(a)
            cf=int(product>mask) if not kind else int(not -(1<<63)<=product<(1<<63))
            values.extend([(a*a)&mask,(a*a)&mask,cf])
    for a in patterns:
        values.extend([(-a)&mask,(-a)&mask,int(a!=0)])
    for kind in range(4):
        for a in patterns:
            for seed in range(2):
                after=(a+(1 if kind in (0,2) else -1))&mask
                values.extend([after if kind<2 else a,after,seed])
    return struct.pack('<'+'Q'*len(values),*values)
EXPECTED=expected_output()

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
    fixture = ROOT/'tests/guest/i386-carry-arithmetic/Contract.HC'
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
                  scope='216 triples of expression result, stored result and carry for U64/I64 variable multiplication and square intrinsics, U64 negation and pre/post increment/decrement with both carry seeds. Independent full-width Python oracle and normal public compiler; not other flags or narrow-width qualification.')
    (out/'fixture.HC').write_bytes(fixture.read_bytes())
    (out/'runner-source.py').write_bytes(Path(__file__).read_bytes())
    g = None
    try:
        if args.disk:
            image = out/'working.img'
            pack = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))
            before = pack['snapshot'](args.disk.read_bytes())[1]
            additions = {'/Probe/CarryArithmetic.HC': fixture.read_bytes()}
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
            g.command('#include "C:/Probe/CarryArithmetic.HC"')
        g.wait('CARRY ARITHMETIC DONE\n')
        data=(g.out/'carry-arithmetic.bin').read_bytes()
        (out/'carry-arithmetic.bin').write_bytes(data)
        if data!=EXPECTED:
            actual=struct.unpack('<'+'Q'*(len(data)//8),data)
            expected=struct.unpack('<'+'Q'*(len(EXPECTED)//8),EXPECTED)
            report['mismatches']=[{'word':i,'actual':a,'expected':e} for i,(a,e) in enumerate(zip(actual,expected)) if a!=e]
            raise ValueError('Carry operations differ; see mismatches and raw binary')
        report['outputs']={'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest(),'triples':len(data)//24}
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
