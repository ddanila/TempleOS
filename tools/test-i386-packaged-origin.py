#!/usr/bin/env python3
"""Exercise packaged-image provenance using real native artifacts and mutations."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ('disk', 'native-disk', 'native-result', 'installed-audit',
                 'packaging-result', 'out'):
        parser.add_argument('--' + name, type=Path, required=True)
    args = parser.parse_args()
    if args.out.exists():
        parser.error('Use a fresh output report')
    paths = [args.disk, args.native_disk, args.native_result,
             args.installed_audit, args.packaging_result,
             Path(__file__), ROOT / 'tools/test-i386-installed-workflows.py',
             ROOT / 'tools/package-i386-native-image.py', ROOT / 'tools/build-i386-kernel.py']
    sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    inputs = {str(p.resolve()): sha(p) for p in paths}
    verify = runpy.run_path(str(ROOT / 'tools/test-i386-installed-workflows.py'))['verify_image_origin']
    native = json.loads(args.native_result.read_text())
    audit = json.loads(args.installed_audit.read_text())
    common = [args.disk, native, audit, args.native_disk, args.packaging_result]
    verify(*common)
    cases = ['real packaged native origin accepted']

    def reject(label, arguments):
        try:
            verify(*arguments)
        except ValueError:
            cases.append(label)
        else:
            raise AssertionError('Accepted invalid provenance: ' + label)

    reject('packaged disk without origin rejected', common[:3])
    reject('missing packaging report rejected', common[:4])
    wrong = dict(audit, installed_disk_sha256=sha(args.native_disk))
    reject('unpackaged image audit rejected', [args.disk, native, wrong, *common[3:]])
    wrong_native = dict(native, target_disk_sha256='0' * 64)
    reject('wrong native prerequisite rejected', [args.disk, wrong_native, audit, *common[3:]])
    with tempfile.TemporaryDirectory(prefix='i386-package-mutation-') as directory:
        directory = Path(directory)
        damaged = bytearray(args.disk.read_bytes())
        damaged[0] ^= 1  # Preserve valid RedSea and native payload; alter boot bytes.
        disk = directory / 'forged.img'
        disk.write_bytes(damaged)
        packaging = json.loads(args.packaging_result.read_text())
        packaging['image_sha256'] = sha(disk)
        report = directory / 'forged.json'
        report.write_text(json.dumps(packaging))
        forged_audit = dict(audit, installed_disk_sha256=sha(disk))
        reject('matching forged reports cannot hide altered boot bytes',
               [disk, native, forged_audit, args.native_disk, report])
    if any(sha(Path(p)) != digest for p, digest in inputs.items()):
        raise ValueError('Origin test inputs changed')
    result = dict(result='pass', cases=cases, input_sha256=inputs,
                  scope='Packaging origin and targeted provenance mutations; not workstation runtime or release acceptance')
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps(result))


if __name__ == '__main__':
    main()
