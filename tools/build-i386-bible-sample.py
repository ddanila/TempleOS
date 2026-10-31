#!/usr/bin/env python3
"""Build a bounded Bible-link test image from an existing native build."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

ROOT = Path(__file__).resolve().parents[1]


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('build', type=Path, help='Completed native cross-build directory')
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    build, out = args.build.resolve(), args.out.resolve()
    if out.exists():
        parser.error('Use a fresh output directory')
    source, bible = build/'kernel.img', ROOT/'Misc/Bible.TXT'
    exports = build/'exports'
    inputs = [source, bible, Path(__file__).resolve(), ROOT/'tools/build-i386-kernel.py',
              ROOT/'tools/package-i386-native-image.py']
    inputs += sorted(p for p in exports.iterdir() if p.is_file())
    for directory in ('Kernel', 'Compiler', 'Adam', 'Doc'):
        inputs += sorted(p for p in (ROOT/directory).rglob('*')
                         if p.is_file() and p.suffix.upper() in ('.HC', '.HH', '.DD', '.PRJ'))
    inputs += [ROOT/'tools/guest/i386-kernel/IncludeInner.HC',
               ROOT/'tools/guest/i386-kernel/IncludeOuter.HC']
    pins = {str(p): sha(p) for p in inputs}
    out.mkdir(parents=True)
    base, result = out/'minimal.img', out/'kernel.img'
    with source.open('rb') as f:
        boot = f.read(2048*512)
    if len(boot) != 2048*512:
        raise ValueError('Source image is too short')
    with base.open('wb') as f:
        f.write(boot)
        f.truncate(16*1024*1024)
    builder = runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))
    volume = builder['package_volume'](base, exports, 'minimal')
    builder['verify_volume'](base, volume)
    lines = bible.read_bytes().splitlines(keepends=True)
    if len(lines) < 400:
        raise ValueError('Bible source has fewer than 400 lines')
    sample = b''.join(lines[:400])
    if b'1:1 In the beginning' not in sample:
        raise ValueError('Bible sample lacks Genesis 1:1')
    package = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))
    report = package['package'](base, result, additions={'/Misc/Bible.TXT': sample})
    report.update(input_sha256=pins, sample_lines=400,
                  sample_sha256=hashlib.sha256(sample).hexdigest(),
                  inputs_unchanged=all(sha(Path(p)) == digest for p,digest in pins.items()))
    if not report['inputs_unchanged']:
        raise ValueError('Inputs changed while constructing sample image')
    (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
    print('Built bounded Bible sample image', result)


if __name__ == '__main__':
    main()
