"""Verify a nonzero horizontal recoil operand on paired X-Caliber runs."""

import argparse
import json
from pathlib import Path
import re


def read(path):
    receipt = json.loads(path.read_text())
    if receipt['result'] != 'pass':
        raise ValueError(f'Gameplay failed in {path}')
    workflow = receipt.get('play', receipt)
    if not workflow['gun_fired'] or not workflow['returned']:
        raise ValueError(f'Incomplete firing workflow in {path}')
    shots = [line for line in receipt['input_trace'] if line.startswith('XC shot return ')]
    if len(shots) != 1:
        raise ValueError(f'Expected exactly one shot in {path}')
    shot = re.fullmatch(r'XC shot return (\w+) queued (\w+) values (\w+) (\w+) (\w+)', shots[0])
    if shot is None:
        raise ValueError(f'Invalid shot trace in {path}')
    returned, queued, recoil, mass, velocity = (int(value, 16) for value in shot.groups())
    if recoil != velocity or not recoil & ((1 << 63) - 1) or recoil == mass:
        raise ValueError(f'Expected nonzero horizontal velocity as the recoil operand in {path}')
    if recoil & 0x7FF0000000000000 == 0x7FF0000000000000:
        raise ValueError(f'Non-finite horizontal velocity in {path}')
    return workflow, {
        'receipt': str(path),
        'return_offset': returned - queued,
        'recoil_bits': f'{recoil:016X}',
        'queued_mass_bits': f'{mass:016X}',
        'queued_horizontal_velocity_bits': f'{velocity:016X}',
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('original', type=Path)
    parser.add_argument('portable', type=Path, nargs='+')
    args = parser.parse_args()
    original, reference = read(args.original)
    if reference['return_offset'] != 40:
        raise ValueError('The original return does not point to the embedded mass')
    results = []
    for path in args.portable:
        workflow, candidate = read(path)
        for key in ('fixture_sha256', 'level', 'enemies', 'score', 'gun_fired', 'returned'):
            if original[key] != workflow[key]:
                raise ValueError(f'{key} differs in {path}')
        if candidate['return_offset'] != 0:
            raise ValueError(f'The portable return does not point to the queued shot in {path}')
        results.append(candidate)
    print(json.dumps({'result': 'pass', 'original': reference, 'portable': results}, indent=2))


if __name__ == '__main__':
    main()
