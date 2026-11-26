"""Validate the four prime-sieve reports independently of timing."""
import hashlib
import json
from math import isqrt
from pathlib import Path
import re

BATCH = Path(__file__).resolve().parent / 'comparison'
LIMITS = (100, 100, 1_000_000, 1_000_000)
SUMMARY = re.compile(rb'\$FG,4\$CPUs:1 PrimeRange:([\d,]+) PrimeCnt:([\d,]+) Time: *([\d.,]+)\$FG\$')


def expected(limit):
    flags = bytearray(b'\x01') * limit
    flags[:2] = b'\x00\x00'
    for n in range(2, isqrt(limit - 1) + 1):
        if flags[n]:
            flags[n*n::n] = b'\x00' * ((limit - 1 - n*n) // n + 1)
    return sum(flags), [n for n in range(limit - 100, limit) if flags[n]]


def observe(data):
    lines = data[:-1].splitlines()
    if not data.endswith(b'\x05') or len(lines) != 2 * len(LIMITS):
        raise ValueError('Expected four complete prime reports')
    runs = []
    for limit, values, summary in zip(LIMITS, lines[::2], lines[1::2]):
        header = SUMMARY.fullmatch(summary)
        found = list(map(int, values.split()))
        count, tail = expected(limit)
        if (not header or int(header[1].replace(b',', b'')) != limit or
                int(header[2].replace(b',', b'')) != count or found != tail):
            raise ValueError(f'Incorrect prime count or tail for {limit}')
        runs.append({'limit': limit, 'count': count, 'tail': found,
                     'elapsed_seconds': float(header[3].replace(b',', b''))})
    return {'sha256': hashlib.sha256(data).hexdigest(), 'runs': runs}


if __name__ == '__main__':
    print(json.dumps({'result':'pass', **observe((BATCH/'original/demo-0.DD').read_bytes())},
                     indent=2))
