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
    ap.add_argument('disk', type=Path, nargs='?')
    ap.add_argument('--reference', type=Path)
    ap.add_argument('--shared-x64', action='store_true')
    args = ap.parse_args()
    if args.disk and not args.reference:
        ap.error('Native runs require a passing original --reference')
    if args.disk and args.shared_x64:
        ap.error('Shared x64 is an original-OS run')
    out = args.out.resolve()
    if out.exists():
        ap.error('Use a fresh output directory')
    fixture = ROOT/'tests/guest/i386-asm-resolve/Contract.HC'
    paths = [Path(__file__).resolve(), fixture] + [ROOT/'tools'/n for n in (
        'test-i386-autocomplete-interaction.py', 'test-i386-timeclock-reference.py',
        'test-i386-timeclock-welcome.py', 'build-iso.py')]
    if args.disk:
        paths += [args.disk.resolve(), ROOT/'Kernel/I386/PublicLoader.HH', ROOT/'tools/package-i386-native-image.py', ROOT/'tools/build-i386-kernel.py', ROOT/'Compiler/AsmResolveCore.HC', ROOT/'Compiler/I386/PublicJITSupport.HC']
    if args.shared_x64:
        paths.append(ROOT/'Compiler/AsmResolveCore.HC')
    if args.reference:
        paths += [args.reference.resolve()/'result.json', args.reference.resolve()/'asm-values.bin']
    pins = {str(p): sha(p) for p in paths}
    out.mkdir()
    report = dict(result='running', input_sha256=pins, reference_revision=REFERENCE,
                  scope='Original/shared/native deferred expression execution, all eight relocation widths, cross-block writes, unresolved import metadata, constructor local precedence/LIFO, local resolution/table reset, import ordering/addends, external call patching and function exports. Original retained constructor names and consumed list heads are explicitly observed and caller-cleaned. Cold and steady caller data/code heaps must return exactly to their baselines. Eight first-record exceptions check range limits, undefined locals/globals, double imports and unresolved exports before writes or expression execution. Allocation failures and partial-progress unwind remain open.')
    guest = None
    try:
        (out/'fixture.HC').write_bytes(fixture.read_bytes())
        (out/'runner-source.py').write_bytes(Path(__file__).read_bytes())
        if args.disk:
            image = out/'working.img'
            pack = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))
            before = pack['snapshot'](args.disk.read_bytes())[1]
            additions = {'/Probe/AsmResolve.HC': b'#include "/Kernel/I386/PublicLoader.HH"\n'+fixture.read_bytes()}
            report['packaging'] = pack['package'](args.disk.resolve(), image, additions=additions)
        else:
            overlay = out/'overlay'
            overlay.mkdir()
            report['reference_sha256'] = runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
            code = subprocess.check_output(['git', 'show', REFERENCE+':Compiler/AsmResolve.HC'], cwd=ROOT)
            aliases = b'#define AsmResolve ARReferenceResolve\n#define AOTLocalsResolve ARReferenceLocals\n#define AOTGlblsResolve ARReferenceGlobals\n#define AsmUnresolvedAdd ARReferenceAdd\n'
            stores = subprocess.check_output(['git', 'show', REFERENCE+':Compiler/AsmLib.HC'], cwd=ROOT)
            start = stores.index(b'U0 AOTStoreCodeU8At(')
            end = stores.index(b'\nI64 AsmLexExpression(', start+1)
            if args.shared_x64:
                code = (ROOT/'Compiler/AsmResolveCore.HC').read_bytes()
                aliases = b'#define CCF_TARGET_I386 0x10000000000\n#define IEF_I386_DATA_EXPORT 2\n'
                aliases += b'#define ASM_RESOLVE_IMPL AsmResolve\n#define AOT_LOCALS_RESOLVE_IMPL AOTLocalsResolve\n#define AOT_GLBLS_RESOLVE_IMPL AOTGlblsResolve\n#define ASM_UNRESOLVED_ADD_IMPL AsmUnresolvedAdd\n'
            core = b'#define AOTStoreCodeU8At ARReferenceStoreAt\n'+stores[start:end]+aliases+code
            (out/'reference-core.HC').write_bytes(core)
            report['reference_core_sha256'] = hashlib.sha256(core).hexdigest()
            original = 1
            if args.shared_x64:
                original = 0
            (overlay/'Once.HC').write_bytes(core+f'#define AR_X64 1\n#define AR_ORIGINAL {original}\n'.encode()+fixture.read_bytes())
            image = out/'original.iso'
            subprocess.run(['python3', 'tools/build-iso.py', '--overlay', str(overlay), '--output', str(image)], cwd=ROOT, check=True)
        Guest = runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest']
        guest = Guest(image, out/'guest', bool(args.disk), reference_cpus=1)
        if args.disk:
            guest.wait('DONE native kernel startup\n')
            guest.command('#include "C:/Probe/AsmResolve.HC"', timeout=900)
        guest.wait('ASM RESOLVE DONE\n', timeout=900)
        for name in ('asm-resolve.bin', 'asm-values.bin', 'asm-heap.bin'):
            (out/name).write_bytes((guest.out/name).read_bytes())
        report['state'] = list(struct.unpack('<38Q', (out/'asm-resolve.bin').read_bytes()))
        report['values'] = list(struct.unpack('<8Q', (out/'asm-values.bin').read_bytes()))
        if report['state'] != [1]*38:
            raise ValueError('Assembler resolver contract failed; see state')
        report['heap_metrics'] = list(struct.unpack('<6q', (out/'asm-heap.bin').read_bytes()))
        if report['heap_metrics'][:4] != [0]*4:
            raise ValueError('Resolver retained caller heap bytes')
        if args.reference:
            gold = json.loads((args.reference/'result.json').read_text())
            if gold.get('result')!='pass' or not gold.get('inputs_unchanged'):
                raise ValueError('Passing original reference required')
            if (out/'asm-values.bin').read_bytes() != (args.reference/'asm-values.bin').read_bytes():
                raise ValueError('Raw relocation values differ from original')
        if args.disk:
            report['system_loads'] = guest.collect().count('PUBLIC JIT loaded\n')
            if report['system_loads']!=1:
                raise ValueError('Expected one system resolver load')
            guest.command('6*7;')
            report['arithmetic_pixels'] = guest.result_pixels()
        guest.close()
        guest = None
        if args.disk:
            after = pack['snapshot'](image.read_bytes())[1]
            if {n for n in set(before)|set(after) if before.get(n)!=after.get(n)} != set(additions):
                raise ValueError('Unexpected filesystem changes')
            report['filesystem'] = runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['verify_mutated_volume'](image)
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
