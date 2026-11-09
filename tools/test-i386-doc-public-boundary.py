#!/usr/bin/env python3
"""Check DolDoc success/error cleanup nested in queued public compiler controls."""
from pathlib import Path
import argparse
import hashlib
import json
import runpy
import struct

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    source, out = args.disk.resolve(), args.out.resolve()
    if out.exists():
        parser.error('Use a fresh output directory')
    out.mkdir(parents=True)
    fixture = ROOT/'tests/guest/i386-doc-public-boundary/Contract.HC'
    paths = [Path(__file__).resolve(), source, fixture, ROOT/'Compiler/OpCodes.DD']
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
                  scope='Real DolDoc valid foreground/button payloads and eight malformed commands, including unbound BI declarations inside queued public controls, exact outer queue/flags, caller heap recovery and owner-task backing usage/allocation recovery. No allocation-fault or cancellation-during-parse qualification.')
    (out/'fixture.HC').write_bytes(fixture.read_bytes())
    (out/'runner-source.py').write_bytes(Path(__file__).read_bytes())
    guest = None
    try:
        pack = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))
        before = pack['snapshot'](source.read_bytes())[1]
        for path in paths:
            if path.is_relative_to(ROOT) and path.suffix in ('.HC', '.HH', '.DD'):
                name = '/'+str(path.relative_to(ROOT))
                if name in before and path.read_bytes() != before[name][2]:
                    raise ValueError('Delivered source differs: '+name)
        layouts, layout_hashes = runpy.run_path(str(ROOT/'tools/test-i386-public-task-accounting.py'))['accounting_layouts'](source)
        report['accounting_layout_sha256'] = layout_hashes
        prelude = '\n'.join(text for text, _ in layouts).encode()+b'\n'
        additions = {'/Probe/Boundary.HC': prelude+fixture.read_bytes()}
        report['packaging'] = pack['package'](source, out/'working.img', additions=additions)
        Guest = runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest']
        guest = Guest(out/'working.img', out/'guest', True)
        guest.wait('DONE native kernel startup\n')
        guest.command('#include "C:/Probe/Boundary.HC"', timeout=300)
        guest.wait('DOC PUBLIC BOUNDARY DONE\n')
        data = (guest.out/'doc-boundary.bin').read_bytes()
        (out/'doc-boundary.bin').write_bytes(data)
        report['records'] = list(struct.unpack('<53q',data))
        detail = (guest.out/'doc-boundary-detail.bin').read_bytes()
        (out/'doc-boundary-detail.bin').write_bytes(detail)
        report['details'] = list(struct.unpack('<30q',detail))
        if report['records'] != [1,1,1,0,0]*10+[1,1,1]:
            raise ValueError('Public document boundary differs: '+str(report['records']))
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
        raise ValueError(report.get('error', 'Document boundary contract failed'))
    print('PASS public DolDoc compiler boundary')


if __name__ == '__main__':
    main()
