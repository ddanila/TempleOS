#!/usr/bin/env python3
"""Verify an unpacked i386 release-candidate directory without the source tree."""

import argparse
import gzip
import hashlib
import json
from pathlib import Path


def file_sha256(path):
    digest = hashlib.sha256()
    with path.open('rb') as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b''):
            digest.update(chunk)
    return digest.hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('package', nargs='?', type=Path,
                        default=Path(__file__).resolve().parent,
                        help='Directory containing manifest.json')
    args = parser.parse_args()
    package = args.package.resolve()
    manifest = json.loads((package / 'manifest.json').read_text())
    if manifest.get('format') != 1 or manifest.get('image') != 'TempleOS-i386-gen2.img':
        raise ValueError('Unexpected release manifest format or image')
    files = manifest['files_sha256']
    actual = {str(path.relative_to(package)) for path in package.rglob('*')
              if path.is_file() and path.relative_to(package) != Path('manifest.json')}
    if actual != set(files):
        raise ValueError(f'Bundle file set differs: missing={set(files)-actual}, extra={actual-set(files)}')
    for name, expected in files.items():
        if file_sha256(package / name) != expected:
            raise ValueError(f'Bundle file hash differs: {name}')
    disk = package / (manifest['image'] + '.gz')
    digest = hashlib.sha256()
    size = 0
    with gzip.open(disk, 'rb') as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b''):
            digest.update(chunk)
            size += len(chunk)
    if (size, digest.hexdigest()) != (manifest['image_bytes'], manifest['image_sha256']):
        raise ValueError('Decompressed disk differs from manifest')
    print(json.dumps({'result': 'pass', 'files': len(files),
                      'image_sha256': digest.hexdigest(),
                      'packaging_revision': manifest['packaging_revision']}, indent=2))


if __name__ == '__main__':
    main()
