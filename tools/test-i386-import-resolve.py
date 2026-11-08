#!/usr/bin/env python3
"""Compare import relocation and deferred resolution against original source bodies."""
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
    fixture = ROOT/'tests/guest/i386-import-resolve/Contract.HC'
    paths = [Path(__file__).resolve(), fixture] + [ROOT/('tools/'+name) for name in (
        'test-i386-autocomplete-interaction.py', 'test-i386-timeclock-reference.py',
        'test-i386-timeclock-welcome.py', 'build-iso.py',
        'package-i386-native-image.py', 'build-i386-kernel.py')]
    paths.extend([ROOT/'Kernel/FontStd.HC',ROOT/'Kernel/ImportResolveCore.HC'])
    if args.disk:
        paths.extend([args.disk.resolve(),ROOT/'Kernel/I386/PublicLoader.HH'])
    out.mkdir()
    pins = {str(p): sha(p) for p in paths}
    report = dict(result='running', input_sha256=pins,
                  scope='Original source-loaded import resolution versus normal native bindings: grouped stream cursor, eight relocation widths, delayed export lookup, function/global targets, repeated pending imports, parent-table lookup and exact cleanup. Whole module loading remains open.')
    (out/'fixture.HC').write_bytes(fixture.read_bytes())
    (out/'runner-source.py').write_bytes(Path(__file__).read_bytes())
    g = None
    try:
        if args.disk:
            image = out/'working.img'
            pack = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))
            before = pack['snapshot'](args.disk.read_bytes())[1]
            additions = {'/Probe/ImportResolve.HC': b'#include \"/Kernel/I386/PublicLoader.HH\"\n'+fixture.read_bytes(),**{'/'+name:data for name,data in TREE.items()}}
            report['packaging'] = pack['package'](args.disk.resolve(), image, additions=additions)
        else:
            overlay = out/'overlay'
            overlay.mkdir()
            report['reference_sha256'] = runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
            original=subprocess.check_output(['git','show','c26482bb6ad3f80106d28504ec5db3c6a360732c:Kernel/KLoad.HC'],cwd=ROOT)
            reference=original[:original.index(b'U0 LoadPass1(')]
            (out/'reference-core.HC').write_bytes(reference)
            report['reference_core_sha256']=hashlib.sha256(reference).hexdigest()
            (overlay/'Once.HC').write_bytes(b'#define LoadOneImport IRReferenceLoadOneImport\n#define SysSymImportsResolve IRReferenceSysSymImportsResolve\n'+reference+fixture.read_bytes())
            for name,data in TREE.items():
                target=overlay/name;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(data)
            image = out/'original.iso'
            subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(image)],cwd=ROOT,check=True)
        Guest = runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest']
        g = Guest(image, out/'guest', bool(args.disk), reference_cpus=1)
        if args.disk:
            g.wait('DONE native kernel startup\n')
            g.command('#include "C:/Probe/ImportResolve.HC"',timeout=900)
        g.wait('IMPORT RESOLVE DONE\n',timeout=900)
        data=(g.out/'import-resolve.bin').read_bytes()
        (out/'import-resolve.bin').write_bytes(data)
        (out/'import-negative.bin').write_bytes((g.out/'import-negative.bin').read_bytes())
        report['negative_relocations']=list(struct.unpack('<4Q',(out/'import-negative.bin').read_bytes()))
        words=struct.unpack('<24Q',data)
        report['state']=list(words)
        if data!=expected_bytes:
            report['mismatches']=[{'word':i,'actual':v,'expected':1} for i,v in enumerate(words) if v!=1]
            raise ValueError('Import resolution differs; see raw records')
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
