#!/usr/bin/env python3
"""Compare original save-key dispatch, metadata, modifier guards and native reboot persistence."""
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
    fixture = ROOT/'tests/guest/i386-doc-save-keys/Contract.HC'
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
                  scope='Fourteen save-key API cases: descriptions, Alt suppression, autosave on/off, create/overwrite, incoming locks, consuming/passing callback, null document, missing Ctrl bit and invalid signature. Exact files/text/cursor, roles and directory; native reboot persistence. No physical shortcut, timed autosave, heap or full editor qualification.')
    (out/'fixture.HC').write_bytes(fixture.read_bytes())
    (out/'runner-source.py').write_bytes(Path(__file__).read_bytes())
    g = None
    try:
        if args.disk:
            image = out/'working.img'
            pack = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))
            before = pack['snapshot'](args.disk.read_bytes())[1]
            additions = {'/Probe/DocSaveKeys.HC': fixture.read_bytes()}
            report['packaging'] = pack['package'](args.disk.resolve(), image, additions=additions)
        else:
            overlay = out/'overlay'
            overlay.mkdir()
            report['reference_sha256'] = runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
            (overlay/'Once.HC').write_bytes(fixture.read_bytes()+b'\nSKCheck("B:/SaveKeys");\n')
            image = out/'original.iso'
            subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(image)],cwd=ROOT,check=True)
        Guest = runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest']
        g = Guest(image, out/'guest', bool(args.disk), reference_cpus=1)
        if args.disk:
            g.wait('DONE native kernel startup\n')
            g.command('#include "C:/Probe/DocSaveKeys.HC"')
            g.command('SKCheck("C:/SaveKeys");')
        g.wait('DOC SAVE KEYS DONE\n')
        data = (g.out/'save-key-masks.bin').read_bytes()
        (out/'save-key-masks.bin').write_bytes(data)
        report['rows'] = list(struct.unpack('<14q',data))
        if args.disk:
            g.command('6*7;')
            report['arithmetic_pixels'] = g.result_pixels()
        g.close()
        g = None
        if args.disk:
            after = pack['snapshot'](image.read_bytes())[1]
            actual_new = {n:v[2] for n,v in after.items() if n not in before}
            expected_new = dict(additions)
            for i in range(14):
                expected_new[f'/SaveKeys/Case{i:02d}.TXT'] = b'Keep\n' if i in (6,7,9,10,11) else b'unchanged\n'
            report['new_files_hex'] = {n:v.hex() for n,v in actual_new.items() if n not in additions}
            report['expected_files_match'] = actual_new == expected_new
            if any(after.get(n)!=v for n,v in before.items()):
                raise ValueError('Preexisting filesystem entry changed')
            if after.get('/Probe/DocSaveKeys.HC', (None,None,None))[2] != fixture.read_bytes():
                raise ValueError('Packaged fixture changed')
            report['filesystem'] = runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['verify_mutated_volume'](image)
            if report['rows'] == [255]*14 and report['expected_files_match']:
                g=Guest(image,out/'reboot',True)
                g.wait('DONE native kernel startup\n')
                g.command('#include "C:/Probe/DocSaveKeys.HC"')
                g.command('SKReopen("C:/SaveKeys");')
                g.wait('DOC SAVE KEYS REOPEN DONE\n')
                data=(g.out/'save-key-reopen.bin').read_bytes()
                (out/'save-key-reopen.bin').write_bytes(data)
                report['reopen_rows']=list(struct.unpack('<14q',data))
                g.command('6*7;');report['reboot_arithmetic_pixels']=g.result_pixels()
                g.close();g=None
                if report['reopen_rows'] != [1]*14:raise ValueError('Reboot bytes differ')
                if pack['snapshot'](image.read_bytes())[1]!=after:raise ValueError('Reboot changed files')
                report['reboot_filesystem']=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['verify_mutated_volume'](image)
        if report['rows'] != [255]*14 or args.disk and not report['expected_files_match']:
            raise ValueError('Save key masks/files differ: '+repr(report['rows']))
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
