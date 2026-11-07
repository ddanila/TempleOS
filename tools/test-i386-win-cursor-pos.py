#!/usr/bin/env python3
"""Compare original window cursor selection and document/window state."""
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
    fixture = ROOT/'tests/guest/i386-win-cursor-pos/Contract.HC'
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
                  scope='Original WinCursorPosSet: current/default task, two-line text selection, scroll coordinate adjustment/reset, query-only preservation, focus, four outside edges, hidden document/window, lock ownership and text preservation. Not corrupt-document, cross-task or full mouse/FileMgr qualification.')
    (out/'fixture.HC').write_bytes(fixture.read_bytes())
    (out/'runner-source.py').write_bytes(Path(__file__).read_bytes())
    g = None
    try:
        if args.disk:
            image = out/'working.img'
            pack = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))
            before = pack['snapshot'](args.disk.read_bytes())[1]
            additions = {'/Probe/WC.HC': fixture.read_bytes()}
            report['packaging'] = pack['package'](args.disk.resolve(), image, additions=additions)
        else:
            overlay = out/'overlay'
            overlay.mkdir()
            report['reference_sha256'] = runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
            (overlay/'Once.HC').write_bytes(fixture.read_bytes()+b'\nWCContract;\n')
            image = out/'original.iso'
            subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(image)],cwd=ROOT,check=True)
        Guest = runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest']
        g = Guest(image, out/'guest', bool(args.disk))
        if args.disk:
            g.wait('DONE native kernel startup\n')
            g.command('#include "C:/Probe/WC.HC"')
            g.command('WCContract;')
        g.wait('WIN CURSOR DONE\n')
        data = (g.out/'cursor.bin').read_bytes()
        (out/'cursor.bin').write_bytes(data)
        report['rows'] = list(struct.unpack('<16q',data))
        if data != struct.pack('<16q', *([1]*16)):
            raise ValueError('Cursor behavior differs from independent assertions')
        details = (g.out/'details.bin').read_bytes()
        (out/'details.bin').write_bytes(details)
        report['coordinate_details'] = list(struct.unpack('<12q', details))
        if report['coordinate_details'] != [24,24,32,32,2,1,3,1,3,0,0,0]:
            raise ValueError('Viewport/coordinate record differs')
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
    except Exception as exc:
        report.update(result='fail',error=str(exc))
        raise
    finally:
        if g:
            g.close()
        report['inputs_unchanged'] = all(p.is_file() and sha(p)==pins[str(p)] for p in paths)
        if not report['inputs_unchanged']:
            report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')

if __name__ == '__main__':
    main()
