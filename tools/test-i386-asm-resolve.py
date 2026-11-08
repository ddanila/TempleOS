#!/usr/bin/env python3
"""Capture executed deferred assembler expressions and local resolution ownership."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import struct
import subprocess

ROOT = Path(__file__).resolve().parents[1]
REFERENCE = 'c26482bb6ad3f80106d28504ec5db3c6a360732c'


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--out', type=Path, required=True)
    args = ap.parse_args()
    out = args.out.resolve()
    if out.exists():
        ap.error('Use a fresh output directory')
    fixture = ROOT/'tests/guest/i386-asm-resolve/Contract.HC'
    paths = [Path(__file__).resolve(), fixture] + [ROOT/'tools'/n for n in (
        'test-i386-autocomplete-interaction.py', 'test-i386-timeclock-reference.py',
        'test-i386-timeclock-welcome.py', 'build-iso.py')]
    pins = {str(p): sha(p) for p in paths}
    out.mkdir()
    report = dict(result='running', input_sha256=pins, reference_revision=REFERENCE,
                  scope='Original deferred expression execution, all eight relocation widths, cross-block writes, unresolved import metadata, constructor local precedence/LIFO, local resolution/table reset, import ordering/addends, external call patching and function exports. Original retained constructor names and consumed list heads are explicitly observed and caller-cleaned. Diagnostics, allocation failures and native delivery remain open.')
    guest = None
    try:
        overlay = out/'overlay'
        overlay.mkdir()
        report['reference_sha256'] = runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
        code = subprocess.check_output(['git', 'show', REFERENCE+':Compiler/AsmResolve.HC'], cwd=ROOT)
        aliases = b'#define AsmResolve ARReferenceResolve\n#define AOTLocalsResolve ARReferenceLocals\n#define AOTGlblsResolve ARReferenceGlobals\n#define AsmUnresolvedAdd ARReferenceAdd\n'
        stores = subprocess.check_output(['git', 'show', REFERENCE+':Compiler/AsmLib.HC'], cwd=ROOT)
        start = stores.index(b'U0 AOTStoreCodeU8At(')
        end = stores.index(b'\nI64 AsmLexExpression(', start+1)
        core = b'#define AOTStoreCodeU8At ARReferenceStoreAt\n'+stores[start:end]+aliases+code
        (out/'reference-core.HC').write_bytes(core)
        report['reference_core_sha256'] = hashlib.sha256(core).hexdigest()
        (out/'fixture.HC').write_bytes(fixture.read_bytes())
        (out/'runner-source.py').write_bytes(Path(__file__).read_bytes())
        (overlay/'Once.HC').write_bytes(core+b'#define AR_X64 1\n'+fixture.read_bytes())
        image = out/'original.iso'
        subprocess.run(['python3', 'tools/build-iso.py', '--overlay', str(overlay), '--output', str(image)], cwd=ROOT, check=True)
        Guest = runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest']
        guest = Guest(image, out/'guest', False, reference_cpus=1)
        guest.wait('ASM RESOLVE DONE\n', timeout=900)
        for name in ('asm-resolve.bin', 'asm-values.bin'):
            (out/name).write_bytes((guest.out/name).read_bytes())
        report['state'] = list(struct.unpack('<32Q', (out/'asm-resolve.bin').read_bytes()))
        report['values'] = list(struct.unpack('<8Q', (out/'asm-values.bin').read_bytes()))
        if report['state'] != [1]*32:
            raise ValueError('Assembler resolver contract failed; see state')
        guest.close()
        guest = None
        report['result'] = 'pass'
    except BaseException as exc:
        report.update(result='fail', error=str(exc))
        if guest:
            guest.screenshot('failure')
        raise
    finally:
        if guest:
            guest.close()
        report['inputs_unchanged'] = all(p.is_file() and sha(p)==pins[str(p)] for p in paths)
        if not report['inputs_unchanged']:
            report.update(result='fail', error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')


if __name__ == '__main__':
    main()
