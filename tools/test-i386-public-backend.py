#!/usr/bin/env python3
"""Compare normal public COCCompile with the pinned original compiler."""
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
    args = ap.parse_args()
    if args.disk and not args.reference:
        ap.error('Native runs require a passing original --reference')
    out = args.out.resolve()
    if out.exists():
        ap.error('Use a fresh output directory')
    fixture = ROOT/'tests/guest/i386-public-backend/Contract.HC'
    paths = [Path(__file__).resolve(), fixture] + [ROOT/'tools'/n for n in (
        'test-i386-autocomplete-interaction.py', 'test-i386-timeclock-reference.py',
        'test-i386-timeclock-welcome.py', 'build-iso.py')]
    if args.disk:
        paths += [args.disk.resolve(), ROOT/'Kernel/I386/PublicLoader.HH', ROOT/'tools/package-i386-native-image.py', ROOT/'tools/build-i386-kernel.py', ROOT/'Compiler/I386/PublicBackendCore.HC', ROOT/'Compiler/I386/PublicBackendSupport.HC', ROOT/'Kernel/I386/PublicCompiler.HH']
    if args.reference:
        paths += [args.reference.resolve()/'result.json', args.reference.resolve()/'backend-trace.bin']
    pins = {str(p): sha(p) for p in paths}
    out.mkdir()
    report = dict(result='running', input_sha256=pins, reference_revision=REFERENCE,
                  scope='Original COCCompile binary versus normal target backend: sixteen integer/F64 IR graphs, executed retained code after control deletion, returned raw type, debug map range/start/end, consumed graph, restored context and exact caller data/code heaps. Two executable AOT constant graphs also check segment-relative debug maps, output types and borrowed context/metadata. Direct and late-slot JIT calls, AOT import/extern relocation ownership and execution after control deletion are also checked. Failure recovery, assembly, tracing and complete compiler workflows remain open.')
    guest = None
    try:
        (out/'fixture.HC').write_bytes(fixture.read_bytes())
        (out/'runner-source.py').write_bytes(Path(__file__).read_bytes())
        if args.disk:
            image = out/'working.img'
            pack = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))
            before = pack['snapshot'](args.disk.read_bytes())[1]
            additions = {'/Probe/Backend.HC': b'#include "/Kernel/I386/PublicCompiler.HH"\n'+fixture.read_bytes()}
            report['packaging'] = pack['package'](args.disk.resolve(), image, additions=additions)
        else:
            overlay = out/'overlay'
            overlay.mkdir()
            report['reference_sha256'] = runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
            original = lambda name: subprocess.check_output(['git','show',REFERENCE+':'+name],cwd=ROOT)
            core=b'public extern U8 *COCCompile(CCmpCtrl *cc,I64 *_code_size,CDbgInfo **_dbg,I64 *_type);\n'
            code=original('Compiler/PrsLib.HC')
            core+=code[code.index(b'CIntermediateCode *ICAdd('):code.index(b'CCodeMisc *COCGoToLabelFind(')]
            (out/'reference-core.HC').write_bytes(core)
            report['reference_core_sha256'] = hashlib.sha256(core).hexdigest()
            (overlay/'Once.HC').write_bytes(core+b'#define BC_ORIGINAL 1\n'+fixture.read_bytes())
            image = out/'original.iso'
            subprocess.run(['python3', 'tools/build-iso.py', '--overlay', str(overlay), '--output', str(image)], cwd=ROOT, check=True)
        Guest = runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest']
        guest = Guest(image, out/'guest', bool(args.disk), ram_mib=args.ram_mib, reference_cpus=1)
        if args.disk:
            guest.wait('DONE native kernel startup\n')
            guest.command('#include "C:/Probe/Backend.HC"', timeout=900)
        guest.wait('PUBLIC BACKEND DONE\n', timeout=900)
        for name in ('backend-state.bin', 'backend-trace.bin', 'backend-heap.bin'):
            (out/name).write_bytes((guest.out/name).read_bytes())
        report['state'] = list(struct.unpack('<48Q', (out/'backend-state.bin').read_bytes()))
        report['values'] = list(struct.unpack('<44Q', (out/'backend-trace.bin').read_bytes()))
        if report['state'] != [1]*48:
            raise ValueError('Public backend contract failed; see state')
        report['heap_metrics'] = list(struct.unpack('<2q', (out/'backend-heap.bin').read_bytes()))
        if report['heap_metrics'] != [0]*2:
            raise ValueError('Backend retained caller heap bytes')
        if args.reference:
            gold = json.loads((args.reference/'result.json').read_text())
            if gold.get('result')!='pass' or not gold.get('inputs_unchanged'):
                raise ValueError('Passing original reference required')
            if (out/'backend-trace.bin').read_bytes() != (args.reference/'backend-trace.bin').read_bytes():
                raise ValueError('Raw relocation values differ from original')
        if args.disk:
            report['system_loads'] = guest.collect().count('PUBLIC BACKEND loaded\n')
            if report['system_loads']!=1:
                raise ValueError('Expected one system backend load')
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
