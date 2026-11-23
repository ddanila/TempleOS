"""Compare the offscreen terrain raster and map state from paired guest runs."""

import argparse
import hashlib
import json
from pathlib import Path


def read_run(directory):
    report = json.loads((directory / 'result.json').read_text())
    if report['result'] != 'pass':
        raise ValueError(f'Guest run did not pass in {directory}')
    files = {}
    for name in ('map-pixels', 'terrain', 'rivers', 'roads'):
        data = (directory / 'guest' / f'{name}.bin').read_bytes()
        if hashlib.sha256(data).hexdigest() != report['map'][name]:
            raise ValueError(f'Unexpected {name} hash in {directory}')
        files[name] = data
    return report, files


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('original', type=Path)
    parser.add_argument('native', type=Path)
    args = parser.parse_args()
    original, original_files = read_run(args.original)
    native, native_files = read_run(args.native)
    for key in ('fixture_sha256', 'phases'):
        if original[key] != native[key]:
            raise ValueError(f'Guest {key} differs')
    keys = ('width', 'height', 'stride', 'rows', 'columns')
    dimensions = {key: original['map'][key] for key in keys}
    if dimensions != {key: native['map'][key] for key in keys}:
        raise ValueError('Guest map dimensions differ')

    differences = {
        name: sum(left != right for left, right in zip(data, native_files[name], strict=True))
        for name, data in original_files.items()
    }
    match = not any(differences.values())
    print(json.dumps({'result': 'pass' if match else 'fail',
                      'original': str(args.original / 'result.json'),
                      'native': str(args.native / 'result.json'),
                      'dimensions': dimensions,
                      'differing_bytes': differences}, indent=2))
    return 0 if match else 1


if __name__ == '__main__':
    raise SystemExit(main())
