#!/usr/bin/env python3
"""Run the unchanged 64-bit carry demo and compare every counter, shift and branch bit."""
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
    lines=['BigCnt\n']
    for n in range(1,1025):lines.append(f'{n//64:016X} {((n%64)<<58):016X}\n')
    lines.append('Big Shift\n')
    for n in range(1,129):
        bits=(1<<n)&((1<<128)-1)
        lines.append(f'{bits>>64:016X} {bits&mask:016X}\n')
    lines.append('Branch\n'+f'{0xFFCC3311:064b}'+'\n')
    return ''.join(lines).encode()+b'\x05'
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
    fixture = ROOT/'tests/guest/i386-carry-demo/Contract.HC'
    paths = [Path(__file__).resolve(), fixture] + [ROOT/('tools/'+name) for name in (
        'test-i386-autocomplete-interaction.py', 'test-i386-timeclock-reference.py',
        'test-i386-timeclock-welcome.py', 'build-iso.py',
        'package-i386-native-image.py', 'build-i386-kernel.py')]
    paths.append(ROOT/'Kernel/FontStd.HC')
    paths.append(ROOT/'Demo/Carry.HC')
    if args.disk:
        paths.append(args.disk.resolve())
    out.mkdir()
    pins = {str(p): sha(p) for p in paths}
    report = dict(result='running', input_sha256=pins,
                  scope='Complete unchanged Demo/Carry.HC on the normal system: all 1024 counter rows, 128 two-word shift rows and 64 carry-branch bits, plus retained real functions called after declaration input release and churn. Exact mathematical output oracle; not full CPU-flag/compiler qualification.')
    (out/'fixture.HC').write_bytes(fixture.read_bytes())
    (out/'runner-source.py').write_bytes(Path(__file__).read_bytes())
    g = None
    try:
        if args.disk:
            image = out/'working.img'
            pack = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))
            before = pack['snapshot'](args.disk.read_bytes())[1]
            if before['/Demo/Carry.HC'][2]!=(ROOT/'Demo/Carry.HC').read_bytes():raise ValueError('Delivered demo differs')
            additions = {'/Probe/CarryDemo.HC': fixture.read_bytes()}
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
            g.command('#include "C:/Probe/CarryDemo.HC"')
        g.wait('CARRY DEMO DONE\n')
        data=(g.out/'carry-demo-mask.bin').read_bytes()
        (out/'carry-demo-mask.bin').write_bytes(data)
        for name in ('carry-demo-initial.DD','carry-demo-retained.DD'):
            if (g.out/name).exists():
                (out/name).write_bytes((g.out/name).read_bytes())
        report['mask']=struct.unpack('<q',data)[0]
        if report['mask']!=7:raise ValueError('Carry demo workflow differs: '+str(report['mask']))
        report['outputs']={}
        for name,expected in [('carry-demo-initial.DD',EXPECTED),('carry-demo-retained.DD',EXPECTED)]:
            actual=(out/name).read_bytes()
            if actual!=expected:raise ValueError('Unexpected complete demo output: '+name)
            report['outputs'][name]={'bytes':len(actual),'sha256':hashlib.sha256(actual).hexdigest()}
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
