#!/usr/bin/env python3
"""Compare carry and values for 64-bit add/subtract and shift boundaries."""
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
    values=[]
    for kind in range(3):
        for a in patterns:
            for count in [0,1,31,32,33,63,64,65,95,127]:
                n=count&63
                for seed in range(2):
                    signed=a if a<(1<<63) else a-(1<<64)
                    value=((a<<n) if kind==0 else (a>>n) if kind==1 else (signed>>n))&mask
                    cf=seed if not n else ((a>>(64-n))&1) if kind==0 else ((a>>(n-1))&1)
                    values.extend([value,cf])
    for kind in range(2):
        for a in patterns:
            for b in patterns:
                value=a+b if kind==0 else a-b
                values.extend([value&mask,int(value>mask) if kind==0 else int(a<b)])
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
    fixture = ROOT/'tests/guest/i386-carry-operations/Contract.HC'
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
                  scope='608 actual value/carry pairs: U64 add/subtract and U64/I64 shifts with both carry seeds, counts 0/1/31/32/33/63/64/65/95/127, eight full-width patterns. Normal public compiler, independent Python arithmetic oracle; not other flag or operator qualification.')
    (out/'fixture.HC').write_bytes(fixture.read_bytes())
    (out/'runner-source.py').write_bytes(Path(__file__).read_bytes())
    g = None
    try:
        if args.disk:
            image = out/'working.img'
            pack = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))
            before = pack['snapshot'](args.disk.read_bytes())[1]
            additions = {'/Probe/CarryOperations.HC': fixture.read_bytes()}
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
            g.command('#include "C:/Probe/CarryOperations.HC"')
        g.wait('CARRY OPERATIONS DONE\n')
        data=(g.out/'carry-operations.bin').read_bytes()
        (out/'carry-operations.bin').write_bytes(data)
        if data!=EXPECTED:
            actual=struct.unpack('<'+'Q'*(len(data)//8),data)
            expected=struct.unpack('<'+'Q'*(len(EXPECTED)//8),EXPECTED)
            report['mismatches']=[{'word':i,'actual':a,'expected':e} for i,(a,e) in enumerate(zip(actual,expected)) if a!=e]
            raise ValueError('Carry operations differ; see mismatches and raw binary')
        report['outputs']={'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest(),'pairs':len(data)//16}
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
