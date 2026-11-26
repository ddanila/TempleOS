"""Check both MagicPairs documents against an independent divisor sieve."""

from array import array
import hashlib
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parent
BATCH = ROOT / 'comparison'
LIMIT = 1_000_000
HEADER = b'N:1000000 SqrtPrimes:168 CbrtPrimes:25 PowersOfPrimes:404'


def expected_pairs():
    sums = array('I', [0]) * LIMIT
    for divisor in range(2, LIMIT // 2):
        for value in range(2 * divisor, LIMIT, divisor):
            sums[value] += divisor
    return {(left, right) for left, right in enumerate(sums)
            if left < right < LIMIT and sums[right] == left}


def read_document(path, expected):
    data = path.read_bytes()
    if not data.endswith(b'\x05'):
        raise ValueError(f'Missing DolDoc end marker in {path}')
    lines = data[:-1].splitlines()
    if lines[0] != HEADER or any(not re.fullmatch(rb'\d+:\d+', line) for line in lines[1:-1]):
        raise ValueError(f'Invalid output in {path}')
    pairs = [tuple(map(int, line.split(b':'))) for line in lines[1:-1]]
    if len(pairs) != len(expected) or set(pairs) != expected:
        raise ValueError(f'Divisor pairs differ in {path}')
    summary = re.fullmatch(rb'Found:(\d+) Time:\s*(\d+\.\d{4})', lines[-1])
    if not summary or int(summary[1]) != len(expected):
        raise ValueError(f'Incorrect summary in {path}')
    return {'sha256': hashlib.sha256(data).hexdigest(),
            'elapsed_seconds': float(summary[2]), 'pairs': pairs}


def main():
    receipt = json.loads((BATCH/'result.json').read_text())
    if not receipt['inputs_unchanged'] or 'error' in receipt:
        raise ValueError('The guest batch did not complete with unchanged inputs')
    entry = receipt['entries']['Demo/MagicPairs.HC']
    expected = expected_pairs()
    runs = {name: read_document(BATCH/name/entry['output_file'], expected)
            for name in ('original', 'native')}
    for name, run in runs.items():
        if run['sha256'] != entry[name + '_sha256']:
            raise ValueError(f'{name} document differs from the batch receipt')
    print(json.dumps({'result': 'pass', 'image_sha256': receipt['input_sha256'],
                      'source_sha256': entry['source_sha256'], 'runs': runs,
                      'scope': 'All pairs and summary counts match an independent sieve. Elapsed time and worker output order may vary.'}, indent=2))


if __name__ == '__main__':
    main()
