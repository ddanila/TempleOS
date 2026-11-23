"""Compare first-movement SimpleAI states from paired guest receipts."""

import argparse
import json
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('original', type=Path)
    parser.add_argument('native', type=Path)
    args = parser.parse_args()
    original, native = (json.loads(p.read_text()) for p in (args.original, args.native))
    if original['result'] != 'pass' or native['result'] != 'pass':
        raise ValueError('Both guest workflows must finish')
    if original['fixture_sha256'] != native['fixture_sha256']:
        raise ValueError('Guest fixtures differ')
    differences = {}
    for stage in ('before_movement', 'after_movement'):
        differences[stage] = [
            {'unit': reference[0], 'original': reference[1:], 'native': actual[1:]}
            for reference, actual in zip(original['simple_ai'][stage],
                                         native['simple_ai'][stage], strict=True)
            if reference != actual
        ]
    match = not any(differences.values())
    print(json.dumps({'result': 'pass' if match else 'fail',
                      'original': str(args.original),
                      'native': str(args.native),
                      'differences': differences}, indent=2))
    return 0 if match else 1


if __name__ == '__main__':
    raise SystemExit(main())
