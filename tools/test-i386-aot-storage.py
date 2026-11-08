#!/usr/bin/env python3
"""Compare shared AOT storage with original stores and normal native bindings."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import re
import struct
import subprocess

ROOT = Path(__file__).resolve().parents[1]
EXPECTED=struct.pack('<24Q',*([1]*24))
TREE={}

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('disk', type=Path, nargs='?')
    ap.add_argument('--out', type=Path, required=True)
    args = ap.parse_args()
    expected_bytes=EXPECTED
    out = args.out.resolve()
    if out.exists():
        ap.error('Use a fresh output directory')
    fixture = ROOT/'tests/guest/i386-aot-storage/Contract.HC'
    paths = [Path(__file__).resolve(), fixture] + [ROOT/('tools/'+name) for name in (
        'test-i386-autocomplete-interaction.py', 'test-i386-timeclock-reference.py',
        'test-i386-timeclock-welcome.py', 'build-iso.py',
        'package-i386-native-image.py', 'build-i386-kernel.py')]
    paths.extend([ROOT/'Kernel/FontStd.HC',ROOT/'Compiler/I386DataRangeCore.HC',ROOT/'Compiler/AOTStoreCore.HC'])
    if args.disk:
        paths.append(args.disk.resolve())
    out.mkdir()
    pins = {str(p): sha(p) for p in paths}
    report = dict(result='running', input_sha256=pins,
                  scope='Actual AOT store bindings: sequential widths, exact block ends and crossings, sparse absolute variadic patches, listing, high-water cursor, data-range gates/order/64-bit fields and heap recovery. Original source-loads unchanged store bodies (private in its compiler) and the port data-range recorder.')
    (out/'fixture.HC').write_bytes(fixture.read_bytes())
    (out/'runner-source.py').write_bytes(Path(__file__).read_bytes())
    g = None
    try:
        if args.disk:
            image = out/'working.img'
            pack = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))
            before = pack['snapshot'](args.disk.read_bytes())[1]
            additions = {'/Probe/AOTStorage.HC': fixture.read_bytes(),**{'/'+name:data for name,data in TREE.items()}}
            report['packaging'] = pack['package'](args.disk.resolve(), image, additions=additions)
        else:
            overlay = out/'overlay'
            overlay.mkdir()
            report['reference_sha256'] = runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
            (overlay/'Once.HC').write_bytes(b'#define CCF_TARGET_I386 0x10000000000\n#define IET_I386_DATA 26\n'+(ROOT/'Compiler/AOTStoreCore.HC').read_bytes()+(ROOT/'Compiler/I386DataRangeCore.HC').read_bytes()+fixture.read_bytes())
            for name,data in TREE.items():
                target=overlay/name;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(data)
            image = out/'original.iso'
            subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(image)],cwd=ROOT,check=True)
        Guest = runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest']
        g = Guest(image, out/'guest', bool(args.disk), reference_cpus=1)
        if args.disk:
            g.wait('DONE native kernel startup\n')
            g.command('#include "C:/Probe/AOTStorage.HC"',timeout=900)
        g.wait('AOT STORAGE DONE\n',timeout=900)
        data=(g.out/'aot-storage.bin').read_bytes()
        (out/'aot-storage.bin').write_bytes(data)
        (out/'aot-storage-bytes.bin').write_bytes((g.out/'aot-storage-bytes.bin').read_bytes())
        (out/'aot-storage-listing.txt').write_bytes((g.out/'aot-storage-listing.txt').read_bytes())
        if (out/'aot-storage-listing.txt').read_bytes()!=b'\n12 89ABCDEF FEDCBA9876543210 \n34 ':
            raise ValueError('AOT listing bytes differ')
        words=struct.unpack('<24Q',data)
        report['state']=list(words)
        if data!=expected_bytes:
            report['mismatches']=[{'word':i,'actual':v,'expected':1} for i,v in enumerate(words) if v!=1]
            raise ValueError('AOT storage differs; see raw records')
        expected=bytes.fromhex('cc00cdab891032547698badcfe000000000000dd12efcdab891032547698badc')
        if (out/'aot-storage-bytes.bin').read_bytes()!=expected:
            raise ValueError('AOT storage final bytes differ')
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
