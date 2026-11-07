#!/usr/bin/env python3
"""Compare carry-preserving indexed loads and stores across all native scalar scales."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import struct
import subprocess

ROOT = Path(__file__).resolve().parents[1]
def expected_output():
    values=[]
    source=bytes(range(1,129))
    for kind in range(8):
        width=[1,2,4,8][kind%4]
        for n in range(8):
            for seed in range(2):
                value=int.from_bytes(source[n*width:n*width+width],'little') if kind<4 else (0x8877665544332211+n)&((1<<(width*8))-1)
                values.extend([value,value,0])
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
    fixture = ROOT/'tests/guest/i386-carry-addresses/Contract.HC'
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
                  scope='128 value/value/carry triples for indexed unsigned 1/2/4/8-byte loads and stores, indices 0..7 and both incoming carry seeds. Full-width output values and the zero carry of runtime scale arithmetic checked against original and independent byte oracle; not arbitrary pointer arithmetic or full flags qualification.')
    (out/'fixture.HC').write_bytes(fixture.read_bytes())
    (out/'runner-source.py').write_bytes(Path(__file__).read_bytes())
    g = None
    try:
        if args.disk:
            image = out/'working.img'
            pack = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))
            before = pack['snapshot'](args.disk.read_bytes())[1]
            additions = {'/Probe/CarryAddresses.HC': fixture.read_bytes()}
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
            g.command('#include "C:/Probe/CarryAddresses.HC"')
        g.wait('CARRY ADDRESSES DONE\n')
        data=(g.out/'carry-addresses.bin').read_bytes()
        (out/'carry-addresses.bin').write_bytes(data)
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
