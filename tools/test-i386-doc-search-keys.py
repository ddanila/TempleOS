#!/usr/bin/env python3
"""Compare original Ctrl-F/Shift-Ctrl-F dispatch through real forms and replacement menus."""
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
    fixture = ROOT/'tests/guest/i386-doc-search-keys/Contract.HC'
    paths = [Path(__file__).resolve(), fixture] + [ROOT/('tools/'+name) for name in (
        'test-i386-autocomplete-interaction.py', 'test-i386-timeclock-reference.py',
        'test-i386-timeclock-welcome.py', 'build-iso.py',
        'package-i386-native-image.py', 'build-i386-kernel.py')]
    paths.append(ROOT/'Kernel/FontStd.HC')
    find=ROOT/'Adam/Opt/Utils/Find.HC'
    original=subprocess.check_output(['git','show','c26482bb6ad3f80106d28504ec5db3c6a360732c:Adam/Opt/Utils/Find.HC'],cwd=ROOT)
    if find.read_bytes()!=original:raise ValueError('Original Find source changed')
    paths.append(find)
    if args.disk:
        paths.append(args.disk.resolve())
    out.mkdir()
    pins = {str(p): sha(p) for p in paths}
    report = dict(result='running', input_sha256=pins,
                  scope='Nine public Ctrl-F action cases: edited form accept/cancel, replacement ALL/cancel, Shift-Ctrl-F wizard cancellation, Alt guards, incoming lock and absent Ctrl scan flag; four metadata cases. Real forms/menu, programmatic field formatting and posted Esc/ShiftEsc. No physical shortcut, file-search execution, heap or visual qualification.')
    (out/'fixture.HC').write_bytes(fixture.read_bytes())
    (out/'runner-source.py').write_bytes(Path(__file__).read_bytes())
    g = None
    try:
        if args.disk:
            image = out/'working.img'
            pack = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))
            before = pack['snapshot'](args.disk.read_bytes())[1]
            if before['/Adam/Opt/Utils/Find.HC'][2]!=original:raise ValueError('Delivered Find differs')
            additions = {'/Probe/DocSearchKeys.HC': fixture.read_bytes()}
            report['packaging'] = pack['package'](args.disk.resolve(), image, additions=additions)
        else:
            overlay = out/'overlay'
            overlay.mkdir()
            report['reference_sha256'] = runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
            (overlay/'Once.HC').write_bytes(fixture.read_bytes()+b'\nSKCheck;\n')
            image = out/'original.iso'
            subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(image)],cwd=ROOT,check=True)
        Guest = runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest']
        g = Guest(image, out/'guest', bool(args.disk), reference_cpus=1)
        if args.disk:
            g.wait('DONE native kernel startup\n')
            g.command('#include "C:/Adam/Opt/Utils/Find.HC"')
            g.command('#include "C:/Probe/DocSearchKeys.HC"')
            g.command('SKCheck;')
        g.wait('DOC SEARCH KEYS DONE\n')
        for name in ('search-key-actions.bin','search-key-metadata.bin'):
            (out/name).write_bytes((g.out/name).read_bytes())
        report['actions']=list(struct.unpack('<9q',(out/'search-key-actions.bin').read_bytes()))
        report['metadata']=list(struct.unpack('<4q',(out/'search-key-metadata.bin').read_bytes()))
        if args.disk:
            g.command('6*7;')
            report['arithmetic_pixels'] = g.result_pixels()
        g.close()
        g = None
        if args.disk:
            after = pack['snapshot'](image.read_bytes())[1]
            if {n for n in set(before)|set(after) if before.get(n)!=after.get(n)} != set(additions):
                raise ValueError('Unexpected filesystem changes')
            if any(n in before or after[n][2]!=data for n,data in additions.items()):
                raise ValueError('Fixture additions differ')
            report['preserved_files']=len(before)
            report['filesystem'] = runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['verify_mutated_volume'](image)
        if report['actions']!=[127]*9 or report['metadata']!=[15]*4:
            raise ValueError('Search-key dispatch differs: '+repr((report['actions'],report['metadata'])))
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
