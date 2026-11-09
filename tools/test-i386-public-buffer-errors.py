#!/usr/bin/env python3
"""Check failed normal CmpBuf ownership and subsequent recovery."""
from pathlib import Path
import argparse
import hashlib
import json
import runpy
import struct
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--baseline-revision', help='Require delivered sources to match this Git revision instead of the checkout')
    parser.add_argument('--assembly-errors', action='store_true', help='Check failures within nested assembly joins')
    parser.add_argument('--operand-errors', action='store_true', help='Check partial assembly operand expression ownership')
    args = parser.parse_args()
    if args.assembly_errors and args.operand_errors:
        parser.error('Select one error fixture')
    source, out = args.disk.resolve(), args.out.resolve()
    if out.exists():
        parser.error('Use a fresh output directory')
    out.mkdir(parents=True)
    fixture = ROOT/'tests/guest/i386-public-buffer-errors'/('Operands.HC' if args.operand_errors else 'Assembly.HC' if args.assembly_errors else 'Contract.HC')
    paths = [Path(__file__).resolve(), source, fixture, ROOT/'Compiler/OpCodes.DD']
    boundary = ROOT/'tests/guest/i386-public-buffer-errors/Boundary.HC'
    if args.assembly_errors:
        paths.append(boundary)
    paths += [ROOT/'Adam/DolDoc'/name for name in ('DocDollarParseCore.HC', 'DocDollarFlagsCore.HC', 'DocDollarServices.HH', 'DocEntryLife.HC', 'DocFormDataCore.HC')]
    paths += [ROOT/'tools'/name for name in (
        'test-i386-autocomplete-interaction.py', 'package-i386-native-image.py',
        'build-i386-kernel.py', 'test-i386-timeclock-welcome.py',
        'test-i386-public-task-accounting.py')]
    paths += sorted(p for directory in ('Compiler', 'Kernel')
                    for p in (ROOT/directory).rglob('*')
                    if p.is_file() and p.suffix in ('.HC', '.HH'))
    sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    pins = {str(p): sha(p) for p in paths}
    report = dict(result='running', input_sha256=pins,
                  scope='Ten actual normal CmpBuf compiler failures after different partial outputs; borrowed input, errors/warnings, control queue, caller heap, fresh successful compilation and owner-task backing reclamation. Not OOM, arbitrary exceptions or cancellation qualification.')
    (out/'fixture.HC').write_bytes(fixture.read_bytes())
    (out/'runner-source.py').write_bytes(Path(__file__).read_bytes())
    baseline = None
    if args.baseline_revision:
        baseline = subprocess.check_output(['git', 'rev-parse', args.baseline_revision+'^{commit}'], cwd=ROOT, text=True).strip()
        report['baseline_revision'] = baseline
        report['baseline_source_sha256'] = {}
    report['assembly_errors'] = args.assembly_errors
    report['operand_errors'] = args.operand_errors
    guest = None
    try:
        pack = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))
        before = pack['snapshot'](source.read_bytes())[1]
        for path in paths:
            if path.is_relative_to(ROOT) and path.suffix in ('.HC', '.HH', '.DD'):
                name = '/'+str(path.relative_to(ROOT))
                if name in before:
                    expected_source = path.read_bytes()
                    if baseline:
                        expected_source = subprocess.check_output(['git', 'show', baseline+':'+name[1:]], cwd=ROOT)
                        report['baseline_source_sha256'][name] = hashlib.sha256(expected_source).hexdigest()
                    if expected_source != before[name][2]:
                        raise ValueError('Delivered source differs: '+name)
        layouts, layout_hashes = runpy.run_path(str(ROOT/'tools/test-i386-public-task-accounting.py'))['accounting_layouts'](source)
        report['accounting_layout_sha256'] = layout_hashes
        prelude = '\n'.join(text for text, _ in layouts).encode()+b'\n'
        additions = {'/Probe/BufferErrors.HC': prelude+fixture.read_bytes()}
        if args.assembly_errors:
            additions['/Probe/JoinBoundary.HC'] = boundary.read_bytes()
        report['packaging'] = pack['package'](source, out/'working.img', additions=additions)
        Guest = runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest']
        guest = Guest(out/'working.img', out/'guest', True)
        guest.wait('DONE native kernel startup\n')
        guest.command('#include "C:/Probe/BufferErrors.HC"', timeout=300)
        guest.wait('PUBLIC BUFFER ERRORS DONE\n')
        data = (guest.out/'buffer-errors.bin').read_bytes()
        (out/'buffer-errors.bin').write_bytes(data)
        report['records'] = list(struct.unpack('<217q',data))
        report['raw_screen_cache'] = report['records'][214:217]
        report['diagnostic_owner_heap_raw'] = report['records'][210:214]
        report['diagnostic_warmup_raw'] = report['records'][202:210]
        report['diagnostic_warmup_stable'] = report['records'][206:210] == report['records'][93:97]
        report['fix_set_records'] = report['records'][187:197]
        report['single_user'] = report['records'][197]
        report['backing_after_fix_restore'] = report['records'][198:202]
        report['backing_raw'] = report['records'][93:105]
        report['backing_per_case'] = [report['records'][107+i*8:115+i*8] for i in range(10)]
        expected = [1,1,1,1,1,0,0,1]*10+[1,1,1]
        report['ownership_matches'] = report['records'][:83] == expected and report['fix_set_records'] == [1]*10 and report['diagnostic_warmup_stable'] and report['records'][213] == 1 and report['records'][215] == 1
        if args.assembly_errors:
            guest.command('#include \"C:/Probe/JoinBoundary.HC\"', timeout=180)
            guest.wait('JOIN BOUNDARY DONE\n')
            report['boundary_records'] = list(struct.unpack('<45q', (guest.out/'join-boundary.bin').read_bytes()))
            report['boundary_matches'] = all(report['boundary_records'][i*15:i*15+14] == [1]*12+[0,0] for i in range(3))
            report['ownership_matches'] = report['ownership_matches'] and report['boundary_matches']
        guest.command('6*7;')
        report['arithmetic_pixels'] = guest.result_pixels()
        guest.close()
        guest = None
        after = pack['snapshot']((out/'working.img').read_bytes())[1]
        changed = {n for n in set(before)|set(after) if before.get(n) != after.get(n)}
        report['changed_files'] = sorted(changed)
        if changed != set(additions):
            raise ValueError('Unexpected filesystem changes')
        report['filesystem'] = runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['verify_mutated_volume'](out/'working.img')
        if not report['ownership_matches']:
            raise ValueError('Failed-buffer ownership differs: '+str(report['records']))
        report['result'] = 'pass'
    except BaseException as error:
        report.update(result='fail', error=str(error) or type(error).__name__)
        raise
    finally:
        if guest:
            guest.close()
        report['inputs_unchanged'] = all(sha(Path(name)) == digest for name, digest in pins.items())
        if not report['inputs_unchanged']:
            report.update(result='fail', error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
    if report['result'] != 'pass':
        raise ValueError(report.get('error', 'Failed buffer contract failed'))
    print('PASS failed normal CmpBuf ownership')


if __name__ == '__main__':
    main()
