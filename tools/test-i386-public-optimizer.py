#!/usr/bin/env python3
"""Compare normal public optimizer IR folding with the pinned original."""
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
    ap.add_argument('--ram-mib', type=int, default=16)
    ap.add_argument('--optimizer-storage', choices=('source', 'provider', 'resident'))
    args = ap.parse_args()
    if args.optimizer_storage is None:
        args.optimizer_storage = 'resident' if args.disk else 'source'
    if args.disk and not args.reference:
        ap.error('Native runs require a passing original --reference')
    if args.optimizer_storage != 'source' and not args.disk:
        ap.error('Provider/resident storage requires a native disk')
    out = args.out.resolve()
    if out.exists():
        ap.error('Use a fresh output directory')
    fixture = ROOT/'tests/guest/i386-public-optimizer/Contract.HC'
    paths = [Path(__file__).resolve(), fixture] + [ROOT/'tools'/n for n in (
        'test-i386-autocomplete-interaction.py', 'test-i386-timeclock-reference.py',
        'test-i386-timeclock-welcome.py', 'build-iso.py')]
    if args.disk:
        paths += [args.disk.resolve(), ROOT/'Kernel/I386/PublicLoader.HH', ROOT/'tools/package-i386-native-image.py', ROOT/'tools/build-i386-kernel.py', ROOT/'Compiler/OptPass012Core.HC', ROOT/'Compiler/I386/PublicOptSupport.HC', ROOT/'Kernel/I386/PublicCompiler.HH']
    if args.reference:
        paths += [args.reference.resolve()/'result.json', args.reference.resolve()/'optimizer-trace.bin']
    pins = {str(p): sha(p) for p in paths}
    out.mkdir()
    report = dict(result='running', input_sha256=pins, reference_revision=REFERENCE,
                  ram_mib=args.ram_mib, optimizer_storage=args.optimizer_storage,
                  scope='Complete pinned original optimizer versus normal public optimizer: sixteen manually constructed integer/F64 expression graphs through passes 0/1/2, exact opcode/type/value traces, reusable full parser stacks, canonical type identity and exact caller heap recovery. This does not qualify parsing, COCCompile, diagnostics, branch/pointer rewrites or full compiler delivery.')
    guest = None
    try:
        (out/'fixture.HC').write_bytes(fixture.read_bytes())
        (out/'runner-source.py').write_bytes(Path(__file__).read_bytes())
        if args.disk:
            image = out/'working.img'
            pack = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))
            before = pack['snapshot'](args.disk.read_bytes())[1]
            additions = {'/Probe/Optimizer.HC': b'#include "/Kernel/I386/PublicCompiler.HH"\n'+fixture.read_bytes()}
            report['packaging'] = pack['package'](args.disk.resolve(), image, additions=additions)
        else:
            overlay = out/'overlay'
            overlay.mkdir()
            report['reference_sha256'] = runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
            original = lambda name: subprocess.check_output(['git','show',REFERENCE+':'+name],cwd=ROOT)
            code=original('Compiler/CInit.HC')
            core=code[code.index(b'CIntermediateStruct intermediate_code_table'):code.index(b'\nU0 CmpLoadDefines(')]
            code=original('Compiler/PrsLib.HC')
            core+=code[:code.index(b'I64 PrsKeyWord(')]
            core+=code[code.index(b'CIntermediateCode *ICAdd('):code.index(b'CCodeMisc *COCGoToLabelFind(')]
            core+=code[code.index(b'U0 COCDel('):code.index(b'U0 COCHeaderPut(')]
            core+=original('Compiler/OptLib.HC').split(b'I64 CmpRawType(')[0]
            code=original('Compiler/CExcept.HC');core+=code[code.index(b'U0 ICClassPut('):]
            core+=b'#define OptPass012 POReferenceOptimize\n'+original('Compiler/OptPass012.HC')
            (out/'reference-core.HC').write_bytes(core)
            report['reference_core_sha256'] = hashlib.sha256(core).hexdigest()
            (overlay/'Once.HC').write_bytes(core+fixture.read_bytes())
            image = out/'original.iso'
            subprocess.run(['python3', 'tools/build-iso.py', '--overlay', str(overlay), '--output', str(image)], cwd=ROOT, check=True)
        Guest = runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest']
        guest = Guest(image, out/'guest', bool(args.disk), ram_mib=args.ram_mib, reference_cpus=1)
        if args.disk:
            guest.wait('DONE native kernel startup\n')
            guest.command('#include "C:/Probe/Optimizer.HC"', timeout=900)
        guest.wait('PUBLIC OPTIMIZER DONE\n', timeout=900)
        for name in ('optimizer-state.bin', 'optimizer-trace.bin', 'optimizer-heap.bin'):
            (out/name).write_bytes((guest.out/name).read_bytes())
        report['state'] = list(struct.unpack('<18Q', (out/'optimizer-state.bin').read_bytes()))
        report['values'] = list(struct.unpack('<48Q', (out/'optimizer-trace.bin').read_bytes()))
        if report['state'] != [1]*18:
            raise ValueError('Public optimizer contract failed; see state')
        report['heap_metrics'] = list(struct.unpack('<2q', (out/'optimizer-heap.bin').read_bytes()))
        if report['heap_metrics'] != [0]*2:
            raise ValueError('Optimizer retained caller heap bytes')
        if args.reference:
            gold = json.loads((args.reference/'result.json').read_text())
            if gold.get('result')!='pass' or not gold.get('inputs_unchanged'):
                raise ValueError('Passing original reference required')
            if (out/'optimizer-trace.bin').read_bytes() != (args.reference/'optimizer-trace.bin').read_bytes():
                raise ValueError('Raw relocation values differ from original')
        if args.disk:
            log = guest.collect()
            report['source_loads'] = log.count('PUBLIC OPT loaded\n')
            report['provider_loads'] = log.count('PUBLIC OPT provider\n')
            report['resident_loads'] = log.count('PUBLIC OPT resident\n')
            expected = {'source': (1, 0, 0), 'provider': (0, 1, 0), 'resident': (0, 0, 1)}[args.optimizer_storage]
            if (report['source_loads'], report['provider_loads'], report['resident_loads']) != expected:
                raise ValueError('Expected exactly one optimizer load from the selected storage')
            report['system_loads'] = sum((report['source_loads'], report['provider_loads'], report['resident_loads']))
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
            try:
                guest.screenshot('failure')
            except Exception as cleanup_error:
                report['failure_screenshot_error'] = str(cleanup_error)
        raise
    finally:
        if guest:
            try:
                guest.close()
            except Exception as cleanup_error:
                report['guest_cleanup_error'] = str(cleanup_error)
        report['inputs_unchanged'] = all(p.is_file() and sha(p)==pins[str(p)] for p in paths)
        if not report['inputs_unchanged']:
            report.update(result='fail', error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')


if __name__ == '__main__':
    main()
