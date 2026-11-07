#!/usr/bin/env python3
"""Compare manager-frame borders with native synchronous frames from an offset caller."""
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
    fixture = ROOT/'tests/guest/i386-window-border-context/Contract.HC'
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
                  scope='Actual GrUpdateTaskWin on a parked task: all 4800 text cells checked for exact screen-coordinate borders and fill. Original executes on WinMgr; native synchronous frame executes on offset caller. Not complete window/graphics qualification.')
    (out/'fixture.HC').write_bytes(fixture.read_bytes())
    (out/'runner-source.py').write_bytes(Path(__file__).read_bytes())
    g = None
    try:
        if args.disk:
            image = out/'working.img'
            pack = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))
            before = pack['snapshot'](args.disk.read_bytes())[1]
            additions = {'/Probe/WBC.HC': b'#define WBC_NATIVE\n'+fixture.read_bytes()}
            report['packaging'] = pack['package'](args.disk.resolve(), image, additions=additions)
        else:
            overlay = out/'overlay'
            overlay.mkdir()
            report['reference_sha256'] = runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
            (overlay/'Once.HC').write_bytes(fixture.read_bytes()+b'\nWBCContract;\n')
            image = out/'original.iso'
            subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(image)],cwd=ROOT,check=True)
        Guest = runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest']
        g = Guest(image, out/'guest', bool(args.disk))
        if args.disk:
            g.wait('DONE native kernel startup\n')
            g.command('#include "C:/Probe/WBC.HC"')
            g.command('WBCContract;')
        g.wait('WINDOW BORDER DONE\n')
        data = (g.out/'border-rows.bin').read_bytes()
        (out/'border-rows.bin').write_bytes(data)
        report['rows'] = list(struct.unpack('<2q',data))
        cells=(g.out/'border-cells.bin').read_bytes()
        if len(cells)!=19200:raise ValueError('Incomplete cell capture')
        (out/'border-cells.bin').write_bytes(cells)
        expected = [0x0720]*4800
        for y in range(15,26):
            for x in range(10,21):expected[y*80+x]=0xF100
        for x in range(10,21):
            for y in (14,26):expected[y*80+x]=0x0102
        for y in range(15,26):
            for x in (9,21):expected[y*80+x]=0x0104
        for x,y,ch in ((9,14,6),(21,14,8),(9,26,10),(21,26,12)):
            expected[y*80+x]=0x0100+ch
        report['host_cell_matches'] = sum(a==b for a,b in
            zip(struct.unpack('<4800I',cells),expected))
        if data != struct.pack('<2q', 4800, 0 if args.disk else 1) or report['host_cell_matches']!=4800:
            raise ValueError('Border coordinates differ: '+repr(report['rows']))
        if args.disk:
            g.command('6*7;')
            report['arithmetic_pixels'] = g.result_pixels()
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
