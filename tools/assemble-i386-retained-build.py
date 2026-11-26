#!/usr/bin/env python3
"""Assemble audited guest-built modules from separate copies of one base disk."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path, help='Common input disk used for each guest build')
    parser.add_argument('--build', type=Path, action='append', required=True,
                        help='Passing retained-build output directory, repeat for each build')
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    disk, out = args.disk.resolve(), args.out.resolve()
    if out.exists():
        parser.error('Use a fresh output directory')

    builder = ROOT/'tools/test-i386-retained-build.py'
    packer = ROOT/'tools/package-i386-native-image.py'
    helper = ROOT/'tools/build-i386-kernel.py'
    build = runpy.run_path(str(builder))
    pack = runpy.run_path(str(packer))
    sha = build['sha256']
    expected = set(build['MODULES'])
    snapshot = pack['snapshot']
    verify = runpy.run_path(str(helper))['verify_mutated_volume']
    pins = {str(path): sha(path) for path in (disk, builder, packer, helper, Path(__file__).resolve())}
    verify(disk)
    volume_offset = pack['START'] * 512
    base = disk.read_bytes()
    _, base_files, _ = snapshot(base)
    boot_area = base[:volume_offset]
    del base

    modules, additions, receipts = {}, {}, []
    for directory in args.build:
        directory = directory.resolve()
        receipt, image = directory/'result.json', directory/'source.img'
        report = json.loads(receipt.read_text())
        records = report.get('modules', {})
        names = set(records)
        if report.get('result') != 'pass' or not names or not names <= expected:
            raise ValueError(f'Invalid retained build receipt: {receipt}')
        if report.get('build_provider_loads') != 1:
            raise ValueError(f'Missing native build provider evidence: {receipt}')
        if names & modules.keys():
            raise ValueError(f'Duplicate retained builds: {sorted(names & modules.keys())}')
        pins[str(receipt)], pins[str(image)] = sha(receipt), sha(image)
        if pins[str(image)] != report.get('source_disk_sha256'):
            raise ValueError(f'Retained build disk hash differs: {image}')

        verify(image)
        contents = image.read_bytes()
        if contents[:volume_offset] != boot_area:
            raise ValueError(f'Retained build boot area differs from the base: {image}')
        _, files, _ = snapshot(contents)
        del contents
        outputs = {f'/Probe/Retained{name}.t32m' for name in names}
        changed = {name for name in files.keys() | base_files.keys()
                   if files.get(name) != base_files.get(name)}
        if changed != outputs or outputs & base_files.keys():
            raise ValueError(f'Build changed files outside its new module outputs: {image}')
        for name, record in records.items():
            path = f'/Probe/Retained{name}.t32m'
            payload = files[path][2]
            count, exports = build['exports_of'](payload)
            if (record.get('sha256') != hashlib.sha256(payload).hexdigest() or
                    record.get('bytes') != len(payload) or record.get('records') != count or
                    record.get('exports') != len(exports)):
                raise ValueError(f'Retained build payload differs: {name}')
            installed = base_files[f'/Modules/I386/{name}.t32m'][2]
            _, installed_exports = build['exports_of'](installed)
            missing = set(installed_exports) - set(exports)
            if name == 'CompilerRuntime':
                missing -= {'_I386_DIV_BEGIN', '_I386_DIV_END'}
            if missing or set(exports) - set(installed_exports):
                raise ValueError(f'Retained exports differ from the base: {name}')
            if name == 'ConsoleRuntime':
                build['check_console_alloc_wrappers'](payload)
            modules[name] = record
            additions[path] = payload
        receipts.append(str(receipt))

    if modules.keys() != expected:
        raise ValueError(f'Missing retained builds: {sorted(expected - modules.keys())}')
    out.mkdir(parents=True)
    source = out/'source.img'
    packaging = pack['package'](disk, source, additions=additions)
    _, merged, _ = snapshot(source.read_bytes())
    if (merged.keys() != base_files.keys() | additions.keys() or
            any(merged[path] != original for path, original in base_files.items()) or
            any(merged[path][2] != payload for path, payload in additions.items())):
        raise ValueError('Assembled disk differs from its base and audited outputs')
    if not all(sha(Path(path)) == digest for path, digest in pins.items()):
        raise ValueError('Retained assembly inputs changed')
    result = dict(result='pass', source_disk_sha256=sha(source),
                  module_order=list(modules), modules=modules, build_receipts=receipts,
                  input_sha256=pins, inputs_unchanged=True, packaging=packaging,
                  scope='Byte-verified assembly of complete guest-built retained module outputs')
    (out/'result.json').write_text(json.dumps(result, indent=2)+'\n')


if __name__ == '__main__':
    main()
